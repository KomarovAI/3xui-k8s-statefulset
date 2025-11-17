#!/bin/bash
set -e

# Скрипт для настройки Traefik с Let's Encrypt
# Использование: ./scripts/setup-traefik.sh <email>

if [ -z "$1" ]; then
    echo "Укажите email для Let's Encrypt:"
    echo "  ./scripts/setup-traefik.sh admin@example.com"
    exit 1
fi

EMAIL="$1"
TRAEFIK_NAMESPACE="traefik"

echo "[✓] Проверка наличия namespace $TRAEFIK_NAMESPACE..."
if ! kubectl get namespace $TRAEFIK_NAMESPACE &>/dev/null; then
    echo "[×] Namespace $TRAEFIK_NAMESPACE не найден. Создайте его сначала."
    exit 1
fi

echo "[✓] Проверка наличия Traefik deployment..."
if ! kubectl get deployment traefik -n $TRAEFIK_NAMESPACE &>/dev/null; then
    echo "[×] Traefik deployment не найден. Установите Traefik сначала."
    exit 1
fi

echo "[✓] Создание PVC для ACME сертификатов..."
kubectl apply -f manifests/traefik/traefik-config.yaml

echo "[✓] Добавление ACME аргументов в Traefik deployment..."
kubectl patch deployment traefik -n $TRAEFIK_NAMESPACE --type=json -p="[
  {
    \"op\": \"add\",
    \"path\": \"/spec/template/spec/containers/0/args/-\",
    \"value\": \"--certificatesresolvers.letsencrypt.acme.email=$EMAIL\"
  },
  {
    \"op\": \"add\",
    \"path\": \"/spec/template/spec/containers/0/args/-\",
    \"value\": \"--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json\"
  },
  {
    \"op\": \"add\",
    \"path\": \"/spec/template/spec/containers/0/args/-\",
    \"value\": \"--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web\"
  }
]" 2>/dev/null || echo "[✓] ACME аргументы уже добавлены (идемпотентность)"

echo "[✓] Примонтирование PVC к Traefik deployment..."
kubectl patch deployment traefik -n $TRAEFIK_NAMESPACE --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [{"name": "acme-storage", "persistentVolumeClaim": {"claimName": "traefik-acme"}}]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [{"name": "acme-storage", "mountPath": "/data"}]
  }
]' 2>/dev/null || echo "[✓] Volume уже примонтирован (идемпотентность)"

echo "[✓] Ожидание перезапуска Traefik..."
kubectl rollout status deployment traefik -n $TRAEFIK_NAMESPACE --timeout=120s

echo ""
echo "✅ Traefik настроен успешно!"
echo ""
echo "Теперь примени IngressRoute:"
echo "  kubectl apply -f manifests/service.yaml"
echo "  kubectl apply -f manifests/ingressroute.yaml"
echo ""
echo "Доступ к панели: https://xui.31.56.39.58.nip.io"
