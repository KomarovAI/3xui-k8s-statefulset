# Шифрование Secrets в etcd (Encryption at Rest)

## Обзор

По умолчанию Kubernetes Secrets **не шифруются** в etcd — они хранятся в plain text (Base64-encoded). Это критическая уязвимость для production-сред.

## Зачем нужно?

- Защита от утечки credentials при компрометации etcd
- Compliance (GDPR, HIPAA, PCI DSS, SOC 2)
- Защита бэкапов etcd
- Защита от insider threats

---

## Шаг 1: Генерация encryption key

```bash
# Генерируем 32-байтный ключ
head -c 32 /dev/urandom | base64

# Пример вывода:
# XYZ123abc456def789GHI012jkl345M==

# Сохрани этот ключ в безопасном месте (KMS, Vault, password manager)
```

---

## Шаг 2: Создание EncryptionConfiguration

Скопируй `manifests/encryption-config.yaml` и замени placeholder:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: XYZ123abc456def789GHI012jkl345M==  # Твой ключ
      - identity: {}
```

Сохрани как `/etc/kubernetes/encryption-config.yaml` на **всех control plane нодах**.

---

## Шаг 3: Настройка kube-apiserver

### Для kubeadm-кластеров

Редактируй `/etc/kubernetes/manifests/kube-apiserver.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - command:
    - kube-apiserver
    # Добавь эти флаги:
    - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml
    volumeMounts:
    - name: encryption-config
      mountPath: /etc/kubernetes/encryption-config.yaml
      readOnly: true
  volumes:
  - name: encryption-config
    hostPath:
      path: /etc/kubernetes/encryption-config.yaml
      type: File
```

kube-apiserver автоматически перезапустится.

### Для managed Kubernetes (EKS, GKE, AKS)

- **AWS EKS**: Используй [EKS Secrets Encryption](https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html) с AWS KMS
- **GKE**: Автоматическое шифрование через Google Cloud KMS
- **AKS**: Используй [Azure Key Vault Provider](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)

---

## Шаг 4: Проверка

```bash
# Проверь, что apiserver запустился
kubectl get pods -n kube-system | grep apiserver

# Проверь логи
kubectl logs -n kube-system kube-apiserver-<node> | grep -i encrypt

# Должно быть:
# "Loaded encryption provider" или "Успешно загружено"
```

---

## Шаг 5: Перешифрование существующих Secrets

Существующие Secrets **НЕ шифруются автоматически**. Нужно перезаписать:

```bash
# Перешифровать все Secrets в кластере
kubectl get secrets --all-namespaces -o json | \
  kubectl replace -f -

# Или только в конкретном namespace
kubectl get secrets -n xui-vpn -o json | \
  kubectl replace -f -
```

---

## Шаг 6: Проверка шифрования в etcd

```bash
# Получи Secret из etcd напрямую
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/xui-vpn/xui-admin-secret | hexdump -C

# Если шифрование работает, увидишь:
# k8s:enc:aescbc:v1:key1:...<binary_data>...

# Если НЕ шифруется:
# k8s:...<plaintext_data>...
```

---

## Ротация ключей (Key Rotation)

Рекомендуется ротировать ключи **каждые 90 дней**:

1. Генерируй новый ключ (`key2`)
2. Добавь его в `encryption-config.yaml` **ПЕРВЫМ**:
   ```yaml
   providers:
     - aescbc:
         keys:
           - name: key2  # Новый ключ
             secret: NEW_KEY_HERE
           - name: key1  # Старый ключ
             secret: OLD_KEY_HERE
     - identity: {}
   ```
3. Перезапусти apiserver
4. Перешифруй все Secrets: `kubectl get secrets --all-namespaces -o json | kubectl replace -f -`
5. Удали `key1` из config

---

## KMS Provider (рекомендуется для production)

Для enterprise-сред используй **KMS (Key Management Service)**:

### AWS KMS

```yaml
providers:
  - kms:
      name: aws-encryption-provider
      endpoint: unix:///var/run/kmsplugin/socket.sock
      cachesize: 1000
      timeout: 3s
```

Установи [AWS Encryption Provider](https://github.com/kubernetes-sigs/aws-encryption-provider)

### HashiCorp Vault

```yaml
providers:
  - kms:
      name: vault
      endpoint: unix:///var/run/kmsplugin/vault.sock
      cachesize: 1000
```

Установи [Vault KMS Provider](https://github.com/hashicorp/vault-plugin-secrets-kv)

---

## Troubleshooting

### apiserver не запускается

```bash
# Проверь логи
journalctl -u kubelet -f
kubectl logs -n kube-system kube-apiserver-<node>

# Частые проблемы:
# - Неверный путь к encryption-config.yaml
# - Неверный YAML синтаксис
# - Невалидный base64 ключ
```

### Secrets не шифруются

```bash
# Проверь, что apiserver использует encryption-config
ps aux | grep kube-apiserver | grep encryption-provider-config

# Перешифруй вручную
kubectl get secret xui-admin-secret -n xui-vpn -o yaml | kubectl replace -f -
```

---

## Best Practices

✅ **Используй KMS** вместо aescbc для production  
✅ **Ротируй ключи** каждые 90 дней  
✅ **Бэкапь encryption keys** в безопасное хранилище  
✅ **Мониторь** доступ к encryption-config.yaml  
✅ **Audit logging** для доступа к Secrets  

❌ **Не кормить** encryption keys в Git  
❌ **Не использовать** identity provider в production  

---

## Ссылки

- [Kubernetes Docs: Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [AWS EKS Secrets Encryption](https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html)
- [KMS Plugin for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/kms-provider/)
- [OWASP: Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)
