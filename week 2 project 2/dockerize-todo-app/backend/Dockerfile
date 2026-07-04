# ---------- Stage 1: Dependencies ----------
# We use a full node image just to install dependencies.
# This stage is thrown away later, so its size doesn't matter.
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only package files first. Docker caches layers - as long as these
# files don't change, Docker reuses the cached "npm ci" layer on rebuilds,
# instead of reinstalling dependencies every time you change your code.
COPY package.json package-lock.json* ./

# Install only production dependencies (no devDependencies), reproducibly.
RUN npm ci --omit=dev


# ---------- Stage 2: Runtime ----------
# This is the final, small image that actually gets shipped and run.
FROM node:20-alpine AS runtime

# Set NODE_ENV so Express and other libraries run in production mode.
ENV NODE_ENV=production
ENV PORT=4000

WORKDIR /app

# Copy only the installed node_modules from the deps stage (not the npm cache,
# not devDependencies, not build tools). This keeps the final image lean.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

# Create and use a non-root user for security.
# Alpine images already include a 'node' user by default.
USER node

EXPOSE 4000

# Basic container-level health check so 'docker ps' shows container health.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "src/index.js"]
