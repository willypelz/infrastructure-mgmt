# Default Credentials & Access Information

**⚠️ SECURITY WARNING:** Change all default passwords immediately in production!

## 🔐 Infrastructure Services

### Traefik Dashboard
- **URL:** `https://traefik.${DOMAIN}`
- **Username:** `admin`
- **Password:** Set in `.env` via `TRAEFIK_AUTH`
- **Generate password:**
  ```bash
  htpasswd -nb admin yourpassword
  # Add to .env as TRAEFIK_AUTH
  ```

### Portainer
- **URL:** `https://portainer.${DOMAIN}`
- **Username:** Created on first login
- **Password:** Created on first login
- **Note:** First user to access becomes admin

### Jenkins
- **URL:** `https://jenkins.${DOMAIN}`
- **Username:** Set in `.env` as `JENKINS_ADMIN_USER` (default: `admin`)
- **Password:** Set in `.env` as `JENKINS_ADMIN_PASSWORD`
- **Webhook URL:** `https://jenkins.${DOMAIN}/github-webhook/`

### Grafana
- **URL:** `https://grafana.${DOMAIN}`
- **Username:** Set in `.env` as `GRAFANA_ADMIN_USER` (default: `admin`)
- **Password:** Set in `.env` as `GRAFANA_ADMIN_PASSWORD`

### Prometheus
- **URL:** `https://prometheus.${DOMAIN}`
- **Authentication:** Uses Traefik auth (if configured)

### Alertmanager
- **URL:** `https://alerts.${DOMAIN}`
- **Authentication:** Uses Traefik auth (if configured)

---

## 📱 Application Credentials

### WordPress
- **URL:** `https://blog.${DOMAIN}`
- **Admin URL:** `https://blog.${DOMAIN}/wp-admin`
- **Username:** Set during WordPress installation
- **Password:** Set during WordPress installation
- **Database:**
  - Host: `wordpress-db`
  - Database: Set in `.env` as `WORDPRESS_DB_NAME`
  - User: Set in `.env` as `WORDPRESS_DB_USER`
  - Password: Set in `.env` as `WORDPRESS_DB_PASSWORD`
  - Root Password: Set in `.env` as `WORDPRESS_DB_ROOT_PASSWORD`

### Node.js Express API
- **URL:** `https://api.${DOMAIN}`
- **Health:** `https://api.${DOMAIN}/health`
- **Metrics:** `https://api.${DOMAIN}/metrics`
- **Database:**
  - Host: `nodejs-db`
  - Database: Set in `.env` as `POSTGRES_DB`
  - User: Set in `.env` as `POSTGRES_USER`
  - Password: Set in `.env` as `POSTGRES_PASSWORD`

### Python Flask API
- **URL:** `https://app.${DOMAIN}`
- **Health:** `https://app.${DOMAIN}/health`
- **Metrics:** `https://app.${DOMAIN}/metrics`
- **Redis:**
  - Host: `flask-redis`
  - Password: Set in `.env` as `REDIS_PASSWORD`

### React SPA
- **URL:** `https://www.${DOMAIN}`
- **Health:** `https://www.${DOMAIN}/health`
- **Note:** Static site, no authentication

### PHP Laravel
- **URL:** `https://shop.${DOMAIN}`
- **Health:** `https://shop.${DOMAIN}/health`
- **Admin:** Application-specific
- **Database:**
  - Host: `laravel-db`
  - Database: Set in `.env` as `LARAVEL_DB_NAME`
  - User: Set in `.env` as `LARAVEL_DB_USER`
  - Password: Set in `.env` as `LARAVEL_DB_PASSWORD`
  - Root Password: Set in `.env` as `LARAVEL_DB_ROOT_PASSWORD`

---

## 🗝️ Jenkins Credentials (to configure)

These need to be added in Jenkins UI after deployment:

### deployment-server-host
- **Type:** Secret text
- **ID:** `deployment-server-host`
- **Value:** Your deployment server IP or hostname
- **Location:** Manage Jenkins → Credentials → System → Global credentials

### deployment-ssh-key
- **Type:** SSH Username with private key
- **ID:** `deployment-ssh-key`
- **Username:** `root` (or your deployment user)
- **Private Key:** From `docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa`
- **Location:** Manage Jenkins → Credentials → System → Global credentials

### How to Add:
1. Go to Jenkins → Manage Jenkins → Credentials
2. Click on "System" → "Global credentials"
3. Click "Add Credentials"
4. Fill in the details
5. Click "OK"

---

## 🔑 SSH Access

### Server Access
```bash
ssh root@your-server-ip
# Or
ssh your-user@your-server-ip
```

### Jenkins SSH Key (for deployments)
```bash
# Get public key
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub

# Get private key
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa

# Add to deployment server
ssh root@server "echo 'PUBLIC_KEY' >> ~/.ssh/authorized_keys"
```

---

## 📊 Database Access

### Direct Database Connections

#### WordPress MariaDB
```bash
docker exec -it wordpress-db mysql -u${WORDPRESS_DB_USER} -p${WORDPRESS_DB_PASSWORD} ${WORDPRESS_DB_NAME}
```

