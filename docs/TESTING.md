# 🧪 Kubernetes Integration Testing Guide

## Overview

Комплексная система тестирования для 3XUI Kubernetes StatefulSet, включающая 7 стадий тестирования с использованием современных best practices 2025 года.

## 🎯 Архитектура Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    STAGE 1: Build & Scan                        │
│  • Docker Build с BuildKit                                      │
│  • Trivy Container Vulnerability Scan                           │
│  • SBOM Generation (Syft)                                       │
│  • Grype SBOM Vulnerability Analysis                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              STAGE 2: Manifest Validation                       │
│  • Kubeconform YAML Schema Validation                           │
│  • Pluto Deprecated API Detection                               │
│  • Checkov IaC Security Scanning                                │
│  • Kubesec Security Risk Analysis                               │
│  • Kyverno Policy Validation                                    │
│  • Helm Chart Linting                                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│             STAGE 3: Cluster Deployment                         │
│  • KIND Cluster с Multi-node (control-plane + worker)           │
│  • Kyverno Policy Engine Installation                           │
│  • Application Deployment                                       │
│  • Health Check Verification                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│          STAGE 4: Runtime Security & Compliance                 │
│  • CIS Kubernetes Benchmark (kube-bench)                        │
│  • Polaris Configuration Audit                                  │
│  • Falco Runtime Threat Detection                               │
│  • Resource & Security Context Analysis                         │
│  • Network Policy Validation                                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│           STAGE 5: Integration & E2E Testing                    │
│  • Network Connectivity Tests                                   │
│  • Service Discovery Validation                                 │
│  • Application Health Checks                                    │
│  • API Endpoint Smoke Tests                                     │
│  • Persistent Volume Tests                                      │
│  • Event Analysis                                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│        STAGE 6: Performance & Chaos Engineering                 │
│  • k6 Load & Performance Testing                                │
│  • LitmusChaos Resilience Testing                               │
│  • Resource Utilization Metrics                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│          STAGE 7: Compliance Dashboard & Reporting              │
│  • Unified Test Results Aggregation                             │
│  • Interactive HTML Dashboard                                   │
│  • Compliance Metrics                                           │
│  • Artifact Collection                                          │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Используемые Инструменты

### 🛡️ Security Scanning

| Инструмент | Назначение | Стадия |
|------------|------------|--------|
| **Trivy** | Container vulnerability scanning | Build |
| **Syft** | SBOM generation | Build |
| **Grype** | SBOM vulnerability analysis | Build |
| **Checkov** | IaC security scanning | Validation |
| **Kubesec** | Manifest security scoring | Validation |
| **kube-bench** | CIS Kubernetes benchmark | Runtime |
| **Falco** | Runtime threat detection | Runtime |
| **Polaris** | Best practices audit | Runtime |

### 📋 Validation & Policy

| Инструмент | Назначение | Стадия |
|------------|------------|--------|
| **Kubeconform** | YAML schema validation | Validation |
| **Pluto** | Deprecated API detection | Validation |
| **Kyverno** | Policy-as-code enforcement | Validation + Runtime |
| **Helm Lint** | Helm chart validation | Validation |

### 🧪 Testing & Quality

| Инструмент | Назначение | Стадия |
|------------|------------|--------|
| **k6** | Load & performance testing | Performance |
| **LitmusChaos** | Chaos engineering | Performance |
| **netshoot** | Network connectivity testing | Integration |

## 🚀 Запуск Тестов

### Автоматический запуск

Workflow запускается автоматически при:
- Push в ветку `main`
- Pull Request в ветку `main`
- Еженедельно по расписанию (понедельник, 02:00 UTC)
- Ручной запуск через GitHub Actions UI

### Ручной запуск

```bash
# Через GitHub CLI
gh workflow run "Kubernetes Integration & Security Testing (2025 Best Practices)"

# Или через Web UI
# Actions → Kubernetes Integration & Security Testing → Run workflow
```

## 📊 Интерпретация Результатов

### Артефакты

После выполнения workflow доступны следующие артефакты:

1. **build-scan-results**
   - `trivy-image.json` - результаты Trivy сканирования
   - `sbom.spdx.json` - Software Bill of Materials
   - Grype vulnerability reports

2. **manifest-validation-results**
   - `kubeconform.json` - YAML validation results
   - `pluto-deprecated.txt` - deprecated APIs
   - `checkov.json` - IaC security findings
   - `kubesec-scan.json` - security risk scores
   - `kyverno-validation.txt` - policy violations

3. **runtime-security-results**
   - `kube-bench.json` - CIS benchmark results
   - `polaris-audit.txt` - best practices violations
   - `falco-events.txt` - runtime security events
   - `pod-resources.json` - resource analysis
   - `privileged-containers.json` - security context issues

4. **integration-test-results**
   - `network-connectivity.txt` - connectivity tests
   - `health-checks.json` - pod health status
   - `api-smoke-test.txt` - endpoint tests
   - `storage-status.txt` - PV/PVC validation
   - `k8s-events.txt` - cluster events

