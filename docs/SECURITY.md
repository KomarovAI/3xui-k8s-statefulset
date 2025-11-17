# Безопасность CI/CD

## Принципы безопасности

### ✅ Только ручной запуск workflow

**ВСЕ** GitHub Actions workflows в этом репозитории настроены только на **ручной запуск** (`workflow_dispatch`).

```yaml
on:
  workflow_dispatch:  # ✅ ТОЛЬКО ручной запуск
```

**Почему?**

Автоматический деплой при push **ОПАСЕН** для production:

- ❌ Нет возможности code review перед деплоем
- ❌ Может сломать работающий сервис
- ❌ Непреднамеренные изменения в production
- ❌ Нарушает GitOps best practices

---

## Доступные Workflows

### 1. `deploy.yml` — Деплой манифестов

**Назначение**: Деплой Kubernetes манифестов без пересборки Docker-образа.

**Запуск**:
```bash
# GitHub UI: Actions → Deploy 3X-UI Panel - MANUAL ONLY → Run workflow
```

**Что делает**:
- Применяет все манифесты из `manifests/`
- Включает Traefik IngressRoute
- Ожидает готовности StatefulSet

**Когда использовать**:
- Обновление конфигурации (manifests)
- Изменение IngressRoute, Service, PV/PVC
- Не требуется пересборка кода

---

### 2. `deploy-dockerhub.yml` — Полный деплой с пересборкой образа

**Назначение**: Сборка Docker-образа, push на Docker Hub и деплой.

**Запуск**:
```bash
# GitHub UI: Actions → Build, Push & Deploy 3X-UI via Docker Hub - Manual Only → Run workflow
```

**Что делает**:
1. Собирает Docker-образ из `Dockerfile`
2. Push на Docker Hub (`artur7892988/3xui-k8s-statefulset:latest`)
3. Применяет манифесты (включая Traefik)
4. Ожидает готовности StatefulSet

**Когда использовать**:
- Изменения в коде (Dockerfile, scripts)
- Обновление базового образа 3X-UI
- Полный редеплой с новым образом

---

## Как запустить workflow вручную?

### Через GitHub UI

1. Перейди в репозиторий: https://github.com/KomarovAI/3xui-k8s-statefulset
2. Нажми **Actions** (верхнее меню)
3. Выбери workflow:
   - `Deploy 3X-UI Panel - MANUAL ONLY` — только манифесты
   - `Build, Push & Deploy 3X-UI via Docker Hub - Manual Only` — с пересборкой
4. Нажми **Run workflow** (справа)
5. Подтверди **Run workflow** (зеленая кнопка)

### Через GitHub CLI

```bash
# Установи GitHub CLI
brew install gh  # macOS
sudo apt install gh  # Ubuntu

# Авторизуйся
gh auth login

# Запусти deploy.yml
gh workflow run deploy.yml --repo KomarovAI/3xui-k8s-statefulset

# Запусти deploy-dockerhub.yml
gh workflow run deploy-dockerhub.yml --repo KomarovAI/3xui-k8s-statefulset

# Просмотреть статус
gh run list --repo KomarovAI/3xui-k8s-statefulset
```

---

## GitHub Secrets

Для работы workflows требуются следующие secrets:

### Обязательные

| Secret | Назначение | Используется в |
|--------|------------|---------------|
| `KUBECONFIG` | Конфигурация kubectl для доступа к K8s | Все workflows |
| `DOCKERHUB_USERNAME` | Docker Hub логин | `deploy-dockerhub.yml` |
| `DOCKERHUB_TOKEN` | Docker Hub access token | `deploy-dockerhub.yml` |

### Опциональные (для дополнительных фич)

| Secret | Назначение |
|--------|------------|
| `XUI_ADMIN_USER` | Логин админа 3X-UI |
| `XUI_ADMIN_PASS` | Пароль админа 3X-UI |

### Как добавить secrets?

1. Перейди в репозиторий
2. **Settings** → **Secrets and variables** → **Actions**
3. Нажми **New repository secret**
4. Введи `Name` и `Secret`
5. Нажми **Add secret**

---

## Что НЕ допускается?

### ❌ Автоматический запуск при push

**НЕ добавляй** в workflows:

```yaml
# ❌ ОПАСНО ДЛЯ PRODUCTION!
on:
  push:
    branches: [ main ]
```

### ❌ Pull Request автодеплой

**НЕ добавляй**:

```yaml
# ❌ ОПАСНО ДЛЯ PRODUCTION!
on:
  pull_request:
    types: [opened, synchronize]
```

### ❌ Хранение secrets в коде

**НЕ коммить** секреты в репозиторий:

```yaml
# ❌ ОПАСНО!
env:
  KUBECONFIG: "ls0tLS1CRUdJTi..."
  DOCKERHUB_TOKEN: "dckr_pat_abc123..."
```

Используй GitHub Secrets:

```yaml
# ✅ БЕЗОПАСНО
env:
  KUBECONFIG: ${{ secrets.KUBECONFIG }}
  DOCKERHUB_TOKEN: ${{ secrets.DOCKERHUB_TOKEN }}
```

---

## Best Practices

### ✅ Рекомендации

1. **Всегда используй ручной запуск** для production-деплоев
2. **Code review** перед каждым деплоем
3. **Тестирование** в staging-окружении перед production
4. **Мониторинг** после деплоя
5. **Rollback-план** на случай проблем

### ❌ Антипаттерны

1. Не используй `push` triggers для production
2. Не храни secrets в коде
3. Не деплой без тестов
4. Не пропускай code review

---

## Мониторинг workflows

```bash
# Просмотр последних запусков
gh run list --repo KomarovAI/3xui-k8s-statefulset

# Просмотр логов workflow
gh run view <RUN_ID> --repo KomarovAI/3xui-k8s-statefulset

# Отслеживание текущего запуска
gh run watch --repo KomarovAI/3xui-k8s-statefulset
```

---

## Ссылки

- [GitHub Actions документация](https://docs.github.com/en/actions)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub CLI](https://cli.github.com/)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
