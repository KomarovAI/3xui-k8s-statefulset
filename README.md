# 3X-UI VPN Panel on Kubernetes

## StatefulSet + Local Persistent Volume Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)

---

## 📋 Описание

Production-ready развертывание 3X-UI VPN панели в Kubernetes с использованием **StatefulSet** и **Local Persistent Volumes**.

### Почему именно Local PV?

| Критерий | hostPath | Local PV | NFS/Longhorn |
|----------|----------|----------|-------------|
| **Kubernetes Lifecycle** | ❌ Нет | ✅ Да | ✅ Да |
| **Production Ready** | ❌ Нет | ✅ Да | ✅ Да |
| **kubectl Visibility** | ❌ Нет | ✅ Да | ✅ Да |
| **Scheduler Awareness** | ❌ Нет | ✅ Да | ✅ Да |
| **Сложность Setup** | ✅ Простая | 🟡 Средняя | 🔴 Высокая |
| **Multi-Node Support** | ❌ Нет | 🟡 С nodeAffinity | ✅ Да |
| **High Availability** | ❌ Нет | ❌ Нет | ✅ Да |

**Вывод**: Local PV — оптимальный выбор для single-node VPN развертывания с полной интеграцией в Kubernetes экосистему.

---

## 🚀 Возможности

- ✅ **Production-ready StatefulSet** с Local Persistent Volumes
- ✅ **hostNetwork** для прямого доступа к портам
- ✅ **OnDelete update strategy** — только ручные обновления
- ✅ **Автоматические backup скрипты**
- ✅ **Простое восстановление данных**
- ✅ **Single или multi-node** поддержка через nodeSelector
- ✅ **Kubernetes lifecycle management**

---

## 📦 Требования

- Kubernetes кластер (k3s/k8s)
- kubectl, настроенный и готовый к работе
- Single node или multi-node с node selector
- **Рекомендуется**: 512MB RAM, 1 CPU для 3X-UI pod

---

## 🎯 Быстрый старт

### 1. Клонировать репозиторий

```bash
git clone https://github.com/KomarovAI/3xui-k8s-statefulset.git
cd 3xui-k8s-statefulset
```

### 2. Развернуть одной командой

```bash
./deploy.sh
```

### 3. Проверить статус

```bash
kubectl get all -n xui-vpn
```

---

## 📂 Структура проекта

```
3xui-k8s-statefulset/
├── README.md                    # Этот файл
├── deploy.sh                    # Скрипт автоматического развертывания
├── uninstall.sh                 # Скрипт полного удаления
├── manifests/
│   ├── namespace.yaml           # Namespace xui-vpn
│   ├── storageclass.yaml        # StorageClass с WaitForFirstConsumer
│   ├── persistentvolume.yaml    # Local PV с nodeAffinity
│   ├── persistentvolumeclaim.yaml # PVC для данных
│   └── statefulset.yaml         # StatefulSet с 3X-UI
├── scripts/
│   ├── backup.sh                # Автоматический backup базы данных
│   ├── restore.sh               # Восстановление из backup
│   └── migrate-node.sh          # Миграция между нодами
└── config/
    └── values.yaml              # Конфигурационные параметры
```

---

## 🔧 Управление

### Просмотр логов

```bash
kubectl logs -n xui-vpn xui-panel-0 -f
```

### Backup базы данных

```bash
./scripts/backup.sh
```

### Восстановление из backup

```bash
./scripts/restore.sh <backup-file>
```

### Удаление

```bash
./uninstall.sh
```

---

## 🌐 Доступ к панели

```
URL: http://<node-ip>:2053
Логин: admin
Пароль: admin
```

⚠️ **Сразу после установки смените пароль!**

---

## 🏗️ Архитектура

### Компоненты

1. **StorageClass** (`local-storage`)
   - `volumeBindingMode: WaitForFirstConsumer`
   - Откладывает binding до момента создания Pod

