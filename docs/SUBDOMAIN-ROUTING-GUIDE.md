# Subdomain Routing Guide

Complete guide explaining how Traefik automatically routes subdomains to your deployed applications.

## Table of Contents

- [How It Works](#how-it-works)
- [The Complete Flow](#the-complete-flow)
- [DNS Configuration](#dns-configuration)
- [Docker Labels Explained](#docker-labels-explained)
- [Environment Variables](#environment-variables)
- [The Web Network](#the-web-network)
- [Automatic SSL Certificates](#automatic-ssl-certificates)
- [Complete Example](#complete-example)
- [Troubleshooting](#troubleshooting)

## How It Works

When you deploy an application via Jenkins, Traefik automatically discovers it and routes traffic based on Docker labels. Here's the magic:

```
User visits: https://api.yourdomain.com
              ↓
         Traefik (Port 443)
              ↓
    Reads Docker labels from containers
              ↓
    Finds: traefik.http.routers.nodejs.rule=Host(`api.yourdomain.com`)
              ↓
    Routes traffic to: nodejs-express-api container
              ↓
    Application responds
```

**Key Concept:** Traefik watches Docker for containers on the `web` network and automatically configures routing based on their labels.

## The Complete Flow

### 1. **DNS Setup** (One-time)

Configure your DNS provider to point subdomain to server:

```
A Record: api.yourdomain.com → 142.93.123.45 (your server IP)
```

### 2. **Application Repository** Contains:

**docker-compose.yml** with Traefik labels:

```yaml
services:
  nodejs-api:
    image: nodejs-express-api:latest
    container_name: nodejs-express-api
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nodejs.rule=Host(`${NODEJS_SUBDOMAIN}.${DOMAIN}`)"
      - "traefik.http.routers.nodejs.entrypoints=websecure"
      - "traefik.http.routers.nodejs.tls.certresolver=letsencrypt"
      - "traefik.http.services.nodejs.loadbalancer.server.port=3000"
      - "traefik.docker.network=web"

networks:
  web:
    external: true
```

### 3. **Server .env File** Contains:

```bash
DOMAIN=yourdomain.com
NODEJS_SUBDOMAIN=api
```

### 4. **Jenkins Deploys:**

```bash
# Jenkins pipeline:
1. Checks out code from GitHub
2. Builds Docker image
3. Copies docker-compose.yml to server
4. Runs: docker-compose up -d
5. Container joins the 'web' network
```

### 5. **Traefik Auto-Discovers:**

```bash
# Traefik sees new container on 'web' network
# Reads labels and creates routing rule:
Host(`api.yourdomain.com`) → nodejs-express-api container
```

### 6. **SSL Certificate:**

```bash
# Traefik automatically:
1. Detects tls.certresolver=letsencrypt
2. Requests SSL certificate from Let's Encrypt
3. Stores in /letsencrypt/acme.json
4. Automatically renews before expiration
```

### 7. **App is Live:**

```bash
https://api.yourdomain.com → Your application ✅
```

## DNS Configuration

### Required DNS Records

For each application, create an A record pointing to your server:

| Subdomain | Record Type | Value | Purpose |
|-----------|-------------|-------|---------|
| `api.yourdomain.com` | A | `YOUR_SERVER_IP` | Node.js API |
| `blog.yourdomain.com` | A | `YOUR_SERVER_IP` | WordPress |
| `app.yourdomain.com` | A | `YOUR_SERVER_IP` | Flask API |
| `www.yourdomain.com` | A | `YOUR_SERVER_IP` | React SPA |
| `shop.yourdomain.com` | A | `YOUR_SERVER_IP` | Laravel App |

### DNS Provider Examples

**DigitalOcean:**
1. Go to Networking → Domains
2. Select your domain
3. Add Record → A
4. Hostname: `api`, Will Direct To: Your Droplet

**Cloudflare:**
1. Go to DNS
2. Add record → A
3. Name: `api`, IPv4 address: Your Server IP
4. Proxy status: DNS only (orange cloud off)

**Namecheap:**
1. Domain List → Manage
2. Advanced DNS
3. Add New Record → A Record
4. Host: `api`, Value: Your Server IP

### Verify DNS

Check DNS propagation:

```bash
# Check from your local machine
dig api.yourdomain.com

# Or use
nslookup api.yourdomain.com

# Or online tool
https://dnschecker.org
```

Expected output should show your server IP.

**Note:** DNS propagation can take 5-60 minutes.

## Docker Labels Explained

Each label serves a specific purpose in routing. Let's break down each one:

### Essential Labels

#### 1. Enable Traefik

```yaml
- "traefik.enable=true"
```

**Purpose:** Tells Traefik to monitor this container  
**Required:** Yes  
**Without it:** Traefik ignores the container

#### 2. Routing Rule

```yaml
- "traefik.http.routers.nodejs.rule=Host(`${NODEJS_SUBDOMAIN}.${DOMAIN}`)"
```

**Purpose:** Defines the routing rule (which domain/subdomain routes to this container)  
**Required:** Yes  
**Format:** `Host(\`subdomain.domain.com\`)`  
**Variables:** Uses environment variables from server's `.env` file  

**Router Name:** `nodejs` - must be unique across all containers

#### 3. Entry Point

```yaml
- "traefik.http.routers.nodejs.entrypoints=websecure"
```

**Purpose:** Specifies to use HTTPS (port 443)  
**Required:** Yes for HTTPS  
**Options:**
- `web` = HTTP (port 80)
- `websecure` = HTTPS (port 443)

#### 4. TLS/SSL Certificate

```yaml
- "traefik.http.routers.nodejs.tls.certresolver=letsencrypt"
```

**Purpose:** Enables automatic SSL certificate from Let's Encrypt  
**Required:** Yes for HTTPS  
**Certificate Resolver:** Must match Traefik's configured resolver name

#### 5. Load Balancer Port

```yaml
- "traefik.http.services.nodejs.loadbalancer.server.port=3000"
```

**Purpose:** Tells Traefik which port your application is listening on inside the container  
**Required:** Yes (if app doesn't expose port or exposes multiple ports)  
**Value:** The internal container port (not the external port)

**Examples:**
- Node.js typically: `3000`
- Flask typically: `5000`
- Laravel/PHP: `80` or `9000`
- React (nginx): `80`
- WordPress: `80`

#### 6. Network Specification

```yaml
- "traefik.docker.network=web"
```

**Purpose:** Specifies which Docker network Traefik should use for routing  
**Required:** Yes (if container is on multiple networks)  
**Value:** Must be `web` (the network Traefik is on)

### Optional But Recommended Labels

#### Middlewares

```yaml
- "traefik.http.routers.nodejs.middlewares=compress,security-headers"
```

**Purpose:** Apply middleware for compression, security headers, rate limiting, etc.

#### Custom Headers

```yaml
- "traefik.http.middlewares.nodejs-headers.headers.customRequestHeaders.X-Forwarded-Proto=https"
```

**Purpose:** Pass specific headers to your application

## Environment Variables

### Server .env File

Your deployment server must have these variables in `/root/appdeployment/.env`:

```bash
# Main domain
DOMAIN=yourdomain.com

# Application subdomains
WORDPRESS_SUBDOMAIN=blog
NODEJS_SUBDOMAIN=api
FLASK_SUBDOMAIN=app
REACT_SUBDOMAIN=www
LARAVEL_SUBDOMAIN=shop
```

### How Variables Work

When Jenkins deploys and runs `docker-compose up`:

```yaml
# In docker-compose.yml
- "traefik.http.routers.nodejs.rule=Host(`${NODEJS_SUBDOMAIN}.${DOMAIN}`)"
```

Docker Compose reads `.env` and substitutes:

```yaml
# Becomes:
- "traefik.http.routers.nodejs.rule=Host(`api.yourdomain.com`)"
```

### Adding New App Subdomain

To add a new application:

1. Add subdomain variable to server `.env`:
   ```bash
   NEW_APP_SUBDOMAIN=myapp
   ```

2. Use variable in app's docker-compose.yml:
   ```yaml
   - "traefik.http.routers.myapp.rule=Host(`${NEW_APP_SUBDOMAIN}.${DOMAIN}`)"
   ```

3. Configure DNS: `myapp.yourdomain.com` → Server IP

4. Deploy via Jenkins

## The Web Network

### Why It's Important

Traefik can only route to containers on the same Docker network. The `web` network is created by Traefik and shared by all applications.

### Network Configuration

**In Traefik's docker-compose.yml:**

```yaml
networks:
  web:
    name: web
    driver: bridge
```

**In Application's docker-compose.yml:**

```yaml
networks:
  web:
    external: true
```

**Key Difference:**
- `external: true` means the network already exists (created by Traefik)
- Don't try to create it again in your app

### Multiple Networks

If your app needs both external access (via Traefik) and internal services (database):

```yaml
services:
  app:
    networks:
      - web          # For Traefik routing
      - app-internal # For database access
      
  database:
    networks:
      - app-internal # Only internal, not exposed to Traefik

networks:
  web:
    external: true
  app-internal:
    name: ${APP_NAME}-internal
    driver: bridge
```

## Automatic SSL Certificates

### How Let's Encrypt Works

1. **Application deployed** with `tls.certresolver=letsencrypt` label
2. **Traefik detects** new HTTPS route
3. **Requests certificate** from Let's Encrypt
4. **HTTP-01 Challenge:**
   - Let's Encrypt sends request to `http://yourdomain.com/.well-known/acme-challenge/xxx`
   - Traefik responds automatically
5. **Certificate issued** and stored in `/letsencrypt/acme.json`
6. **HTTPS enabled** immediately
7. **Auto-renewal** happens automatically before expiration

### Staging vs Production

In Traefik's docker-compose.yml:

```yaml
# For testing (doesn't count against Let's Encrypt rate limits)
TRAEFIK_SSL_PRODUCTION=false

# For production (real certificates)
TRAEFIK_SSL_PRODUCTION=true
```

**Important:** Use staging first to test, then switch to production!

### Rate Limits

Let's Encrypt has rate limits:
- 50 certificates per domain per week
- Use staging for testing

### Troubleshooting SSL

Check certificate status:

```bash
# View Traefik logs
docker logs traefik | grep -i certificate

# Check acme.json
docker exec traefik cat /letsencrypt/acme.json | jq
```

## Complete Example

Here's a complete `docker-compose.yml` for a Node.js application with all necessary Traefik labels:

```yaml
version: '3.8'

services:
  nodejs-api:
    image: nodejs-express-api:latest
    container_name: nodejs-express-api
    restart: unless-stopped
    networks:
      - web
      - app-internal
    environment:
      - NODE_ENV=production
      - DATABASE_HOST=nodejs-db
      - DATABASE_PORT=5432
      - DATABASE_NAME=${POSTGRES_DB}
      - DATABASE_USER=${POSTGRES_USER}
      - DATABASE_PASSWORD=${POSTGRES_PASSWORD}
    labels:
      # Enable Traefik
      - "traefik.enable=true"
      
      # HTTP Router
      - "traefik.http.routers.nodejs.rule=Host(`${NODEJS_SUBDOMAIN}.${DOMAIN}`)"
      - "traefik.http.routers.nodejs.entrypoints=websecure"
      - "traefik.http.routers.nodejs.tls.certresolver=letsencrypt"
      - "traefik.http.routers.nodejs.service=nodejs"
      
      # Service Configuration
      - "traefik.http.services.nodejs.loadbalancer.server.port=3000"
      
      # Middlewares (optional)
      - "traefik.http.routers.nodejs.middlewares=compress,security-headers"
      
      # Network
      - "traefik.docker.network=web"
    depends_on:
      - nodejs-db

  nodejs-db:
    image: postgres:15-alpine
    container_name: nodejs-db
    restart: unless-stopped
    networks:
      - app-internal
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - nodejs-db-data:/var/lib/postgresql/data

networks:
  web:
    external: true
  app-internal:
    name: nodejs-internal
    driver: bridge

volumes:
  nodejs-db-data:
    name: nodejs-db-data
```

### Key Points in Example

1. **web network** - Application joins for Traefik routing
2. **app-internal network** - Database communication (not exposed)
3. **Environment variables** - Uses server .env for configuration
4. **Port 3000** - Application's internal port
5. **HTTPS only** - Uses websecure entrypoint
6. **Auto SSL** - Let's Encrypt certificate resolver
7. **Database isolated** - Only on internal network

## Troubleshooting

### App Not Accessible After Deployment

**Symptom:** Build succeeds, container running, but app not accessible at subdomain

**Check List:**

1. **Verify DNS:**
   ```bash
   dig api.yourdomain.com
   # Should return your server IP
   ```

2. **Check Container is Running:**
   ```bash
   docker ps | grep nodejs-express-api
   ```

3. **Verify Container is on Web Network:**
   ```bash
   docker network inspect web
   # Look for your container in the "Containers" section
   ```

4. **Check Traefik Dashboard:**
   - Visit `https://traefik.yourdomain.com`
   - Look for your app's router in the list
   - Check if router is showing as active

5. **Inspect Container Labels:**
   ```bash
   docker inspect nodejs-express-api | grep -A 20 Labels
   ```

6. **Check Traefik Logs:**
   ```bash
   docker logs traefik --tail 100 | grep nodejs
   ```

### SSL Certificate Not Issued

**Symptom:** App accessible via HTTP but not HTTPS, or certificate errors

**Solutions:**

1. **Check DNS First:**
   - SSL won't work without correct DNS
   - Ensure subdomain points to server IP

2. **Check Traefik SSL Mode:**
   ```bash
   cat /root/appdeployment/.env | grep TRAEFIK_SSL_PRODUCTION
   ```

3. **Review Certificate Logs:**
   ```bash
   docker logs traefik | grep -i "certificate\|acme\|letsencrypt"
   ```

4. **Check Port 80 is Open:**
   ```bash
   sudo ufw status
   # Ports 80 and 443 must be open
   ```

5. **Verify acme.json Permissions:**
   ```bash
   docker exec traefik ls -la /letsencrypt/
   # acme.json should exist
   ```

### Wrong Application Responding

**Symptom:** Visiting subdomain shows different application

**Cause:** Router name collision or incorrect routing rule

**Solutions:**

1. **Ensure Unique Router Names:**
   ```yaml
   # Each app needs unique router name
   - "traefik.http.routers.nodejs.rule=..."  # ← 'nodejs' must be unique
   ```

2. **Check Routing Rules:**
   ```bash
   docker inspect <container> | grep "traefik.http.routers"
   ```

3. **Restart Traefik:**
   ```bash
   docker restart traefik
   ```

### Container Can't Connect to Database

**Symptom:** App starts but can't connect to database

**Cause:** Database not on same network

**Solution:**

Ensure both app and database are on the same internal network:

```yaml
services:
  app:
    networks:
      - web          # For external access
      - app-internal # For database
      
  database:
    networks:
      - app-internal # Same network as app
```

## Next Steps

Now that you understand subdomain routing:

1. **Set up Jenkins Pipeline** - [JENKINS-UI-SETUP-GUIDE.md](JENKINS-UI-SETUP-GUIDE.md)
2. **Prepare Your Repository** - [APP-REPOSITORY-SETUP.md](APP-REPOSITORY-SETUP.md)
3. **Deploy Your Application** - [DEPLOYMENT-WORKFLOW.md](DEPLOYMENT-WORKFLOW.md)
4. **Monitor Your Apps** - Access Grafana dashboards

## Additional Resources

- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik Routing](https://doc.traefik.io/traefik/routing/overview/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Docker Networks](https://docs.docker.com/network/)
