# Backup and Restore Guide

Comprehensive guide for backing up and restoring your infrastructure and applications.

## Overview

The backup strategy includes:
- **Hourly database backups** (7-day retention)
- **Daily full system backups** (30-day retention)
- **Automated upload to DigitalOcean Spaces**
- **Local backup storage**

## Setup

### 1. Configure DigitalOcean Spaces

Create a Spaces bucket:
1. Go to DigitalOcean → Spaces
2. Create new Space
3. Note the region (e.g., `nyc3`)
4. Generate API keys (Access Key + Secret)

### 2. Update Environment

Edit `.env`:
```bash
DO_SPACES_KEY=your_access_key_here
DO_SPACES_SECRET=your_secret_key_here
DO_SPACES_BUCKET=your-backup-bucket-name
DO_SPACES_REGION=nyc3
DO_SPACES_ENDPOINT=https://nyc3.digitaloceanspaces.com

# Retention periods
BACKUP_RETENTION_DAYS=30
DB_BACKUP_RETENTION_DAYS=7
```

### 3. Install Cron Jobs

```bash
sudo ./scripts/setup-cron.sh
```

Verify:
```bash
crontab -l
```

## Manual Backups

### Database Backup

```bash
./scripts/backup-databases.sh
```

This backs up:
- WordPress MariaDB database
- Node.js PostgreSQL database
- Laravel MySQL database

Output: `backups/databases/[container]-[timestamp].sql.gz`

### Full System Backup

```bash
./scripts/backup-full.sh
```

This backs up:
- All Docker volumes
- Configuration files
- Application code
- Environment files

Output: `backups/full/full-backup-[timestamp].tar.gz`

## Automated Backups

After running `setup-cron.sh`:

### Hourly Database Backups
- **Schedule:** Every hour at :00
- **Retention:** 7 days local, 30 days in Spaces
- **Log:** `/var/log/backup-databases.log`

### Daily Full Backups
- **Schedule:** 2:00 AM UTC daily
- **Retention:** 30 days local and in Spaces
- **Log:** `/var/log/backup-full.log`

## Monitoring Backups

### Check Backup Logs

```bash
# Database backups
tail -f /var/log/backup-databases.log

# Full backups
tail -f /var/log/backup-full.log
```

### List Local Backups

```bash
./scripts/restore.sh --list
```

### List Remote Backups

```bash
./scripts/restore.sh --list-remote
```

### Manual Check Spaces

```bash
export AWS_ACCESS_KEY_ID="$DO_SPACES_KEY"
export AWS_SECRET_ACCESS_KEY="$DO_SPACES_SECRET"

aws s3 ls s3://your-bucket/databases/ \
  --recursive \
  --endpoint-url=https://nyc3.digitaloceanspaces.com
```

## Restore Procedures

### Restore Database

```bash
# List available backups
./scripts/restore.sh --list

# Restore specific database
./scripts/restore.sh --db backups/databases/wordpress-db-20240122-120000.sql.gz
```

**Example: Restore WordPress Database**

```bash
# Stop WordPress
./scripts/deploy.sh --stop wordpress

# Restore database
./scripts/restore.sh --db backups/databases/wordpress-db-20240122-120000.sql.gz

# Start WordPress
./scripts/deploy.sh --app wordpress
```

### Restore Full System

⚠️ **WARNING:** This will replace ALL current data!

```bash
# List backups
./scripts/restore.sh --list

# Restore full backup
./scripts/restore.sh --full backups/full/full-backup-20240122-020000.tar.gz
```

The restore process:
1. Stops all containers
2. Removes existing volumes
3. Restores volumes from backup
4. Restores configuration files
5. You then restart services

**After restore:**
```bash
# Restart infrastructure
./scripts/deploy.sh --infrastructure

# Restart applications
./scripts/deploy.sh --all
```

### Restore from DigitalOcean Spaces

```bash
# Download backup
aws s3 cp s3://your-bucket/full-backups/2024/01/full-backup-20240122-020000.tar.gz \
  backups/full/ \
  --endpoint-url=https://nyc3.digitaloceanspaces.com

# Restore
./scripts/restore.sh --full backups/full/full-backup-20240122-020000.tar.gz
```

## Application-Specific Backups

### WordPress

**Manual backup:**
```bash
# Database
docker-compose exec wordpress-db mysqldump \
  -u root -p${WORDPRESS_DB_ROOT_PASSWORD} \
  ${WORDPRESS_DB_NAME} > wordpress-backup.sql

# Files
docker run --rm \
  -v wordpress-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wordpress-files.tar.gz -C /data .
```

**Manual restore:**
```bash
# Database
cat wordpress-backup.sql | docker-compose exec -T wordpress-db mysql \
  -u root -p${WORDPRESS_DB_ROOT_PASSWORD} \
  ${WORDPRESS_DB_NAME}

# Files
docker run --rm \
  -v wordpress-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/wordpress-files.tar.gz -C /data
```

