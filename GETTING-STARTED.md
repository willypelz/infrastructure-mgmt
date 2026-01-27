# Getting Started Guide

Your first steps to deploying a production-ready multi-application infrastructure on DigitalOcean.

## What You're Building

A complete Docker-based hosting environment with:
- ✅ Automatic SSL certificates for all domains
- ✅ Web-based container management (Portainer)
- ✅ Monitoring dashboards (Grafana)
- ✅ Automated daily backups
- ✅ 5 example applications ready to deploy
- ✅ Production-ready security features

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] DigitalOcean account (or any Ubuntu server)
- [ ] Domain name (e.g., `yourdomain.com`)
- [ ] Access to domain's DNS settings
- [ ] SSH access to your server
- [ ] Basic command-line knowledge
- [ ] 30-60 minutes of time

**Recommended Server Specs:**
- Ubuntu 20.04 or 22.04
- 2GB RAM minimum (4GB recommended)
- 50GB SSD storage
- $12-24/month DigitalOcean droplet

## Step-by-Step Setup

### Step 1: Create DigitalOcean Droplet

1. Log into DigitalOcean
2. Click "Create" → "Droplets"
3. Choose:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic ($12/mo - 2GB RAM)
   - **Datacenter:** Closest to your users
   - **Authentication:** SSH key (recommended) or password
4. Click "Create Droplet"
5. Note your droplet's IP address

### Step 2: Configure DNS

Point these subdomains to your droplet's IP:

1. Go to your domain registrar's DNS settings
2. Add A records:

```
Type    Name        Value           TTL
A       traefik     YOUR_SERVER_IP  300
A       portainer   YOUR_SERVER_IP  300
A       grafana     YOUR_SERVER_IP  300
A       prometheus  YOUR_SERVER_IP  300
A       alerts      YOUR_SERVER_IP  300
A       blog        YOUR_SERVER_IP  300
A       api         YOUR_SERVER_IP  300
A       app         YOUR_SERVER_IP  300
A       www         YOUR_SERVER_IP  300
A       shop        YOUR_SERVER_IP  300
```

**Example:** If your IP is `164.90.123.45` and domain is `example.com`:
```
traefik.example.com    → 164.90.123.45
portainer.example.com  → 164.90.123.45
etc...
```

⏱️ **Wait 15-30 minutes** for DNS to propagate before continuing.

### Step 3: Connect to Your Server

```bash
# Replace with your server's IP
ssh root@YOUR_SERVER_IP

# Or if using SSH key
ssh -i ~/.ssh/your-key root@YOUR_SERVER_IP
```

### Step 4: Clone Repository

```bash
# Install git if needed
apt update && apt install -y git

# Clone the repository
git clone https://github.com/yourusername/appdeployment.git /opt/appdeployment

# Navigate to directory
cd /opt/appdeployment
```

### Step 5: Run Server Setup

This installs Docker, configures firewall, and sets up the environment:

```bash
# Make script executable
chmod +x scripts/setup-server.sh

# Run setup (takes 5-10 minutes)
sudo ./scripts/setup-server.sh
```

The script will:
- ✅ Update system packages
- ✅ Install Docker and Docker Compose
- ✅ Configure UFW firewall
- ✅ Install fail2ban (SSH protection)
- ✅ Create swap space
- ✅ Install AWS CLI (for backups)

### Step 6: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with nano (or vim)
nano .env
```

**Minimum required changes:**

```bash
# Your domain (without www or https://)
DOMAIN=yourdomain.com

# Your email for SSL certificates
SSL_EMAIL=admin@yourdomain.com

# Generate admin password for Traefik dashboard
# On your LOCAL computer, run: htpasswd -nb admin yourpassword
# Then paste the output here:
TRAEFIK_AUTH=admin:$apr1$...your_hash_here...

# Grafana admin password
GRAFANA_ADMIN_PASSWORD=your_secure_password_here

