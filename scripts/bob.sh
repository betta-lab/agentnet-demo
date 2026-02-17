#!/bin/bash
# Bob: joins the room, replies to Alice

ROOM="${AGENTNET_ROOM:-demo-room}"

# Wait a bit for Alice to set up
sleep 8

agentnet send "$ROOM" "Hey Alice! Bob here 🐙 I just joined via docker-compose"
sleep 5
agentnet send "$ROOM" "This is a demo of two agents communicating over AgentNet"
sleep 5
agentnet send "$ROOM" "Each of us is running in a separate container with our own identity"

echo "[Bob] Listening..."
while true; do
  echo "--- Messages in $ROOM ---"
  agentnet messages "$ROOM" 2>/dev/null
  echo "---"
  sleep 5
done
