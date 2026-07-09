# ---------- Frontend Dockerfile ----------
FROM nginx:1.27-alpine

# Install curl so the container's own healthcheck (used by docker-compose)
# can reliably reach the nginx server. (wget can be flaky/missing on some
# alpine nginx builds, so we use curl here too, same as the backend.)
RUN apk add --no-cache curl

# Remove nginx's default sample site
RUN rm -rf /usr/share/nginx/html/*

# Copy our static files
COPY public/ /usr/share/nginx/html/

# Copy our custom nginx config (replaces the default server block)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80