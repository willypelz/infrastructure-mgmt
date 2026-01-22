# Deployment Guide

Complete guide for deploying the multi-application infrastructure.

## Prerequisites

- Ubuntu 20.04+ server
- Minimum 2GB RAM (4GB recommended for monitoring stack)
- Domain name with DNS access
- SSH access to server

## Step-by-Step Deployment

### 1. Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repository
git clone https://github.com/yourusername/appdeployment.git /opt/appdeployment
cd /opt/appdeployment

# Run setup script
sudo ./scripts/setup-server.sh
```

The setup script will:
- Install Docker and Docker Compose
- Configure UFW firewall (ports 22, 80, 443)
- Install fail2ban for SSH protection
- Create swap space (if needed)
- Install AWS CLI for backups

### 2. Configure DNS

Before deploying, configure DNS A records for all subdomains pointing to your server's IP address:

```
traefik.yourdomain.com    → YOUR_SERVER_IP
portainer.yourdomain.com  → YOUR_SERVER_IP
grafana.yourdomain.com    → YOUR_SERVER_IP
prometheus.yourdomain.com → YOUR_SERVER_IP
alerts.yourdomain.com     → YOUR_SERVER_IP
blog.yourdomain.com       → YOUR_SERVER_IP
api.yourdomain.com        → YOUR_SERVER_IP
app.yourdomain.com        → YOUR_SERVER_IP
www.yourdomain.com        → YOUR_SERVER_IP
shop.yourdomain.com       → YOUR_SERVER_IP
```

**Verify DNS propagation:**
```bash
dig traefik.yourdomain.com
```

### 3. Configure Environment

```bash
cd /opt/appdeployment
cp .env.example .env
nano .env
```

**Essential Configuration:**

```bash
# Domain
DOMAIN=yourdomain.com
SSL_EMAIL=admin@yourdomain.com

# Generate Traefik auth (replace admin:yourpassword)
# Run: htpasswd -nb admin yourpassword
TRAEFIK_AUTH=admin:$apr1$...

# SSL Production (false for testing, true for production)
TRAEFIK_SSL_PRODUCTION=false

# Database passwords (change all of these!)
WORDPRESS_DB_PASSWORD=strong_password_here
WORDPRESS_DB_ROOT_PASSWORD=strong_root_password
POSTGRES_PASSWORD=strong_pg_password
LARAVEL_DB_PASSWORD=strong_laravel_password
REDIS_PASSWORD=strong_redis_password

# Grafana
GRAFANA_ADMIN_PASSWORD=strong_grafana_password

# DigitalOcean Spaces (for backups)
DO_SPACES_KEY=your_spaces_key
DO_SPACES_SECRET=your_spaces_secret
DO_SPACES_BUCKET=your-backup-bucket
DO_SPACES_REGION=nyc3
```

### 4. Deploy Infrastructure

```bash
# Deploy Traefik reverse proxy
./scripts/deploy.sh --infrastructure
```

This deploys:
- Traefik (reverse proxy + SSL)
- Portainer (container management)
- Prometheus, Grafana, Loki (monitoring)

**Verify deployment:**
```bash
docker ps
docker network ls | grep web
```

### 5. Access Management Interfaces

Wait 2-3 minutes for SSL certificates to be issued, then access:

- **Traefik Dashboard:** `https://traefik.yourdomain.com`
  - Login with credentials from TRAEFIK_AUTH
  
- **Portainer:** `https://portainer.yourdomain.com`
  - Create admin account on first access
  
- **Grafana:** `https://grafana.yourdomain.com`
  - Login: admin / GRAFANA_ADMIN_PASSWORD

### 6. Deploy Applications

#### Option A: Deploy All Applications

```bash
./scripts/deploy.sh --all
```

#### Option B: Deploy Individually

