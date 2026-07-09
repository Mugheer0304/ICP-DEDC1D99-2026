-- This script runs automatically ONE TIME when the postgres container
-- starts with an empty data volume (Postgres official image behavior:
-- anything in /docker-entrypoint-initdb.d/ is executed on first init).

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO tasks (title, completed) VALUES
    ('Learn Docker Compose', TRUE),
    ('Build a microservices project', FALSE),
    ('Deploy to production', FALSE);
