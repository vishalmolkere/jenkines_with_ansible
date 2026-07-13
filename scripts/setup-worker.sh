#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-worker.sh
# Run this script ONCE on the Worker EC2 instance (Ubuntu 22.04 / 24.04).
#
# What it installs:
#   • Docker CE (to run application containers)
#
# Usage:
#   chmod +x setup-worker.sh && sudo ./setup-worker.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "============================================================"
echo "  Worker Server Setup — Docker Only"
echo "============================================================"

# ── Update system ─────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y

# ── Install Docker ─────────────────────────────────────────────────────────────
echo "--- Installing Docker ---"
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

# Allow ubuntu user to run docker without sudo
usermod -aG docker ubuntu

docker --version

# ── Open port 8080 in UFW (if active) ─────────────────────────────────────────
if ufw status | grep -q "Status: active"; then
    ufw allow 8080/tcp
    echo "UFW: allowed port 8080"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  ✅  Worker Server setup complete!"
echo "============================================================"
echo "  Docker : $(docker --version)"
echo ""
echo "  ⚠️  IMPORTANT NEXT STEPS:"
echo "  1. Ensure SSH access from Master to Worker using the same PEM key."
echo "  2. Open port 8080 in your EC2 Security Group for the application."
echo "  3. On the Master, test SSH:  ssh -i ~/.ssh/aws-key.pem ubuntu@<WORKER_IP>"
echo "============================================================"
