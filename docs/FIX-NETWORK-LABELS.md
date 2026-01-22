# 🔧 Fix: Network Label Error

## Error Message
```
network web was found but has incorrect label com.docker.compose.network set to "" (expected: "web")
```

## What This Means
The Docker network "web" was created manually (e.g., `docker network create web`) instead of by Docker Compose. Docker Compose expects networks it manages to have specific labels, and when they're missing, it shows this warning.

## ⚡ Quick Fix (Run on Server)

### Option 1: Use the Automated Fix Script (RECOMMENDED)
```bash
cd /root/infrastructure-mgmt
./scripts/fix-network-labels.sh
```

This script will:
- ✅ Check the current network labels
- ✅ Gracefully stop all connected containers
- ✅ Remove the old network
- ✅ Recreate it with proper Docker Compose labels
- ✅ Restart all containers
- ✅ Verify the fix worked

### Option 2: Redeploy Infrastructure
```bash
cd /root/infrastructure-mgmt
./scripts/deploy.sh --infrastructure
```

The deploy script now automatically detects and fixes this issue!

### Option 3: Manual Fix
```bash
# 1. Stop all containers on the network
docker ps --filter network=web --format '{{.Names}}' | xargs -r docker stop

# 2. Remove the network
docker network rm web

# 3. Redeploy infrastructure (creates network with correct labels)
cd /root/infrastructure-mgmt
docker-compose --env-file .env up -d

# 4. Redeploy apps
./scripts/deploy.sh --app nodejs-express-api
```

## 🔍 Understanding the Issue

### Why It Happens
1. Network was created with `docker network create web` (no labels)
2. Docker Compose expects: `com.docker.compose.network=web` label
3. When Docker Compose finds the network without labels, it warns you

### Why It Matters
- ⚠️ Warning messages clutter output
- ⚠️ Docker Compose can't properly manage the network
- ⚠️ May cause issues with network lifecycle management
- ⚠️ Can break `docker-compose down` (won't remove network)

### The Correct Way
Networks should be created by Docker Compose in your `docker-compose.yml`:

```yaml
networks:
  web:
    name: web
    driver: bridge
```

When Docker Compose creates it, it adds the label: `com.docker.compose.network=web`

## ✅ Verification

After running the fix, verify it worked:

```bash
# Check the network label
docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}'
```

**Expected output:** `web`

**If empty or error:** The label is still missing

### Full Network Info
```bash
docker network inspect web --format='
Network Name: {{.Name}}
Labels: {{.Labels}}
Containers: {{range .Containers}}{{.Name}} {{end}}'
```

## 🚀 What I Fixed

### 1. Updated `scripts/deploy.sh`

**In `deploy_infrastructure()` function:**
- Now checks if network has correct label
- If label is wrong, disconnects all containers
- Removes old network
- Lets Docker Compose recreate with proper labels

**In `deploy_app()` function:**
- Warns if network has incorrect labels
- Provides helpful message to run infrastructure deployment
- Creates basic network only as fallback (with warning)

### 2. Created `scripts/fix-network-labels.sh`
A dedicated script that:
- Checks current network state
- Fixes label issues automatically
- Handles all containers gracefully
- Provides verification

## 🎯 Prevention

To avoid this issue in the future:

### ✅ DO:
```bash
# Always deploy infrastructure first
./scripts/deploy.sh --infrastructure

# Or use docker-compose
docker-compose up -d
```

### ❌ DON'T:
```bash
# Don't manually create networks that docker-compose manages
docker network create web
```

## 🔄 Impact on Running Services

**Is it safe to fix?**
- ✅ Yes, if done correctly
- ⚠️ Will cause brief downtime (containers restart)
- ⚠️ All containers on the network need to restart

**Recommended approach:**
1. Run during maintenance window
2. Use the automated script (handles everything safely)
3. Verify all services come back up

## 📊 Troubleshooting

### Issue: "Cannot remove network, containers are connected"
```bash
# Force disconnect all containers
docker network inspect web --format='{{range .Containers}}{{.Name}} {{end}}' | xargs -n1 docker network disconnect -f web

# Then remove
docker network rm web
```

### Issue: "Network already exists"
This is fine! The fix scripts handle existing networks.

### Issue: Containers won't reconnect
```bash
# Restart the containers
docker-compose --env-file /root/infrastructure-mgmt/.env restart

# Or redeploy
./scripts/deploy.sh --infrastructure
./scripts/deploy.sh --app nodejs-express-api
```

## 🆘 Emergency Rollback

If the fix causes issues:

```bash
# Create a simple network to get services back online
docker network create web

# Restart all containers
docker ps -a --filter network=web --format '{{.Names}}' | xargs -r docker restart

# Fix properly later during maintenance
```

## 📝 Summary

| Issue | Solution | Script |
|-------|----------|--------|
| Network has wrong labels | Run fix script | `./scripts/fix-network-labels.sh` |
| Want to prevent issue | Deploy infrastructure first | `./scripts/deploy.sh --infrastructure` |
| Need manual fix | See "Manual Fix" section above | - |

## ✨ Final Notes

After I fixed your code:
- ✅ Deploy script now auto-detects and fixes label issues
- ✅ Dedicated fix script available for existing deployments
- ✅ Helpful warnings guide you to the right solution
- ✅ No more label warnings on deployments!

**Run this now on your server:**
```bash
cd /root/infrastructure-mgmt
./scripts/fix-network-labels.sh
```

This will permanently fix the label issue! 🎉
