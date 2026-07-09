# Task Manager — Docker Compose Microservices Project

A complete, working example of a multi-container application orchestrated
with Docker Compose, demonstrating service networking, environment
configuration, health checks, and proper startup dependencies.

## What this project contains

```
task-manager/
├── docker-compose.yml       ← orchestrates all 4 services
├── .env.example             ← template for environment variables
├── .gitignore
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js            ← Express API (talks to Postgres + Redis)
│   └── db/init.sql          ← auto-seeds the database on first run
└── frontend/
    ├── Dockerfile
    ├── nginx.conf           ← serves UI + proxies /api to backend
    └── public/
        ├── index.html
        └── app.js
```

## The 4 services

| Service   | Role                              | Image / Build      | Exposed Port |
|-----------|-----------------------------------|---------------------|--------------|
| postgres  | Database (stores tasks)           | postgres:16-alpine  | 5432         |
| redis     | Cache (speeds up reads)           | redis:7-alpine      | 6379         |
| backend   | REST API (Node/Express)           | built from ./backend| 5000         |
| frontend  | Web UI (static site via Nginx)    | built from ./frontend| 8080        |

**Startup order enforced by health checks:**
`postgres` & `redis` must report **healthy** → then `backend` starts →
`backend` must report **healthy** → then `frontend` starts.
This is exactly what `depends_on: condition: service_healthy` does —
it's stronger than plain `depends_on`, which only waits for the container
to *start*, not for the app inside it to actually be *ready*.

**Networking:** two isolated Docker networks are used.
`backend-net` holds postgres, redis, and backend.
`frontend-net` holds backend and frontend.
The frontend container can reach the backend, but it **cannot** reach
postgres or redis directly — only the backend can. This mirrors how
real production systems isolate the database tier.

---

## Step-by-Step Setup Guide

### Step 1 — Install prerequisites

You need Docker and Docker Compose installed:

- **Windows/Mac**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop) (includes Compose).
- **Linux**: Install Docker Engine, then the Compose plugin:
  ```bash
  sudo apt update
  sudo apt install docker.io docker-compose-plugin
  sudo systemctl enable --now docker
  ```

Verify installation:
```bash
docker --version
docker compose version
```

### Step 2 — Get the project files

Unzip/copy the `task-manager/` folder anywhere on your machine, then:
```bash
cd task-manager
```

### Step 3 — Create your environment file

The `.env.example` file lists every variable the project needs
(database credentials, ports, etc). Copy it to a real `.env` file:

```bash
cp .env.example .env
```

Open `.env` in an editor and change at least `POSTGRES_PASSWORD` to
something of your own. **Never commit `.env` to version control** —
`.gitignore` already excludes it.

### Step 4 — Understand what each variable does

| Variable            | Used by   | Purpose                              |
|----------------------|-----------|---------------------------------------|
| POSTGRES_USER        | postgres, backend | DB login username              |
| POSTGRES_PASSWORD    | postgres, backend | DB login password              |
| POSTGRES_DB          | postgres, backend | Database name                  |
| POSTGRES_PORT        | postgres  | Host port mapped to DB's port 5432 |
| REDIS_PORT           | redis     | Host port mapped to Redis's port 6379 |
| BACKEND_PORT         | backend   | Host port to reach the API directly |
| FRONTEND_PORT        | frontend  | Host port to open the web UI   |
| NODE_ENV             | backend   | Runtime mode for the Node app  |

Docker Compose automatically reads `.env` in the same folder and
substitutes `${VARIABLE_NAME}` placeholders inside `docker-compose.yml`.

### Step 5 — Build the images

```bash
docker compose build
```
This reads the `Dockerfile` in `backend/` and `frontend/`, installs
dependencies (npm packages for backend; copies static files for
frontend), and produces two custom images. `postgres` and `redis` use
official pre-built images, so nothing needs building for them.

### Step 6 — Start everything

```bash
docker compose up -d
```
`-d` runs it in the background ("detached"). Compose will:
1. Create the two networks and the `pg_data` volume.
2. Start `postgres` and `redis` together (they don't depend on each other).
3. Wait until **both** report healthy.
4. Start `backend`, wait until it's healthy.
5. Start `frontend`.

### Step 7 — Watch it start up (optional but recommended the first time)

```bash
docker compose up
```
(without `-d`) streams logs from every container to your terminal so you
can see the dependency chain happen in real time. Press `Ctrl+C` to stop
watching (containers keep running if you used `-d` instead).

### Step 8 — Check that everything is healthy

```bash
docker compose ps
```
You should see all 4 containers with a `STATUS` of `Up (healthy)`.
If any show `starting` or `unhealthy`, wait a few seconds and re-run —
some services take a moment to finish their startup checks.

### Step 9 — Use the application

- Open the web UI: **http://localhost:8080**
  You'll see a live health banner (Postgres/Redis status) and a task list.
  Add a task, mark tasks done — this all flows through backend → Postgres,
  with Redis caching reads for 30 seconds.

- Hit the API directly: **http://localhost:5000/api/tasks**
- Check backend health directly: **http://localhost:5000/health**

### Step 10 — View logs for a specific service

```bash
docker compose logs -f backend
docker compose logs -f postgres
```
`-f` follows the log output live. Press `Ctrl+C` to exit.

### Step 11 — Stop / restart / clean up

```bash
# Stop all containers, keep data
docker compose stop

# Start them again later
docker compose start

# Stop and remove containers (data volume is preserved)
docker compose down

# Stop and remove EVERYTHING including the database volume (full reset)
docker compose down -v
```

### Step 12 — Rebuild after changing code

If you edit `server.js`, `app.js`, or any Dockerfile:
```bash
docker compose up -d --build
```
`--build` forces Compose to rebuild images before restarting containers.

---

## How the health checks work (important concept)

Each service's `healthcheck:` block in `docker-compose.yml` tells Docker
how to ask "are you actually ready?", not just "are you running?":

- **postgres**: runs `pg_isready` inside the container.
- **redis**: runs `redis-cli ping`, expects `PONG`.
- **backend**: calls its own `/health` endpoint, which itself checks
  that it can reach Postgres AND Redis. If either is down, backend
  reports itself unhealthy too — this is why `depends_on` on backend
  matters for frontend.
- **frontend**: checks that Nginx responds on port 80.

`interval` = how often to check. `timeout` = how long to wait per check.
`retries` = how many failures before marking "unhealthy". `start_period`
= grace period after container start before failures count against it
(useful for slow-starting apps).

## Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `port is already allocated` | Something else on your machine uses that port | Change the port number in `.env` |
| backend stuck "starting" | Postgres/Redis not healthy yet | Run `docker compose logs postgres redis` |
| Frontend shows "Backend unreachable" | Backend crashed or unhealthy | Run `docker compose logs backend` |
| Changes to code don't show up | Old image still cached | Run `docker compose up -d --build` |
| Want a totally fresh start | Old volume has old data | Run `docker compose down -v` then `up -d --build` |

## Extending this project (ideas for practice)

- Add a 5th service: an `adminer` or `pgadmin` container for a GUI into Postgres.
- Add a `worker` service (e.g., a cron-like background job) that also depends on postgres/redis.
- Add resource limits (`deploy.resources.limits`) to simulate production constraints.
- Add a `.env.production` and use `docker compose --env-file .env.production up -d`.
- Put Nginx in front of the backend too, and enable HTTPS with a self-signed cert.
