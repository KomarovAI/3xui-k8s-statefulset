# Быстрый старт (production-ready Kustomize overlay)

1. **Проверь параметры кластера:**
   - Получи node name:
     ```bash
     kubectl get nodes
     # Например: node-1
     ```
   - Определи реальный публичный IP сервера (например: 31.56.39.58)

2. **Прими все manifests, используя шаблонизацию через Kustomize:**

```bash
kubectl kustomize overlays/prod > prod-all.yaml
kubectl apply -f prod-all.yaml
```

3. Перед деплоем обязательно:
   - Измени значения в `overlays/prod/kustomization.yaml`:
      - `NODE_NAME` (имя твоего worker/master)
      - `SERVER_IP` (твой внешний IP для nip.io, Let's Encrypt, etc)
   - Создай на worker/master директорию `/opt/xui-vpn/data` с нужными правами:
     ```bash
     mkdir -p /opt/xui-vpn/data; chown 1000:1000 /opt/xui-vpn/data
     ```

4. Применяй все остальные инструкции из README.md (секреты, Traefik, PAT и т.д.)

---

## Production-шаблонизация переменных cluster

Смотри: `overlays/prod/kustomization.yaml` -
```
configMapGenerator:
  - name: production-values
    literals:
      - NODE_NAME=node-1
      - SERVER_IP=31.56.39.58
replacements:
  - ... (см. пример)
```

> Все значения задаются в одном месте и автоматически подставляются во все манифесты без ручного поиска yaml!

---

## Важно
- Никогда не коммить реальные секреты.
- Не забывай обновлять значения переменных при смене сервера или мастера.

