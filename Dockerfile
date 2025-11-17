# ============================================
# Stage 1: Builder - Подготовка зависимостей
# ============================================
FROM ghcr.io/mhsanaei/3x-ui:v2.5.3 AS builder

# Используем builder stage для подготовки всех нужных файлов
# Здесь можно установить build tools, скомпилировать бинарники
WORKDIR /build

# Копируем только runtime-файлы из базового образа
# 3X-UI хранит бинарники в /usr/local/x-ui
RUN mkdir -p /build/x-ui /build/xray-core && \
    # Копируем только необходимые файлы
    if [ -d /usr/local/x-ui ]; then cp -r /usr/local/x-ui/* /build/x-ui/; fi && \
    if [ -d /usr/local/bin ]; then \
        cp -f /usr/local/bin/x-ui /build/ 2>/dev/null || true; \
        cp -f /usr/local/bin/xray /build/ 2>/dev/null || true; \
    fi && \
    # Удаляем ненужные файлы (логи, кэши, build артефакты)
    find /build -type f -name '*.log' -delete && \
    find /build -type f -name '*.cache' -delete && \
    find /build -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true

# ============================================
# Stage 2: Runtime - Минимальный финальный образ
# ============================================
FROM alpine:3.19

# Metadata
LABEL maintainer="KomarovAI" \
      version="2.5.3-optimized" \
      description="3X-UI VPN Panel - Multi-stage optimized for minimal size" \
      org.opencontainers.image.source="https://github.com/KomarovAI/3xui-k8s-statefulset"

# Установка только runtime зависимостей (без build tools)
# Объединяем RUN команды для уменьшения количества слоев
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl \
    # Минимальные зависимости для 3X-UI
    libc6-compat \
    libstdc++ && \
    # Очистка APK кэша
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Создаем непривилегированного пользователя (безопасность)
RUN addgroup -g 2000 x-ui && \
    adduser -D -u 2000 -G x-ui x-ui

# Создаем структуру директорий
RUN mkdir -p /etc/x-ui /usr/local/x-ui /usr/local/bin && \
    chown -R x-ui:x-ui /etc/x-ui /usr/local/x-ui

# Копируем ONLY runtime файлы из builder stage
COPY --from=builder --chown=x-ui:x-ui /build/x-ui/ /usr/local/x-ui/
COPY --from=builder --chown=x-ui:x-ui /build/x-ui /usr/local/bin/x-ui
COPY --from=builder --chown=x-ui:x-ui /build/xray /usr/local/bin/xray

# Делаем бинарники исполняемыми
RUN chmod +x /usr/local/bin/x-ui /usr/local/bin/xray 2>/dev/null || true

# Рабочая директория
WORKDIR /usr/local/x-ui

# Volumes для persistent данных
VOLUME ["/etc/x-ui"]

# Порты
EXPOSE 2053

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:2053/ || exit 1

# Запуск от имени непривилегированного пользователя
USER x-ui

# ENTRYPOINT и CMD наследуются из базового образа
# Или указываем явно:
ENTRYPOINT ["/usr/local/bin/x-ui"]
CMD ["run"]
