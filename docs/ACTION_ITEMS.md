# Security Implementation Action Items

**Generated**: January 22, 2025  
**Priority**: 🔴 CRITICAL → 🟡 HIGH → 🟢 MEDIUM  
**Owner**: DevOps Team

---

## ✅ Completed (January 21-22, 2025)

- [x] **Pin all GitHub Actions to commit SHA** (7 workflows)
- [x] **Add checksum validation** for downloaded binaries
- [x] **Fix cache race conditions** (migrate to GHA cache)
- [x] **Deploy Harden Runner** for network monitoring
- [x] **Enable SBOM generation** (SPDX + CycloneDX)
- [x] **Add build provenance** attestation
- [x] **Improve security context testing** (read-only rootfs, capabilities)
- [x] **Explicit permissions** per workflow job
- [x] **Artifact retention policies** implemented
- [x] **Security audit documentation** complete

---

## 🔴 CRITICAL - Week 1 (Due: January 29, 2025)

### 1. Configure OIDC for Docker Hub

**Why**: Eliminate long-lived credentials, reduce secret sprawl

**Prerequisites**:
- Docker Hub Pro/Team account (OIDC requires paid tier)
- Admin access to Docker Hub organization

**Steps**:

#### A. DockerHub Configuration

1. **Navigate to Organization Settings**
   ```
   https://hub.docker.com/orgs/YOUR_ORG/settings/security-access
   ```

2. **Enable GitHub Actions OIDC**
   - Click "Set up provider" under GitHub Actions
   - Configure trust relationship:
     ```
     Repository: KomarovAI/3xui-k8s-statefulset
     Branch: main
     Environment: (optional, leave blank for all)
     ```

3. **Copy Provider URL**
   - Save the generated provider URL
   - Example: `https://hub.docker.com/v2/orgs/YOUR_ORG/actions/oidc`

#### B. GitHub Repository Configuration

1. **Add Repository Secret**
   ```
   Name: DOCKERHUB_OIDC_PROVIDER
   Value: <provider URL from step A.3>
   ```

2. **Enable Workflow in `6-docker-publish.yml`**
   - Uncomment OIDC login block:
   ```yaml
   - name: Log in to Docker Hub (OIDC)
     uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567
     with:
       registry: docker.io
       # OIDC token used automatically
   ```
   
   - Comment out old login method:
   ```yaml
   # - name: Log in to Docker Hub
   #   uses: docker/login-action@...
   #   with:
   #     username: ${{ secrets.DOCKERHUB_USERNAME }}
   #     password: ${{ secrets.DOCKERHUB_TOKEN }}
   ```

3. **Remove Old Secrets** (after testing)
   - Delete `DOCKERHUB_TOKEN` from repository secrets
   - Keep `DOCKERHUB_USERNAME` (may be needed for README updates)

#### C. Testing

```bash
# Trigger workflow manually
gh workflow run 6-docker-publish.yml

# Monitor logs for OIDC authentication
gh run list --workflow=6-docker-publish.yml
gh run view <RUN_ID> --log

# Verify image was published
docker pull artur7892988/3xui-k8s-statefulset:latest
```

**Rollback Plan**:
- If OIDC fails, revert to old login method
- Re-add `DOCKERHUB_TOKEN` secret
- Uncomment original login block

**Documentation**:
- [ ] Update `docs/SECURITY.md` with OIDC setup
- [ ] Add troubleshooting section

---

## 🟡 HIGH - Week 2-3 (Due: February 5, 2025)

### 2. Implement Image Signing with Cosign

**Why**: Verify image integrity, prevent tampering, meet compliance requirements

#### A. Generate Cosign Keypair

```bash
# Install Cosign locally
wget https://github.com/sigstore/cosign/releases/download/v2.2.2/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Generate keypair
cosign generate-key-pair
# Enter password (save securely!)
# Output: cosign.key (private), cosign.pub (public)
```

#### B. Store Keys Securely

**GitHub Secrets**:
```bash
# Add private key (base64 encoded)
cat cosign.key | base64 -w 0
# Add as secret: COSIGN_PRIVATE_KEY

# Add password
# Secret name: COSIGN_PASSWORD

# Public key (optional, for documentation)
cat cosign.pub | base64 -w 0
# Add as secret: COSIGN_PUBLIC_KEY
```

