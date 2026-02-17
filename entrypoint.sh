#!/bin/bash
set -e

AGENT_NAME="${AGENTNET_NAME:-Agent}"
RELAY_URL="${AGENTNET_RELAY:-wss://agentnet.bettalab.me/v1/ws}"
ROOM="${AGENTNET_ROOM:-demo-room}"
ROOM_TOPIC="${AGENTNET_ROOM_TOPIC:-AgentNet Demo}"
PROVIDER_KEY="${OPENCLAW_PROVIDER_KEY:-}"
OPENCLAW_MODEL="${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-20250514}"
GATEWAY_TOKEN="demo-token-${AGENT_NAME}"

# --- Write OpenClaw config ---
mkdir -p /root/.openclaw

cat > /root/.openclaw/openclaw.json << CONF
{
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "${GATEWAY_TOKEN}"
    }
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

# --- Start OpenClaw gateway directly (no systemctl) ---
echo "[$AGENT_NAME] Starting OpenClaw gateway..."
export ANTHROPIC_API_KEY="${PROVIDER_KEY}"
export OPENAI_API_KEY="${PROVIDER_KEY}"
export OPENCLAW_GATEWAY_TOKEN="${GATEWAY_TOKEN}"

openclaw gateway --allow-unconfigured --bind loopback &
GATEWAY_PID=$!

# Wait for gateway to be ready
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:18789/ > /dev/null 2>&1; then
    echo "[$AGENT_NAME] Gateway ready"
    break
  fi
  sleep 2
done

# --- Send task to OpenClaw via CLI ---
echo "[$AGENT_NAME] Sending task to agent..."

if [ -f "/scripts/${AGENT_NAME,,}.txt" ]; then
  TASK=$(cat "/scripts/${AGENT_NAME,,}.txt")
else
  TASK="You are connected to AgentNet. Run 'agentnet status' to verify, then 'agentnet rooms' to see rooms. Join 'demo-room' and say hello."
fi

openclaw agent -m "$TASK" --session-id main --timeout 300 &
AGENT_RUN_PID=$!

echo "[$AGENT_NAME] Agent running (PID $AGENT_RUN_PID)"

# Keep alive
wait
