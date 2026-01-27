# Multi-Application Docker Deployment Infrastructure

Complete production-ready Docker infrastructure for hosting multiple applications on Ubuntu DigitalOcean with automatic SSL, monitoring, and backups.

## 🚀 Features

- **Reverse Proxy**: Traefik v2 with automatic service discovery (alternative: Nginx Proxy Manager)
- **SSL Certificates**: Automatic Let's Encrypt SSL with auto-renewal
- **CI/CD Pipeline**: Jenkins with GitHub webhooks for automated deployments
- **Container Management**: Portainer web interface
- **Monitoring Stack**: Prometheus + Grafana + Loki for metrics and logs
- **Automated Backups**: Hourly database backups + daily full backups to DigitalOcean Spaces
- **Security**: Rate limiting, DDoS protection, security headers, fail2ban
- **Example Applications**: WordPress, Node.js API, Python Flask, React SPA, PHP Laravel

## 📋 Table of Contents

- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [DNS Configuration](#dns-configuration)
- [Deployment](#deployment)
- [CI/CD with Jenkins](#cicd-with-jenkins)
- [Applications](#applications)
- [Monitoring](#monitoring)
- [Backups](#backups)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture

```
Internet
   ↓
Traefik (Port 80/443) ← SSL Certificates (Let's Encrypt)
   ↓
   ├─→ Portainer        (portainer.domain.com)
   ├─→ Jenkins          (jenkins.domain.com) ← GitHub Webhooks
   ├─→ Grafana          (grafana.domain.com)
   ├─→ Prometheus       (prometheus.domain.com)
   ├─→ WordPress        (blog.domain.com)
   ├─→ Node.js API      (api.domain.com)
   ├─→ Flask API        (app.domain.com)
   ├─→ React SPA        (www.domain.com)
   └─→ Laravel App      (shop.domain.com)
```

## 🎯 Quick Start

### Prerequisites

- Ubuntu 20.04+ DigitalOcean Droplet (minimum 2GB RAM recommended)
- Domain name with DNS access
- DigitalOcean Spaces (optional, for backups)

### 1. Server Setup

SSH into your server and run:

```bash
# Clone repository
git clone https://github.com/yourusername/appdeployment.git
cd appdeployment

# Make scripts executable
chmod +x scripts/*.sh

# Run server setup (installs Docker, configures firewall, etc.)
sudo ./scripts/setup-server.sh
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your settings
nano .env
```

**Required Settings:**
- `DOMAIN` - Your domain name
- `SSL_EMAIL` - Email for Let's Encrypt
- `TRAEFIK_AUTH` - Generate with: `htpasswd -nb admin yourpassword`

**Optional (for backups):**
- `DO_SPACES_KEY`, `DO_SPACES_SECRET`, `DO_SPACES_BUCKET`

### 3. Deploy Infrastructure

```bash
# Deploy Traefik, Portainer, and Monitoring
./scripts/deploy.sh --infrastructure
```

### 4. Deploy Applications

```bash
# Deploy all applications
./scripts/deploy.sh --all

# Or deploy individually
./scripts/deploy.sh --app wordpress
./scripts/deploy.sh --app nodejs-express-api
```

### 5. Setup Automated Backups

```bash
sudo ./scripts/setup-cron.sh
```

## 🌐 DNS Configuration

Configure these DNS A records pointing to your server IP:

| Subdomain | Purpose |
|-----------|---------|
| `traefik.domain.com` | Traefik Dashboard |
| `portainer.domain.com` | Container Management |
| `jenkins.domain.com` | CI/CD Pipeline |
| `grafana.domain.com` | Monitoring Dashboard |
| `prometheus.domain.com` | Metrics Database |
| `alerts.domain.com` | Alert Manager |
| `blog.domain.com` | WordPress Blog |
| `api.domain.com` | Node.js API |
| `app.domain.com` | Flask API |
| `www.domain.com` | React SPA |
| `shop.domain.com` | Laravel App |

**DNS Propagation:** Wait 5-60 minutes for DNS to propagate before accessing services.

## 📦 Deployment

### Infrastructure Services

```bash
# Deploy everything
./scripts/deploy.sh --all

# Infrastructure only
./scripts/deploy.sh --infrastructure

# Individual components
./scripts/deploy.sh --traefik
./scripts/deploy.sh --portainer
./scripts/deploy.sh --jenkins
./scripts/deploy.sh --monitoring
```

### Applications

**Applications are now deployed via Jenkins CI/CD pipelines.**

- Access Jenkins: `https://jenkins.${DOMAIN}`
- react-spa is pre-configured as example
- Add other apps via Jenkins UI
- See: [docs/JENKINS-UI-SETUP-GUIDE.md](docs/JENKINS-UI-SETUP-GUIDE.md)

## 🔧 Applications

### WordPress Blog
- **URL:** `https://blog.${DOMAIN}`
- **Database:** MariaDB
- **Location:** `apps/wordpress/`

### Node.js Express API
- **URL:** `https://api.${DOMAIN}`
- **Database:** PostgreSQL
- **Health:** `/health`
- **Metrics:** `/metrics`
- **Location:** `apps/nodejs-express-api/`

### Python Flask API
- **URL:** `https://app.${DOMAIN}`
- **Cache:** Redis
- **Health:** `/health`
- **Metrics:** `/metrics`
- **Location:** `apps/flask-api/`

### React SPA
- **URL:** `https://www.${DOMAIN}`
- **Server:** Nginx
- **Health:** `/health`
- **Location:** `apps/react-spa/`

### PHP Laravel
- **URL:** `https://shop.${DOMAIN}`
- **Database:** MySQL
- **Health:** `/health`
- **Location:** `apps/php-laravel/`

## 🚀 CI/CD with Jenkins

### Overview

Jenkins provides automated CI/CD pipelines for deploying applications from separate GitHub repositories with webhook integration.

**Access:** `https://jenkins.${DOMAIN}`

### Quick Setup

```bash
# Deploy Jenkins
./scripts/deploy.sh --jenkins

# Run initial setup
./scripts/setup-jenkins.sh
```

### Features

- ✅ **Automated Deployments** - Push to GitHub triggers automatic builds
- ✅ **Docker Integration** - Build and deploy Docker images
- ✅ **Automatic Subdomain Routing** - Traefik automatically routes to deployed apps
- ✅ **GitHub Webhooks** - Automatic trigger on git push
- ✅ **SSH Deployment** - Secure deployment to your server
- ✅ **Health Checks** - Automatic verification after deployment
- ✅ **Scalable** - Easy to add new applications via Jenkins UI

### Application Repositories

Applications are maintained in separate repositories for better separation of concerns:

1. **react-spa** - https://github.com/willypelz/react-spa.git **(pre-configured)**
2. **wordpress-docker-app** - https://github.com/willypelz/wordpress-docker-app.git
3. **nodejs-express-api** - https://github.com/willypelz/nodejs-express-api.git
4. **php-laravel** - https://github.com/willypelz/php-laravel.git
5. **flask-api** - https://github.com/willypelz/flask-api.git

### Setup Steps

1. **react-spa is pre-configured** - Use as reference example
2. **Add additional apps via Jenkins UI** - See detailed UI guide below
3. **Configure credentials** (deployment-server-host and deployment-ssh-key)
4. **Set up GitHub webhooks** (Webhook URL: `https://jenkins.${DOMAIN}/github-webhook/`)
5. **Each repo needs Jenkinsfile** (examples in `infrastructure/jenkins/jenkinsfiles/`)

### Documentation

- **UI Setup Guide:** [docs/JENKINS-UI-SETUP-GUIDE.md](docs/JENKINS-UI-SETUP-GUIDE.md) ← **Start here for adding apps**
- **Subdomain Routing:** [docs/SUBDOMAIN-ROUTING-GUIDE.md](docs/SUBDOMAIN-ROUTING-GUIDE.md)
- **App Repository Setup:** [docs/APP-REPOSITORY-SETUP.md](docs/APP-REPOSITORY-SETUP.md)
- **Deployment Workflow:** [docs/DEPLOYMENT-WORKFLOW.md](docs/DEPLOYMENT-WORKFLOW.md)
- **Jenkins README:** [infrastructure/jenkins/README.md](infrastructure/jenkins/README.md)

## 📊 Monitoring

Access monitoring dashboards:

- **Grafana:** `https://grafana.${DOMAIN}`
  - Pre-configured dashboards for Docker, Traefik, system metrics
  - Log aggregation with Loki
  
- **Prometheus:** `https://prometheus.${DOMAIN}`
  - 30-day metric retention
  - Service discovery for all containers
  
- **Alertmanager:** `https://alerts.${DOMAIN}`
  - Email notifications for critical alerts
  - Pre-configured alert rules

### Key Metrics

- Container CPU/Memory usage
- Application response times
- HTTP request rates
- SSL certificate expiration
- Disk space usage

## 💾 Backups

### Automated Backups

After running `./scripts/setup-cron.sh`:

- **Hourly:** Database backups (7-day retention)
- **Daily:** Full volume backups (30-day retention)

### Manual Backup

```bash
# Backup databases
./scripts/backup-databases.sh

# Full system backup
./scripts/backup-full.sh
```

### Restore

```bash
# List available backups
./scripts/restore.sh --list

# Restore full backup
./scripts/restore.sh --full backups/full/full-backup-YYYYMMDD-HHMMSS.tar.gz

# Restore specific database
./scripts/restore.sh --db backups/databases/wordpress-db-YYYYMMDD-HHMMSS.sql.gz
```

## 🔒 Security

### Features

- **Firewall:** UFW configured (ports 22, 80, 443)
- **fail2ban:** SSH brute force protection
- **Rate Limiting:** 100 req/min global, 20 req/min for admin panels
- **SSL:** Automatic HTTPS with HSTS
- **Security Headers:** XSS protection, frame denial, content type sniffing prevention
- **Container Isolation:** Separate networks for each application

### Access Control

Traefik dashboard and Prometheus are protected with basic auth. Update credentials:

```bash
# Generate new password
htpasswd -nb admin your-new-password

# Update TRAEFIK_AUTH in .env file
```

### IP Whitelisting (Optional)

In `.env`, uncomment and set:
```
ADMIN_IP_WHITELIST=1.2.3.4/32,5.6.7.8/32
```

## 🔄 Alternative: Nginx Proxy Manager

Prefer a GUI? Switch to Nginx Proxy Manager:

```bash
./scripts/switch-to-npm.sh
```

See `alternative-configs/nginx-proxy-manager/README.md` for details.

## 🐛 Troubleshooting

### SSL Certificate Issues

```bash
# Check Traefik logs
docker logs traefik

# Verify DNS
dig traefik.yourdomain.com

# Use staging for testing
# Set TRAEFIK_SSL_PRODUCTION=false in .env
```

### Application Won't Start

```bash
# Check container status
docker ps -a

# View logs
./scripts/deploy.sh --logs app-name

# Check health
docker inspect container-name | grep -A 10 Health
```

### Database Connection Errors

```bash
# Verify database container is running
docker ps | grep db

# Check database logs
docker logs wordpress-db

# Test connection
docker exec -it wordpress-db mysql -u root -p
```

### Out of Disk Space

```bash
# Clean up unused Docker resources
docker system prune -a

# Check disk usage
df -h
du -sh /var/lib/docker/*

# Clean old logs
./scripts/cleanup-logs.sh
```

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Monitoring Setup](docs/MONITORING.md)
- [Backup & Restore](docs/BACKUP-RESTORE.md)
- [Security Guide](docs/SECURITY.md)
- [Nginx Proxy Manager](alternative-configs/nginx-proxy-manager/README.md)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📝 License

MIT License - feel free to use for personal and commercial projects.

## 🙏 Acknowledgments

- [Traefik](https://traefik.io/)
- [Portainer](https://www.portainer.io/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
