# 3X-UI VPN Panel - Kubernetes Deployment

> 🚀 **Production-ready?** Смотри быстрый старт: [README-prod-quickstart.md](README-prod-quickstart.md)

## 🚨 Безопасность CI/CD: Только ручной запуск

**Внимание!** Все workflows GitHub Actions в этом репозитории запускаются **только вручную** (через Actions → Run workflow либо через GitHub CLI). Это защищает production и предотвращает автоматические или случайные деплои. См. [docs/SECURITY.md](docs/SECURITY.md).

## 💾 Автоматические бэкапы в GitHub

**Новое!** Бэкапы автоматически дублируются в GitHub (ветка `backups`) каждый день в 03:00.

### Преимущества

- ✅ **Внешнее хранение** — защита от потери PV/PVC
- ✅ **Git-версионирование** — каждый бэкап в отдельном commit
- ✅ **Легкое восстановление** — `git clone -b backups`
- ✅ **Хранение 30 бэкапов** в GitHub + 7 дней в PVC

### Быстрая настройка

```bash
# 1. Создать GitHub PAT: https://github.com/settings/tokens
# Permissions: repo (полный доступ)

# 2. Создать Secret
kubectl create secret generic github-backup-secret \
  --from-literal=token='ghp_YOUR_TOKEN' \
  -n xui-vpn

# 3. Применить CronJob
kubectl apply -f manifests/cronjob-backup.yaml

# 4. Тестовый запуск
kubectl create job --from=cronjob/xui-selfbackup manual-backup-test -n xui-vpn
```

**Подробная инструкция**: [docs/BACKUP_TO_GITHUB.md](docs/BACKUP_TO_GITHUB.md)

**Просмотр бэкапов**: https://github.com/KomarovAI/3xui-k8s-statefulset/tree/backups

---

## Интеграция с Traefik + HTTPS (Автоматические SSL-сертификаты)

Репозиторий теперь поддерживает **автоматическую выдачу DNS и SSL-сертификатов** через Traefik:

### Преимущества

- ✅ **Автоматический DNS** через nip.io (не нужно регистрировать домен!)
- ✅ **Автоматические HTTPS-сертификаты** от Let's Encrypt
- ✅ **Редирект HTTP → HTTPS** автоматически
- ✅ **Идемпотентность** — можно применять многократно
- ✅ **Нужны только порты 80 и 443** (для Traefik)

### Архитектура

```
Интернет
   ↓
DNS: xui.${SERVER_IP}.nip.io → ${SERVER_IP}
   ↓
Traefik (порты 80/443)
   ↓ Let's Encrypt SSL
IngressRoute → 3X-UI Service (порт 2053)
   ↓
3X-UI Pod
```

### Быстрый старт

#### 1. Настройка Traefik

```bash
# Замени admin@example.com на свой email!
chmod +x scripts/setup-traefik.sh
./scripts/setup-traefik.sh admin@example.com
```

Скрипт автоматически:
- Создаст PVC для хранения ACME сертификатов
- Добавит Let's Encrypt resolver в Traefik
- Примонтирует volume для сертификатов
- Перезапустит Traefik

#### 2. Развертывание 3X-UI с Traefik

```bash
# Применить все манифесты
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/storageclass.yaml
kubectl apply -f manifests/persistentvolume.yaml
kubectl apply -f manifests/persistentvolumeclaim.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/statefulset.dockerhub.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingressroute.yaml
kubectl apply -f manifests/cronjob-backup.yaml
kubectl apply -f manifests/networkpolicy.yaml
```

#### 3. Проверка

```bash
kubectl get all -n xui-vpn
kubectl get ingressroute -n xui-vpn
kubectl exec -n traefik deployment/traefik -- cat /data/acme.json | jq
kubectl logs -n traefik deployment/traefik -f
```

#### 4. Доступ к панели

После развертывания панель доступна по HTTPS:

```
URL: https://xui.${SERVER_IP}.nip.io
Логин: (из GitHub Secrets XUI_ADMIN_USER)
Пароль: (из GitHub Secrets XUI_ADMIN_PASS)
```

### Порты

| Порт | Протокол | Назначение | Открыт в firewall? |
|------|----------|------------|--------------------|
| **80** | TCP | HTTP (Traefik) | ✅ Да |
| **443** | TCP | HTTPS (Traefik) | ✅ Да |
| **2053** | TCP | 3X-UI Panel (внутри кластера) | ❌ Не нужно |
| **6443** | TCP | K8s API | ❌ Закрыт |

### Как это работает

1. **Пользователь** заходит на `https://xui.${SERVER_IP}.nip.io`
2. **DNS nip.io** автоматически резолвит → `${SERVER_IP}`
3. **Traefik** (порт 443) получает запрос
4. **IngressRoute** матчит `Host(xui.${SERVER_IP}.nip.io)`
5. **Traefik** проксирует → Service `xui-panel-service:2053`
6. **Service** проксирует → Pod `xui-panel-0:2053`
7. **Let's Encrypt** автоматически выдает SSL-сертификат
8. **Profit!** Панель доступна по HTTPS с валидным сертификатом

---

## Поддержка секретов для логина и пароля

> Описание демонстрационное. Настоящие секреты всегда должны храниться в GitHub Secrets, .env или внешних secret management системах, а НЕ в исходном коде/репозитории!

В StatefulSet добавлен yaml-фрагмент для внедрения секретов (`manifests/statefulset.secret.env.yaml`):

```yaml
env:
  - name: XUI_ADMIN_USER
    valueFrom:
      secretKeyRef:
        name: xui-admin-secret
        key: XUI_ADMIN_USER
  - name: XUI_ADMIN_PASS
    valueFrom:
      secretKeyRef:
        name: xui-admin-secret
        key: XUI_ADMIN_PASS
```

Переменные `XUI_ADMIN_USER`/`XUI_ADMIN_PASS` попадают в ENV контейнера.

---

## Дополнительные улучшения безопасности

- [x] Ограничен ingress/egress через manifests/networkpolicy.yaml
- [x] Включены Pod Security Standards (baseline)
- [x] Pipeline сканирует образы Trivy
- [ ] Для production использования рекомендуются Sealed Secrets/external secret-manager
- [ ] Для публичных IP используйте Kustomize/ConfigMap для подстановки реального значения
- [ ] Для бэкапов используйте GPG/age шифрование

---

## Troubleshooting

### Traefik

```bash
kubectl get deployment traefik -n traefik -o yaml | grep letsencrypt
kubectl exec -n traefik deployment/traefik -- cat /data/acme.json
kubectl logs -n traefik deployment/traefik | grep -i acme
```

### IngressRoute

```bash
kubectl get ingressroute -n xui-vpn
kubectl describe ingressroute xui-panel-https -n xui-vpn
```

### Если сертификат не выдается

1. Проверь порт **80** (HTTP Challenge)
2. Проверь DNS:
   ```bash
   nslookup xui.${SERVER_IP}.nip.io
   ```
3. Проверь логи Traefik
   ```bash
   kubectl logs -n traefik deployment/traefik -f | grep -i error
   ```
