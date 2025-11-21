# Contributing to 3X-UI Kubernetes Image

Спасибо за интерес к проекту! 🚀

Thank you for your interest in contributing! This guide will help you get started.

---

## 🛠️ Development Setup

### Prerequisites

- **Docker**: 24.0+ with BuildKit enabled
- **kubectl**: 1.28+ (for K8s testing)
- **KIND**: 0.20+ (Kubernetes in Docker)
- **Git**: 2.40+
- **Bash**: 5.0+ (for test scripts)

### Local Environment Setup

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/3xui-k8s-statefulset.git
cd 3xui-k8s-statefulset

# 2. Add upstream remote
git remote add upstream https://github.com/KomarovAI/3xui-k8s-statefulset.git

# 3. Install testing tools
./scripts/install-test-tools.sh  # If available, or follow manual steps below
```

---

## 🧪 Running Tests Locally

### 1. Docker Build Test

```bash
# Build image
docker build -t test-image:local .

# Verify image size
docker images test-image:local
# Expected: ~200-250MB

# Inspect layers
docker history test-image:local
```

### 2. Structure Tests

```bash
# Install container-structure-test
curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64
chmod +x container-structure-test-linux-amd64
sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# Run tests
container-structure-test test \
  --image test-image:local \
  --config structure-test.yaml
```

### 3. Runtime Tests (goss)

```bash
# Install goss and dgoss
curl -fsSL https://goss.rocks/install | sh
curl -fsSL -o dgoss https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss
chmod +x dgoss && sudo mv dgoss /usr/local/bin/

# Create test volume
docker volume create test-pvc

# Run dgoss
GOSS_FILES_STRATEGY=cp GOSS_SLEEP=10 \
dgoss run \
  -v test-pvc:/etc/x-ui:rw \
  -e XUI_ENABLE_FAIL2BAN=false \
  test-image:local

# Cleanup
docker volume rm test-pvc
```

### 4. Kubernetes Integration Tests

```bash
# Install KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Create test cluster
kind create cluster --name xui-test

# Load image
kind load docker-image test-image:local --name xui-test

# Create test namespace
kubectl create namespace xui-test

# Deploy test pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: xui-test
  namespace: xui-test
spec:
  containers:
  - name: xui
    image: test-image:local
    imagePullPolicy: Never
    ports:
    - containerPort: 2053
    volumeMounts:
    - name: data
      mountPath: /etc/x-ui
    securityContext:
      runAsUser: 2000
      runAsGroup: 2000
      allowPrivilegeEscalation: false
  volumes:
  - name: data
    emptyDir: {}
EOF

# Wait for ready
kubectl wait --for=condition=Ready pod/xui-test -n xui-test --timeout=120s

# Test connectivity
kubectl exec xui-test -n xui-test -- curl -sf http://localhost:2053/

# Cleanup
kind delete cluster --name xui-test
```

---

## 🔄 CI/CD Pipeline

### Workflow Architecture

The project uses **7 parallel workflows** for comprehensive testing:

1. **1-build-critical.yml** (⚡ BLOCKING)
   - Builds Docker image
   - Runs smoke tests
   - Tests health probes in KIND
   - **Blocks merge if fails**

2. **2-static-analysis.yml** (📊 Parallel)
   - Hadolint (Dockerfile linting)
   - Kube-score (K8s best practices)
   - Kubeconform (YAML validation)
   - **Non-blocking warnings**

3. **3-security-scans.yml** (🔒 After build)
   - Trivy (CVE scanning)
   - Grype (vulnerability analysis)
   - Dockle (Docker hardening)
   - Syft (SBOM generation)

4. **4-image-optimization.yml** (🎯 Scheduled)
   - Dive layer analysis
   - Weekly optimization reports

5. **5-unified-report.yml** (📊 Summary)
   - Aggregates all test results
   - Posts PR comments

6. **6-docker-publish.yml** (📦 Production)
   - Publishes to Docker Hub
   - Multi-arch builds (amd64, arm64)
   - Updates Docker Hub description

7. **7-release-automation.yml** (🏷️ Manual)
   - Creates GitHub releases
   - Generates changelogs
   - Tags versions

### Self-Hosted Runners

**Why self-hosted for smoke/health tests?**

1. **Performance**: Persistent Docker layer cache (~3x faster builds)
2. **KIND clusters**: Pre-configured clusters reduce setup time
3. **Cost**: Free compute for private repos
4. **Isolation**: Dedicated resources for integration tests

**For contributors:**
- **PRs automatically use GitHub-hosted runners** (✅ You don't need self-hosted!)
- Maintainers run final validation on self-hosted before merge
- All tools work identically on both runner types

**Setting up self-hosted runner** (maintainers only):
```bash
# Download runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64.tar.gz

