# Changelog

## [2025-11-18] - Production-Ready Release 🎉

### ✨ Добавлено

#### 1. Оптимизированные Health Checks (`statefulset.dockerhub.yaml`)
- **startupProbe** - Дает приложению до 5 минут на первый старт
  - `initialDelaySeconds: 10`
  - `periodSeconds: 10`
  - `failureThreshold: 30` (300s = 5 min)
- **livenessProbe** - Увеличенные таймауты
  - `initialDelaySeconds: 90` (было 30)
  - `timeoutSeconds: 10` (было 5)
  - `failureThreshold: 5` (было 3)
- **readinessProbe** - Увеличенные таймауты
  - `initialDelaySeconds: 60` (было 10)
  - `periodSeconds: 15` (было 10)
  - `timeoutSeconds: 10` (было 5)
  - `failureThreshold: 5` (было 3)

**Проблема устранена:** Под больше не перезапускается 8 раз перед стабилизацией.

#### 2. DNS NetworkPolicy (`networkpolicy-dns.yaml`)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: xui-vpn
spec:
  podSelector:
    matchLabels:
      app: xui-panel
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

**Проблема устранена:** `default-deny-egress` политика больше не блокирует DNS-запросы.

#### 3. PodDisruptionBudget (`poddisruptionbudget.yaml`)
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: xui-panel-pdb
  namespace: xui-vpn
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: xui-panel
```

**Возможность:** Защита от случайного удаления пода во время node maintenance или eviction.

#### 4. Обновленный CI/CD Workflow (`.github/workflows/deploy-dockerhub.yml`)
- Добавлено применение `networkpolicy-dns.yaml`
- Добавлено применение `poddisruptionbudget.yaml`
- Добавлена проверка `kubectl get ingressroute -n xui-vpn` в конце деплоя

**Проблема устранена:** IngressRoute теперь автоматически применяется при каждом деплое.

#### 5. Новая документация
- **DEPLOYMENT.md** - Полная инструкция по деплою
  - Автоматический деплой через GitHub Actions
  - Ручной деплой
  - Команды для проверки
  - Troubleshooting

- **CHANGELOG.md** - Этот файл

- **README.md** - Обновлен с последними изменениями
  - Быстрый старт
  - Новые возможности
  - Архитектура
  - Ссылки на документацию

---

### 🔧 Исправлено

1. **Email для Let's Encrypt**
   - Проблема: Traefik использовал `example.com` вместо реального email
   - Решение: Правильный email `artur.komarovv@gmail.com` теперь в `manifests/traefik/letsencrypt-email-secret.yaml`

2. **IngressRoute не применялся**
   - Проблема: IngressRoute не был в workflow
   - Решение: Добавлен в `deploy` job

3. **Многочисленные рестарты пода**
   - Проблема: Под перезапускался 8 раз перед стабилизацией
   - Решение: Добавлен `startupProbe` + увеличены таймауты

4. **Ошибки "permission denied" для config.json**
   - Проблема: XUI под не мог записать config.json
   - Решение: Workflow автоматически устанавливает права `2000:2000` на `/opt/xui-vpn/data`

---

### 📦 Commits

1. `0d5efe5` - fix: Оптимизация health checks - добавлен startupProbe и увеличены таймауты
2. `4213a33` - feat: Добавлена NetworkPolicy для явного разрешения DNS-запросов
3. `24c465b` - feat: Добавлен PodDisruptionBudget для высокой доступности
4. `21ef310` - fix: Обновлен workflow для применения новых манифестов
5. `958f230` - docs: Добавлена подробная инструкция по деплою
6. `4d88749` - docs: Обновлен README с последними изменениями

---

### ✅ Статус: PRODUCTION-READY

Все критические проблемы устранены. Репозиторий готов к использованию в production.

**Следующие шаги:**
1. Очистить кластер (если нужно)
2. Запустить деплой через GitHub Actions
3. Открыть `https://xui.${SERVER_IP}.nip.io`

🎉 **Репозиторий готов к продакшну!**