# Database passwords (make these strong!)
WORDPRESS_DB_PASSWORD=wp_strong_password_123
WORDPRESS_DB_ROOT_PASSWORD=wp_root_strong_password_123
POSTGRES_PASSWORD=pg_strong_password_123
LARAVEL_DB_PASSWORD=laravel_strong_password_123
REDIS_PASSWORD=redis_strong_password_123
```

**For backups (optional but recommended):**

```bash
# DigitalOcean Spaces configuration
DO_SPACES_KEY=your_spaces_access_key
DO_SPACES_SECRET=your_spaces_secret_key
DO_SPACES_BUCKET=your-backup-bucket
DO_SPACES_REGION=nyc3
```

Save and exit (Ctrl+X, then Y, then Enter)

### Step 7: Verify DNS (Important!)

Before deploying, verify DNS is working:

```bash
# Replace with your domain
dig traefik.yourdomain.com

# Should show your server's IP in the ANSWER section
```

If DNS isn't ready, **wait longer**. SSL certificates will fail if DNS isn't working.

### Step 8: Deploy Infrastructure

```bash
# Make deploy script executable
chmod +x scripts/deploy.sh

# Deploy Traefik, Portainer, and Monitoring
./scripts/deploy.sh --infrastructure
```

This takes 2-3 minutes. You'll see containers being created.

**Verify deployment:**
```bash
docker ps
```

You should see containers running: traefik, portainer, prometheus, grafana, loki, etc.

### Step 9: Access Admin Interfaces

Wait 2-3 minutes for SSL certificates to be generated, then visit:

**Traefik Dashboard** (https://traefik.yourdomain.com)
- Login with username `admin` and password from `TRAEFIK_AUTH`
- Should show green checkmarks for services

**Portainer** (https://portainer.yourdomain.com)
- First time: Create admin account
- Click "Get Started" → "Local" environment

**Grafana** (https://grafana.yourdomain.com)
- Login: `admin` / your `GRAFANA_ADMIN_PASSWORD`
- Explore pre-configured dashboards

### Step 10: Deploy Your First Application

Let's deploy WordPress as an example:

```bash
# Deploy WordPress blog
./scripts/deploy.sh --app wordpress

# Wait 30 seconds, then visit
# https://blog.yourdomain.com
```

Complete the WordPress setup wizard!

### Step 11: Deploy More Applications (Optional)

```bash
# Node.js Express API
./scripts/deploy.sh --app nodejs-express-api
# Visit: https://api.yourdomain.com/health

# Python Flask API
./scripts/deploy.sh --app flask-api
# Visit: https://app.yourdomain.com/health

# React SPA
./scripts/deploy.sh --app react-spa
# Visit: https://www.yourdomain.com