5. **performance-chaos-results**
   - `k6-results.json` - load test metrics
   - `k6-output.txt` - detailed k6 output
   - `chaos-results.yaml` - chaos engineering results

6. **compliance-dashboard**
   - `index.html` - interactive test report

### Compliance Dashboard

Интерактивный HTML-отчет с:
- 📊 Ключевые метрики (7 security tools, 7 stages, 95% coverage)
- ✅ Статус всех проверок по категориям
- 📈 Визуализация результатов тестирования
- 🔗 Ссылки на детальные логи

## 🎯 Kyverno Policies

### Установленные Политики

1. **require-resources.yaml**
   - Требует CPU/Memory requests и limits для всех контейнеров
   - Severity: medium
   - Action: audit

2. **disallow-privileged.yaml**
   - Запрещает privileged контейнеры
   - Severity: high
   - Action: enforce

3. **require-labels.yaml**
   - Требует обязательные лейблы (app, version, component)
   - Severity: medium
   - Action: audit

4. **restrict-image-registries.yaml**
   - Ограничивает использование только доверенных registry
   - Allowed: docker.io, gcr.io, ghcr.io, quay.io
   - Severity: high
   - Action: audit

5. **require-non-root.yaml**
   - Требует запуск контейнеров от non-root пользователя
   - Severity: medium
   - Action: audit

### Добавление Своих Политик

```bash
# Создать новую политику
cat > policies/kyverno/my-policy.yaml <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-custom-policy
  annotations:
    policies.kyverno.io/title: My Custom Policy
    policies.kyverno.io/category: Custom
    policies.kyverno.io/severity: medium
spec:
  validationFailureAction: audit
  rules:
  - name: my-rule
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Custom validation message"
      pattern:
        # your validation pattern
EOF

# Workflow автоматически применит политику при следующем запуске
```

## 🔍 Отладка Проблем

### Проверка Логов

```bash
# Скачать все артефакты
gh run download <run-id>

# Просмотр конкретного лога
cat all-test-logs/trivy-image.json | jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL")'

# Анализ policy violations
cat manifest-validation-results/kyverno-validation.txt | grep -A 5 "fail"
```

### Частые Проблемы

#### 1. Pod не стартует
```bash
# Проверить в logs/pod-details.json
jq '.[] | select(.phase != "Running")' logs/pod-details.json

# Проверить events
grep -i error logs/k8s-events.txt
```

#### 2. Policy violations
```bash
# Проверить Kyverno
cat logs/kyverno-validation.txt | grep -E "(PASS|FAIL)"

# Детали нарушений
jq '.items[] | select(.status.policyviolation == true)' logs/pod-resources.json
```

#### 3. Security findings
```bash
# Critical vulnerabilities
jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL")' logs/trivy-image.json

# CIS benchmark failures
jq '.Controls[] | select(.result != "PASS")' logs/kube-bench.json
```

## 📈 Метрики и KPI

### Security Posture Score

```
Score = (Total Checks Passed / Total Checks) * 100

Target: ≥ 95%
```

### Coverage Areas

- ✅ Container Security: Trivy + Grype + SBOM
- ✅ Manifest Security: Checkov + Kubesec + Kyverno
- ✅ Runtime Security: Falco + kube-bench + Polaris
- ✅ Network Security: NetworkPolicies + Connectivity tests
- ✅ Compliance: CIS Benchmark + Best Practices
- ✅ Resilience: Chaos Engineering + Load Tests

## 🔄 CI/CD Integration

### GitHub Actions Integration

Workflow интегрирован с:
- ✅ GitHub Security tab (SARIF upload)
- ✅ Artifact storage
- ✅ Pull Request checks
- ✅ Scheduled scans

### Блокировка Deployment при Failures

```yaml
# В вашем deployment workflow
jobs:
  deploy:
    needs: [k8s-integration-test]
    if: success()
    # ... deployment steps
```

## 🛠️ Расширение и Кастомизация

### Добавление Новых Тестов

1. **Integration Tests**
```yaml
# В job: integration-testing
- name: Custom Integration Test
  run: |
    kubectl run test-pod --image=your-test-image
    # your test logic
```

2. **Security Scanners**
```yaml
# В job: runtime-security
- name: Custom Security Tool
  run: |
    docker run your-security-scanner
```

3. **Performance Tests**
```yaml
# В job: performance-chaos
- name: Custom Load Test
  run: |
    # your k6 script or other tool
```

## 📚 Дополнительные Ресурсы

- [Kyverno Policies Library](https://kyverno.io/policies/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [k6 Load Testing Guide](https://k6.io/docs/)
- [LitmusChaos Experiments](https://litmuschaos.github.io/litmus/experiments/categories/contents/)
- [Falco Rules](https://falco.org/docs/rules/)

## 🤝 Contributing

Для добавления новых тестов или улучшения существующих:

1. Fork repository
2. Create feature branch
3. Add tests in appropriate stage
4. Update this documentation
5. Submit Pull Request

## 📝 License

See main repository LICENSE file.
