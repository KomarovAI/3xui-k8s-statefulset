#!/bin/bash
set -e

echo "[INFO] Проверка предварительных условий..."

# 1. Проверить наличие PV директории на хосте
if [ ! -d "/opt/xui-vpn/data" ]; then
  echo "[ERROR] Директория /opt/xui-vpn/data не найдена!"
  echo "[FIX] Создайте её: sudo mkdir -p /opt/xui-vpn/data && sudo chown 1000:1000 /opt/xui-vpn/data"
  exit 1
fi

# 2. Проверить, что node name в PV совпадает с реальным
CURRENT_NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
PV_NODE=$(grep -A 10 "nodeAffinity" manifests/persistentvolume.yaml | grep "values:" -A 1 | tail -1 | xargs | sed 's/- //')

if [ "$CURRENT_NODE" != "$PV_NODE" ]; then
  echo "[WARN] Node name в PV ($PV_NODE) не совпадает с текущим ($CURRENT_NODE)!"
  echo "[FIX] Обновите manifests/persistentvolume.yaml или используйте overlays/prod/kustomization.yaml"
  read -p "Продолжить всё равно? (y/N): " CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "[INFO] Все проверки пройдены успешно."
echo "[INFO] Запуск деплоя..."

kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/storageclass.yaml
kubectl apply -f manifests/persistentvolume.yaml
kubectl apply -f manifests/persistentvolumeclaim.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/statefulset.dockerhub.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingressroute.yaml
kubectl apply -f manifests/cronjob-backup.yaml

echo "[✅] Деплой завершен!"
echo "[ℹ️] Проверь статус: kubectl get all -n xui-vpn"
