#!/usr/bin/env bash
# start.sh — starts all Khayal AI backend services
# Usage:
#   ./start.sh        → start all services
#   ./start.sh stop   → stop all services
#   ./start.sh status → check which are running

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$BACKEND_DIR/.venv/bin/uvicorn"
LOG_DIR="$BACKEND_DIR/logs"
PID_FILE="$BACKEND_DIR/.pids"

# ── Stop ──────────────────────────────────────────────────────────────────────
if [ "$1" == "stop" ]; then
  if [ -f "$PID_FILE" ]; then
    echo "⏹  Stopping all services..."
    while read -r pid; do
      kill "$pid" 2>/dev/null && echo "  Killed $pid"
    done < "$PID_FILE"
    rm -f "$PID_FILE"
    echo "✅ Done."
  else
    echo "No .pids file found — nothing to stop."
  fi
  exit 0
fi

# ── Status ────────────────────────────────────────────────────────────────────
if [ "$1" == "status" ]; then
  [ ! -f "$PID_FILE" ] && echo "No services running." && exit 0
  while read -r pid; do
    kill -0 "$pid" 2>/dev/null && echo "  PID $pid — ✅ running" || echo "  PID $pid — ❌ dead"
  done < "$PID_FILE"
  exit 0
fi

# ── Start ─────────────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
rm -f "$PID_FILE"

# Format: "dir:port"
SERVICES=(
  "gateway:8000"
  "auth-service:8001"
  "user-service:8002"
  "therapist-service:8003"
  "journal-service:8004"
  "chat-service:8005"
  "community-service:8006"
  "notification-service:8007"
)

echo "🚀 Starting Khayal AI backend..."
echo ""

for ENTRY in "${SERVICES[@]}"; do
  SERVICE="${ENTRY%%:*}"
  PORT="${ENTRY##*:}"
  LOG="$LOG_DIR/$SERVICE.log"
  DIR="$BACKEND_DIR/$SERVICE"

  # Use env -C to change directory without a subshell,
  # then exec uvicorn directly so it IS the process (no wrapper shell in between)
  env -C "$DIR" "$VENV" main:app --host 0.0.0.0 --port "$PORT" \
    > "$LOG" 2>&1 &

  echo "$!" >> "$PID_FILE"
  printf "  ✅ %-26s port %-5s  →  logs/%s.log\n" "$SERVICE" "$PORT" "$SERVICE"
done

echo ""
echo "  Gateway → http://localhost:8000"
echo "  Stop    → ./start.sh stop"
echo "  Logs    → tail -f logs/journal-service.log"
