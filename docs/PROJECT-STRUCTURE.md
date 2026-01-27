# Project Structure

Complete overview of the application deployment infrastructure.

## Directory Structure

```
appdeployment/
├── .env.example                           # Environment configuration template
├── .gitignore                             # Git ignore rules
├── docker-compose.yml                     # Traefik reverse proxy
├── README.md                              # Main documentation
│
├── alternative-configs/                   # Alternative proxy configurations
│   └── nginx-proxy-manager/
│       ├── docker-compose.yml            # NPM setup
│       └── README.md                     # NPM documentation
│
├── docs/                                 # Documentation
│   ├── DEPLOYMENT.md                     # Deployment guide
│   ├── BACKUP-RESTORE.md                 # Backup procedures
│   ├── JENKINS-UI-SETUP-GUIDE.md         # Jenkins UI setup (NEW)
│   ├── SUBDOMAIN-ROUTING-GUIDE.md        # Subdomain routing explained (NEW)
│   ├── APP-REPOSITORY-SETUP.md           # App repository structure (NEW)
│   ├── SECURITY.md                       # Security guide
│   ├── MONITORING.md                     # Monitoring setup
│   └── QUICK-REFERENCE.md                # Quick commands
│
├── infrastructure/                       # Infrastructure services
│   ├── jenkins/                          # CI/CD Server
│   │   ├── docker-compose.yml
│   │   ├── jenkins-casc.yaml             # Configuration as Code
│   │   ├── plugins.txt
│   │   ├── README.md
│   │   └── jenkinsfiles/                 # Jenkinsfile templates
│   │       ├── Jenkinsfile.react
│   │       ├── Jenkinsfile.nodejs
│   │       ├── Jenkinsfile.laravel
│   │       ├── Jenkinsfile.flask
│   │       └── Jenkinsfile.wordpress
│   │
│   ├── portainer/
│   │   └── docker-compose.yml            # Container management UI
│   │
│   └── monitoring/
│       ├── docker-compose.yml            # Monitoring stack
│       ├── prometheus.yml                # Prometheus config
│       ├── alerts.yml                    # Alert rules
│       ├── alertmanager.yml              # Alert manager config
│       ├── loki-config.yml               # Loki config
│       ├── promtail-config.yml           # Promtail config
│       └── grafana/
│           ├── provisioning/
│           │   ├── datasources/
│           │   │   └── datasources.yml
│           │   └── dashboards/
│           │       └── dashboards.yml
│           └── dashboards/
│               └── README.md             # Dashboard import guide
│
├── scripts/                              # Automation scripts
│   ├── setup-server.sh                   # Initial server setup
│   ├── deploy.sh                         # Application deployment
│   ├── backup-databases.sh               # Hourly DB backups
│   ├── backup-full.sh                    # Daily full backups
│   ├── restore.sh                        # Restore backups
│   ├── setup-cron.sh                     # Configure cron jobs
│   └── switch-to-npm.sh                  # Switch to NPM
│
├── backups/                              # Local backup storage (created)
│   ├── databases/
│   └── full/
│
└── logs/                                 # Application logs (created)
    └── traefik/
```

## File Descriptions

### Root Level

- **`.env.example`** - Template for environment variables (80+ configurations)
- **`.gitignore`** - Excludes sensitive files, logs, and volumes from git
- **`docker-compose.yml`** - Traefik reverse proxy with SSL, rate limiting, security headers
- **`README.md`** - Main project documentation and quick start guide

### Applications (Separate Repositories)

**Applications are now maintained in separate GitHub repositories for better separation of concerns:**

1. **react-spa** - https://github.com/willypelz/react-spa.git
   - React SPA with Nginx
   - Pre-configured in Jenkins ✅
   - Deployed to `www.${DOMAIN}`

2. **wordpress-docker-app** - https://github.com/willypelz/wordpress-docker-app.git
   - WordPress with MariaDB
   - Custom themes/plugins support
   - Deployed to `blog.${DOMAIN}`

3. **nodejs-express-api** - https://github.com/willypelz/nodejs-express-api.git
   - Express API with PostgreSQL
   - Health and metrics endpoints
   - Deployed to `api.${DOMAIN}`

4. **php-laravel** - https://github.com/willypelz/php-laravel.git
   - Laravel with MySQL
   - Migrations support
   - Deployed to `shop.${DOMAIN}`

5. **flask-api** - https://github.com/willypelz/flask-api.git
   - Flask API with Redis
   - Health and metrics endpoints
   - Deployed to `app.${DOMAIN}`

**Each repository contains:**
- `Jenkinsfile` - CI/CD pipeline definition
- `docker-compose.yml` - Services with Traefik labels
- `Dockerfile` - Application image build
- `.env.example` - Environment variable template

**Deployment:**
- Deployed via Jenkins CI/CD pipelines
- Automatic subdomain routing via Traefik
- SSL certificates from Let's Encrypt
- See: [docs/JENKINS-UI-SETUP-GUIDE.md](JENKINS-UI-SETUP-GUIDE.md)

### Infrastructure (`infrastructure/`)

**Portainer:**
- Web UI for Docker management
- Accessible at `portainer.domain.com`

