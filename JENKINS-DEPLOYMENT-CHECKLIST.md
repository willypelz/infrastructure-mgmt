# 🚀 Jenkins Deployment Checklist

Use this checklist to deploy and configure Jenkins CI/CD.

---

## Pre-Deployment

- [ ] Server is running and accessible
- [ ] Docker and Docker Compose installed
- [ ] Domain DNS configured
- [ ] `.env` file exists and configured

---

## Step 1: Configure Environment Variables

```bash
cd /root/infrastructure-mgmt
nano .env
```

Add these lines:
```bash
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD_HERE
```

- [ ] Added `JENKINS_SUBDOMAIN`
- [ ] Added `JENKINS_ADMIN_USER`
- [ ] Added `JENKINS_ADMIN_PASSWORD` (use strong password!)

---

## Step 2: Fix Network Issues (if needed)

```bash
./scripts/fix-network.sh
```

- [ ] Network 'web' has correct labels

---

## Step 3: Deploy Jenkins

```bash
./scripts/deploy.sh --jenkins
```

Expected output: "✓ Jenkins deployed"

- [ ] Jenkins container is running (`docker ps | grep jenkins`)
- [ ] No errors in logs (`docker logs jenkins`)

---

## Step 4: Configure DNS

Add A record in your DNS provider:

| Type | Name | Value |
|------|------|-------|
| A | jenkins | YOUR_SERVER_IP |

Wait 5-10 minutes for propagation.

Test: `nslookup jenkins.yourdomain.com`

- [ ] DNS A record added
- [ ] DNS propagated (can resolve jenkins.yourdomain.com)

---

## Step 5: Run Setup Helper

```bash
./scripts/setup-jenkins.sh
```

This will:
- Generate SSH keys
- Display access credentials
- Show webhook URL
- Test SSH connection (optional)

- [ ] Setup script completed
- [ ] SSH key generated
- [ ] Noted the public key for later

---

## Step 6: Access Jenkins

Open browser: `https://jenkins.yourdomain.com`

Login with:
- Username: (from .env JENKINS_ADMIN_USER)
- Password: (from .env JENKINS_ADMIN_PASSWORD)

- [ ] Can access Jenkins URL
- [ ] Successfully logged in
- [ ] Dashboard shows "Applications" folder
- [ ] See 5 pre-configured pipelines

---

## Step 7: Add Deployment Server Credential

In Jenkins:
1. Go to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**
4. Select **Secret text**
5. Fill in:
   - Secret: `your-server-ip`
   - ID: `deployment-server-host`
   - Description: `Deployment Server Host`
6. Click **OK**

- [ ] Credential `deployment-server-host` added

---

## Step 8: Add SSH Key Credential

Get private key:
```bash
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa
```

In Jenkins:
1. Go to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**
4. Select **SSH Username with private key**
5. Fill in:
   - ID: `deployment-ssh-key`
   - Username: `root` (or your deployment user)
   - Private Key: **Enter directly** → Paste the entire key
6. Click **OK**

- [ ] Credential `deployment-ssh-key` added

---

## Step 9: Add SSH Public Key to Deployment Server

Get public key:
```bash
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub
```

On deployment server:
```bash
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Test connection:
```bash
docker exec jenkins ssh -o StrictHostKeyChecking=no root@your-server-ip "echo 'Success'"
```

- [ ] Public key added to deployment server
- [ ] SSH connection test successful

---

## Step 10: Add Jenkinsfile to Repositories

For each repository, add the appropriate Jenkinsfile:

### Repository 1: nodejs-express-api
```bash
cd /path/to/nodejs-express-api
# Copy content from infrastructure/jenkins/jenkinsfiles/Jenkinsfile.nodejs
# Create file named "Jenkinsfile" in root
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

- [ ] Jenkinsfile added to nodejs-express-api

### Repository 2: react-spa
- [ ] Jenkinsfile added to react-spa (use Jenkinsfile.react)

### Repository 3: php-laravel
- [ ] Jenkinsfile added to php-laravel (use Jenkinsfile.laravel)

### Repository 4: flask-api
- [ ] Jenkinsfile added to flask-api (use Jenkinsfile.flask)

### Repository 5: wordpress-docker-app
- [ ] Jenkinsfile added to wordpress-docker-app (use Jenkinsfile.wordpress)

---

## Step 11: Configure GitHub Webhooks

For **EACH** repository:

