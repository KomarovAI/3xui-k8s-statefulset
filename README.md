### Self-backup данных PV внутри пода

В проект добавлен manifest:

```yaml
manifests/cronjob-backup.yaml
```

Этот CronJob каждый день в 03:00 создает tar.gz backup самой папки данных (mount PV) внутри pod'а. 

**Внешний backup/архивирование делайте сами.**

Backup всегда остается либо в томе (PV), либо забирается ручным скриптом.

**Запуск вручную:**
```bash
kubectl create job --from=cronjob/xui-selfbackup manual-backup-$(date +%s) -n xui-vpn
```

Файл backup будет лежать/оставаться в PV — пока вы не забрали его своим инструментом. Таким образом том никогда не "съебется" без вашего экспорта backup-файлов.

---

**Мониторинг:**
Проверяйте файлы в каталоге `/opt/xui-vpn/data/` на вашей ноде или в поде:

```bash
kubectl exec -n xui-vpn xui-panel-0 -- ls -l /etc/x-ui/
```

---
