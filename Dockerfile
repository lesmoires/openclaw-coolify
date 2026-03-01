syntax=docker/dockerfile:1

FROM node:20-bookworm-slim AS base
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

FROM base AS builder
WORKDIR /build
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git . && \
    npm install && \
    npm run build

FROM base AS final
WORKDIR /app
COPY --from=builder /build/dist /app/dist
COPY --from=builder /build/node_modules /app/node_modules
COPY . .
RUN chmod +x /app/scripts/*.sh
EXPOSE 18789
CMD ["node", "/app/dist/index.js", "gateway", "run"]

