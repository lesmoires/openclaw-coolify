# syntax=docker/dockerfile:1
# CACHE_BUST: 2026-03-01T14:30:00Z-v1

FROM node:20-bookworm-slim AS base
RUN apt-get update && apt-get install -y git curl openssl jq && rm -rf /var/lib/apt/lists/*

FROM base AS builder
WORKDIR /build
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git . && \
    npm install && \
    npm run build

FROM base AS final
WORKDIR /app
COPY --from=builder /build/dist /app/dist
COPY --from=builder /build/node_modules /app/node_modules
COPY --from=builder /build/package.json /app/package.json
COPY --from=builder /build/bin /app/bin

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
ENV PATH="/app/bin:${PATH}"

VOLUME ["/data"]
EXPOSE 18789

# Use bootstrap as entrypoint
ENTRYPOINT ["openclaw-bootstrap"]

