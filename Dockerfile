# Stage 1: Builder
FROM ghcr.io/mhsanaei/3x-ui:2.8.5 AS builder

# Stage 2: Runtime
FROM alpine:3.22

# Build-time arguments (passed from CI/CD)
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="KomarovAI" \
      org.opencontainers.image.url="https://github.com/KomarovAI/3xui-k8s-statefulset" \
      org.opencontainers.image.documentation="https://github.com/KomarovAI/3xui-k8s-statefulset/blob/main/README.md" \
      org.opencontainers.image.source="https://github.com/KomarovAI/3xui-k8s-statefulset" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="KomarovAI" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="3X-UI VPN Panel for Kubernetes" \
      org.opencontainers.image.description="Production-ready 3X-UI Docker image optimized for Kubernetes StatefulSet deployments" \
      org.opencontainers.image.base.name="alpine:3.20"

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
