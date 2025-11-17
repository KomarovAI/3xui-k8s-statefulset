#!/bin/bash
# Миграция StatefulSet на новую ноду
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <from_node> <to_node>"
  exit 1
fi
FROM_NODE="$1"
TO_NODE="$2"
POD=xui-panel-0
NAMESPACE=xui-vpn
BACKUP_FILE=tmp-xui-backup.tgz

# 1. Backup
kubectl exec -n "$NAMESPACE" "$POD" -- tar -czf /tmp/xui-backup.tar.gz -C /etc/x-ui .
kubectl cp "$NAMESPACE/$POD:/tmp/xui-backup.tar.gz" "$BACKUP_FILE"

# 2. Patch StatefulSet nodeSelector
kubectl patch statefulset xui-panel -n "$NAMESPACE" -p "{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"$TO_NODE\"}}}}}"

# 3. Delete pod
kubectl delete pod "$POD" -n "$NAMESPACE"
echo "Waiting for pod to recreate..."
kubectl wait --for=condition=Ready pod/$POD -n "$NAMESPACE" --timeout=120s

# 4. Restore
NODE_IP=$(kubectl get node "$TO_NODE" -o jsonpath='{.status.addresses[0].address}')
scp "$BACKUP_FILE" root@$NODE_IP:/opt/xui-vpn/
ssh root@$NODE_IP 'tar -xzf /opt/xui-vpn/tmp-xui-backup.tgz -C /opt/xui-vpn/data/'
echo "Migration completed."
