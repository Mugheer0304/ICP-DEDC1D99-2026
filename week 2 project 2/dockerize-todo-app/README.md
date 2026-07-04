# Dockerized Todo App

A full-stack Todo application demonstrating how to containerize a real app using:
- Dockerfile writing
- Multi-stage builds
- Docker Compose (multi-container orchestration)
- Image size optimization

## Stack
- **Frontend**: React (Vite) → built into static files → served by Nginx
- **Backend**: Node.js + Express REST API
- **Database**: PostgreSQL

## Project Structure
```
dockerize-todo-app/
├── backend/
│   ├── src/index.js       # Express API
│   ├── package.json
│   ├── Dockerfile         # multi-stage: deps -> runtime
│   └── .dockerignore
├── frontend/
│   ├── src/                # React app
│   ├── index.html
│   ├── nginx.conf          # reverse proxy + SPA routing
│   ├── package.json
│   ├── Dockerfile          # multi-stage: build -> nginx runtime
│   └── .dockerignore
├── docker-compose.yml
├── .env.example
└── README.md
```

## Quick Start

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Build and start everything:
   ```bash
   docker compose up --build
   ```

3. Open the app: http://localhost:3000
   Backend API directly: http://localhost:4000/api/todos
   Health check: http://localhost:4000/health

4. Stop everything:
   ```bash
   docker compose down
   ```

5. Stop and wipe the database volume too:
   ```bash
   docker compose down -v
   ```

## Checking Image Sizes (Optimization Proof)
```bash
docker images | grep todo
```
You should see the backend and frontend final images are small (tens of MB),
because multi-stage builds discard build tools, dev dependencies, and source
maps that aren't needed at runtime.
