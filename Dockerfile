FROM ghcr.io/mhsanaei/3x-ui:latest AS base

# Секреты должны передаваться через Kubernetes Secrets/GitHub Secrets,
# а НЕ через COPY в Docker image!
# 
# Для dev-тестирования можно временно добавить:
# COPY manifests/secret.yaml /opt/setup/secret.yaml
#
# Но ДЛЯ PRODUCTION используй kubectl create secret или CI/CD!

# Можно добавить свои скрипты init (не секреты) здесь.
# ENTRYPOINT и CMD можно доработать если свой init.