#### Node.js PostgreSQL
```bash
docker exec -it nodejs-db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

#### Laravel MySQL
```bash
docker exec -it laravel-db mysql -u${LARAVEL_DB_USER} -p${LARAVEL_DB_PASSWORD} ${LARAVEL_DB_NAME}
```

#### Flask Redis
```bash
docker exec -it flask-redis redis-cli
# Then authenticate:
AUTH ${REDIS_PASSWORD}
```

### Database Backups Location
```bash
backups/databases/
├── wordpress-db-YYYYMMDD-HHMMSS.sql.gz
├── nodejs-db-YYYYMMDD-HHMMSS.sql.gz
├── laravel-db-YYYYMMDD-HHMMSS.sql.gz
└── ...
```

---

## 🌐 GitHub Integration

### Webhook Configuration

For each repository, configure webhook:

**Webhook URL:** `https://jenkins.${DOMAIN}/github-webhook/`
**Content type:** `application/json`
**Events:** Just the push event

**Repositories:**
- https://github.com/willypelz/wordpress-docker-app
- https://github.com/willypelz/nodejs-express-api
- https://github.com/willypelz/php-laravel
- https://github.com/willypelz/react-spa
- https://github.com/willypelz/flask-api

---

## 🔒 SSL Certificates

### Let's Encrypt

Managed automatically by Traefik.

**Storage:** `./letsencrypt/acme.json`

**Staging vs Production:**
- Staging: `TRAEFIK_SSL_PRODUCTION=false` (for testing)
- Production: `TRAEFIK_SSL_PRODUCTION=true`

### Certificate Locations
```bash
# Traefik stores certificates in
./letsencrypt/acme.json

# Backup this file regularly!
```

---

## 💾 Backup Credentials

### DigitalOcean Spaces

Set in `.env`:

```bash
DO_SPACES_KEY=your_spaces_access_key
DO_SPACES_SECRET=your_spaces_secret_key
DO_SPACES_REGION=nyc3
DO_SPACES_BUCKET=your-backup-bucket
DO_SPACES_ENDPOINT=https://nyc3.digitaloceanspaces.com
```

### Backup Encryption (Recommended)

```bash
# Encrypt backup
gpg --symmetric --cipher-algo AES256 backup-file.tar.gz

# Decrypt backup
gpg --decrypt backup-file.tar.gz.gpg > backup-file.tar.gz
```

---

## 📝 Environment Variables Summary

### Required in `.env`

```bash
# Domain
DOMAIN=yourdomain.com
SSL_EMAIL=your-email@example.com

# Traefik
TRAEFIK_SUBDOMAIN=traefik
TRAEFIK_AUTH=admin:$apr1$...  # Generate with htpasswd

# Portainer
PORTAINER_SUBDOMAIN=portainer

# Jenkins
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=change_this_password

# Grafana
GRAFANA_SUBDOMAIN=grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=change_this_password

# Databases
WORDPRESS_DB_PASSWORD=change_this
WORDPRESS_DB_ROOT_PASSWORD=change_this
POSTGRES_PASSWORD=change_this
LARAVEL_DB_PASSWORD=change_this
LARAVEL_DB_ROOT_PASSWORD=change_this
REDIS_PASSWORD=change_this

# Backups
DO_SPACES_KEY=your_key
DO_SPACES_SECRET=your_secret
```

---

## 🛡️ Security Best Practices

### 1. Change Default Passwords

```bash
# Generate strong password
openssl rand -base64 32

# Or use
pwgen -s 32 1
```

### 2. Use SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy to server
ssh-copy-id user@server
```

### 3. Enable 2FA

- Portainer: Settings → Authentication → Enable 2FA
- Grafana: Profile → Security → Two-Factor Authentication

### 4. Regular Backups

```bash
# Enable automated backups
sudo ./scripts/setup-cron.sh

# Test restore process regularly
./scripts/restore.sh --list
```

### 5. Keep Credentials Secure

- ✅ Store `.env` file securely
- ✅ Never commit `.env` to git
- ✅ Use password manager for credentials
- ✅ Rotate passwords regularly
- ✅ Use different passwords for each service

---

## 🆘 Password Recovery

### Reset Jenkins Password

```bash
# Get initial admin password (if available)
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Or reset via environment variable
# Edit .env, change JENKINS_ADMIN_PASSWORD, then:
docker-compose up -d jenkins
```

### Reset Grafana Password

```bash
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

### Reset Database Passwords

```bash
# Stop containers
docker-compose down

# Edit .env file with new passwords
nano .env

# Start containers (databases will use new passwords)
docker-compose up -d
```

---

## 📞 Emergency Access

### Lost All Passwords?

1. **Server Access:** Contact your hosting provider for password reset
2. **Databases:** Reset via environment variables in `.env`
3. **Jenkins:** Reset via CasC configuration
4. **Grafana:** Use CLI to reset admin password
5. **Portainer:** Reinstall (data is preserved in volumes)

### Locked Out of Server?

1. Use DigitalOcean console/recovery mode
2. Reset root password via hosting panel
3. Add new SSH key via hosting panel

---

**Remember:** Keep this file updated as you change credentials and never commit it to a public repository!
