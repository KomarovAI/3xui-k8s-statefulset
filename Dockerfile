# ============================================
# Stage 1: Builder - подготовка бинарников
# ============================================
FROM ghcr.io/mhsanaei/3x-ui:v2.5.3 AS builder

# ============================================
# Stage 2: Runtime - финальный минимальный контейнер
# ============================================
FROM alpine:3.19

LABEL maintainer="KomarovAI" \
      version="2.5.3-optimized" \
      description="3X-UI VPN Panel - Multi-stage optimized for minimal size" \
      org.opencontainers.image.source="https://github.com/KomarovAI/3xui-k8s-statefulset"

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl \
    libc6-compat \
    libstdc++ && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN addgroup -g 2000 x-ui && \
    adduser -D -u 2000 -G x-ui x-ui

RUN mkdir -p /etc/x-ui /usr/local/x-ui /usr/local/bin && \
    chown -R x-ui:x-ui /etc/x-ui /usr/local/x-ui

COPY --from=builder /usr/local/x-ui/x-ui /usr/local/bin/x-ui
COPY --from=builder /usr/local/x-ui/bin/xray /usr/local/bin/xray
COPY --from=builder /usr/local/x-ui/ /usr/local/x-ui/

RUN chmod +x /usr/local/bin/x-ui /usr/local/bin/xray 2>/dev/null || true

WORKDIR /usr/local/x-ui
VOLUME ["/etc/x-ui"]
EXPOSE 2053

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:2053/ || exit 1

USER x-ui
ENTRYPOINT ["/usr/local/bin/x-ui"]
CMD ["run"]
