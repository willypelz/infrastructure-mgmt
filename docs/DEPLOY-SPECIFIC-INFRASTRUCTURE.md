# 🚀 Deploy Specific Infrastructure Components

You can now deploy infrastructure components individually instead of deploying everything at once!

## New Deployment Options

### Deploy Only Traefik (Reverse Proxy)
```bash
./scripts/deploy.sh --traefik
```

**What it does:**
- ✅ Creates/fixes the `web` network with proper labels
- ✅ Deploys Traefik reverse proxy
- ✅ Sets up SSL/TLS with Let's Encrypt
- ✅ Configures routing for all services

**Access:**
- Dashboard: `https://traefik.gmcloudworks.org`
- Default credentials: admin/admin (CHANGE IN PRODUCTION!)

---

### Deploy Only Portainer (Docker Management UI)
```bash
./scripts/deploy.sh --portainer
```

**What it does:**
- ✅ Ensures `web` network exists
- ✅ Deploys Portainer container management UI
- ✅ Connects to Traefik for HTTPS access

**Access:**
- UI: `https://portainer.gmcloudworks.org`
- First login: Create admin user

---

### Deploy Only Monitoring Stack
```bash
./scripts/deploy.sh --monitoring
```

**What it does:**
- ✅ Ensures `web` network exists
- ✅ Deploys Prometheus (metrics collection)
- ✅ Deploys Grafana (visualization)
- ✅ Deploys Alertmanager (alerts)
- ✅ Deploys Loki (log aggregation)
- ✅ Deploys Promtail (log shipping)

**Access:**
- Grafana: `https://grafana.gmcloudworks.org`
- Prometheus: `https://prometheus.gmcloudworks.org`
- Alertmanager: `https://alerts.gmcloudworks.org`

**Credentials:**
- Username: `admin`
- Password: (from your `.env` file - `GRAFANA_ADMIN_PASSWORD`)

---

### Deploy All Infrastructure (Original Method)
```bash
./scripts/deploy.sh --infrastructure
```

**What it does:**
- ✅ Deploys Traefik + Portainer + Monitoring
- ✅ All in one command

---

## Complete Usage Guide

### All Available Options

```bash
# Infrastructure
./scripts/deploy.sh --all                    # Deploy everything
./scripts/deploy.sh --infrastructure         # Deploy all infrastructure
./scripts/deploy.sh --traefik                # Deploy only Traefik
./scripts/deploy.sh --portainer              # Deploy only Portainer
./scripts/deploy.sh --monitoring             # Deploy only Monitoring

# Applications
./scripts/deploy.sh --app nodejs-express-api # Deploy specific app
./scripts/deploy.sh --stop wordpress         # Stop specific app
./scripts/deploy.sh --restart flask-api      # Restart specific app
./scripts/deploy.sh --logs react-spa         # View app logs
./scripts/deploy.sh --list                   # List all apps
```

---

## Use Cases

### 1. Deploy in Stages
```bash
# Step 1: Deploy reverse proxy first
./scripts/deploy.sh --traefik

# Step 2: Deploy apps
./scripts/deploy.sh --app nodejs-express-api

# Step 3: Add monitoring later
./scripts/deploy.sh --monitoring

# Step 4: Add Docker management UI
./scripts/deploy.sh --portainer
```

### 2. Update Single Component
```bash
# Update only Traefik without touching other services
./scripts/deploy.sh --traefik

# Update only monitoring without affecting apps
./scripts/deploy.sh --monitoring
```

### 3. Minimal Setup (Just Traefik + Apps)
```bash
# Deploy only what you need
./scripts/deploy.sh --traefik
./scripts/deploy.sh --app nodejs-express-api
./scripts/deploy.sh --app wordpress
```

### 4. Full Production Setup
```bash
# Deploy everything
./scripts/deploy.sh --infrastructure
./scripts/deploy.sh --app nodejs-express-api
./scripts/deploy.sh --app wordpress
./scripts/deploy.sh --app react-spa
```

