# Quick Reference Guide
- Keep Docker and applications updated
- Enable IP whitelisting for admin panels
- Use strong passwords
- Document custom changes
- Test restores monthly
- Monitor disk space regularly
- Keep `.env` file secure and backed up
- Always test in staging before production

## 💡 Tips

- [Grafana Docs](https://grafana.com/docs/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Docker Docs](https://docs.docker.com/)
- [Traefik Docs](https://doc.traefik.io/traefik/)

## 🎓 Learning Resources

5. Deploy services: `./scripts/deploy.sh --all`
4. Update DNS
3. Restore from backup: `./scripts/restore.sh --full`
2. Run `./scripts/setup-server.sh`
1. Create new server

### Disaster Recovery

- Docker: `journalctl -u docker`
- Backups: `/var/log/backup-*.log`
- Auth: `/var/log/auth.log`
- System: `/var/log/syslog`
- Traefik: `docker logs traefik`

### Key Log Files

## 📞 Emergency Contacts

```
docker-compose up -d
docker-compose build --no-cache
docker-compose down
cd /opt/appdeployment/apps/nodejs-express-api
```bash

### Rebuild Application

```
docker-compose up -d
docker-compose pull
cd /opt/appdeployment/apps/wordpress
```bash

### Update Application

```
docker-compose up -d
docker-compose pull
docker-compose down
git pull
cd /opt/appdeployment
```bash

### Update Infrastructure

## 🔄 Update Procedures

```
└── logs/                         # Application logs
│   └── full/
│   ├── databases/
├── backups/                      # Local backups
├── scripts/                      # Deployment & backup scripts
│   └── monitoring/
│   ├── portainer/
├── infrastructure/               # Infrastructure services
├── apps/                         # Application directories
├── docker-compose.yml            # Traefik reverse proxy
├── .env                          # Environment configuration
/opt/appdeployment/
```

## 📁 File Locations

```
docker exec -it wordpress-db mysql -u root -p
# Test connection

docker network inspect wordpress-internal
# Verify network

docker logs wordpress-db
docker ps | grep db
# Check database container
```bash

### Database Connection Failed

```
./scripts/cleanup-old-backups.sh
# Clean old backups

find /var/log -name "*.log" -mtime +7 -delete
sudo journalctl --vacuum-time=7d
# Clean logs

docker volume prune
docker system prune -a
# Clean Docker

du -sh /var/lib/docker/*
df -h
# Check usage
```bash

### Out of Disk Space

```
docker-compose up -d
docker-compose down
# Remove and recreate

free -h
df -h
docker stats
# Check resources

docker-compose config
# Check config

docker logs container-name
# Check logs
```bash

### Container Won't Start

```
# Set TRAEFIK_SSL_PRODUCTION=false in .env
# Use staging for testing

docker exec traefik cat /letsencrypt/acme.json | grep -A 5 Main
# Check certificate

dig traefik.yourdomain.com
# Verify DNS

docker logs traefik | grep -i error
# Check Traefik logs
```bash

### SSL Not Working

## 🐛 Troubleshooting

```
rate(traefik_service_requests_total{code=~"5.."}[5m])
# HTTP error rate

rate(traefik_service_requests_total[5m])
# HTTP requests per second

container_memory_usage_bytes / container_spec_memory_limit_bytes * 100
# Container memory usage

rate(container_cpu_usage_seconds_total[5m])
# Container CPU usage
```promql

### Prometheus Queries

## 📊 Monitoring Queries

```
sudo tail -f /var/log/auth.log
# View auth logs

sudo fail2ban-client status sshd
sudo fail2ban-client status
# Check fail2ban

sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp
sudo ufw status
# Update firewall

htpasswd -nb admin yourpassword
# Generate Traefik auth
```bash

## 🔐 Security Commands

```
cat backup.sql | docker exec -i laravel-db mysql -u root -p${LARAVEL_DB_ROOT_PASSWORD} laravel
# Restore

docker exec laravel-db mysqldump -u root -p${LARAVEL_DB_ROOT_PASSWORD} laravel > backup.sql
# Backup

docker exec -it laravel-db mysql -u root -p
# Access MySQL shell
```bash

### Laravel (MySQL)

```
cat backup.sql | docker exec -i nodejs-db psql -U ${POSTGRES_USER} ${POSTGRES_DB}
# Restore

docker exec nodejs-db pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > backup.sql
# Backup

docker exec -it nodejs-db psql -U ${POSTGRES_USER} ${POSTGRES_DB}
# Access psql shell
```bash

### Node.js (PostgreSQL)

```
cat backup.sql | docker exec -i wordpress-db mysql -u root -p${WORDPRESS_DB_ROOT_PASSWORD} wordpress
# Restore

docker exec wordpress-db mysqldump -u root -p${WORDPRESS_DB_ROOT_PASSWORD} wordpress > backup.sql
# Backup

docker exec -it wordpress-db mysql -u root -p
# Access MySQL shell
```bash

### WordPress (MariaDB)

## 🗄️ Database Access

```
curl https://shop.yourdomain.com/health
# Laravel

curl https://www.yourdomain.com/health
# React SPA

curl https://app.yourdomain.com/metrics
curl https://app.yourdomain.com/health
# Flask API

curl https://api.yourdomain.com/metrics
curl https://api.yourdomain.com/health
# Node.js API

curl https://blog.yourdomain.com/wp-admin/install.php
# WordPress
```bash

## 🔧 Application Health Checks

| Laravel | `https://shop.yourdomain.com` | - |
| React SPA | `https://www.yourdomain.com` | - |
| Flask API | `https://app.yourdomain.com` | - |
| Node.js API | `https://api.yourdomain.com` | - |
| WordPress | `https://blog.yourdomain.com` | Set in WP admin |
| Alertmanager | `https://alerts.yourdomain.com` | TRAEFIK_AUTH |
| Prometheus | `https://prometheus.yourdomain.com` | TRAEFIK_AUTH |
| Grafana | `https://grafana.yourdomain.com` | admin / GRAFANA_ADMIN_PASSWORD |
| Portainer | `https://portainer.yourdomain.com` | Set on first access |
| Traefik Dashboard | `https://traefik.yourdomain.com` | TRAEFIK_AUTH |
|---------|-----|-------------|
| Service | URL | Credentials |

Replace `yourdomain.com` with your domain:

## 🌐 Access URLs

```
docker system df
# Docker disk usage

free -h
df -h
htop
# System resources

tail -f /var/log/backup-full.log
tail -f /var/log/backup-databases.log
# Check backup logs

crontab -l
# View cron jobs
```bash

### Monitoring

```
./scripts/restore.sh --full backups/full/full-backup-20240122.tar.gz
# Restore full

./scripts/restore.sh --db backups/databases/wordpress-db-20240122.sql.gz
# Restore database

./scripts/restore.sh --list-remote
# List remote backups

./scripts/restore.sh --list
# List local backups

./scripts/backup-full.sh
# Manual full backup

./scripts/backup-databases.sh
# Manual database backup
```bash

### Backups

```
docker system prune -a
# Clean up

docker stats
# View resource usage

docker exec -it wordpress bash
# Execute command in container

docker restart portainer
# Restart container

docker logs -f wordpress  # follow
docker logs traefik
# View logs

docker ps -a
# View all containers (including stopped)

docker ps
# View all containers
```bash

### Docker Operations

```
./scripts/deploy.sh --list
# List apps

./scripts/deploy.sh --logs react-spa
# View logs

./scripts/deploy.sh --stop flask-api
# Stop app

./scripts/deploy.sh --restart nodejs-express-api
# Restart app

./scripts/deploy.sh --app wordpress
# Deploy specific app

./scripts/deploy.sh --infrastructure
# Deploy infrastructure
```bash

### Deployment

## 📋 Common Commands

```
sudo ./scripts/setup-cron.sh
# Setup backups

./scripts/deploy.sh --all
# Deploy everything

nano .env
cp .env.example .env
sudo ./scripts/setup-server.sh
# Initial setup
```bash

## 🚀 Quick Start Commands

Fast reference for common tasks and commands.

