#!/bin/bash
set -e
# Путь к данным на хосте
DATA_DIR=/opt/xui-vpn/data
BACKUP_DIR=./backups
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/xui-db-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$DATA_DIR" .
echo "Backup complete: $BACKUP_DIR"