2. **PersistentVolume** (`xui-local-pv`)
   - Capacity: 10Gi
   - Path: `/opt/xui-vpn/data`
   - `nodeAffinity` для привязки к ноде

3. **PersistentVolumeClaim** (`xui-data-pvc`)
   - Запрашивает 10Gi
   - Связывается с PV через StorageClass

4. **StatefulSet** (`xui-panel`)
   - 1 реплика
   - `hostNetwork: true`
   - `updateStrategy: OnDelete`
   - Монтирует PVC в `/etc/x-ui`

### Почему WaitForFirstConsumer?

- PVC не связывается с PV до создания Pod
- Kubernetes Scheduler учитывает `nodeAffinity` PV
- Pod создается **только** на ноде, где доступен Local PV
- Исключает ситуацию "Pod на node-2, но PV на node-1"

---

## 🔄 Lifecycle Management

### Обновление StatefulSet

```bash
# 1. Изменить манифест
vim manifests/statefulset.yaml

# 2. Применить изменения
kubectl apply -f manifests/statefulset.yaml

# 3. Вручную удалить Pod (OnDelete strategy)
kubectl delete pod xui-panel-0 -n xui-vpn

# 4. StatefulSet автоматически пересоздаст Pod
kubectl get pod -n xui-vpn -w
```

### Миграция на другую ноду

```bash
./scripts/migrate-node.sh node-1 node-2
```

Скрипт автоматически:
1. Создает backup данных
2. Меняет `nodeSelector` в StatefulSet
3. Удаляет старый Pod
4. Переносит данные на новую ноду
5. Ждет создания нового Pod
6. Восстанавливает данные

---

## 🛡️ Best Practices

### Безопасность

- [ ] Сменить дефолтный пароль `admin/admin`
- [ ] Настроить IP whitelist через IngressRoute middleware
- [ ] Использовать TLS для web-панели
- [ ] Регулярные backup базы данных

### Мониторинг

```bash
# Статус PV
kubectl get pv

# Статус PVC
kubectl get pvc -n xui-vpn

# Детали PV (nodeAffinity, capacity, status)
kubectl describe pv xui-local-pv

# Логи панели
kubectl logs -n xui-vpn xui-panel-0 -f
```

### Backup Strategy

```bash
# Автоматический backup каждый день в 3:00
kubectl apply -f manifests/cronjob-backup.yaml

# Или вручную
./scripts/backup.sh
```

---

## 🐛 Troubleshooting

### Pod в статусе Pending

```bash
kubectl describe pod xui-panel-0 -n xui-vpn
```

**Возможные причины:**
- PV не привязан к PVC (проверить `nodeAffinity`)
- Нода недоступна или не соответствует селектору
- Недостаточно ресурсов на ноде

### PVC не связывается с PV

```bash
kubectl get pvc -n xui-vpn
kubectl describe pvc xui-data-pvc -n xui-vpn
```

**Решение:**
- Проверить `storageClassName` в PV и PVC
- Проверить `capacity` (PVC не может запрашивать больше, чем есть в PV)
- Убедиться, что `volumeBindingMode: WaitForFirstConsumer`

### База данных потеряна после рестарта

```bash
# Проверить, смонтирован ли volume
kubectl exec -n xui-vpn xui-panel-0 -- df -h | grep x-ui

# Проверить данные на хосте
ssh root@<node-ip> ls -la /opt/xui-vpn/data
```

**Решение:**
- Восстановить из backup: `./scripts/restore.sh <backup-file>`

---

## 📚 Ссылки

- [3X-UI GitHub](https://github.com/MHSanaei/3x-ui)
- [Kubernetes Local Persistent Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)
- [StatefulSet Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

---

## 📄 Лицензия

MIT License - свободно используйте для личных и коммерческих проектов.

---

## 🤝 Автор

Создано на основе production опыта развертывания VPN инфраструктуры в Kubernetes.

**Вопросы и предложения** — открывайте Issues или Pull Requests!
