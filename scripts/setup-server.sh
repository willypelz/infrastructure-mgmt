#!/bin/bash

##############################################################################
# Server Setup Script for Ubuntu DigitalOcean
# This script installs Docker, configures firewall, and sets up the environment
##############################################################################

set -e

echo ""
echo "======================================"
echo "Docker Server Setup Script"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "[1/10] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "[2/10] Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    htop \
    ufw \
    fail2ban \
    unzip

# Install Docker
if ! command -v docker &> /dev/null; then
echo "[3/10] Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
echo "[4/10] Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose already installed"
fi

# Configure UFW Firewall
echo "[5/10] Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

# Configure fail2ban
echo "[6/10] Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Create swap if needed (recommended for 1GB droplets)
echo "[7/10] Checking swap space..."
if [ $(free | grep Swap | awk '{print $2}') -eq 0 ]; then
    echo "Creating 2GB swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
else
    echo "Swap already configured"
fi

# Create application directory
echo "[8/10] Creating application directory..."
mkdir -p /opt/appdeployment
mkdir -p /opt/appdeployment/logs
mkdir -p /opt/appdeployment/backups

# Install AWS CLI for DigitalOcean Spaces (S3-compatible)
echo "[9/10] Installing AWS CLI for backups..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "AWS CLI already installed"
fi

# Enable Docker metrics (optional, for Prometheus)
echo "[10/10] Configuring Docker metrics..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "metrics-addr": "127.0.0.1:9323",
  "experimental": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker

echo ""
echo "======================================"
echo "✓ Server setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Clone your repository to /opt/appdeployment"
echo "2. Copy .env.example to .env and configure"
echo "3. Run: cd /opt/appdeployment && docker-compose up -d"
echo ""
echo "Installed versions:"
docker --version
docker-compose --version
aws --version
echo ""
