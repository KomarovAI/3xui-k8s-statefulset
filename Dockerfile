FROM ghcr.io/mhsanaei/3x-ui:latest AS base
# Можно добавить свои скрипты для init-пароля здесь
COPY manifests/secret.yaml /opt/setup/secret.yaml
# ENTRYPOINT и CMD можно доработать если свой init
