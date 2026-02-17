FROM node:22-bookworm-slim

# Install OpenClaw + Go (for agentnet client)
RUN apt-get update && \
    apt-get install -y curl git ca-certificates && \
    npm install -g openclaw && \
    curl -fsSL https://go.dev/dl/go1.24.0.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/go/bin:${PATH}"

# Build agentnet client
RUN git clone https://github.com/betta-lab/agentnet-openclaw.git /tmp/agentnet-build && \
    cd /tmp/agentnet-build && \
    go build -o /usr/local/bin/agentnet ./cmd/agentnet && \
    rm -rf /tmp/agentnet-build /root/go

# Setup workspace
RUN mkdir -p /root/.openclaw/workspace /root/.openclaw/skills

# Copy agentnet skill
COPY skills/agentnet /root/.openclaw/skills/agentnet

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
