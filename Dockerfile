# Stage 1: Builder
FROM ghcr.io/mhsanaei/3x-ui:v2.5.3 AS builder

# Stage 2: Runtime
FROM alpine:3.20

LABEL maintainer="KomarovAI"
LABEL version="2.5.3-optimized"

# Pin package versions for reproducible builds and security compliance
# Versions verified for Alpine 3.20 as of 2025-11-21
RUN apk add --no-cache \
    ca-certificates=20250911-r0 \
    tzdata=2025b-r0 \
    bash=5.2.37-r0 \
    curl=8.14.1-r2 \
    libc6-compat=1.2.5-r7 \
    libstdc++=13.2.1_git20240309-r1 && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 2000 x-ui && \
    adduser -D -u 2000 -G x-ui x-ui

RUN mkdir -p /app /app/bin && \
    chown -R x-ui:x-ui /app

# Копируем из builder и обязательно кладём bin/ внутри образа
COPY --from=builder --chown=x-ui:x-ui /app/ /app/
COPY --from=builder --chown=x-ui:x-ui /usr/bin/x-ui /usr/bin/x-ui
COPY --from=builder --chown=x-ui:x-ui /usr/local/x-ui/bin/ /app/bin/

# Здесь создаём минимальный config.json, если его не было
RUN test -f /app/bin/config.json || echo '{"log":{"level":"info"},"inbounds":[],"outbounds":[]}' > /app/bin/config.json
RUN chmod 777 /app/bin && chmod 666 /app/bin/config.json

WORKDIR /app
VOLUME ["/etc/x-ui"]
EXPOSE 2053 2096

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:2053/ || exit 1

USER x-ui
ENTRYPOINT ["/app/DockerEntrypoint.sh"]
CMD ["./x-ui"]