---

## Benefits

### 🎯 Granular Control
- Deploy only what you need
- Update components independently
- Faster deployments

### 💰 Resource Optimization
- Don't deploy monitoring if you don't need it yet
- Save server resources on small VPS

### 🔧 Easier Troubleshooting
- Isolate issues to specific components
- Test individual services

### 📦 Modular Architecture
- Add services as you grow
- Scale incrementally

---

## Examples

### Example 1: Minimal API Server
```bash
# Just reverse proxy + API
./scripts/deploy.sh --traefik
./scripts/deploy.sh --app nodejs-express-api
```

### Example 2: Add Monitoring Later
```bash
# You've been running for a while, now want monitoring
./scripts/deploy.sh --monitoring
```

### Example 3: Quick Portainer Fix
```bash
# Portainer container crashed, redeploy just that
./scripts/deploy.sh --portainer
```

### Example 4: Fresh Server Setup (Staged)
```bash
# Stage 1: Core infrastructure
./scripts/deploy.sh --traefik

# Stage 2: Management tools
./scripts/deploy.sh --portainer

# Stage 3: Deploy apps
./scripts/deploy.sh --app nodejs-express-api

# Stage 4: Add monitoring
./scripts/deploy.sh --monitoring
```

---

## What Gets Deployed

### Traefik Only (`--traefik`)
- Container: `traefik`
- Network: `web` (created with proper labels)
- Ports: 80, 443
- SSL: Let's Encrypt automatic certificates
- Dashboard: Enabled with authentication

### Portainer Only (`--portainer`)
- Container: `portainer`
- Network: Connected to `web`
- UI: Full Docker management interface
- Volume: Persistent data storage

### Monitoring Only (`--monitoring`)
- Container: `prometheus` (metrics database)
- Container: `grafana` (dashboards)
- Container: `alertmanager` (alerts)
- Container: `loki` (logs database)
- Container: `promtail` (log collector)
- Network: `web` + `monitoring` (internal)
- Volumes: Persistent data for all components

### All Infrastructure (`--infrastructure`)
- Everything above in one command

---

## Network Management

All individual deployment commands:
- ✅ Check if `web` network exists
- ✅ Create it if missing
- ✅ Fix labels if incorrect
- ✅ Connect services properly

You don't need to worry about network setup!

---

## Quick Reference

| Command | Deploys | Use When |
|---------|---------|----------|
| `--traefik` | Reverse proxy only | Fresh setup or updating Traefik |
| `--portainer` | Docker UI only | Need container management |
| `--monitoring` | Prometheus + Grafana + Loki | Want metrics and logs |
| `--infrastructure` | All infrastructure | Standard deployment |
| `--all` | Everything | Complete setup |

---

## Tips

### 💡 Start Small
```bash
# Minimum for API hosting
./scripts/deploy.sh --traefik
./scripts/deploy.sh --app nodejs-express-api
```

### 💡 Add Services Gradually
```bash
# Already running? Add monitoring
./scripts/deploy.sh --monitoring
```

### 💡 Update Individual Components
```bash
# Updated Traefik config? Redeploy just that
./scripts/deploy.sh --traefik
```

### 💡 Cost Optimization
On a small VPS (512MB RAM)?
- Skip monitoring initially: Save ~200MB RAM
- Add it later when needed

---

## Verification

After deploying individual components:

### Check Traefik
```bash
docker ps | grep traefik
curl https://traefik.gmcloudworks.org
```

### Check Portainer
```bash
docker ps | grep portainer
curl https://portainer.gmcloudworks.org
```

### Check Monitoring
```bash
docker ps | grep -E "prometheus|grafana"
curl https://grafana.gmcloudworks.org
```

---

## 🎉 Summary

You now have **complete control** over your infrastructure deployment!

- ✅ Deploy components individually
- ✅ Update without affecting other services
- ✅ Optimize resource usage
- ✅ Scale incrementally

**Try it now:**
```bash
./scripts/deploy.sh --help
```
