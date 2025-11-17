# Настройка Traefik для 3X-UI с автоматическими SSL-сертификатами

## Обзор

Этот гайд показывает, как настроить Traefik для:

- ✅ Автоматического DNS через **nip.io**
- ✅ Автоматических SSL-сертификатов от **Let's Encrypt**
- ✅ Автоматического редиректа **HTTP → HTTPS**

## Предварительные требования

- Kubernetes кластер (k3s или k8s)
- Traefik уже установлен в namespace `traefik`
- Открытые порты **80** и **443** в firewall
- IP-адрес вашего сервера (в примере: `31.56.39.58`)

## Шаг 1: Проверка Traefik

```bash
# Проверить, что Traefik работает
kubectl get deployment traefik -n traefik

# Проверить порты
kubectl get svc -n traefik
# Должны быть порты 80 и 443
```

## Шаг 2: Настройка Traefik для ACME

### Автоматическая настройка (рекомендуется)

```bash
# Замените admin@example.com на свой email!
chmod +x scripts/setup-traefik.sh
./scripts/setup-traefik.sh admin@example.com
```

Скрипт выполнит:
1. Создание PVC для хранения ACME сертификатов
2. Добавление ACME resolver в Traefik
3. Примонтирование volume к Traefik
4. Перезапуск Traefik

### Ручная настройка

#### 2.1 Создать PVC для ACME

```bash
kubectl apply -f manifests/traefik/traefik-config.yaml
```

#### 2.2 Добавить ACME resolver

```bash
# Замените admin@example.com на свой email!
EMAIL="admin@example.com"

kubectl patch deployment traefik -n traefik --type=json -p="[
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
]"
```

#### 2.3 Примонтировать volume

```bash
kubectl patch deployment traefik -n traefik --type=json -p='[
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
]'
```

#### 2.4 Проверить перезапуск

```bash
kubectl rollout status deployment traefik -n traefik --timeout=120s
```

## Шаг 3: Развернуть 3X-UI с Traefik

```bash
# Применить Service
kubectl apply -f manifests/service.yaml

# Применить IngressRoute (с nip.io DNS)
kubectl apply -f manifests/ingressroute.yaml
```

## Шаг 4: Проверка

### 4.1 Проверить статус IngressRoute

```bash
kubectl get ingressroute -n xui-vpn
# Должно показать xui-panel-https и xui-panel-http
```

### 4.2 Проверить сертификаты

```bash
# Логи Traefik (поиск ACME)
kubectl logs -n traefik deployment/traefik | grep -i acme

# Проверить acme.json
kubectl exec -n traefik deployment/traefik -- cat /data/acme.json | jq
```

### 4.3 Проверить DNS

```bash
nslookup xui.31.56.39.58.nip.io
# Должно вернуть: 31.56.39.58
```

### 4.4 Проверить HTTPS

```bash
curl -v https://xui.31.56.39.58.nip.io
# Должен вернуть валидный SSL-сертификат Let's Encrypt
```

## Шаг 5: Доступ к панели

Открой в браузере:

```
https://xui.31.56.39.58.nip.io
```

Логин: `(из GitHub Secrets XUI_ADMIN_USER)`  
Пароль: `(из GitHub Secrets XUI_ADMIN_PASS)`

## Troubleshooting

### Проблема: Сертификат не выдается

#### Причина 1: Порт 80 закрыт

Let's Encrypt использует **HTTP Challenge** на порту 80:

```bash
# Проверить firewall
sudo ufw status | grep 80

# Открыть порт 80
sudo ufw allow 80/tcp
```

#### Причина 2: DNS не работает

```bash
nslookup xui.31.56.39.58.nip.io
# Если не вернул 31.56.39.58 — проверь IP
```

#### Причина 3: ACME не настроен

```bash
# Проверить аргументы Traefik
kubectl get deployment traefik -n traefik -o yaml | grep letsencrypt

# Должно быть:
# --certificatesresolvers.letsencrypt.acme.email=...
# --certificatesresolvers.letsencrypt.acme.storage=/data/acme.json
# --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
```

#### Причина 4: Volume не примонтирован

```bash
# Проверить volume
kubectl get deployment traefik -n traefik -o yaml | grep -A 5 volumes

# Должно быть:
# - name: acme-storage
#   persistentVolumeClaim:
#     claimName: traefik-acme
```

### Проблема: HTTP не редиректит на HTTPS

```bash
# Проверить Middleware
kubectl get middleware redirect-https -n xui-vpn

# Проверить IngressRoute HTTP
kubectl describe ingressroute xui-panel-http -n xui-vpn
```

### Проблема: Ошибка "Too Many Requests" от Let's Encrypt

Let's Encrypt имеет rate limits:

- **5 неудачных попыток в час**
- **50 сертификатов на домен в неделю**

Решение: Подожди 1 час и попробуй снова.

## Порты

| Порт | Протокол | Назначение | Firewall |
|------|----------|------------|----------|
| **80** | TCP | HTTP (Traefik, ACME Challenge) | ✅ Открыт |
| **443** | TCP | HTTPS (Traefik) | ✅ Открыт |
| **2053** | TCP | 3X-UI Panel (внутри кластера) | ❌ Закрыт |
| **6443** | TCP | K8s API | ❌ Закрыт |

## Дополнительные настройки

### Изменить IP адрес

Если твой IP не `31.56.39.58`, отредактируй:

```bash
# Открыть manifests/ingressroute.yaml
vim manifests/ingressroute.yaml

# Заменить все вхождения 31.56.39.58 на свой IP
:%s/31.56.39.58/ТВОЙ_IP/g

# Применить
kubectl apply -f manifests/ingressroute.yaml
```

### Использовать свой домен

Если у тебя есть домен (example.com):

1. Добавь A-запись в DNS:
   ```
   xui.example.com  A  31.56.39.58
   ```

2. Отредактируй `manifests/ingressroute.yaml`:
   ```yaml
   - match: Host(`xui.example.com`)  # Вместо xui.31.56.39.58.nip.io
   ```

3. Примени:
   ```bash
   kubectl apply -f manifests/ingressroute.yaml
   ```

## Идемпотентность

Все команды можно выполнять многократно — они не сломают существующую конфигурацию.

```bash
# Повторное применение — безопасно
./scripts/setup-traefik.sh admin@example.com
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingressroute.yaml
```

## Полезные команды

```bash
# Просмотр всех IngressRoute
kubectl get ingressroute -A

# Удалить IngressRoute (если нужно пересоздать)
kubectl delete ingressroute xui-panel-https xui-panel-http -n xui-vpn

# Проверить статус сертификата
curl -vI https://xui.31.56.39.58.nip.io 2>&1 | grep -i "SSL certificate"

# Полные логи Traefik
kubectl logs -n traefik deployment/traefik -f
```

## Ссылки

- [Traefik документация](https://doc.traefik.io/traefik/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [nip.io](https://nip.io/)
- [Kubernetes IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/)
