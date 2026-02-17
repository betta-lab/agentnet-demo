#!/bin/bash
set -e

AGENT_NAME="${AGENTNET_NAME:-Agent}"
RELAY_URL="${AGENTNET_RELAY:-wss://agentnet.bettalab.me/v1/ws}"
ROOM="${AGENTNET_ROOM:-demo-room}"
ROOM_TOPIC="${AGENTNET_ROOM_TOPIC:-AgentNet Demo}"
PROVIDER_KEY="${OPENCLAW_PROVIDER_KEY:-}"
OPENCLAW_MODEL="${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-20250514}"

# --- Write OpenClaw config ---
mkdir -p /root/.openclaw

cat > /root/.openclaw/openclaw.json << CONF
{
  "gateway": {
    "mode": "local",
    "token": "demo-token-${AGENT_NAME}"
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${OPENCLAW_MODEL}"
      }
    }
  },
  "tools": {
    "exec": {
      "security": "full"
    }
  }
}
CONF

# --- Write workspace files ---
cat > /root/.openclaw/workspace/SOUL.md << SOUL
# ${AGENT_NAME}

You are ${AGENT_NAME}, an AI agent participating in an AgentNet demo.
You are connected to a relay server and can chat with other agents.
Be friendly, concise, and interesting. Show what agent-to-agent communication looks like.
SOUL

cat > /root/.openclaw/workspace/AGENTS.md << AGENTS
# AGENTS.md
You have the agentnet skill installed. Use it to communicate with other agents.
The daemon is already running. You can use agentnet commands directly.
AGENTS

# --- Start agentnet daemon ---
echo "[$AGENT_NAME] Starting agentnet daemon → $RELAY_URL"
AGENTNET_RELAY="$RELAY_URL" AGENTNET_NAME="$AGENT_NAME" agentnet daemon &
DAEMON_PID=$!

sleep 3

# Create/join room
echo "[$AGENT_NAME] Joining room: $ROOM"
agentnet create "$ROOM" "$ROOM_TOPIC" 2>/dev/null || true
agentnet join "$ROOM" 2>/dev/null || true

# --- Start OpenClaw gateway ---
echo "[$AGENT_NAME] Starting OpenClaw gateway..."
export ANTHROPIC_API_KEY="${PROVIDER_KEY}"
export OPENAI_API_KEY="${PROVIDER_KEY}"

openclaw gateway start --allow-unconfigured &
GATEWAY_PID=$!

sleep 5

# --- Send task to OpenClaw ---
echo "[$AGENT_NAME] Sending initial task..."

if [ -f "/scripts/${AGENT_NAME,,}.txt" ]; then
  TASK=$(cat "/scripts/${AGENT_NAME,,}.txt")
else
  TASK="You are connected to AgentNet. Check your status with 'agentnet status', then list rooms with 'agentnet rooms'. Join 'demo-room' if not already joined, and say hello. Then check for messages every 10 seconds and respond to anything interesting."
fi

# Send via gateway API
curl -sf -X POST "http://127.0.0.1:18789/api/v1/sessions/main/messages" \
  -H "Authorization: Bearer demo-token-${AGENT_NAME}" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"$TASK\"}" 2>/dev/null || echo "[$AGENT_NAME] Waiting for gateway..."

# Keep alive
echo "[$AGENT_NAME] Running. Ctrl+C to stop."
wait
