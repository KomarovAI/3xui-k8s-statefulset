# 3X-UI VPN Panel on Kubernetes

[![Build, Validate & Push](https://github.com/KomarovAI/3xui-k8s-statefulset/actions/workflows/build-scan-push.yml/badge.svg)](https://github.com/KomarovAI/3xui-k8s-statefulset/actions/workflows/build-scan-push.yml)
[![Kubernetes Integration Test](https://github.com/KomarovAI/3xui-k8s-statefulset/actions/workflows/k8s-integration-test.yml/badge.svg)](https://github.com/KomarovAI/3xui-k8s-statefulset/actions/workflows/k8s-integration-test.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/artur7892988/3xui-k8s-statefulset)](https://hub.docker.com/r/artur7892988/3xui-k8s-statefulset)

> Production-ready 3X-UI VPN panel Docker image optimized for Kubernetes StatefulSet deployments

---

## ✨ Migration Summary 2025-11-21

В рамках аудита CI-репозитория произведено удаление всех инфраструктурных манифестов и скриптов, не связанных напрямую с контейнеризацией и сборкой Docker-образа:

### 📋 Список удалённых инфраструктурных файлов:

- `manifests/*` (все yaml: StatefulSet, Service, PDB, NetworkPolicy, PV/PVC, resourcequota и пр.)
- `scripts/install-traefik.sh`, `setup-traefik.sh`, `migrate-node.sh`, `backup.sh`, `restore.sh`

#### 🗑️ Причины:

- Всё, что отвечает за деплой, инфраструктуру, сетевые политики, хранение, работа с облаком/секретами — теперь должно находиться в отдельном GitOps/Helm/Flux репозитории (например, `k3s-infrastructure`).
- CI-репозиторий (этот) должен содержать исключительно `Dockerfile` и скрипты сборки контейнера.

### ⚡ Для дальнейшей работы:

- Все новые инфраструктурные манифесты и deploy-скрипты добавляйте только в infra-репозиторий!
- CI-репо — только `Dockerfile`, `entrypoint.sh`, `healthcheck.sh` и скрипты сборки/проверки!

*Дата миграции: 21 ноября 2025, МСК*

---

## 🛠️ Features

- **✅ Kubernetes-native**: Designed for StatefulSet with PersistentVolumeClaims
- **🔒 Security-first**: Non-root user (UID:GID 2000:2000), minimal attack surface
- **💨 Lightweight**: Alpine-based multi-stage build (~200MB)
- **🐳 Production-ready**: Liveness/Readiness probes, proper signal handling
- **🧪 Fully tested**: Docker + Kubernetes integration tests

---

## 🧪 CI/CD Testing Strategy

### 🔍 Testing Levels

Our CI/CD pipeline implements **4-tier testing** to ensure production readiness:

```
┌─────────────────────────────────────────────┐
│  1. STATIC ANALYSIS                           │
│  - Hadolint (Dockerfile linting)              │
│  - container-structure-test (file structure)  │
└─────────────────────────────────────────────┘
           │
           │
┌─────────────────────────────────────────────┐
│  2. RUNTIME TESTS (Docker)                    │
│  - dgoss with PVC emulation                   │
│  - Port availability                          │
│  - User/permissions validation                │
│  - Healthcheck endpoint                       │
└─────────────────────────────────────────────┘
           │
           │
┌─────────────────────────────────────────────┐
│  3. KUBERNETES INTEGRATION (KIND)             │
│  - Real StatefulSet deployment                │
│  - PVC persistence across restarts            │
│  - Liveness/Readiness probes                  │
│  - SecurityContext enforcement                │
│  - Service connectivity                       │
└─────────────────────────────────────────────┘
           │
           │
┌─────────────────────────────────────────────┐
│  4. SECURITY SCANNING                         │
│  - Trivy (CVE detection)                      │
│  - Dockle (Docker best practices)             │
│  - SARIF upload to GitHub Security            │
└─────────────────────────────────────────────┘
```

### 📊 Testing Matrix

| Test Type | Tool | What it validates | K8s Compatible |
|-----------|------|-------------------|----------------|
| **Dockerfile lint** | Hadolint | Syntax, best practices | ✅ |
| **Structure test** | container-structure-test | Files, permissions, commands | ✅ |
| **Runtime test** | dgoss | Processes, ports, healthcheck | ✅ |
| **K8s integration** | KIND | StatefulSet, PVC, probes | ✅✅ |
| **Security scan** | Trivy | CVE vulnerabilities | ✅ |
| **Docker hardening** | Dockle | Security best practices | ✅ |

### 🎯 Why Kubernetes Integration Tests?

Standard Docker tests **don't catch K8s-specific issues**:

| Issue | Docker Test | K8s Test |
|-------|-------------|----------|
| PVC mount failures | ❌ Can't detect | ✅ Catches |
| Probe misconfiguration | ❌ Not tested | ✅ Validates |
| SecurityContext violations | ❌ Skipped | ✅ Enforces |
| StatefulSet ordering | ❌ Impossible | ✅ Tests |
| Service DNS resolution | ❌ Not applicable | ✅ Verifies |

---

## 🚀 Quick Start

### Docker

```bash
docker run -d \
  -p 2053:2053 \
  -p 2096:2096 \
  -v /path/to/data:/etc/x-ui \
  artur7892988/3xui-k8s-statefulset:latest
```

### Kubernetes (K3s/K8s)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: xui
spec:
  serviceName: xui
  replicas: 1
  selector:
    matchLabels:
      app: xui
  template:
    metadata:
      labels:
        app: xui
    spec:
      securityContext:
        fsGroup: 2000
      containers:
      - name: xui
        image: artur7892988/3xui-k8s-statefulset:latest
        ports:
        - containerPort: 2053
        - containerPort: 2096
        livenessProbe:
          httpGet:
            path: /
            port: 2053
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 2053
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: data
          mountPath: /etc/x-ui
        securityContext:
          runAsUser: 2000
          runAsGroup: 2000
          allowPrivilegeEscalation: false
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

---

## 🛠️ Development

### Running Tests Locally

#### 1. Structure Tests

```bash
# Install container-structure-test
curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
chmod +x container-structure-test-linux-amd64
sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# Build and test
docker build -t test-image:local .
container-structure-test test --image test-image:local --config structure-test.yaml
```

#### 2. Runtime Tests (dgoss)

```bash
# Install goss and dgoss
curl -fsSL https://goss.rocks/install | sh
curl -fsSL -o dgoss https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss
chmod +x dgoss && sudo mv dgoss /usr/local/bin/

# Create PVC emulation volume
docker volume create test-pvc

# Run dgoss with volume
GOSS_FILES_STRATEGY=cp GOSS_SLEEP=10 \
dgoss run \
  -v test-pvc:/etc/x-ui:rw \
  -e XUI_ENABLE_FAIL2BAN=false \
  test-image:local

# Cleanup
docker volume rm test-pvc
```

#### 3. Kubernetes Integration Tests

```bash
# Install KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name test-cluster

# Load image
docker build -t test-image:local .
kind load docker-image test-image:local --name test-cluster

# Deploy and test (see .github/workflows/k8s-integration-test.yml)
kubectl apply -f <your-manifests>
```

---

## 📚 Documentation

- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [3X-UI Official Repo](https://github.com/MHSanaei/3x-ui)

---

## 🔗 Related Projects

- **Infrastructure Repo**: `k3s-infrastructure` (манифесты, Helm charts, GitOps)
- **Base Image**: [mhsanaei/3x-ui](https://github.com/MHSanaei/3x-ui)

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details

---

## 💬 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/KomarovAI/3xui-k8s-statefulset/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/KomarovAI/3xui-k8s-statefulset/discussions)

---

**Built with ❤️ for production Kubernetes deployments**
