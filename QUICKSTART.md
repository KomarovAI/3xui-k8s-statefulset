# 🚀 Быстрый старт - Полный деплой за 5 минут

## 📋 Предварительные требования

- ✅ Kubernetes кластер (k3s, k8s, minikube)
- ✅ `kubectl` настроен и подключен
- ✅ Helm 3 установлен
- ✅ Внешний IP адрес (LoadBalancer или NodePort)

---

## ⚡ Одна команда - полный деплой

```bash
# Склонировать репозиторий
git clone https://github.com/KomarovAI/3xui-k8s-statefulset.git
cd 3xui-k8s-statefulset

# Запустить автоматическую установку Traefik
chmod +x scripts/install-traefik.sh
./scripts/install-traefik.sh
```

**Что произойдет:**
1. ✅ Установит Traefik v3 с CRDs
2. ✅ Настроит Let's Encrypt с вашим email
3. ✅ Создаст PVC для сертификатов
4. ✅ Настроит редирект HTTP → HTTPS

---

## 🛠️ Шаг 2: Деплой 3X-UI приложения

### А. Через GitHub Actions (Рекомендуется)

1. Открой https://github.com/KomarovAI/3xui-k8s-statefulset/actions
2. Выбери workflow **"Build, Push & Deploy 3X-UI via Docker Hub"**
3. Нажми **"Run workflow"** → **"Run workflow"**
4. Подожди 2-3 минуты

### Б. Ручной деплой

```bash
# 1. Создать namespaces
kubectl apply -f manifests/namespace.yaml

# 2. Создать admin секреты (замени на свои значения!)
kubectl create secret generic xui-admin-secret \
  --from-literal=XUI_ADMIN_USER="admin" \
  --from-literal=XUI_ADMIN_PASS="your-strong-password" \
  -n xui-vpn

# 3. Создать директорию для данных (только для local storage)
sudo mkdir -p /opt/xui-vpn/data
sudo chown -R 2000:2000 /opt/xui-vpn/data
sudo chmod -R 755 /opt/xui-vpn/data

# 4. Применить инфраструктуру
kubectl apply -f manifests/storageclass.yaml
kubectl apply -f manifests/persistentvolume.yaml
kubectl apply -f manifests/persistentvolumeclaim.yaml

# 5. Деплой приложения
kubectl apply -f manifests/statefulset.dockerhub.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingressroute.yaml
kubectl apply -f manifests/networkpolicy.yaml
kubectl apply -f manifests/networkpolicy-dns.yaml
kubectl apply -f manifests/poddisruptionbudget.yaml

# 6. Проверить статус
kubectl get pods -n xui-vpn -w
```

---

## 🔍 Проверка работы

### 1. Проверить Traefik

```bash
# Поды Traefik
kubectl get pods -n traefik
# Ожидаемый результат:
# NAME                       READY   STATUS    RESTARTS   AGE
# traefik-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

# Сервис Traefik
kubectl get svc -n traefik
# Ожидаемый результат:
# NAME      TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)
# traefik   LoadBalancer   10.43.x.x      31.56.39.58     80:xxx/TCP,443:xxx/TCP
```

### 2. Проверить 3X-UI

```bash
# Под 3X-UI
kubectl get pods -n xui-vpn
# Ожидаемый результат:
# NAME          READY   STATUS    RESTARTS   AGE
# xui-panel-0   1/1     Running   0          5m

# IngressRoute
kubectl get ingressroute -n xui-vpn
# Ожидаемый результат:
# NAME               AGE
# xui-panel-http     5m
# xui-panel-https    5m
```

### 3. Получить URL

```bash
# Автоматический URL через nip.io
SERVER_IP=$(curl -s ifconfig.me)
echo "https://xui.${SERVER_IP}.nip.io"

# Пример вывода:
# https://xui.31.56.39.58.nip.io
```

### 4. Открыть в браузере

⚠️ **Подожди 2-3 минуты для выдачи SSL-сертификата Let's Encrypt**

1. Открой `https://xui.YOUR_IP.nip.io`
2. Введи логин/пароль из `xui-admin-secret`
3. ✅ **Готово!**

---

## 🐞 Troubleshooting

### Проблема 1: "502 Bad Gateway" или "404 Not Found"

```bash
# Проверь, что IngressRoute создан
kubectl get ingressroute -n xui-vpn

# Если пусто - примени вручную
kubectl apply -f manifests/ingressroute.yaml

# Проверь логи Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50
```

### Проблема 2: Под не запускается

```bash
# Проверь статус
kubectl describe pod xui-panel-0 -n xui-vpn

# Логи
kubectl logs xui-panel-0 -n xui-vpn --tail=100

# Если permission denied:
sudo chown -R 2000:2000 /opt/xui-vpn/data
kubectl delete pod xui-panel-0 -n xui-vpn
```

### Проблема 3: SSL сертификат не выдается

```bash
# Проверь логи Traefik на ACME ошибки
kubectl logs -n traefik -l app.kubernetes.io/name=traefik | grep -i "acme\|error"

# Проверь, что порты 80 и 443 открыты
sudo ufw status

# Проверь email в secret
kubectl get secret letsencrypt-email -n traefik -o jsonpath='{.data.email}' | base64 -d
```

### Проблема 4: "ingressroutes.traefik.containo.us not found"

Это означает, что Traefik CRDs не установлены:

```bash
# Запусти скрипт установки Traefik
./scripts/install-traefik.sh
```

---

## 🎉 Готово!

После выполнения всех шагов:
- ✅ 3X-UI панель доступна по HTTPS
- ✅ SSL-сертификат от Let's Encrypt
- ✅ Автоматический редирект HTTP → HTTPS
- ✅ Zero-downtime updates
- ✅ Автоматические бэкапы

**Подробная документация**: [DEPLOYMENT.md](DEPLOYMENT.md)
