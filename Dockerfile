FROM node:22-bookworm-slim

ARG TARGETARCH

# Install OpenClaw + dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates git && \
    npm install -g openclaw && \
    rm -rf /var/lib/apt/lists/*

# Copy pre-built agentnet binary (multi-arch)
COPY bin/agentnet-linux-${TARGETARCH} /usr/local/bin/agentnet
RUN chmod +x /usr/local/bin/agentnet

# Setup workspace
RUN mkdir -p /root/.openclaw/workspace /root/.openclaw/skills

# Copy agentnet skill
COPY skills/agentnet /root/.openclaw/skills/agentnet

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
