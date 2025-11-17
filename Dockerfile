# Stage 1: Builder
FROM ghcr.io/mhsanaei/3x-ui:v2.5.3 AS builder

# Stage 2: Runtime
FROM alpine:3.20

LABEL maintainer="KomarovAI"
LABEL version="2.5.3-optimized"

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl \
    libc6-compat \
    libstdc++ && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 2000 x-ui && \
    adduser -D -u 2000 -G x-ui x-ui

RUN mkdir -p /etc/x-ui /app && \
    chown -R x-ui:x-ui /etc/x-ui /app

COPY --from=builder /app/ /app/
COPY --from=builder /usr/bin/x-ui /usr/bin/x-ui

RUN chmod +x /app/x-ui /usr/bin/x-ui 2>/dev/null || true

WORKDIR /app
VOLUME ["/etc/x-ui"]
EXPOSE 2053

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:2053/ || exit 1

USER x-ui
ENTRYPOINT ["/app/DockerEntrypoint.sh"]
CMD ["./x-ui"]
