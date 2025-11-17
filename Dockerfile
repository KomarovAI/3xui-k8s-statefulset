FROM ghcr.io/mhsanaei/3x-ui:v2.5.3

# Security: Using specific version tag instead of 'latest'
# v2.5.3+ fixes CVE-2025-29331 (SSL verification bypass)

LABEL maintainer="KomarovAI"
LABEL version="2.5.3"
LABEL description="3X-UI VPN Panel for Kubernetes with security hardening"

# Custom initialization scripts can be added here
# Example: COPY scripts/init.sh /docker-entrypoint.d/

# Default ENTRYPOINT and CMD inherited from base image
