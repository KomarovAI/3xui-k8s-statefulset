# 🚀 Инструкция по деплою 3X-UI в Kubernetes

## 📅 Обзор изменений

### ✅ Что было исправлено

1. **Оптимизация Health Checks** – `statefulset.dockerhub.yaml`
   - Добавлен `startupProbe` (до 5 минут на первый старт)
   - Увеличен `initialDelaySeconds` для `readinessProbe` до 60s
   - Увеличен `initialDelaySeconds` для `livenessProbe` до 90s
   - Устраняет проблему с 8 рестартами перед стабилизацией

2. **DNS NetworkPolicy** – `networkpolicy-dns.yaml`
   - Явное разрешение UDP/TCP порт 53 к `kube-system`
   - Предотвращает блокировку DNS `default-deny-egress` политикой

3. **PodDisruptionBudget** – `poddisruptionbudget.yaml`
   - Защищает от случайного удаления пода во время node maintenance
   - Гарантирует `minAvailable: 1`

4. **Обновление CI/CD Workflow**
   - Автоматическое применение всех новых манифестов
   - Добавлена проверка IngressRoute в конце деплоя

5. **Email для Let's Encrypt**
   - `manifests/traefik/letsencrypt-email-secret.yaml` уже содержит `artur.komarovv@gmail.com`
   - Автоматически применяется при деплое

---

## 🛠️ Как использовать

### 1. Автоматический деплой через GitHub Actions

```bash
# Через GitHub CLI
gh workflow run deploy-dockerhub.yml

# Или в браузере
# Открой: https://github.com/KomarovAI/3xui-k8s-statefulset/actions
# Выбери workflow "Build, Push & Deploy 3X-UI via Docker Hub"
# Нажми "Run workflow"
```

**Что произойдет:**
1. Build и Push Docker образа в DockerHub
2. Trivy сканирование безопасности
3. Автоматическое применение всех манифестов
4. RollingUpdate StatefulSet с zero-downtime
5. Проверка готовности

---

### 2. Ручной деплой (если нужно)

```bash
# 1. Создать namespaces
kubectl create namespace traefik
kubectl apply -f manifests/namespace.yaml

# 2. Применить Traefik SSL секреты
kubectl apply -f manifests/traefik/letsencrypt-email-secret.yaml
kubectl apply -f manifests/traefik/traefik-config.yaml

# 3. Создать admin secret (замени на свои значения)
kubectl create secret generic xui-admin-secret \
  --from-literal=XUI_ADMIN_USER="admin" \
  --from-literal=XUI_ADMIN_PASS="password" \
  -n xui-vpn

# 4. Применить инфраструктуру
kubectl apply -f manifests/storageclass.yaml
kubectl apply -f manifests/persistentvolume.yaml
kubectl apply -f manifests/persistentvolumeclaim.yaml

# 5. Применить приложение
kubectl apply -f manifests/statefulset.dockerhub.yaml
kubectl apply -f manifests/cronjob-backup.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingressroute.yaml
kubectl apply -f manifests/networkpolicy.yaml
kubectl apply -f manifests/networkpolicy-dns.yaml
kubectl apply -f manifests/poddisruptionbudget.yaml

# 6. Проверить статус
kubectl get pods -n xui-vpn -w
```

---

## 🔍 Проверка после деплоя

```bash
# 1. Проверить поды
kubectl get pods -n xui-vpn
# Ожидаемый результат:
# NAME          READY   STATUS    RESTARTS   AGE
# xui-panel-0   1/1     Running   0          2m

# 2. Проверить IngressRoute
kubectl get ingressroute -n xui-vpn
# Ожидаемый результат:
# NAME               AGE
# xui-panel-http     2m
# xui-panel-https    2m

# 3. Проверить логи Traefik на правильный email
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=30 | grep -i acme
# Должно быть:
# level=info msg="Register..." providerName=letsencrypt.acme
# БЕЗ ошибок про example.com

# 4. Проверить DNS
SERVER_IP=$(curl -s ifconfig.me)
nslookup xui.${SERVER_IP}.nip.io

# 5. Открыть в браузере (подожди 2-3 минуты для SSL)
echo "https://xui.${SERVER_IP}.nip.io"
```

---

## 🐞 Решение проблем

### Проблема: Под перезапускается много раз

**Решение:** Уже исправлено в `statefulset.dockerhub.yaml` через `startupProbe` и увеличенные таймауты.

### Проблема: SSL сертификат не выдается

```bash
# Проверь логи Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50 | grep -i "acme\|error"

# Если видишь "example.com" - Traefik не использует правильный email
# Решение: Переустанови Traefik с правильным email:

kubectl delete deployment traefik -n traefik
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik -n traefik \
  --set additionalArguments[0]="--certificatesresolvers.letsencrypt.acme.email=artur.komarovv@gmail.com" \
  --set additionalArguments[1]="--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json" \
  --set additionalArguments[2]="--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web" \
  --set persistence.enabled=true \
  --set persistence.existingClaim=traefik-acme
```

### Проблема: IngressRoute не найден

```bash
# Примени вручную
kubectl apply -f manifests/ingressroute.yaml

# Проверь
kubectl get ingressroute -n xui-vpn
```

### Проблема: Permission denied для config.json

```bash
# Исправи права на хосте
sudo chown -R 2000:2000 /opt/xui-vpn/data
sudo chmod -R 755 /opt/xui-vpn/data

# Перезапусти под
kubectl delete pod -n xui-vpn -l app=xui-panel
```

---

## 🎉 Заключение

Все критические проблемы устранены:
- ✅ Health checks оптимизированы
- ✅ DNS NetworkPolicy добавлена
- ✅ PodDisruptionBudget настроен
- ✅ Email для Let's Encrypt правильный
- ✅ CI/CD workflow обновлен

**Репозиторий готов к продакшну! 🚀**