# Configure
./config.sh --url https://github.com/KomarovAI/3xui-k8s-statefulset --token <TOKEN>

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

---

## 📝 Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **chore**: Maintenance tasks
- **refactor**: Code refactoring
- **test**: Test updates
- **ci**: CI/CD changes
- **perf**: Performance improvements

### Examples

```bash
# Good commits
git commit -m "feat(docker): add multi-arch support for arm64"
git commit -m "fix(healthcheck): increase timeout to 10s"
git commit -m "docs: update installation instructions"
git commit -m "ci: parallelize security scans"

# Bad commits (avoid)
git commit -m "update stuff"
git commit -m "fix bug"
git commit -m "WIP"
```

---

## 🔀 Pull Request Process

### Before Creating PR

- [ ] Code builds successfully: `docker build -t test:local .`
- [ ] Tests pass locally: `container-structure-test` + `dgoss`
- [ ] Commit messages follow convention
- [ ] Documentation updated (if needed)
- [ ] CHANGELOG.md updated (for user-facing changes)

### PR Template

```markdown
## Description
<!-- What does this PR do? -->

## Type of Change
- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update

## Testing
<!-- How was this tested? -->

## Checklist
- [ ] Code follows project conventions
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Commits follow conventional format
```

### Review Process

1. **Automated checks** run on PR creation
2. **Maintainer review** within 48 hours
3. **CI/CD validation** must pass (1-build-critical.yml)
4. **Merge** after approval + green CI

---

## 🎯 Code Style Guidelines

### Dockerfile

```dockerfile
# ✅ Good: Multi-line with comments
RUN apk update && apk upgrade --no-cache && apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl>=8.16.0 && \
    rm -rf /var/cache/apk/*

# ❌ Bad: Single long line
RUN apk update && apk upgrade --no-cache && apk add --no-cache ca-certificates tzdata bash curl>=8.16.0 && rm -rf /var/cache/apk/*
```

### YAML (workflows)

```yaml
# ✅ Good: Descriptive names, proper indentation
- name: Run smoke tests with retry
  run: |
    for i in {1..3}; do
      kubectl wait --for=condition=Ready pod/test --timeout=60s && break
      sleep 10
    done

# ❌ Bad: Unclear names, poor formatting
- name: test
  run: kubectl wait --for=condition=Ready pod/test --timeout=60s
```

### Bash Scripts

```bash
#!/bin/bash
set -euo pipefail  # Fail fast

# ✅ Good: Error handling
if ! docker build -t test:local .; then
    echo "❌ Build failed"
    exit 1
fi

# ❌ Bad: No error checking
docker build -t test:local .
```

---

## 🐛 Reporting Issues

### Bug Reports

Include:
- **Environment**: OS, Docker version, Kubernetes version
- **Steps to reproduce**: Exact commands/configs
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Logs**: Relevant error messages

### Feature Requests

Include:
- **Use case**: Why is this needed?
- **Proposed solution**: How should it work?
- **Alternatives**: Other options considered

---

## 💬 Questions?

- **Discussions**: [GitHub Discussions](https://github.com/KomarovAI/3xui-k8s-statefulset/discussions)
- **Issues**: [GitHub Issues](https://github.com/KomarovAI/3xui-k8s-statefulset/issues)
- **Email**: artur.komarovv@gmail.com

---

**Спасибо за ваш вклад! Thank you for contributing!** ❤️
