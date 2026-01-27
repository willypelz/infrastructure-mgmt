# Scripts Directory

This directory contains all deployment, maintenance, and troubleshooting scripts.

## 🚀 Deployment Scripts

### `deploy.sh`
Main deployment script for infrastructure and applications.

```bash
# Deploy everything
./scripts/deploy.sh --all

# Deploy infrastructure only
./scripts/deploy.sh --infrastructure

# Deploy specific components
./scripts/deploy.sh --traefik
./scripts/deploy.sh --portainer
./scripts/deploy.sh --jenkins
./scripts/deploy.sh --monitoring

# Deploy applications
./scripts/deploy.sh --app wordpress
./scripts/deploy.sh --app nodejs-express-api

# Manage applications
./scripts/deploy.sh --stop wordpress
./scripts/deploy.sh --restart nodejs-express-api
./scripts/deploy.sh --logs flask-api

# List available apps
./scripts/deploy.sh --list
```

### `setup-server.sh`
Initial server setup script (Docker, Docker Compose, security).

```bash
sudo ./scripts/setup-server.sh
```

**What it does:**
- Installs Docker and Docker Compose
- Configures firewall (UFW)
- Enables automatic security updates
- Sets up fail2ban
- Optimizes system settings

## 🔧 Setup Scripts

### `setup-jenkins.sh`
Jenkins initial configuration helper.

```bash
./scripts/setup-jenkins.sh
```

**What it does:**
- Generates SSH keys for deployments
- Displays access credentials
- Shows webhook URL
- Tests SSH connectivity
- Provides next steps

### `setup-cron.sh`
Configures automated backups with cron jobs.

```bash
sudo ./scripts/setup-cron.sh
```

**Schedules:**
- Hourly database backups
- Daily full backups
- Automatic cleanup of old backups

## 💾 Backup Scripts

### `backup-databases.sh`
Backup all application databases.

```bash
./scripts/backup-databases.sh
```

**Backs up:**
- WordPress MariaDB
- Node.js PostgreSQL
- Laravel MySQL
- All other configured databases

**Location:** `backups/databases/`

### `backup-full.sh`
Complete system backup (all Docker volumes).

```bash
./scripts/backup-full.sh
```

**Backs up:**
- All Docker volumes
- Configuration files
- SSL certificates
- Application data

**Location:** `backups/full/`

### `restore.sh`
Restore from backups.

```bash
# List available backups
./scripts/restore.sh --list

# Restore full backup
./scripts/restore.sh --full backups/full/full-backup-20260127-120000.tar.gz

# Restore specific database
./scripts/restore.sh --db backups/databases/wordpress-db-20260127-120000.sql.gz
```

## 🔍 Troubleshooting Scripts

### `fix-network.sh`
Fix Docker network label issues.

```bash
./scripts/fix-network.sh
```

**Fixes:**
- "network web was found but has incorrect label" error
- Recreates network with proper Docker Compose labels
- Reconnects all containers

### `troubleshoot.sh`
Comprehensive system diagnostics.

```bash
./scripts/troubleshoot.sh
```

**Checks:**
- Docker installation and status
- Network configuration
- Container health
- SSL certificates
- Disk space
- Memory usage
- Recent errors in logs

### `fix-521.sh`
Fix Cloudflare 521 errors.

```bash
./scripts/fix-521.sh
```

**Fixes:**
- Port configuration issues
- Traefik connectivity
- Network problems
- Firewall rules

## 🔄 Migration Scripts

### `switch-to-npm.sh`
Switch from Traefik to Nginx Proxy Manager.

```bash
./scripts/switch-to-npm.sh
```

**What it does:**
- Stops Traefik
- Deploys Nginx Proxy Manager
- Preserves SSL certificates
- Reconfigures applications

## 📋 Script Usage Patterns

### Daily Operations

```bash
# Deploy new application version
./scripts/deploy.sh --app myapp

# Check application logs
./scripts/deploy.sh --logs myapp

# Restart problematic service
./scripts/deploy.sh --restart myapp
```

### Maintenance

```bash
# Manual backup before major changes
./scripts/backup-full.sh

# Check system health
./scripts/troubleshoot.sh

# Fix network issues
./scripts/fix-network.sh
```

### Initial Setup

```bash
# 1. Setup server
sudo ./scripts/setup-server.sh

# 2. Deploy infrastructure
./scripts/deploy.sh --infrastructure

# 3. Setup Jenkins
./scripts/setup-jenkins.sh

# 4. Enable backups
sudo ./scripts/setup-cron.sh

# 5. Deploy applications
./scripts/deploy.sh --app wordpress
```

## 🛡️ Security Notes

### Requiring sudo

Some scripts require `sudo`:
- `setup-server.sh` - System-level changes
- `setup-cron.sh` - Cron job installation

### SSH Key Management

Scripts that handle SSH keys:
- `setup-jenkins.sh` - Generates deployment keys
- Stores keys in Jenkins container (`/var/jenkins_home/.ssh/`)

### Backup Security

Backups may contain sensitive data:
- Databases with user credentials
- SSL certificates
- Environment variables
- Application secrets

**Recommendation:** Encrypt backups before uploading to remote storage.

## 📝 Script Customization

### Environment Variables

All scripts load from `.env` file:

```bash
source "$PROJECT_ROOT/.env"
```

### Adding Custom Scripts

1. Create script in `scripts/` directory
2. Make executable: `chmod +x scripts/myscript.sh`
3. Follow naming convention: `action-target.sh`
4. Add error handling: `set -e`
5. Use color output for clarity

### Example Template

```bash
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Your script logic here
echo -e "${GREEN}Success!${NC}"
```

## 🔗 Related Documentation

- **Main README:** `../README.md`
- **Deployment Guide:** `../docs/DEPLOYMENT.md`
- **Troubleshooting:** `../docs/TROUBLESHOOTING-521.md`
- **Backup/Restore:** `../docs/BACKUP-RESTORE.md`
- **Jenkins Setup:** `../docs/JENKINS-SETUP.md`

## 🆘 Common Issues

### Script Won't Execute

```bash
# Make executable
chmod +x scripts/scriptname.sh

# Check shebang
head -n 1 scripts/scriptname.sh  # Should be #!/bin/bash
```

### Permission Denied

```bash
# Some scripts need sudo
sudo ./scripts/setup-server.sh

# Check file ownership
ls -la scripts/
```

### .env Not Found

```bash
# Copy from example
cp .env.example .env

# Edit with your values
nano .env
```

## 📊 Script Summary

| Script | Purpose | Requires sudo | Frequency |
|--------|---------|---------------|-----------|
| `deploy.sh` | Deploy services | No | As needed |
| `setup-server.sh` | Initial setup | Yes | Once |
| `setup-jenkins.sh` | Jenkins config | No | Once |
| `setup-cron.sh` | Backup automation | Yes | Once |
| `backup-databases.sh` | DB backup | No | Hourly (auto) |
| `backup-full.sh` | Full backup | No | Daily (auto) |
| `restore.sh` | Restore data | No | As needed |
| `fix-network.sh` | Fix network | No | As needed |
| `troubleshoot.sh` | Diagnostics | No | As needed |
| `fix-521.sh` | Fix 521 errors | No | As needed |
| `switch-to-npm.sh` | Switch proxy | No | As needed |

---

**Tip:** All scripts support `-h` or `--help` flag for usage information (where implemented).