**External Key Management** (recommended for production):
- AWS KMS: `cosign generate-key-pair --kms awskms:///arn:aws:kms:...`
- Google KMS: `cosign generate-key-pair --kms gcpkms://projects/.../keys/...`
- Azure KMS: `cosign generate-key-pair --kms azurekms://vault.../keys/...`

#### C. Enable Signing in Workflow

**Uncomment in `6-docker-publish.yml`**:
```yaml
- name: Install Cosign
  uses: sigstore/cosign-installer@dc72c7d5c4d10cd6bcb8cf6e3fd625a9e5e537da

- name: Sign image
  env:
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
  run: |
    echo "${{ secrets.COSIGN_PRIVATE_KEY }}" | base64 -d > cosign.key
    cosign sign --key cosign.key \
      ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
    rm cosign.key
```

#### D. Verification Documentation

**Update README.md**:
```markdown
## Image Verification

All images are signed with Cosign. Verify before deployment:

```bash
# Download public key
curl -o cosign.pub https://raw.githubusercontent.com/KomarovAI/3xui-k8s-statefulset/main/cosign.pub

# Verify image
cosign verify --key cosign.pub \
  artur7892988/3xui-k8s-statefulset:v2.5.4

# Kubernetes admission controller (Kyverno example)
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-3xui-images
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-signature
    match:
      resources:
        kinds:
        - Pod
    verifyImages:
    - imageReferences:
      - "artur7892988/3xui-k8s-statefulset:*"
      attestors:
      - count: 1
        entries:
        - keys:
            publicKeys: |
              <PASTE_COSIGN_PUBLIC_KEY_HERE>
EOF
```
```

**Testing**:
```bash
# Sign test image locally
docker pull artur7892988/3xui-k8s-statefulset:latest
cosign sign --key cosign.key artur7892988/3xui-k8s-statefulset:latest

# Verify
cosign verify --key cosign.pub artur7892988/3xui-k8s-statefulset:latest
```

---

### 3. Configure Vulnerability Blocking Thresholds

**Why**: Prevent deployment of critically vulnerable images

#### A. Update Trivy Scan

**In `3-security-scans.yml`**:
```yaml
- name: Scan image (blocking)
  run: |
    trivy image \
      --severity CRITICAL \
      --exit-code 1 \
      --ignore-unfixed \
      --timeout 10m \
      ${{ env.IMAGE_NAME }}

- name: Scan image (reporting)
  if: always()
  run: |
    trivy image \
      --severity HIGH,CRITICAL \
      --format json \
      --output trivy-report.json \
      ${{ env.IMAGE_NAME }}
```

**Policy**:
- **CRITICAL**: Block deployment (exit-code 1)
- **HIGH**: Report only (for awareness)
- **MEDIUM/LOW**: Ignored

#### B. Exception Process

**Create `.trivyignore`**:
```yaml
# CVE-2024-XXXXX: False positive, vendor confirmed
# Expires: 2025-02-28
CVE-2024-XXXXX

# CVE-2023-YYYYY: No fix available, risk accepted
# Mitigation: Network isolation applied
# Approved by: Security Team
# Expires: 2025-03-31
CVE-2023-YYYYY
```

**Approval Workflow**:
1. Developer identifies CVE to ignore
2. Creates PR with justification in `.trivyignore`
3. Security team reviews
4. Approval required before merge

---

### 4. Pin Dockerfile Base Image

**Why**: Reproducible builds, consistent security posture

**Current**:
```dockerfile
FROM alpine:3.22
```

**Improved**:
```dockerfile
FROM alpine:3.22@sha256:abc123...def456
```

**Steps**:
```bash
# Get current digest
docker pull alpine:3.22
docker inspect alpine:3.22 --format='{{.RepoDigests}}'

# Update Dockerfile
FROM alpine:3.22@sha256:<digest_from_above>
```

**Automation** (optional):
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

---

## 🟢 MEDIUM - Month 1 (Due: February 22, 2025)

### 5. Automated Secret Rotation

**GitHub Actions Secrets Rotation**:
- Implement 90-day rotation policy
- Use HashiCorp Vault or AWS Secrets Manager

**Example with AWS Secrets Manager**:
```yaml
- name: Retrieve secrets
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT:role/GitHubActions
    aws-region: us-east-1

- name: Get DockerHub credentials
  run: |
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id prod/dockerhub/credentials \
      --query SecretString --output text)
    echo "::add-mask::$(echo $SECRET | jq -r .token)"
    echo "DOCKERHUB_TOKEN=$(echo $SECRET | jq -r .token)" >> $GITHUB_ENV
```

