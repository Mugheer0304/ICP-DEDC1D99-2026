# ---------- Stage 1: Build ----------
# Use a Node image with build tools to compile the React app into static files.
FROM node:20-alpine AS build

WORKDIR /app

# Copy package files first for better layer caching.
COPY package.json package-lock.json* ./
RUN npm ci

# Copy the rest of the source and build the production bundle.
COPY . .
RUN npm run build
# At this point /app/dist contains plain HTML/CSS/JS - no Node.js needed to run it.


# ---------- Stage 2: Serve ----------
# Nginx alpine is tiny (~40MB) and perfect for serving static files.
# None of the Node.js toolchain, source code, or node_modules end up in this image.
FROM nginx:1.27-alpine AS runtime

# Remove default nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy only the compiled static files from the build stage.
COPY --from=build /app/dist /usr/share/nginx/html

# Custom nginx config: serves the SPA and proxies /api to the backend container.
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --spider -q http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]
