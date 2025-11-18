# 3X-UI VPN Panel - Kubernetes Deployment

## ⚡ Быстрый старт за 5 минут

👉 **[QUICKSTART.md](QUICKSTART.md)** - Полная инструкция от нуля до работающего сайта

```bash
# 1. Склонировать репозиторий
git clone https://github.com/KomarovAI/3xui-k8s-statefulset.git
cd 3xui-k8s-statefulset

# 2. Установить Traefik (один раз)
chmod +x scripts/install-traefik.sh
./scripts/install-traefik.sh

# 3. Запустить деплой через GitHub Actions
gh workflow run deploy-dockerhub.yml

# 4. Открыть сайт (2-3 минуты на SSL)
echo "https://xui.$(curl -s ifconfig.me).nip.io"
```

---

## ✨ Новые возможности (2025-11-18)

### 1. ️⚡ Оптимизированные Health Checks
- **startupProbe** - до 5 минут на первый старт
- **Увеличенные таймауты** для liveness/readiness
- **Устранена проблема** с 8 рестартами перед стабилизацией

### 2. 🔐 DNS NetworkPolicy
- Явное разрешение UDP/TCP порт 53
- Предотвращает блокировку DNS

### 3. 🚪 PodDisruptionBudget
- Защита от случайного удаления пода
- Гарантия `minAvailable: 1`

### 4. 🔒 SSL-сертификаты Let's Encrypt
- Автоматическая выдача через Traefik
- Email `artur.komarovv@gmail.com` хранится в Secret
- Редирект HTTP → HTTPS

### 5. 🛠️ Автоматическая установка Traefik
- Одна команда - полная настройка
- CRDs, Let's Encrypt, PVC - все автоматически
- Решение проблемы "Bad Gateway"

---

## 📚 Документация

- **[QUICKSTART.md](QUICKSTART.md)** 🌟 - Быстрый старт за 5 минут
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Полная инструкция по деплою
- **[CHANGELOG.md](CHANGELOG.md)** - История изменений
- **[docs/BACKUP_TO_GITHUB.md](docs/BACKUP_TO_GITHUB.md)** - Автоматические бэкапы
- **[docs/SECURITY.md](docs/SECURITY.md)** - Безопасность CI/CD
- **[docs/ETCD_ENCRYPTION.md](docs/ETCD_ENCRYPTION.md)** - Шифрование бэкапов

---

## 🐞 Troubleshooting

### 🔴 Проблема: "502 Bad Gateway" или "сайт не открывается"

**Причина:** Traefik CRDs не установлены

```bash
# Решение: установи Traefik
./scripts/install-traefik.sh

# Проверь, что IngressRoute создан
kubectl get ingressroute -n xui-vpn
```

✅ **Подробнее**: [QUICKSTART.md - Troubleshooting](QUICKSTART.md#-troubleshooting)

### 🔴 Проблема: Под перезапускается
✅ **Решено**: Добавлен `startupProbe` + увеличены таймауты

### 🔴 Проблема: SSL не выдается
```bash
# Проверь логи Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50 | grep -i acme
```
✅ **Решение**: См. [DEPLOYMENT.md](DEPLOYMENT.md#🐞-решение-проблем)

### 🔴 Проблема: Permission denied
```bash
sudo chown -R 2000:2000 /opt/xui-vpn/data
kubectl delete pod -n xui-vpn -l app=xui-panel
```

---

## 🎉 Статус репозитория

✅ **ГОТОВ К ПРОДАКШНУ!**

Все критические проблемы устранены:
- ✅ Health checks оптимизированы
- ✅ DNS NetworkPolicy добавлена
- ✅ PodDisruptionBudget настроен
- ✅ Email для Let's Encrypt правильный
- ✅ CI/CD workflow обновлен
- ✅ IngressRoute применяется автоматически
- ✅ **Traefik устанавливается автоматически**

---

## 🔧 Архитектура

```
Интернет
   ↓
DNS: xui.${SERVER_IP}.nip.io → ${SERVER_IP}
   ↓
Traefik (порты 80/443)
   ↓ Let's Encrypt SSL
IngressRoute → 3X-UI Service (порт 2053)
   ↓
3X-UI StatefulSet
   ↓
PersistentVolume (/opt/xui-vpn/data)
```

### Компоненты

- **StatefulSet** - 3X-UI приложение с RollingUpdate
- **PersistentVolume** - Local storage на хосте
- **Service** - ClusterIP для внутренней связи
- **IngressRoute** - Traefik маршрутизация с SSL
- **NetworkPolicy** - Безопасность сети + DNS
- **PodDisruptionBudget** - Защита от eviction
- **CronJob** - Автоматические бэкапы
