#!/bin/sh
# ═══════════════════════════════════════════════════════════════════════════
# 🚀 ENTRYPOINT SCRIPT FOR 3X-UI CONTAINER
# ═══════════════════════════════════════════════════════════════════════════
# Проверяет окружение и запускает 3X-UI
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Configuration
DATA_DIR=${XUI_DATA_DIR:-/etc/x-ui}
PORT=${XUI_PORT:-2053}
LOG_LEVEL=${XUI_LOG_LEVEL:-info}

echo "═══════════════════════════════════════════════════════════════════════════"
echo "🚀 Starting 3X-UI VPN Panel for Kubernetes"
echo "═══════════════════════════════════════════════════════════════════════════"

# Pre-flight checks
echo "🔍 Pre-flight checks..."

# Check data directory exists
if [ ! -d "$DATA_DIR" ]; then
  echo "❌ ERROR: Data directory $DATA_DIR not found"
  exit 1
fi

# Check data directory is writable
if [ ! -w "$DATA_DIR" ]; then
  echo "❌ ERROR: Data directory $DATA_DIR is not writable"
  exit 1
fi

# Display configuration
echo "⚙️  Configuration:"
echo "   • Pod Name: ${POD_NAME:-unknown}"
echo "   • Namespace: ${POD_NAMESPACE:-unknown}"
echo "   • Data Directory: $DATA_DIR"
echo "   • Port: $PORT"
echo "   • Log Level: $LOG_LEVEL"
echo "   • User: $(id -u):$(id -g)"
echo ""

# Check if running as non-root
if [ $(id -u) -eq 0 ]; then
  echo "⚠️  WARNING: Running as root is not recommended!"
else
  echo "✅ Running as non-root user (UID: $(id -u))"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "✅ All pre-flight checks passed"
echo "🚀 Launching 3X-UI on port $PORT..."
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# Start 3X-UI (replace with actual command from base image)
exec x-ui "$@"
