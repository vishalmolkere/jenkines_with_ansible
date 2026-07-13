#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-master.sh
# Run this script ONCE on the Master EC2 instance (Ubuntu 22.04 / 24.04).
#
# What it installs:
#   • Java 21 (Temurin / Eclipse)
#   • Jenkins LTS
#   • Ansible
#   • Docker (for building images)
#   • Python3 & pip (needed by Ansible Docker modules)
#
# Usage:
#   chmod +x setup-master.sh && sudo ./setup-master.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "============================================================"
echo "  Master Server Setup — Jenkins + Ansible + Docker"
echo "============================================================"

# ── Update system ─────────────────────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y

# ── 1. Java 21 (Temurin) ──────────────────────────────────────────────────────
echo "--- Installing Java 21 (Eclipse Temurin) ---"
apt-get install -y wget apt-transport-https gnupg

wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
  | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg

echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] \
  https://packages.adoptium.net/artifactory/deb jammy main" \
  > /etc/apt/sources.list.d/adoptium.list

apt-get update -y
apt-get install -y temurin-21-jdk

java -version

# ── 2. Jenkins LTS ────────────────────────────────────────────────────────────
echo "--- Installing Jenkins LTS ---"
wget -qO /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins
systemctl status jenkins --no-pager

echo ""
echo "👉  Jenkins initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword || true

# ── 3. Ansible ────────────────────────────────────────────────────────────────
echo "--- Installing Ansible ---"
apt-get install -y software-properties-common
add-apt-repository -y ppa:ansible/ansible
apt-get update -y
apt-get install -y ansible

ansible --version

# ── 4. Docker ─────────────────────────────────────────────────────────────────
echo "--- Installing Docker ---"
apt-get install -y ca-certificates curl

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

# Allow jenkins user to run docker without sudo
usermod -aG docker jenkins
usermod -aG docker ubuntu

docker --version

# ── 5. Python & Ansible Docker collection ─────────────────────────────────────
echo "--- Installing Python3, pip, and Ansible Docker collection ---"
apt-get install -y python3 python3-pip
pip3 install docker                         # Python Docker SDK
ansible-galaxy collection install community.docker

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  ✅  Master Server setup complete!"
echo "============================================================"
echo "  Java    : $(java -version 2>&1 | head -1)"
echo "  Jenkins : $(jenkins --version 2>/dev/null || echo 'running (check port 8080)')"
echo "  Ansible : $(ansible --version | head -1)"
echo "  Docker  : $(docker --version)"
echo ""
echo "  ⚠️  IMPORTANT NEXT STEPS:"
echo "  1. Open port 8080 in your EC2 Security Group for Jenkins UI."
echo "  2. Access Jenkins at  http://<MASTER_PUBLIC_IP>:8080"
echo "  3. Use the password above for initial setup."
echo "  4. Restart Jenkins after setup:  systemctl restart jenkins"
echo "============================================================"