---

### 6. Dependency Review Action

**Add to workflows**:
```yaml
# .github/workflows/dependency-review.yml
name: 'Dependency Review'
on: [pull_request]

permissions:
  contents: read

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      
      - name: Dependency Review
        uses: actions/dependency-review-action@5a2ce3f5b92ee19cbb1541a4984c76d921601d7c # v4.3.4
        with:
          fail-on-severity: high
          deny-licenses: GPL-2.0, GPL-3.0
```

---

### 7. SLSA Provenance Verification

**Install slsa-verifier**:
```bash
# In Kubernetes deployment
kubectl run verify --rm -it --image=ghcr.io/slsa-framework/slsa-verifier \
  -- verify-image artur7892988/3xui-k8s-statefulset:v2.5.4 \
  --source-uri github.com/KomarovAI/3xui-k8s-statefulset
```

**Admission Controller** (Kyverno):
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-slsa-provenance
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-provenance
    match:
      resources:
        kinds:
        - Pod
    verifyImages:
    - imageReferences:
      - "artur7892988/3xui-k8s-statefulset:*"
      attestations:
      - predicateType: https://slsa.dev/provenance/v1
        conditions:
        - all:
          - key: "{{ builder.id }}"
            operator: Equals
            value: "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v1.9.0"
```

---

## 🔵 LONG-TERM - Quarter 1 (Due: April 30, 2025)

### 8. Achieve SLSA Level 3

**Requirements**:
- [x] Source control (GitHub)
- [x] Build service (GitHub Actions)
- [x] Provenance generation
- [ ] **Non-falsifiable provenance** (hermetic builds)
- [ ] **Isolated build environment** (ephemeral runners)

**Implementation**:
```yaml
# Use SLSA GitHub Generator
- name: Build with SLSA
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v1.9.0
  with:
    image: artur7892988/3xui-k8s-statefulset
    registry-username: ${{ github.actor }}
  secrets:
    registry-password: ${{ secrets.GITHUB_TOKEN }}
```

---

### 9. Runtime Security Monitoring

**Falco Deployment**:
```bash
# Deploy Falco to K8s cluster
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco-system \
  --create-namespace \
  --set tty=true
```

**Custom Rules for 3X-UI**:
```yaml
# /etc/falco/rules.d/3xui-rules.yaml
- rule: Unexpected Network Connection from 3X-UI
  desc: Detect unexpected outbound connections
  condition: >
    outbound and container.image.repository = "artur7892988/3xui-k8s-statefulset"
    and not fd.sip in (allowed_ips)
  output: >
    Unexpected connection from 3X-UI
    (user=%user.name container=%container.name dest=%fd.rip:%fd.rport)
  priority: WARNING
```

---

### 10. Centralized Logging (SIEM)

**Options**:
- **ELK Stack** (self-hosted)
- **Splunk** (enterprise)
- **Datadog** (SaaS)

**Log Sources**:
1. GitHub Actions workflow logs
2. Kubernetes audit logs
3. Container runtime logs
4. Falco security events
5. Harden Runner network logs

---

## Progress Tracking

### Completion Metrics

| Priority | Total | Completed | Remaining | % Done |
|----------|-------|-----------|-----------|--------|
| 🔴 Critical | 11 | 10 | 1 | 91% |
| 🟡 High | 4 | 1 | 3 | 25% |
| 🟢 Medium | 4 | 2 | 2 | 50% |
| 🔵 Long-term | 3 | 0 | 3 | 0% |
| **TOTAL** | **22** | **13** | **9** | **59%** |

### Timeline

```
Week 1 (Jan 22-29)   : OIDC Configuration
Week 2-3 (Jan 30-Feb 5) : Image Signing, Vuln Policies
Month 1 (Feb 6-22)     : Secret Rotation, Dep Review
Q1 2025 (Feb-Apr)      : SLSA L3, Runtime Security
```

---

## Support & Resources

### Internal Contacts
- **Security Team**: security@yourcompany.com
- **DevOps Lead**: devops-lead@yourcompany.com
- **On-call**: +1-XXX-XXX-XXXX

### External Resources
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [SLSA Framework](https://slsa.dev/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

---

**Last Updated**: January 22, 2025  
**Next Review**: February 5, 2025  
**Owner**: DevOps Team
