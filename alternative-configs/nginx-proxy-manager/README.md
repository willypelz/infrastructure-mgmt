# Nginx Proxy Manager Configuration

This is an alternative to Traefik for reverse proxy management. It provides a web-based GUI for managing proxies, SSL certificates, and access control.

## Features

- **Web-based GUI** - Easy-to-use interface on port 81
- **Automatic SSL** - Let's Encrypt integration with one-click SSL
- **Access Lists** - Built-in authentication and IP whitelisting
- **Custom Locations** - Advanced nginx configuration support
- **Stream Support** - TCP/UDP proxying

## Setup

### 1. Stop Traefik

If you're currently using Traefik, stop it first:

```bash
cd /path/to/appdeployment
docker-compose down
```

### 2. Start Nginx Proxy Manager

```bash
cd alternative-configs/nginx-proxy-manager
docker-compose up -d
```

### 3. Access Admin Interface

- URL: `http://YOUR_SERVER_IP:81`
- Default Email: `admin@example.com`
- Default Password: `changeme`

**IMPORTANT:** Change the default credentials immediately after first login!

### 4. Configure Proxy Hosts

For each application, create a Proxy Host in the NPM interface:

#### Example: WordPress

1. Click "Proxy Hosts" → "Add Proxy Host"
2. Fill in:
   - **Domain Names:** `blog.yourdomain.com`
   - **Scheme:** `http`
   - **Forward Hostname/IP:** `wordpress` (container name)
   - **Forward Port:** `80`
   - **Block Common Exploits:** ✓
   - **Websockets Support:** ✓ (if needed)

3. Go to "SSL" tab:
   - **SSL Certificate:** Request a new SSL Certificate
   - **Force SSL:** ✓
   - **HTTP/2 Support:** ✓
   - **HSTS Enabled:** ✓

#### Application Endpoints

Configure these proxy hosts:

| Subdomain | Container | Port |
|-----------|-----------|------|
| `portainer.domain.com` | `portainer` | `9000` |
| `grafana.domain.com` | `grafana` | `3000` |
| `prometheus.domain.com` | `prometheus` | `9090` |
| `blog.domain.com` | `wordpress` | `80` |
| `api.domain.com` | `nodejs-api` | `3000` |
| `app.domain.com` | `flask-app` | `5000` |
| `www.domain.com` | `react-spa` | `80` |
| `shop.domain.com` | `laravel-app` | `80` |

### 5. Update Application docker-compose files

Remove Traefik labels from application docker-compose.yml files. The containers just need to be on the same network:

```yaml
services:
  my-app:
    # ... other config ...
    networks:
      - web
    # Remove all traefik.* labels

networks:
  web:
    external: true
```

## Security

### Access Lists

Create access lists for admin panels:

1. Go to "Access Lists"
2. Create new list with:
   - **Name:** Admin Only
   - **Authorization:** Basic Auth or OAuth
   - **Users:** Add username/password

3. Apply to Portainer, Grafana, Prometheus proxy hosts

### IP Whitelisting

In each Proxy Host's "Advanced" tab, add:

```nginx
# Allow only specific IPs
allow 1.2.3.4;
allow 5.6.7.8;
deny all;
```

## Advanced Configuration

### Rate Limiting

In Proxy Host "Advanced" tab:

```nginx
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
limit_req zone=mylimit burst=20 nodelay;
```

### Custom Headers

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

## Switching from Traefik

Use the provided script:

```bash
cd /path/to/appdeployment
./scripts/switch-to-npm.sh
```

This will:
1. Stop Traefik
2. Start Nginx Proxy Manager
3. Update application configs
4. Display configuration instructions

## Backup

NPM data is stored in Docker volumes:
- `npm-data` - Configuration and certificates
- `npm-db-data` - Database

These are included in the automated backup scripts.

## Troubleshooting

### Can't access admin panel

```bash
docker-compose logs nginx-proxy-manager
```

### Certificate generation fails

- Ensure DNS points to server
- Check Let's Encrypt rate limits
- Try staging certificates first

### Application not accessible

- Verify container is running: `docker ps`
- Check container is on `web` network
- Check proxy host configuration
- View NPM logs for errors

## Documentation

- Official Docs: https://nginxproxymanager.com/
- GitHub: https://github.com/NginxProxyManager/nginx-proxy-manager