# PHP Laravel (requires Laravel installation first)
./scripts/deploy.sh --app php-laravel
# Visit: https://shop.yourdomain.com
```

### Step 12: Setup Automated Backups

```bash
# Make backup scripts executable
chmod +x scripts/*.sh

# Configure cron jobs for automated backups
sudo ./scripts/setup-cron.sh
```

Now you have:
- **Hourly** database backups (automatically uploaded to Spaces)
- **Daily** full system backups

## What You Just Built

Congratulations! You now have:

1. **Reverse Proxy** (Traefik)
   - Automatic SSL certificates
   - Routes all traffic to correct apps
   - Dashboard at traefik.yourdomain.com

2. **Container Management** (Portainer)
   - Web UI to manage containers
   - Deploy new apps with clicks
   - portainer.yourdomain.com

3. **Monitoring** (Grafana + Prometheus)
   - Real-time metrics
   - Pre-built dashboards
   - grafana.yourdomain.com

4. **Applications**
   - WordPress blog
   - Node.js API
   - Python Flask API
   - React frontend
   - PHP Laravel

5. **Automated Backups**
   - Hourly database backups
   - Daily full backups
   - Stored in DigitalOcean Spaces

## Next Steps

### Deploy Applications via Jenkins

Applications are now maintained in separate GitHub repositories and deployed via Jenkins:

**Pre-configured:**
- **react-spa** is ready to use - just push to trigger deployment

**Add More Applications:**
1. Access Jenkins at `https://jenkins.yourdomain.com`
2. Create new pipeline via Jenkins UI
3. Configure with GitHub repository URL
4. See: [docs/JENKINS-UI-SETUP-GUIDE.md](docs/JENKINS-UI-SETUP-GUIDE.md)

**Available Application Repositories:**
- https://github.com/willypelz/react-spa.git (pre-configured)
- https://github.com/willypelz/wordpress-docker-app.git
- https://github.com/willypelz/nodejs-express-api.git
- https://github.com/willypelz/php-laravel.git
- https://github.com/willypelz/flask-api.git

### Customize Your Applications

**To modify an application:**

1. Fork or clone the application repository:
   ```bash
   git clone https://github.com/willypelz/react-spa.git
   cd react-spa
   ```

2. Make your changes to the application code

3. Commit and push:
   ```bash
   git add .
   git commit -m "Updated application"
   git push
   ```

4. Jenkins automatically deploys via webhook! 🚀

**See:** [docs/APP-REPOSITORY-SETUP.md](docs/APP-REPOSITORY-SETUP.md) for repository structure

### Monitor Your Infrastructure

- Check container health in Portainer
- View metrics in Grafana
- Monitor Jenkins builds
- Set up email alerts in Alertmanager

### Secure Your Setup

```bash
# Change all default passwords in .env
nano /opt/appdeployment/.env

# Enable IP whitelisting for admin panels (optional)
# Uncomment and set in .env:
ADMIN_IP_WHITELIST=YOUR_HOME_IP/32
```

### Test Your Backups

```bash
# List backups
./scripts/restore.sh --list

# Download from Spaces
./scripts/restore.sh --list-remote
```

## Common Issues & Solutions

### "SSL certificate generation failed"

**Solution:** DNS not ready. Wait longer and restart Traefik:
```bash
docker restart traefik
docker logs traefik
```

### "Cannot access admin dashboard"

**Solution:** Check firewall and DNS:
```bash
sudo ufw status
dig traefik.yourdomain.com
```

### "Container won't start"

**Solution:** Check logs:
```bash
docker ps -a  # See all containers
docker logs container-name
```

### "Out of memory"

**Solution:** Reduce number of running services or upgrade droplet

### "Database connection failed"

**Solution:** Verify credentials in `.env` match database configuration

## Learning More

📖 **Full Documentation:**
- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment steps
- [Quick Reference](docs/QUICK-REFERENCE.md) - Common commands
- [Backup & Restore](docs/BACKUP-RESTORE.md) - Backup procedures
- [Project Structure](docs/PROJECT-STRUCTURE.md) - File organization

🎥 **Watch Containers:**
```bash
# Real-time resource usage
docker stats

# Follow logs
docker logs -f traefik
```

🔧 **Useful Commands:**
```bash
# Restart a service
./scripts/deploy.sh --restart portainer

# View logs
./scripts/deploy.sh --logs wordpress

# Stop a service
./scripts/deploy.sh --stop nodejs-express-api

# Deploy all apps
./scripts/deploy.sh --all
```

## Getting Help

If you run into issues:

1. Check the logs: `docker logs container-name`
2. Review documentation in `docs/` folder
3. Check Traefik dashboard for routing issues
4. Verify DNS configuration
5. Ensure .env file is properly configured

## Success Checklist

- [ ] Server running with Docker installed
- [ ] DNS records configured and propagated
- [ ] `.env` file configured with your settings
- [ ] Infrastructure deployed (Traefik, Portainer, Grafana)
- [ ] At least one application deployed and accessible
- [ ] SSL certificates working (green lock in browser)
- [ ] Automated backups configured
- [ ] Admin interfaces accessible
- [ ] Monitoring dashboards showing data

## You're Done! 🎉

You now have a production-ready infrastructure that can:
- Host multiple applications on different subdomains
- Automatically manage SSL certificates
- Monitor performance and logs
- Backup data automatically
- Scale as you grow

**What's next?**
- Deploy your own applications
- Customize monitoring dashboards
- Explore Portainer's features
- Set up CI/CD pipelines
- Share your success!

Welcome to professional Docker deployment! 🚀
