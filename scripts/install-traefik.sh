#!/bin/bash
set -e

echo "🚀 Установка Traefik v3 в Kubernetes..."

# 1. Добавить Helm репозиторий Traefik
echo "📦 Добавление Helm репозитория..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

# 2. Создать namespace traefik
echo "📁 Создание namespace traefik..."
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# 3. Применить email secret для Let's Encrypt
echo "🔐 Применение Let's Encrypt email secret..."
kubectl apply -f manifests/traefik/letsencrypt-email-secret.yaml

# 4. Создать PVC для ACME сертификатов
echo "💾 Создание PVC для ACME storage..."
kubectl apply -f manifests/traefik/traefik-config.yaml

# 5. Получить email из secret
EMAIL=$(kubectl get secret letsencrypt-email -n traefik -o jsonpath='{.data.email}' | base64 -d)
echo "📧 Используется email: $EMAIL"

# 6. Установить Traefik через Helm
echo "⚙️ Установка Traefik..."
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --set persistence.enabled=true \
  --set persistence.existingClaim=traefik-acme \
  --set ports.web.redirectTo.port=websecure \
  --set additionalArguments[0]="--certificatesresolvers.letsencrypt.acme.email=$EMAIL" \
  --set additionalArguments[1]="--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json" \
  --set additionalArguments[2]="--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web" \
  --set additionalArguments[3]="--log.level=INFO" \
  --wait

echo ""
echo "✅ Traefik успешно установлен!"
echo ""
echo "📋 Проверка статуса:"
kubectl get pods -n traefik
echo ""
kubectl get svc -n traefik
echo ""
echo "🌐 Получение внешнего IP..."
EXTERNAL_IP=$(kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXTERNAL_IP" ]; then
  echo "⚠️  LoadBalancer IP еще не назначен. Проверьте через 1-2 минуты:"
  echo "   kubectl get svc -n traefik -w"
else
  echo "✅ External IP: $EXTERNAL_IP"
fi
echo ""
echo "🔗 Ваш сайт будет доступен через 2-3 минуты на:"
echo "   https://xui.$(curl -s ifconfig.me).nip.io"
echo ""
echo "💡 Чтобы применить IngressRoute:"
echo "   kubectl apply -f manifests/ingressroute.yaml"