### Node.js API (PostgreSQL)

**Manual backup:**
```bash
docker-compose exec nodejs-db pg_dump \
  -U ${POSTGRES_USER} \
  ${POSTGRES_DB} > nodejs-backup.sql
```

**Manual restore:**
```bash
cat nodejs-backup.sql | docker-compose exec -T nodejs-db psql \
  -U ${POSTGRES_USER} \
  ${POSTGRES_DB}
```

### Laravel (MySQL)

**Manual backup:**
```bash
docker-compose exec laravel-db mysqldump \
  -u root -p${LARAVEL_DB_ROOT_PASSWORD} \
  ${LARAVEL_DB_NAME} > laravel-backup.sql
```

**Manual restore:**
```bash
cat laravel-backup.sql | docker-compose exec -T laravel-db mysql \
  -u root -p${LARAVEL_DB_ROOT_PASSWORD} \
  ${LARAVEL_DB_NAME}
```

## Disaster Recovery

### Complete Server Failure

1. **Create new DigitalOcean droplet**
2. **Run setup script:**
   ```bash
   git clone https://github.com/yourusername/appdeployment.git
   cd appdeployment
   sudo ./scripts/setup-server.sh
   ```

3. **Download latest backup:**
   ```bash
   # List backups
   aws s3 ls s3://your-bucket/full-backups/ \
     --recursive \
     --endpoint-url=https://nyc3.digitaloceanspaces.com
   
   # Download latest
   aws s3 cp s3://your-bucket/full-backups/2024/01/full-backup-latest.tar.gz \
     backups/full/ \
     --endpoint-url=https://nyc3.digitaloceanspaces.com
   ```

4. **Restore:**
   ```bash
   ./scripts/restore.sh --full backups/full/full-backup-latest.tar.gz
   ```

5. **Update DNS** to point to new server

6. **Deploy services:**
   ```bash
   ./scripts/deploy.sh --all
   ```

### Single Application Failure

1. **Stop failed application:**
   ```bash
   ./scripts/deploy.sh --stop wordpress
   ```

2. **Restore database:**
   ```bash
   ./scripts/restore.sh --db backups/databases/wordpress-db-latest.sql.gz
   ```

3. **Redeploy:**
   ```bash
   ./scripts/deploy.sh --app wordpress
   ```

## Backup Best Practices

### 1. Test Restores Regularly

```bash
# Monthly restore test
# Use a test environment to verify backups work
```

### 2. Monitor Backup Jobs

```bash
# Add to monitoring
# Check backup logs daily
grep -i error /var/log/backup-*.log
```

### 3. Verify Backup Integrity

```bash
# Test backup file
tar tzf backups/full/full-backup-latest.tar.gz > /dev/null

# Test database backup
gunzip -t backups/databases/wordpress-db-latest.sql.gz
```

### 4. Multiple Backup Locations

- Local: `/opt/appdeployment/backups/`
- DigitalOcean Spaces: Primary offsite
- Optional: Additional S3, Google Cloud Storage

### 5. Encryption (Optional)

Encrypt sensitive backups:

```bash
# Encrypt backup
gpg --symmetric --cipher-algo AES256 backup-file.tar.gz

# Decrypt
gpg --decrypt backup-file.tar.gz.gpg > backup-file.tar.gz
```

## Backup Storage Calculation

Estimate storage needs:

```bash
# Check volume sizes
docker system df -v

# Database sizes
docker exec wordpress-db du -sh /var/lib/mysql
docker exec nodejs-db du -sh /var/lib/postgresql/data
```

**Example calculation:**
- 5 applications × 500MB volumes = 2.5GB per day
- 30 days retention = 75GB
- Database backups: ~100MB/hour × 24 × 7 days = 16.8GB
- **Total: ~92GB/month**

## Troubleshooting

### Backup Script Fails

```bash
# Check logs
tail -100 /var/log/backup-full.log

# Common issues:
# - Disk space full
df -h

# - Spaces credentials wrong
aws s3 ls --endpoint-url=https://nyc3.digitaloceanspaces.com

# - Container not running
docker ps
```

### Restore Fails

```bash
# Verify backup integrity
tar tzf backup-file.tar.gz

# Check disk space
df -h

# Verify permissions
ls -la backups/
```

### Out of Disk Space

```bash
# Clean old backups manually
find backups/databases/ -type f -mtime +7 -delete
find backups/full/ -type f -mtime +30 -delete

# Clean Docker
docker system prune -a
```

## Next Steps

- Set up monitoring for backup jobs in Grafana
- Configure email alerts for backup failures
- Document restore procedures for your team
- Schedule monthly disaster recovery drills
