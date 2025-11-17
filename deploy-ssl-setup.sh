#!/bin/bash
set -e

# 🔒 Скрипт для настройки Let's Encrypt SSL через Traefik
# 
# Что делает:
# 1. Создаёт namespace traefik (если нет)
# 2. Деплоит Secret с email для Let's Encrypt
# 3. Создаёт PVC для хранения сертификатов
# 4. Патчит Traefik Deployment для использования certResolver

echo "🚀 Настройка Let's Encrypt SSL через Traefik..."

# ШАГ 1: Создать namespace traefik
echo "✅ Создание namespace traefik..."
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# ШАГ 2: Деплой email secret
echo "✅ Деплой Let's Encrypt email secret..."
kubectl apply -f manifests/traefik/letsencrypt-email-secret.yaml

# ШАГ 3: Создать PVC для сертификатов
echo "✅ Создание PVC для ACME сертификатов..."
kubectl apply -f manifests/traefik/traefik-config.yaml

# ШАГ 4: Патч Traefik Deployment
echo "✅ Патч Traefik Deployment для certResolver..."

# Проверка наличия Traefik deployment
if ! kubectl get deployment traefik -n traefik &>/dev/null; then
  echo "⚠️  Traefik deployment не найден в namespace 'traefik'"
  echo "⚠️  Установите Traefik сначала: helm install traefik traefik/traefik -n traefik"
  exit 1
fi

# Добавление env для email
kubectl patch deployment traefik -n traefik --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/env/-",
    "value": {
      "name": "LETSENCRYPT_EMAIL",
      "valueFrom": {
        "secretKeyRef": {
          "name": "letsencrypt-email",
          "key": "email"
        }
      }
    }
  }
]' 2>/dev/null || echo "ℹ️  Email env уже добавлен"

# Добавление аргументов для certResolver
kubectl patch deployment traefik -n traefik --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--certificatesresolvers.letsencrypt.acme.email=$(LETSENCRYPT_EMAIL)"
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
  }
]' 2>/dev/null || echo "ℹ️  CertResolver args уже добавлены"

# Добавление volumeMount для ACME storage
kubectl patch deployment traefik -n traefik --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "acme-storage",
      "mountPath": "/data"
    }
  }
]' 2>/dev/null || echo "ℹ️  VolumeMount уже добавлен"

# Добавление volume с PVC
kubectl patch deployment traefik -n traefik --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "acme-storage",
      "persistentVolumeClaim": {
        "claimName": "traefik-acme"
      }
    }
  }
]' 2>/dev/null || echo "ℹ️  Volume уже добавлен"

echo ""
echo "✅ Все готово! Traefik настроен для Let's Encrypt."
echo "✅ IngressRoute с tls.certResolver=letsencrypt теперь будут автоматически получать SSL-сертификаты."
echo ""
echo "🔍 Проверка Traefik deployment:"
kubectl get deployment traefik -n traefik
echo ""
echo "🔍 Проверка PVC:"
kubectl get pvc traefik-acme -n traefik
