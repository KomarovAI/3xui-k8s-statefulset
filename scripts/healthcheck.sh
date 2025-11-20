#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════════
# 🏥 HEALTHCHECK SCRIPT FOR 3X-UI CONTAINER
# ═══════════════════════════════════════════════════════════════════════════
# Проверяет работоспособность 3X-UI для Kubernetes liveness/readiness probes
# Exit codes: 0 = healthy, 1 = unhealthy
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Configuration
PORT=${XUI_PORT:-2053}
TIMEOUT=5

# Check if process is running
if ! pgrep -f "x-ui" > /dev/null 2>&1; then
  echo "❌ ERROR: 3X-UI process not running"
  exit 1
fi

# Check HTTP endpoint
if ! wget --spider --quiet --timeout=$TIMEOUT http://localhost:$PORT/ 2>/dev/null; then
  echo "❌ ERROR: HTTP endpoint not responding on port $PORT"
  exit 1
fi

# Check data directory
if [ ! -d "${XUI_DATA_DIR:-/etc/x-ui}" ]; then
  echo "❌ ERROR: Data directory not found"
  exit 1
fi

# All checks passed
echo "✅ OK: 3X-UI is healthy (port $PORT)"
exit 0
