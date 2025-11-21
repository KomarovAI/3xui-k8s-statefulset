# Stage 1: Builder
FROM ghcr.io/mhsanaei/3x-ui:v2.5.3 AS builder

# Stage 2: Runtime
FROM alpine:3.20

LABEL maintainer="KomarovAI"
LABEL version="2.5.3-optimized-secure"

RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl>=8.16.0 \
    c-ares>=1.34.5 \
    gcompat \
    libstdc++ && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 2000 x-ui && \
    adduser -D -u 2000 -G x-ui x-ui

RUN mkdir -p /app /etc/x-ui && \
    chown -R x-ui:x-ui /app /etc/x-ui && \
    chmod 755 /etc/x-ui

COPY --from=builder --chown=x-ui:x-ui /app/ /app/
COPY --from=builder --chown=x-ui:x-ui /usr/bin/x-ui /usr/bin/x-ui

WORKDIR /app
VOLUME ["/etc/x-ui"]
EXPOSE 2053 2096

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:2053/ || exit 1

USER x-ui
ENTRYPOINT ["/app/DockerEntrypoint.sh"]
CMD ["./x-ui"]
