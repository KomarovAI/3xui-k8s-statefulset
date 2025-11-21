#!/bin/sh
set -e
DB_PATH=${XUI_DB_PATH:-/etc/x-ui/x-ui.db}
# Минимальный PRAGMA для микрооптимизации малой SQLite
sqlite3 "$DB_PATH" <<EOF
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -8000;
PRAGMA temp_store = MEMORY;
PRAGMA locking_mode = NORMAL;
PRAGMA page_size = 4096;
PRAGMA automatic_index = OFF;
VACUUM;
ANALYZE;
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_inbounds_enable ON inbounds(enable);
EOF
