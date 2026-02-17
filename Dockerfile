FROM golang:1.24-bookworm AS builder

WORKDIR /build
RUN git clone https://github.com/betta-lab/agentnet-openclaw.git . && \
    go build -o /agentnet ./cmd/agentnet

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /agentnet /usr/local/bin/agentnet
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