**Monitoring Stack:**
- Prometheus (metrics collection, 30-day retention)
- Grafana (visualization dashboards)
- Loki (log aggregation, 14-day retention)
- Promtail (log shipper)
- Alertmanager (alert routing)
- Node Exporter (system metrics)
- cAdvisor (container metrics)

### Scripts (`scripts/`)

**Setup:**
- `setup-server.sh` - Install Docker, configure firewall, create swap

**Deployment:**
- `deploy.sh` - Universal deployment tool for all services

**Backups:**
- `backup-databases.sh` - MySQL/PostgreSQL dumps
- `backup-full.sh` - Complete volume and config backup
- `restore.sh` - Restore from local or remote backups
- `setup-cron.sh` - Configure automated backup schedule

**Alternative:**
- `switch-to-npm.sh` - Switch from Traefik to Nginx Proxy Manager

### Documentation (`docs/`)

- `DEPLOYMENT.md` - Step-by-step deployment instructions
- `BACKUP-RESTORE.md` - Backup strategies and disaster recovery
- `SECURITY.md` - Security best practices and hardening
- `MONITORING.md` - Monitoring setup and dashboard configuration
- `QUICK-REFERENCE.md` - Common commands and quick fixes

### Alternative Configs (`alternative-configs/`)

- **Nginx Proxy Manager** - GUI-based reverse proxy alternative to Traefik

## Docker Networks

### `web` (External)
- Shared network for all public-facing services
- Traefik connects to this network
- All applications join this network

### Application-Specific Internal Networks
- `wordpress-internal` - WordPress + MariaDB
- `nodejs-internal` - Node.js API + PostgreSQL
- `flask-internal` - Flask + Redis
- `laravel-internal` - Laravel + MySQL
- `monitoring` - Monitoring stack internal communication

## Docker Volumes

### Persistent Data Volumes
- `wordpress-data` - WordPress files
- `wordpress-db-data` - WordPress database
- `nodejs-db-data` - PostgreSQL data
- `flask-redis-data` - Redis cache
- `laravel-storage` - Laravel storage
- `laravel-db-data` - Laravel database
- `portainer-data` - Portainer configuration
- `prometheus-data` - Metrics data
- `grafana-data` - Grafana dashboards and config
- `loki-data` - Log data
- `alertmanager-data` - Alert manager state

### Configuration Volumes
- `letsencrypt/` - SSL certificates (bind mount)
- `logs/` - Application logs (bind mount)

## Environment Variables

See `.env.example` for all available variables:

### Categories
- Domain configuration (10 variables)
- Traefik settings (8 variables)
- Database credentials (15 variables)
- Monitoring config (8 variables)
- Backup settings (10 variables)
- Security options (5 variables)
- Application subdomains (5 variables)

## Port Mappings

### Exposed to Internet (via Traefik)
- Port 80 → HTTP (redirects to 443)
- Port 443 → HTTPS (all applications)

### Internal Only
- 3000 - Grafana, Node.js API
- 5000 - Flask API
- 8080 - Traefik metrics, cAdvisor
- 9000 - Portainer
- 9090 - Prometheus
- 9093 - Alertmanager
- 9100 - Node Exporter
- 9115 - Blackbox Exporter

### Nginx Proxy Manager (Alternative)
- Port 81 - Admin interface (if using NPM)

## Technology Stack

### Reverse Proxy
- Traefik v2.11 (default)
- Nginx Proxy Manager (alternative)

### Containers & Orchestration
- Docker
- Docker Compose v3.8

### Monitoring & Logging
- Prometheus (metrics)
- Grafana (visualization)
- Loki (logs)
- Alertmanager (alerts)

### Databases
- MariaDB (WordPress)
- PostgreSQL (Node.js)
- MySQL (Laravel)
- Redis (Flask)

### Programming Languages
- Node.js 18 (Express API)
- Python 3.11 (Flask API)
- PHP 8.2 (Laravel)
- JavaScript (React)

### Web Servers
- Nginx (React SPA, Laravel)
- Apache (WordPress)
- Gunicorn (Flask)

## Security Features

- Automatic HTTPS with Let's Encrypt
- Rate limiting (100 req/min global, 20 req/min admin)
- Security headers (HSTS, XSS protection, frame denial)
- UFW firewall
- fail2ban for SSH protection
- Basic authentication for admin panels
- Optional IP whitelisting
- Container isolation via networks
- Non-root containers where possible

## Backup Strategy

- **Hourly**: Database backups (7-day retention)
- **Daily**: Full volume backups (30-day retention)
- **Storage**: Local + DigitalOcean Spaces
- **Encryption**: Optional GPG encryption support

## Scalability Considerations

- Each app in separate container (horizontal scaling ready)
- Traefik automatic load balancing
- Separate databases per application
- Volume-based persistence
- Stateless application design

## Next Steps

1. Review [DEPLOYMENT.md](DEPLOYMENT.md) for setup instructions
2. Configure `.env` file with your settings
3. Run `setup-server.sh` on your Ubuntu server
4. Deploy infrastructure and applications
5. Configure monitoring dashboards
6. Set up automated backups

## Contributing

When adding new applications:
1. Create directory in `apps/`
2. Add `docker-compose.yml` with Traefik labels
3. Include health check endpoint
4. Document in README.md
5. Add to deployment script
6. Update DNS records

For questions or improvements, please open an issue or pull request.
