# syntax=docker/dockerfile:1
# CACHE_BUST: 2026-03-01T14:50:00Z-v3

FROM node:22-bookworm-slim AS base
RUN apt-get update && apt-get install -y git curl openssl jq && rm -rf /var/lib/apt/lists/*

FROM base AS builder
WORKDIR /build
RUN npm install -g pnpm && \
    git clone --depth 1 https://github.com/openclaw/openclaw.git . && \
    pnpm install && \
    pnpm build

FROM base AS final
WORKDIR /app
COPY --from=builder /build/dist /app/dist
COPY --from=builder /build/node_modules /app/node_modules
COPY --from=builder /build/package.json /app/package.json

# Copy all scripts and configs
COPY scripts/ /app/scripts/
COPY *.md /app/
COPY coolify.json /app/

RUN chmod +x /app/scripts/*.sh && \
    ln -sf /app/scripts/bootstrap.sh /usr/local/bin/openclaw-bootstrap && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve

ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE=/data/openclaw-workspace
ENV OPENCLAW_GATEWAY_PORT=18789

VOLUME ["/data"]
EXPOSE 18789

# Use bootstrap as entrypoint
ENTRYPOINT ["openclaw-bootstrap"]
