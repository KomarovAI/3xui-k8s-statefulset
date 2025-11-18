# 3X-UI VPN Panel - Kubernetes Deployment

## 🚀 Быстрый старт

### Автоматический деплой через GitHub Actions

```bash
# Через GitHub CLI
gh workflow run deploy-dockerhub.yml

# Или в браузере
# https://github.com/KomarovAI/3xui-k8s-statefulset/actions
```

**Что произойдет:**
1. ✅ Build и Push Docker образа
2. ✅ Trivy сканирование безопасности
3. ✅ Автоматическое применение всех манифестов
4. ✅ RollingUpdate с zero-downtime
5. ✅ SSL-сертификаты от Let's Encrypt

**Подробная инструкция**: [DEPLOYMENT.md](DEPLOYMENT.md)

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

---

## 📚 Документация

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Полная инструкция по деплою
- **[docs/BACKUP_TO_GITHUB.md](docs/BACKUP_TO_GITHUB.md)** - Автоматические бэкапы в GitHub
- **[docs/SECURITY.md](docs/SECURITY.md)** - Безопасность CI/CD
- **[docs/ETCD_ENCRYPTION.md](docs/ETCD_ENCRYPTION.md)** - Шифрование бэкапов

---

## 🐞 Траблшутинг

### Проблема: Под перезапускается
✅ **Решено**: Добавлен `startupProbe` + увеличены таймауты

### Проблема: SSL не выдается
```bash
# Проверь логи Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=50 | grep -i acme
```
✅ **Решение**: См. [DEPLOYMENT.md](DEPLOYMENT.md#🐞-решение-проблем)

### Проблема: Permission denied
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

---

## 🚀 Следующие шаги

1. Очисти кластер (если нужно)
2. Запусти деплой через GitHub Actions
3. Проверь статус: `kubectl get pods -n xui-vpn`
4. Открой `https://xui.${SERVER_IP}.nip.io`

**Подробнее**: [DEPLOYMENT.md](DEPLOYMENT.md)
