const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { createClient } = require('redis');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;

// ---------- Postgres connection pool ----------
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'postgres',
  port: process.env.POSTGRES_PORT || 5432,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

// ---------- Redis client ----------
const redisClient = createClient({
  url: `redis://${process.env.REDIS_HOST || 'redis'}:${process.env.REDIS_PORT || 6379}`,
});
redisClient.on('error', (err) => console.error('Redis Client Error', err));

let redisReady = false;
(async () => {
  try {
    await redisClient.connect();
    redisReady = true;
    console.log('Connected to Redis');
  } catch (err) {
    console.error('Failed to connect to Redis:', err.message);
  }
})();

// ---------- Health check endpoint ----------
// Docker Compose's healthcheck hits this URL. It must return 200 ONLY
// when the service can actually do its job (DB + cache reachable).
app.get('/health', async (req, res) => {
  const status = { service: 'backend', postgres: 'down', redis: 'down' };
  let healthy = true;

  try {
    await pool.query('SELECT 1');
    status.postgres = 'up';
  } catch (err) {
    healthy = false;
  }

  try {
    if (redisReady) {
      await redisClient.ping();
      status.redis = 'up';
    } else {
      healthy = false;
    }
  } catch (err) {
    healthy = false;
  }

  res.status(healthy ? 200 : 503).json(status);
});

// ---------- API routes ----------
app.get('/api/tasks', async (req, res) => {
  try {
    // Try cache first
    const cached = redisReady ? await redisClient.get('tasks:all') : null;
    if (cached) {
      return res.json({ source: 'cache', tasks: JSON.parse(cached) });
    }

    const result = await pool.query('SELECT * FROM tasks ORDER BY id');
    if (redisReady) {
      await redisClient.setEx('tasks:all', 30, JSON.stringify(result.rows)); // cache 30s
    }
    res.json({ source: 'database', tasks: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

app.post('/api/tasks', async (req, res) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: 'title is required' });

  try {
    const result = await pool.query(
      'INSERT INTO tasks (title, completed) VALUES ($1, false) RETURNING *',
      [title]
    );
    if (redisReady) await redisClient.del('tasks:all'); // invalidate cache
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

app.patch('/api/tasks/:id/complete', async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE tasks SET completed = true WHERE id = $1 RETURNING *',
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Task not found' });
    if (redisReady) await redisClient.del('tasks:all');
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

app.listen(PORT, () => {
  console.log(`Backend API listening on port ${PORT}`);
});