1. Go to repository on GitHub
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - Payload URL: `https://jenkins.yourdomain.com/github-webhook/`
   - Content type: `application/json`
   - Which events: **Just the push event**
   - Active: ✓ (checked)
4. Click **Add webhook**

Repositories to configure:

- [ ] https://github.com/willypelz/nodejs-express-api
- [ ] https://github.com/willypelz/react-spa
- [ ] https://github.com/willypelz/php-laravel
- [ ] https://github.com/willypelz/flask-api
- [ ] https://github.com/willypelz/wordpress-docker-app

---

## Step 12: Test Manual Build

In Jenkins:
1. Go to **Applications** folder
2. Click **nodejs-express-api** (or any pipeline)
3. Click **Build Now**
4. Watch the build progress
5. Check console output for any errors

- [ ] Manual build started
- [ ] Build completed successfully
- [ ] No errors in console output

---

## Step 13: Test Automatic Build

Make a test commit:
```bash
cd /path/to/nodejs-express-api
echo "# Test Jenkins" >> README.md
git add README.md
git commit -m "Test Jenkins webhook"
git push
```

In Jenkins, watch for automatic build to start.

- [ ] Push to GitHub triggered build automatically
- [ ] Build completed successfully
- [ ] Application deployed to server

---

## Step 14: Verify Deployment

Check on deployment server:
```bash
docker ps | grep nodejs-api
docker logs nodejs-api
```

- [ ] Container is running
- [ ] Application is accessible
- [ ] Health check passes

---

## Post-Deployment

- [ ] Document any custom configurations
- [ ] Set up backup for Jenkins data
- [ ] Configure notifications (Slack/Email) - Optional
- [ ] Review and optimize build times - Optional
- [ ] Set up staging/production environments - Optional

---

## Troubleshooting Checklist

If something doesn't work:

### Jenkins Not Accessible
- [ ] Check container status: `docker ps | grep jenkins`
- [ ] Check logs: `docker logs jenkins`
- [ ] Verify DNS: `nslookup jenkins.yourdomain.com`
- [ ] Check Traefik: `docker logs traefik`

### Build Fails
- [ ] Check console output in Jenkins
- [ ] Verify Dockerfile exists in repository
- [ ] Check package.json/composer.json syntax
- [ ] Verify dependencies are correct

### Deployment Fails
- [ ] Test SSH connection manually
- [ ] Check credentials in Jenkins
- [ ] Verify deployment server is accessible
- [ ] Check deployment scripts exist

### Webhook Not Triggering
- [ ] Check webhook deliveries in GitHub
- [ ] Verify webhook URL is correct
- [ ] Check Jenkins logs for webhook errors
- [ ] Ensure Jenkins is publicly accessible

---

## Success Criteria

✅ **You've successfully set up Jenkins when:**

- [x] Jenkins is accessible at https://jenkins.yourdomain.com
- [x] All 5 pipelines show in Applications folder
- [x] Can login with configured credentials
- [x] GitHub webhooks show successful deliveries
- [x] Pushing code triggers automatic builds
- [x] Builds complete successfully
- [x] Applications deploy to server
- [x] Health checks pass after deployment

---

## Quick Reference Commands

```bash
# Deploy Jenkins
./scripts/deploy.sh --jenkins

# Setup Jenkins
./scripts/setup-jenkins.sh

# Fix network issues
./scripts/fix-network.sh

# View logs
docker logs jenkins -f

# Restart Jenkins
docker restart jenkins

# Get SSH public key
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub

# Test SSH connection
docker exec jenkins ssh root@your-server-ip "echo 'Success'"

# Check running containers
docker ps

# View all credentials
cat CREDENTIALS-REFERENCE.md
```

---

## Documentation References

- **Setup Guide:** `JENKINS-IMPLEMENTATION-SUMMARY.md`
- **Quick Start:** `docs/JENKINS-QUICK-START.md`
- **Detailed Setup:** `docs/JENKINS-SETUP.md`
- **Credentials:** `CREDENTIALS-REFERENCE.md`
- **Main README:** `README.md`

---

## Completion Time Estimate

- **Steps 1-6:** 15 minutes
- **Steps 7-9:** 10 minutes
- **Steps 10-11:** 20 minutes (5 repos × 4 min)
- **Steps 12-14:** 15 minutes
- **Total:** ~60 minutes

---

**Note:** Save this checklist and check off items as you complete them!

🎉 **Once all items are checked, your Jenkins CI/CD pipeline is fully operational!**
