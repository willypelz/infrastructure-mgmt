#!/bin/bash
echo ""
aws --version
docker-compose --version
docker --version
echo "Installed versions:"
echo ""
echo "3. Run: cd /opt/appdeployment && docker-compose up -d"
echo "2. Copy .env.example to .env and configure"
echo "1. Clone your repository to /opt/appdeployment"
echo "Next steps:"
echo ""
echo "======================================"
echo "✓ Server setup complete!"
echo "======================================"
echo ""

systemctl restart docker
EOF
}
  }
    "max-file": "3"
    "max-size": "10m",
  "log-opts": {
  "log-driver": "json-file",
  "experimental": true,
  "metrics-addr": "127.0.0.1:9323",
{
cat > /etc/docker/daemon.json <<EOF
mkdir -p /etc/docker
echo "[10/10] Configuring Docker metrics..."
# Enable Docker metrics (optional, for Prometheus)

fi
    echo "AWS CLI already installed"
else
    rm -rf aws awscliv2.zip
    ./aws/install
    unzip awscliv2.zip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
if ! command -v aws &> /dev/null; then
echo "[9/10] Installing AWS CLI for backups..."
# Install AWS CLI for DigitalOcean Spaces (S3-compatible)

mkdir -p /opt/appdeployment/backups
mkdir -p /opt/appdeployment/logs
mkdir -p /opt/appdeployment
echo "[8/10] Creating application directory..."
# Create application directory

fi
    echo "Swap already configured"
else
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    swapon /swapfile
    mkswap /swapfile
    chmod 600 /swapfile
    fallocate -l 2G /swapfile
    echo "Creating 2GB swap file..."
if [ $(free | grep Swap | awk '{print $2}') -eq 0 ]; then
echo "[7/10] Checking swap space..."
# Create swap if needed (recommended for 1GB droplets)

systemctl start fail2ban
systemctl enable fail2ban
echo "[6/10] Configuring fail2ban..."
# Configure fail2ban

echo "y" | ufw enable
ufw allow 443/tcp
ufw allow 80/tcp
ufw allow ssh
ufw default allow outgoing
ufw default deny incoming
ufw --force enable
echo "[5/10] Configuring firewall..."
# Configure UFW Firewall

fi
    echo "Docker Compose already installed"
else
    chmod +x /usr/local/bin/docker-compose
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
if ! command -v docker-compose &> /dev/null; then
echo "[4/10] Installing Docker Compose..."
# Install Docker Compose

fi
    echo "Docker already installed"
else
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
    sh get-docker.sh
    curl -fsSL https://get.docker.com -o get-docker.sh
if ! command -v docker &> /dev/null; then
echo "[3/10] Installing Docker..."
# Install Docker

    unzip
    fail2ban \
    ufw \
    htop \
    git \
    lsb-release \
    gnupg \
    curl \
    ca-certificates \
    apt-transport-https \
apt-get install -y \
echo "[2/10] Installing required packages..."
# Install required packages

apt-get upgrade -y
apt-get update
echo "[1/10] Updating system packages..."
# Update system

fi
    exit 1
    echo "Please run as root (use sudo)"
if [ "$EUID" -ne 0 ]; then
# Check if running as root

echo ""
echo "======================================"
echo "Docker Server Setup Script"
echo "======================================"

set -e

##############################################################################
# This script installs Docker, configures firewall, and sets up the environment
# Server Setup Script for Ubuntu DigitalOcean
##############################################################################

