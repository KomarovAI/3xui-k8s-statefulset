# 🚨 Error Reporting & Aggregation System

## 🎯 Обзор

Система автоматической агрегации ошибок из всех 7 стадий тестирования с генерацией единого отчета.

### Ключевые возможности:

- ✅ **Автоматическая сборка** ошибок из всех стадий
- 📈 **Категоризация** по severity (CRITICAL/HIGH/MEDIUM/LOW)
- 🎯 **Группировка** по category, stage, tool
- 💡 **Акционные рекомендации** для каждой ошибки
- 📊 **Interactive HTML Dashboard** с визуализацией
- 📝 **Markdown отчет** для Pull Request
- 🔗 **JSON API** для интеграции

---

## 🏛️ Архитектура

```
┌──────────────────────────────────────────────────────┐
│            STAGE 1: Build & Scan                      │
│  Trivy, Syft, Grype → errors/build-errors.json     │
└──────────────────────────────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│       STAGE 2: Manifest Validation                  │
│  Kubeconform, Pluto, Checkov, Kyverno              │
│  → errors/validation-errors.json                   │
└──────────────────────────────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│          STAGE 3-6: Testing Stages                  │
│  Deployment, Security, Integration, Performance     │
│  → errors/*.json                                   │
└──────────────────────────────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│       STAGE 7: Error Aggregation                     │
│                                                      │
│  1. Сбор всех errors/*.json                      │
│  2. Комбинирование в all-errors.json             │
│  3. Анализ и группировка                         │
│  4. Генерация отчетов                              │
│                                                      │
│  📄 OUTPUT:                                        │
│  • error-summary.json                               │
│  • index.html (интерактивный dashboard)          │
│  • ERRORS.md (Markdown отчет)                    │
│  • by-category.json                                 │
│  • by-stage.json                                    │
│  • by-tool.json                                     │
└──────────────────────────────────────────────────────┘
```

---

## 📊 Формат Ошибок

### Error Object Structure

```json
{
  "category": "container-security",
  "severity": "CRITICAL",
  "tool": "Trivy",
  "message": "Found 5 CRITICAL and 12 HIGH vulnerabilities in container image",
  "recommendation": "Review logs/trivy-image.json and update vulnerable dependencies"
}
```

### Severity Levels

| Severity | Описание | Действие |
|----------|-------------|----------|
| **CRITICAL** | Критические проблемы, блокирующие deployment | Workflow падает, немедленное исправление |
| **HIGH** | Важные проблемы безопасности/качества | Исправить в течение 24ч |
| **MEDIUM** | Умеренные проблемы, требующие внимания | Запланировать исправление |
| **LOW** | Минорные проблемы или улучшения | Исправить при возможности |

### Error Categories

```
container-security     - Уязвимости в контейнере
yaml-validation        - Ошибки валидации YAML
deprecated-api         - Устаревшие API
iac-security           - IaC security проблемы
policy-violation       - Нарушения политик
deployment             - Проблемы с deployment
compliance             - CIS/комплаенс проблемы
best-practices         - Нарушения best practices
security-context       - Security context проблемы
health-check           - Health/readiness проблемы
cluster-events         - Проблемные события кластера
performance            - Performance проблемы
```

---

## 📄 Форматы Отчетов

### 1. error-summary.json

Главный файл с полной информацией об ошибках:

```json
{
  "timestamp": "2025-11-21T18:00:00Z",
  "workflow_run": "12345678",
  "commit": "abc123...",
  "branch": "main",
  "summary": {
    "total_errors": 15,
    "critical": 2,
    "high": 5,
    "medium": 6,
    "low": 2
  },
  "by_category": {
    "container-security": 3,
    "yaml-validation": 2,
    "compliance": 5,
    "...": "..."
  },
  "by_stage": {
    "build-and-scan": 3,
    "manifest-validation": 4,
    "runtime-security": 5,
    "...": "..."
  },
  "by_tool": {
    "Trivy": 3,
    "kube-bench": 5,
    "Kubeconform": 2,
    "...": "..."
  },
  "all_errors": [
    {
      "category": "container-security",
      "severity": "CRITICAL",
      "tool": "Trivy",
      "message": "...",
      "recommendation": "...",
      "stage": "build-and-scan"
    }
  ]
}
```

### 2. index.html - Interactive Dashboard

**Возможности:**
- 📈 Интерактивные графики
- 🎯 Фильтрация по severity, category, tool
- 🔗 Quick links к логам
- 💡 Рекомендации для каждой ошибки
- 🎨 Цветовое кодирование по severity

