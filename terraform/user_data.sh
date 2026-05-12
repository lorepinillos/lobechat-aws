#!/bin/bash
# Cloud-init bootstrap for the LobeChat EC2 instance.
# Stage 1 (this file, iteration 1): just install Docker + Compose + utilities.
# We do NOT yet pull secrets, clone the repo, or start the stack — that is
# added in a subsequent iteration once we confirm the box itself comes up.
set -euxo pipefail

# Variables injected by Terraform (templatefile)
AWS_REGION="${aws_region}"
PUBLIC_HOSTNAME="${public_hostname}"

# Log everything to a known file for debugging via SSH later.
exec > >(tee /var/log/bootstrap.log) 2>&1

echo "=== bootstrap start: $(date -u +%FT%TZ) ==="
echo "region:     $AWS_REGION"
echo "hostname:   $PUBLIC_HOSTNAME"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg jq unzip git make

# Docker install (official Docker apt repo, Ubuntu 24.04 / noble)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu

# AWS CLI v2 (instance role already provides credentials)
cd /tmp
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscli.zip
unzip -q awscli.zip
./aws/install
rm -rf aws awscli.zip
cd /

# Sanity probes — fail loudly here if instance role can't reach Bedrock.
# Secrets Manager is intentionally skipped (CreateSecret denied in sandbox;
# app .env is written to disk by stage 2 instead).
echo "=== caller identity ==="
aws --region "$AWS_REGION" sts get-caller-identity

# Stage 2 placeholder. Replaced in the next Terraform iteration.
echo "=== bootstrap done: $(date -u +%FT%TZ) ==="
echo "Box is up. Docker version: $(docker --version)"
echo "Compose version: $(docker compose version)"
echo "Caddy + LobeChat stack will be installed in iteration 2."
