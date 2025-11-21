#!/bin/sh
# Минималистичный entrypoint для лёгкого контейнера
set -e
DATA_DIR=${XUI_DATA_DIR:-/etc/x-ui}
PORT=${XUI_PORT:-2053}
[ -d "$DATA_DIR" ] || { echo "ERROR: $DATA_DIR not found"; exit 1; }
[ -w "$DATA_DIR" ] || { echo "ERROR: $DATA_DIR not writable"; exit 1; }
exec /app/x-ui "$@"
