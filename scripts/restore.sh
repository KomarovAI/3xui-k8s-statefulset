#!/bin/bash
set -e
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <backup-file>"
  exit 1
fi
BACKUP_FILE="$1"
DATA_DIR=/opt/xui-vpn/data
tar -xzf "$BACKUP_FILE" -C "$DATA_DIR"
echo "Restore complete."