**Разделы:**
1. Executive Summary - общие метрики
2. Error Distribution Charts - графики распределения
3. Detailed Error List - полный список с рекомендациями
4. Quick Links - ссылки на workflow и artifacts

### 3. ERRORS.md - Markdown Report

**Структура:**
```markdown
# 🚨 Kubernetes Testing Error Report

## 📊 Executive Summary
### Error Counts
- **Total Errors:** 15
- **Critical:** 2
- **High:** 5

## 🎯 Errors by Category
- **container-security:** 3
- **compliance:** 5

## 🚨 Detailed Error List
### [CRITICAL] container-security
- **Tool:** Trivy
- **Message:** ...
- **Recommendation:** ...
```

---

## 🚀 Использование

### Просмотр Отчетов

**1. Через GitHub Actions UI:**
```
Actions → Workflow Run → Artifacts → final-error-report
```

**2. Через GitHub CLI:**
```bash
# Скачать отчет
gh run download <run-id> -n final-error-report

# Открыть HTML dashboard
open final-report/index.html

# Просмотреть JSON summary
cat final-report/error-summary.json | jq '.summary'
```

**3. В Pull Request:**
Автоматический комментарий с summary:
```
## ✅ Kubernetes Test Report - SUCCESS

### 📊 Summary
- **Total Errors:** 0
- **Critical:** 0

### 🔗 Quick Links
- [View Full Report](...)
```

### Анализ Ошибок

**1. По категории:**
```bash
jq '.by_category | to_entries | sort_by(.value) | reverse' final-report/error-summary.json
```

**2. Только CRITICAL:**
```bash
jq '.all_errors[] | select(.severity=="CRITICAL")' final-report/error-summary.json
```

**3. По инструменту:**
```bash
jq '.all_errors[] | select(.tool=="Trivy")' final-report/error-summary.json
```

**4. По стадии:**
```bash
jq '.all_errors[] | select(.stage=="runtime-security")' final-report/error-summary.json
```

---

## 🔧 Интеграция

### CI/CD Pipelines

```yaml
# Использование в deployment workflow
jobs:
  deploy:
    needs: [k8s-tests]
    if: |
      needs.k8s-tests.outputs.critical-errors == '0'
    steps:
      - name: Deploy to production
        run: kubectl apply -f k8s/
```

### Monitoring Systems

```bash
# Отправка метрик в Prometheus
curl -X POST prometheus:9091/metrics/job/k8s-tests \
  --data-binary @<(cat final-report/error-summary.json | jq -r '
    "k8s_test_errors_total \(.summary.total_errors)\n" +
    "k8s_test_errors_critical \(.summary.critical)\n" +
    "k8s_test_errors_high \(.summary.high)"
  ')
```

### Slack Notifications

```yaml
- name: Send Slack notification
  if: always()
  run: |
    TOTAL=$(jq '.summary.total_errors' final-report/error-summary.json)
    CRITICAL=$(jq '.summary.critical' final-report/error-summary.json)
    
    COLOR="good"
    if [ "$CRITICAL" -gt "0" ]; then COLOR="danger"; fi
    if [ "$TOTAL" -gt "0" ] && [ "$CRITICAL" -eq "0" ]; then COLOR="warning"; fi
    
    curl -X POST $SLACK_WEBHOOK -H 'Content-type: application/json' --data "{
      'attachments': [{
        'color': '$COLOR',
        'title': 'K8s Test Report',
        'text': 'Total: $TOTAL | Critical: $CRITICAL',
        'actions': [{
          'type': 'button',
          'text': 'View Report',
          'url': '${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}'
        }]
      }]
    }"
```

### Custom Dashboards

```javascript
// Загрузка и отображение данных
fetch('https://api.github.com/repos/USER/REPO/actions/artifacts')
  .then(res => res.json())
  .then(artifacts => {
    const errorReport = artifacts.artifacts
      .find(a => a.name === 'final-error-report');
    
    // Download and process error-summary.json
    fetch(errorReport.archive_download_url)
      .then(res => res.json())
      .then(data => {
        displayErrorMetrics(data.summary);
        renderErrorCharts(data);
      });
  });
```

---

## 📈 Метрики и Тренды

### Отслеживание Трендов

```bash
# Скачать последние 10 отчетов
for run_id in $(gh run list -L 10 --json databaseId -q '.[].databaseId'); do
  gh run download $run_id -n final-error-report -D reports/$run_id
done

# Анализ трендов
jq -s 'map({
  run: .workflow_run,
  total: .summary.total_errors,
  critical: .summary.critical
})' reports/*/error-summary.json
```

