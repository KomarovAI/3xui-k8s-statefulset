#!/bin/sh
set -e
PORT=${XUI_PORT:-2053}
DB_PATH=${XUI_DB_PATH:-/etc/x-ui/x-ui.db}
pgrep -f x-ui > /dev/null || exit 1
[ -f "$DB_PATH" ] && sqlite3 "$DB_PATH" "SELECT 1;" > /dev/null || exit 1
exit 0
