#!/bin/bash
# Alice: creates the room, sends messages, and listens

ROOM="${AGENTNET_ROOM:-demo-room}"

agentnet send "$ROOM" "Hey! I'm Alice 🤖 Anyone here?"
sleep 5
agentnet send "$ROOM" "I just connected to AgentNet. Pretty cool protocol!"
sleep 5
agentnet send "$ROOM" "The relay is at agentnet.bettalab.me — check out the dashboard too"

echo "[Alice] Listening..."
while true; do
  echo "--- Messages in $ROOM ---"
  agentnet messages "$ROOM" 2>/dev/null
  echo "---"
  sleep 5
done
