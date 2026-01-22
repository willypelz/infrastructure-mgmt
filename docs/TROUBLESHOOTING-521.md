# 🚨 Fix: Error 521 - Web Server Down

## What is Error 521?

Error 521 means Cloudflare can't connect to your origin server. The Node.js API container is either:
- Not running
- Not responding on the correct port
- Not accessible through Traefik

## Quick Fix (Run on your server)

### Option 1: Use the troubleshoot script
```bash
cd /root/infrastructure-mgmt
./scripts/troubleshoot.sh
```

This will diagnose and show you exactly what's wrong.

### Option 2: Manual restart
```bash
cd /root/infrastructure-mgmt

# Restart the Node.js API
cd apps/nodejs-express-api
docker-compose --env-file /root/infrastructure-mgmt/.env down
docker-compose --env-file /root/infrastructure-mgmt/.env up -d

# Restart Traefik
cd /root/infrastructure-mgmt
docker-compose --env-file /root/infrastructure-mgmt/.env restart traefik
```

### Option 3: Complete redeployment
```bash
cd /root/infrastructure-mgmt
./scripts/deploy.sh --app nodejs-express-api
```

## Detailed Diagnostics

### 1. Check if containers are running
```bash
docker ps | grep -E "nodejs-api|traefik"
```

**Expected output:**
```
nodejs-api    Up X minutes    0.0.0.0:3000->3000/tcp
traefik       Up X minutes    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### 2. Check Node.js API logs
```bash
docker logs nodejs-api --tail 50
```

**Look for:**
- ✅ "Server listening on port 3000"
- ❌ Error messages
- ❌ Database connection errors
- ❌ Crash/exit messages

### 3. Test API health endpoint
```bash
docker exec nodejs-api curl http://localhost:3000/health
```

**Expected:** `{"status":"healthy"}`

### 4. Check Traefik logs
```bash
docker logs traefik --tail 50
```

**Look for:**
- ✅ Route to nodejs-api registered
- ❌ Backend errors
- ❌ Certificate errors

### 5. Check Traefik routing
```bash
curl -H "Host: api.gmcloudworks.org" http://localhost:3000/health
```

### 6. Verify network connectivity
```bash
docker network inspect web | grep -A 5 nodejs-api
docker network inspect web | grep -A 5 traefik
```

Both should be on the `web` network.

## Common Issues & Solutions

### Issue 1: Container keeps restarting
```bash
docker logs nodejs-api
```
**Solution:** Fix the error shown in logs (usually database connection or code error)

### Issue 2: Database not connected
```bash
docker exec nodejs-api curl http://localhost:3000/health
# If returns error about database
docker-compose --env-file /root/infrastructure-mgmt/.env up -d nodejs-db
```

### Issue 3: Traefik not routing
Check labels in docker-compose.yml:
```bash
docker inspect nodejs-api | grep -A 20 Labels
```

**Required labels:**
- `traefik.enable=true`
- `traefik.http.routers.nodejs-api.rule=Host(\`api.gmcloudworks.org\`)`
- `traefik.http.services.nodejs-api.loadbalancer.server.port=3000`

### Issue 4: Port conflict
```bash
netstat -tulpn | grep :3000
```
If something else is using port 3000, stop it or change the API port.

### Issue 5: Cloudflare SSL/TLS settings
Go to Cloudflare Dashboard → SSL/TLS → Overview

**Set to:** Full or Full (strict)

❌ **NOT:** Flexible (will cause issues)

## Step-by-Step Recovery

If nothing above works, do a complete restart:

```bash
cd /root/infrastructure-mgmt

# Stop everything
docker-compose --env-file .env down
cd apps/nodejs-express-api
docker-compose --env-file /root/infrastructure-mgmt/.env down

# Start from scratch
cd /root/infrastructure-mgmt

# 1. Deploy infrastructure (Traefik)
./scripts/deploy.sh --infrastructure

# 2. Wait 30 seconds
sleep 30

# 3. Deploy Node.js API
./scripts/deploy.sh --app nodejs-express-api

# 4. Wait 30 seconds
sleep 30

# 5. Check status
docker ps
docker logs nodejs-api --tail 20
docker logs traefik --tail 20
```

## Verification Checklist

After fixing, verify:

- [ ] `docker ps` shows nodejs-api is Up
- [ ] `docker ps` shows traefik is Up
- [ ] `docker logs nodejs-api` shows no errors
- [ ] `docker exec nodejs-api curl http://localhost:3000/health` returns success
- [ ] `https://api.gmcloudworks.org/health` returns success (in browser)
- [ ] No 521 error

## Still Not Working?

### Check DNS
```bash
dig api.gmcloudworks.org
```
Should point to your server IP.

### Check server firewall
```bash
ufw status
```
Ports 80 and 443 should be allowed.

### Check if API is actually running
```bash
docker exec -it nodejs-api /bin/sh
ps aux | grep node
netstat -tulpn | grep 3000
exit
```

### Check application code
```bash
docker exec nodejs-api cat server.js | head -20
```
Verify the app starts correctly.

## Contact Information

If all else fails, check:
1. Server logs: `/var/log/syslog`
2. Docker logs: `journalctl -u docker`
3. Application logs in container

## Quick Commands Reference

```bash
# View all containers
docker ps -a

# Restart specific service
docker restart nodejs-api

# View live logs
docker logs -f nodejs-api

# Enter container shell
docker exec -it nodejs-api /bin/sh

# Remove and recreate
docker-compose --env-file /root/infrastructure-mgmt/.env up -d --force-recreate

# Check network
docker network ls
docker network inspect web

# Full cleanup and restart
cd /root/infrastructure-mgmt
docker-compose down
./scripts/deploy.sh --infrastructure
./scripts/deploy.sh --app nodejs-express-api
```