```bash
# WordPress blog
./scripts/deploy.sh --app wordpress

# Node.js API
./scripts/deploy.sh --app nodejs-express-api

# Flask API
./scripts/deploy.sh --app flask-api

# React SPA
./scripts/deploy.sh --app react-spa

# Laravel (requires Laravel app in apps/php-laravel/app/)
./scripts/deploy.sh --app php-laravel
```

### 7. Setup Automated Backups

```bash
sudo ./scripts/setup-cron.sh
```

This configures:
- Hourly database backups
- Daily full system backups
- Automatic upload to DigitalOcean Spaces

### 8. Configure Application-Specific Settings

#### WordPress
```bash
# Access setup wizard
open https://blog.yourdomain.com
```

#### Node.js API
```bash
# Test health endpoint
curl https://api.yourdomain.com/health

# View Prometheus metrics
curl https://api.yourdomain.com/metrics
```

#### Laravel
```bash
# Install Laravel (if not done)
cd apps/php-laravel
composer create-project laravel/laravel app

# Run migrations
docker-compose exec laravel-app php artisan migrate
```

## Verification Checklist

After deployment, verify:

- [ ] All containers are running: `docker ps`
- [ ] SSL certificates issued (check Traefik dashboard)
- [ ] All subdomains accessible via HTTPS
- [ ] Traefik dashboard login works
- [ ] Portainer accessible and configured
- [ ] Grafana dashboards display data
- [ ] Application health checks passing
- [ ] Backups configured (check crontab: `crontab -l`)

## Post-Deployment Tasks

### 1. Security Hardening

```bash
# Change all default passwords
# Update TRAEFIK_AUTH, GRAFANA_ADMIN_PASSWORD, etc.

# Enable IP whitelisting for admin panels (optional)
# Edit .env and set ADMIN_IP_WHITELIST
```

### 2. Monitoring Setup

- Import Grafana dashboards (see `infrastructure/monitoring/grafana/dashboards/README.md`)
- Configure Alertmanager email notifications
- Test alert rules

### 3. Backup Testing

```bash
# Test database backup
./scripts/backup-databases.sh

# Test full backup
./scripts/backup-full.sh

# Verify uploads to Spaces
aws s3 ls s3://your-bucket/databases/ --endpoint-url=https://nyc3.digitaloceanspaces.com
```

### 4. Performance Tuning

```bash
# Monitor resource usage
docker stats

# Adjust container limits if needed
# Edit docker-compose.yml files
```

## Updating Applications

### Update Infrastructure

```bash
cd /opt/appdeployment
git pull
docker-compose pull
docker-compose up -d
```

### Update Specific Application

```bash
cd apps/wordpress
docker-compose pull
docker-compose up -d
```

### Rebuild Application

```bash
./scripts/deploy.sh --restart wordpress
```

## Scaling Considerations

### Vertical Scaling (Larger Droplet)

1. Create snapshot of current droplet
2. Resize droplet in DigitalOcean
3. Reboot and verify

### Horizontal Scaling (Multiple Containers)

Edit `docker-compose.yml`:

```yaml
services:
  nodejs-api:
    deploy:
      replicas: 3
```

Traefik will automatically load balance.

## Troubleshooting Deployment

### SSL Certificate Not Issued

```bash
# Check Traefik logs
docker logs traefik

# Common issues:
# - DNS not propagated (wait 15-60 minutes)
# - Port 80/443 blocked by firewall
# - Email already hit Let's Encrypt rate limit

# Use staging first
# Set TRAEFIK_SSL_PRODUCTION=false
```

### Container Won't Start

```bash
# Check logs
docker logs container-name

# Check resource usage
docker stats
free -h
df -h

# Check configuration
docker-compose config
```

### Database Connection Failed

```bash
# Check database container
docker logs wordpress-db

# Verify credentials in .env
# Verify network connectivity
docker network inspect wordpress-internal
```

## Next Steps

- [Monitoring Setup](MONITORING.md)
- [Backup & Restore Procedures](BACKUP-RESTORE.md)
- [Security Best Practices](SECURITY.md)
