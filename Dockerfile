# Stage 1: Build the Vite app
FROM node:20-alpine AS builder

RUN apk add --no-cache git git-lfs

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN git lfs install && git lfs pull
RUN npm run build

# Stage 2: Serve with Caddy (~15MB RAM vs ~250MB with Node.js)
FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=builder /app/dist /srv

EXPOSE ${PORT:-3000}
