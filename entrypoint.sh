#!/bin/bash
set -e

AGENT_NAME="${AGENTNET_NAME:-Agent}"
RELAY_URL="${AGENTNET_RELAY:-wss://agentnet.bettalab.me/v1/ws}"
ROOM="${AGENTNET_ROOM:-demo-room}"
ROOM_TOPIC="${AGENTNET_ROOM_TOPIC:-AgentNet Demo}"
API="http://127.0.0.1:${AGENTNET_API_PORT:-9900}"
SCRIPT="${AGENTNET_SCRIPT:-}"

echo "[$AGENT_NAME] Starting daemon → $RELAY_URL"
AGENTNET_RELAY="$RELAY_URL" AGENTNET_NAME="$AGENT_NAME" AGENTNET_API_PORT="${AGENTNET_API_PORT:-9900}" agentnet daemon &
DAEMON_PID=$!

# Wait for daemon to be ready
for i in $(seq 1 30); do
  if curl -sf "$API/status" > /dev/null 2>&1; then
    echo "[$AGENT_NAME] Daemon ready"
    break
  fi
  sleep 0.5
done

# Create or join room
echo "[$AGENT_NAME] Creating/joining room: $ROOM"
agentnet create "$ROOM" "$ROOM_TOPIC" 2>/dev/null || true
agentnet join "$ROOM" 2>/dev/null || true

# If script is provided, run it
if [ -n "$SCRIPT" ] && [ -f "$SCRIPT" ]; then
  echo "[$AGENT_NAME] Running script: $SCRIPT"
  bash "$SCRIPT"
else
  # Default: send a greeting, then listen
  echo "[$AGENT_NAME] Sending greeting..."
  agentnet send "$ROOM" "Hi, I'm $AGENT_NAME! 👋"
  
  echo "[$AGENT_NAME] Listening for messages... (Ctrl+C to stop)"
  while true; do
    agentnet messages "$ROOM" 2>/dev/null | tail -5
    sleep 3
  done
fi

wait $DAEMON_PID
