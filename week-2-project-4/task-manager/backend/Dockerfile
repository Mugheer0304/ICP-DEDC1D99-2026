# ---------- Backend Dockerfile ----------
FROM node:20-alpine

WORKDIR /app

# Install curl so the container's own healthcheck (used by docker-compose)
# can call the /health endpoint.
RUN apk add --no-cache curl

# Copy dependency manifests first so Docker can cache the npm install
# layer separately from the source code layer.
COPY package.json ./
RUN npm install --omit=dev

COPY . .

EXPOSE 5000

CMD ["node", "server.js"]
