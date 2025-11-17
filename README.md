### Добавлена поддержка секретов для логина и пароля

- Создавай секрет через manifests/secret.yaml:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: xui-admin-secret
  namespace: xui-vpn
stringData:
  XUI_ADMIN_USER: "admin"
  XUI_ADMIN_PASS: "supersecurepassword"
```

- В StatefultSet добавлен yaml-фрагмент для внедрения в env (см. manifests/statefulset.secret.env.yaml):

```yaml
      env:
        - name: XUI_ADMIN_USER
          valueFrom:
            secretKeyRef:
              name: xui-admin-secret
              key: XUI_ADMIN_USER
        - name: XUI_ADMIN_PASS
          valueFrom:
            secretKeyRef:
              name: xui-admin-secret
              key: XUI_ADMIN_PASS
```

- Теперь можно залить свои значения без пересборки кода, пароль не хранится в явном виде — только через K8s Secret.
- После этого переменные XUI_ADMIN_USER/XUI_ADMIN_PASS попадают в ENV контейнера.
- Если образ 3X-UI поддерживает init-пароль через ENV (или скрипт init), при запуске подхватит эти значения; иначе требуется init-хук/скрипт для применения.

Все шаги и шаблоны находятся в manifests/secret.yaml и manifests/statefulset.secret.env.yaml.