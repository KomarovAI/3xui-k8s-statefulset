# Автоматическое дублирование бэкапов в GitHub

## Обзор

CronJob автоматически:
1. Создает бэкап `.tar.gz` каждый день в 03:00
2. Сохраняет бэкап в PVC (локально)
3. **Автоматически push в GitHub** в ветку `backups`
4. Хранит последние **30 бэкапов** в GitHub
5. Хранит последние **7 дней** в PVC

## Преимущества

- ✅ **Автоматическое версионирование** бэкапов через Git
- ✅ **Внешнее хранение** — защита от потери PV/PVC
- ✅ **Легкое восстановление** — скачать бэкап из GitHub
- ✅ **История изменений** — каждый бэкап в отдельном commit
- ✅ **Не засоряет main** — все бэкапы в отдельной ветке

## Настройка

### Шаг 1: Создать GitHub Personal Access Token (PAT)

1. Перейди в GitHub: https://github.com/settings/tokens
2. Нажми **Generate new token** → **Generate new token (classic)**
3. Укажи:
   - **Note**: `3xui-backup-push`
   - **Expiration**: `No expiration` (или 1 год)
   - **Scopes**: ☑️ `repo` (полный доступ к репозиториям)
4. Нажми **Generate token**
5. **Скопируй токен** (виден только один раз!)

### Шаг 2: Создать Kubernetes Secret

```bash
# Замени ghp_YOUR_TOKEN на свой токен!
kubectl create secret generic github-backup-secret \
  --from-literal=token='ghp_YOUR_TOKEN' \
  -n xui-vpn
```

**Альтернатива**: Отредактировать `manifests/github-backup-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-backup-secret
  namespace: xui-vpn
type: Opaque
stringData:
  token: "ghp_YOUR_REAL_TOKEN_HERE"  # Замени!
```

Применить:

```bash
kubectl apply -f manifests/github-backup-secret.yaml
```

### Шаг 3: Применить обновленный CronJob

```bash
kubectl apply -f manifests/cronjob-backup.yaml
```

### Шаг 4: Проверка

#### Ручной запуск для теста

```bash
# Создать Job из CronJob
kubectl create job --from=cronjob/xui-selfbackup manual-backup-test -n xui-vpn

# Просмотр логов
kubectl logs -n xui-vpn -l app=xui-selfbackup --tail=100 -f
```

Должен появиться вывод:

```
🗡️  Удаление бэкапов старше 7 дней...
📦 Создание бэкапа: xui-backup-20251117-152030.tar.gz
✅ Бэкап создан: 12M
📥 Клонирование репозитория...
✅ Ветка backups существует
📋 Копирование бэкапа в репозиторий...
🗑️  Очистка старых бэкапов в репо (храним последние 30)...
⬆️  Push в GitHub...
✅ Бэкап успешно загружен в GitHub!
🎉 Готово!
```

#### Проверить ветку backups

```bash
# Просмотр в GitHub UI
open https://github.com/KomarovAI/3xui-k8s-statefulset/tree/backups

# Или через CLI
gh browse --branch backups
```

## Расписание бэкапов

- **Частота**: Каждый день в **03:00 UTC**
- **Хранение в PVC**: Последние **7 дней**
- **Хранение в GitHub**: Последние **30 бэкапов**

### Изменить расписание

Отредактируй `manifests/cronjob-backup.yaml`:

```yaml
spec:
  schedule: "0 3 * * *"  # Каждый день в 03:00
  # schedule: "0 */6 * * *"  # Каждые 6 часов
  # schedule: "0 0 * * 0"   # Каждое воскресенье
```

## Восстановление из бэкапа

### Вариант 1: Из GitHub

```bash
# Скачать бэкап из ветки backups
git clone -b backups https://github.com/KomarovAI/3xui-k8s-statefulset.git backups
cd backups

# Просмотр доступных бэкапов
ls -lh xui-backup-*.tar.gz

# Распаковать
tar -xzf xui-backup-20251117-030000.tar.gz -C /path/to/restore/
```

### Вариант 2: Из PVC

```bash
# Подключиться к Pod
kubectl exec -it xui-panel-0 -n xui-vpn -- sh

# Просмотр бэкапов
ls -lh /etc/x-ui/xui-backup-*.tar.gz

# Распаковать
cd /etc/x-ui
tar -xzf xui-backup-20251117-030000.tar.gz
```

## Безопасность

### ✅ Best Practices

1. **Храни PAT только в Kubernetes Secret**
2. **Не коммить PAT в репозиторий**
3. **Отдельная ветка backups** — не засоряет main
4. **Ограничение хранения** — автоматическая ожистка старых бэкапов
5. **Минимальные права** — PAT только с `repo` scope

### ❌ Не допускается

```yaml
# ❌ НЕ ДЕЛАЙ ТАК!
stringData:
  token: "ghp_abc123..."  # Не коммить реальный токен!
```

Используй placeholder или kubectl create secret.

## Troubleshooting

### Проблема: Authentication failed

```
error: Authentication failed for 'https://github.com/...'
```

**Решение**:

1. Проверь PAT:
   ```bash
   kubectl get secret github-backup-secret -n xui-vpn -o jsonpath='{.data.token}' | base64 -d
   ```
2. Убедись, что PAT имеет `repo` permissions
3. Пересоздай Secret с новым токеном

### Проблема: Бэкап не появляется в GitHub

```bash
# Проверить логи CronJob
kubectl logs -n xui-vpn -l app=xui-selfbackup --tail=50

# Проверить статус Jobs
kubectl get jobs -n xui-vpn

# Проверить статус CronJob
kubectl get cronjobs -n xui-vpn
```

### Проблема: Permission denied

```
error: Permission to KomarovAI/3xui-k8s-statefulset.git denied
```

**Решение**:

1. Убедись, что PAT создан от правильного пользователя
2. Проверь права доступа к репозиторию
3. Проверь `GITHUB_REPO` в CronJob

## Мониторинг

```bash
# Просмотр расписания
kubectl get cronjob xui-selfbackup -n xui-vpn

# Просмотр истории запусков
kubectl get jobs -n xui-vpn -l app=xui-selfbackup

# Логи последнего бэкапа
kubectl logs -n xui-vpn -l app=xui-selfbackup --tail=100

# Проверка размера бэкапов в PVC
kubectl exec xui-panel-0 -n xui-vpn -- du -sh /etc/x-ui/xui-backup-*.tar.gz
```

## Ссылки

- [Ветка backups](https://github.com/KomarovAI/3xui-k8s-statefulset/tree/backups)
- [GitHub PAT документация](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Cron расписание](https://crontab.guru/)