### Key Performance Indicators

```bash
# Error Rate
ERROR_RATE=$(jq '.summary.total_errors' final-report/error-summary.json)

# Critical Error Density
CRITICAL_DENSITY=$(jq '.summary.critical / .summary.total_errors * 100' final-report/error-summary.json)

# Most Problematic Stage
WORST_STAGE=$(jq -r '.by_stage | to_entries | max_by(.value) | .key' final-report/error-summary.json)

# Most Problematic Category
WORST_CATEGORY=$(jq -r '.by_category | to_entries | max_by(.value) | .key' final-report/error-summary.json)
```

---

## 💡 Best Practices

### 1. Регулярный Review

```bash
# Ежедневное рассмотрение CRITICAL ошибок
jq '.all_errors[] | select(.severity=="CRITICAL") | 
  {category, tool, message, recommendation}' \
  final-report/error-summary.json
```

### 2. Приоритизация

**Порядок исправления:**
1. ❗ CRITICAL ошибки (немедленно)
2. 🔴 HIGH security проблемы (24ч)
3. 🟮 MEDIUM compliance issues (неделя)
4. 🔵 LOW improvements (при возможности)

### 3. Автоматизация

```yaml
# Авто-создание issues для CRITICAL ошибок
- name: Create issues for critical errors
  run: |
    jq -c '.all_errors[] | select(.severity=="CRITICAL")' \
      final-report/error-summary.json | while read error; do
      TITLE=$(echo $error | jq -r '.category + ": " + .message')
      BODY=$(echo $error | jq -r '.recommendation')
      
      gh issue create \
        --title "[CRITICAL] $TITLE" \
        --body "$BODY" \
        --label "critical,security"
    done
```

### 4. Documentation

```markdown
# Добавьте в README.md

## 🚨 Error Reporting

Our CI/CD generates comprehensive error reports:
- View latest: [Actions](link-to-actions)
- Download: `gh run download --name final-error-report`
- Dashboard: Open `index.html` from artifact
```

---

## 🔍 Troubleshooting

### Не генерируются отчеты

```bash
# Проверьте наличие error artifacts
gh run view <run-id> --log | grep "error-aggregation"

# Проверьте структуру JSON
jq '.' final-report/error-summary.json
```

### Неправильные количества ошибок

```bash
# Проверьте каждую стадию
for stage in build-and-scan manifest-validation runtime-security; do
  echo "=== $stage ==="
  jq ".errors | length" all-results/$stage-results/errors/*.json
done
```

### HTML не открывается

```bash
# Проверьте корректность JSON injection
grep "ERROR_DATA_PLACEHOLDER" final-report/index.html
# Не должно быть результатов

# Валидация HTML
html5validator final-report/index.html
```

---

## 📚 Примеры

### Полный цикл работы с ошибками

```bash
#!/bin/bash
# error-workflow.sh

# 1. Скачать отчет
gh run download --name final-error-report

# 2. Проверить critical ошибки
CRITICAL=$(jq '.summary.critical' final-report/error-summary.json)

if [ "$CRITICAL" -gt "0" ]; then
  echo "⚠️ Found $CRITICAL critical errors!"
  
  # 3. Создать issues
  jq -c '.all_errors[] | select(.severity=="CRITICAL")' \
    final-report/error-summary.json | while read error; do
    
    CATEGORY=$(echo $error | jq -r '.category')
    MESSAGE=$(echo $error | jq -r '.message')
    RECOMMENDATION=$(echo $error | jq -r '.recommendation')
    
    gh issue create \
      --title "[CRITICAL] $CATEGORY" \
      --body "**Message:** $MESSAGE\n\n**Recommendation:** $RECOMMENDATION" \
      --label "critical"
  done
  
  # 4. Отправить в Slack
  curl -X POST $SLACK_WEBHOOK -d "{
    'text': '⚠️ Critical errors found in K8s tests',
    'attachments': [{
      'color': 'danger',
      'fields': [{
        'title': 'Critical Errors',
        'value': '$CRITICAL',
        'short': true
      }]
    }]
  }"
fi

# 5. Открыть dashboard
open final-report/index.html
```

---

## 🔗 Ссылки

- [Main Testing Documentation](./TESTING.md)
- [Workflow Configuration](../.github/workflows/k8s-integration.yml)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

## 🤝 Contributing

Для добавления новых категорий ошибок:

1. Добавьте detection logic в соответствующую стадию
2. Обновите этот документ
3. Добавьте примеры в README
4. Submit Pull Request
