# Jenkins UI Setup Guide

Complete guide for setting up application pipelines via Jenkins UI for scalable deployment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Credentials Setup](#credentials-setup)
- [Creating a Pipeline Job](#creating-a-pipeline-job)
- [App-Specific Configurations](#app-specific-configurations)
- [GitHub Webhook Configuration](#github-webhook-configuration)
- [Testing Your Pipeline](#testing-your-pipeline)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure:

1. ✅ Jenkins is deployed and accessible at `https://jenkins.${DOMAIN}`
2. ✅ You have admin access (credentials from `.env` file)
3. ✅ Application repository exists on GitHub with Jenkinsfile
4. ✅ DNS is configured for the app subdomain
5. ✅ Server `.env` has subdomain variables configured

## Credentials Setup

Jenkins needs credentials to deploy to your server and optionally access private GitHub repositories.

### 1. Add Deployment Server Host

1. Navigate to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**
2. Click on **(global)** domain
3. Click **Add Credentials** (left sidebar)
4. Configure:
   - **Kind:** Secret text
   - **Scope:** Global
   - **Secret:** `your-server-ip-address` (e.g., `142.93.123.45`)
   - **ID:** `deployment-server-host`
   - **Description:** `Deployment Server IP Address`
5. Click **Create**

### 2. Add SSH Deployment Key

#### Generate SSH Key (if not already done)

```bash
# SSH into your Jenkins container
docker exec -it jenkins bash

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f /var/jenkins_home/.ssh/id_rsa -N ""

# Display the public key
cat /var/jenkins_home/.ssh/id_rsa.pub
```

#### Add Public Key to Deployment Server

Copy the public key output and add it to your server:

```bash
# On your deployment server
echo "ssh-rsa AAAA...your-key... jenkins@jenkins" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Add Private Key to Jenkins

1. Get the private key:
   ```bash
   docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa
   ```

2. In Jenkins UI:
   - Go to **Manage Jenkins** → **Credentials** → **(global)**
   - Click **Add Credentials**
   - Configure:
     - **Kind:** SSH Username with private key
     - **Scope:** Global
     - **ID:** `deployment-ssh-key`
     - **Description:** `SSH Key for Deployment`
     - **Username:** `root` (or your deployment user)
     - **Private Key:** Select "Enter directly"
     - Paste the entire private key (including `-----BEGIN` and `-----END` lines)
   - Click **Create**

### 3. Add GitHub Credentials (Optional - for private repos)

If your application repository is private:

1. Go to **Manage Jenkins** → **Credentials** → **(global)**
2. Click **Add Credentials**
3. Configure:
   - **Kind:** Username with password
   - **Username:** Your GitHub username
   - **Password:** GitHub Personal Access Token (create at https://github.com/settings/tokens)
   - **ID:** `github-credentials`
   - **Description:** `GitHub Access Token`
4. Click **Create**

### 4. Verify Credentials

Test SSH connection from Jenkins:

```bash
docker exec -it jenkins ssh -o StrictHostKeyChecking=no root@your-server-ip "echo 'SSH connection successful'"
```

Expected output: `SSH connection successful`

## Creating a Pipeline Job

Follow these steps to add a new application pipeline via Jenkins UI.

### Step 1: Create New Pipeline

1. From Jenkins Dashboard, click **New Item** (left sidebar)
2. Enter item name: Use the app name (e.g., `nodejs-express-api`)
3. Select **Pipeline**
4. Click **OK**

### Step 2: General Configuration

On the configuration page:

1. **Description:** Add a meaningful description
   ```
   CI/CD pipeline for Node.js Express API
   Deploys to https://api.yourdomain.com
   ```

2. **Discard old builds:** (Optional but recommended)
   - Check **Discard old builds**
   - **Days to keep builds:** `30`
   - **Max # of builds to keep:** `10`

3. **GitHub project:** (Optional)
   - Check **GitHub project**
   - **Project url:** `https://github.com/willypelz/nodejs-express-api/`

### Step 3: Build Triggers

Configure automatic builds on git push:

1. Check **GitHub hook trigger for GITScm polling**
   - This allows GitHub webhooks to trigger builds automatically

### Step 4: Pipeline Configuration

This is where you tell Jenkins how to get your code and run the pipeline.

1. **Definition:** Select **Pipeline script from SCM**

2. **SCM:** Select **Git**

3. **Repository URL:** Enter your GitHub repository URL
   ```
   https://github.com/willypelz/nodejs-express-api.git
   ```

4. **Credentials:** 
   - For public repos: Select **- none -**
   - For private repos: Select `github-credentials`

5. **Branches to build:**
   - **Branch Specifier:** `*/main` (or `*/master` if your default branch is master)
   - You can add multiple branches, one per line

6. **Script Path:** 
   - Enter: `Jenkinsfile`
   - This tells Jenkins to look for the Jenkinsfile in the root of your repository

7. **Lightweight checkout:** Leave unchecked (recommended for full checkout)

### Step 5: Save Configuration

1. Click **Save** at the bottom
2. You'll be redirected to the pipeline page

## App-Specific Configurations

Below are specific configurations for each application type.

### WordPress Docker App

**Pipeline Name:** `wordpress-docker-app`
**Repository:** `https://github.com/willypelz/wordpress-docker-app.git`
**Branch:** `*/main` or `*/master`
**Jenkinsfile:** Copy from `infrastructure/jenkins/jenkinsfiles/Jenkinsfile.wordpress`

**Required in Repository:**
- `Jenkinsfile` (in root)
- `docker-compose.yml` with Traefik labels
- WordPress configuration files

**Subdomain:** Configured via `${WORDPRESS_SUBDOMAIN}` in server `.env`

### Node.js Express API

**Pipeline Name:** `nodejs-express-api`
**Repository:** `https://github.com/willypelz/nodejs-express-api.git`
**Branch:** `*/main`
**Jenkinsfile:** Copy from `infrastructure/jenkins/jenkinsfiles/Jenkinsfile.nodejs`

**Required in Repository:**
- `Jenkinsfile` (in root)
- `docker-compose.yml` with Traefik labels
- `Dockerfile`
- `package.json`

**Subdomain:** Configured via `${NODEJS_SUBDOMAIN}` in server `.env`

### PHP Laravel App

**Pipeline Name:** `php-laravel`
**Repository:** `https://github.com/willypelz/php-laravel.git`
**Branch:** `*/main`
**Jenkinsfile:** Copy from `infrastructure/jenkins/jenkinsfiles/Jenkinsfile.laravel`

**Required in Repository:**
- `Jenkinsfile` (in root)
- `docker-compose.yml` with Traefik labels
- `Dockerfile`
- `composer.json`

**Subdomain:** Configured via `${LARAVEL_SUBDOMAIN}` in server `.env`

### React SPA

**Pipeline Name:** `react-spa`
**Repository:** `https://github.com/willypelz/react-spa.git`
**Branch:** `*/main`
**Status:** **Pre-configured** ✅

**Required in Repository:**
- `Jenkinsfile` (in root)
- `docker-compose.yml` with Traefik labels
- `Dockerfile`
- `package.json`

**Subdomain:** Configured via `${REACT_SUBDOMAIN}` in server `.env`

### Flask API

**Pipeline Name:** `flask-api`
**Repository:** `https://github.com/willypelz/flask-api.git`
**Branch:** `*/main`
**Jenkinsfile:** Copy from `infrastructure/jenkins/jenkinsfiles/Jenkinsfile.flask`

**Required in Repository:**
- `Jenkinsfile` (in root)
- `docker-compose.yml` with Traefik labels
- `Dockerfile`
- `requirements.txt`

**Subdomain:** Configured via `${FLASK_SUBDOMAIN}` in server `.env`

## GitHub Webhook Configuration

To enable automatic deployments when you push to GitHub:

### Step 1: Get Webhook URL

Your Jenkins webhook URL is:
```
https://jenkins.yourdomain.com/github-webhook/
```

### Step 2: Configure in GitHub

For each application repository:

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure:
   - **Payload URL:** `https://jenkins.yourdomain.com/github-webhook/`
   - **Content type:** `application/json`
   - **Secret:** Leave empty (unless you configured webhook secret)
   - **Which events would you like to trigger this webhook?**
     - Select **Just the push event**
   - **Active:** ✅ Check this
5. Click **Add webhook**

### Step 3: Test Webhook

1. Make a small change to your repository (edit README, for example)
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test Jenkins webhook"
   git push
   ```
3. Check Jenkins - a build should start automatically
4. In GitHub, go to **Settings** → **Webhooks** → Click on your webhook
5. Scroll down to **Recent Deliveries** - you should see successful deliveries (green check)

## Testing Your Pipeline

### Manual Build

Before setting up webhooks, test with a manual build:

1. Go to your pipeline page in Jenkins
2. Click **Build Now** (left sidebar)
3. Watch the build progress in **Build History**
4. Click on the build number (e.g., `#1`)
5. Click **Console Output** to see detailed logs

### Understanding Build Stages

Your pipeline will go through these stages:

1. **Checkout** - Fetches code from GitHub
2. **Validate** - Checks for required files (package.json, requirements.txt, etc.)
3. **Build Docker Image** - Builds the Docker image
4. **Test** - Runs tests (if available)
5. **Deploy to Server** - Deploys via SSH to your server
6. **Health Check** - Verifies the container is running

### Successful Build

A successful build will:
- ✅ Show green checkmarks for all stages
- ✅ Display in the build history with a blue ball (success)
- ✅ Deploy your app to `https://appname.yourdomain.com`
- ✅ Container will be running on your server

### Failed Build

If a build fails:
- ❌ Red ball in build history
- ❌ Check **Console Output** for error messages
- ❌ Common issues:
  - Missing Jenkinsfile in repository
  - SSH connection failed (check credentials)
  - Docker build errors (check Dockerfile)
  - Missing environment variables on server

## Organizing Pipelines (Optional)

You can organize pipelines in folders:

### Create a Folder

1. From Dashboard, click **New Item**
2. Enter name: `Applications`
3. Select **Folder**
4. Click **OK**
5. Add description and click **Save**

### Move Pipelines to Folder

When creating a new pipeline:
1. Navigate into the folder first
2. Then click **New Item**
3. Create pipeline as usual

The react-spa example is already in an `Applications` folder (configured via jenkins-casc.yaml).

## Troubleshooting

### Pipeline Not Triggering on Push

**Problem:** Git push doesn't trigger Jenkins build

**Solutions:**
1. Check webhook in GitHub (Settings → Webhooks → Recent Deliveries)
2. Ensure webhook URL is correct: `https://jenkins.yourdomain.com/github-webhook/`
3. Verify "GitHub hook trigger for GITScm polling" is checked in pipeline config
4. Check Jenkins system log: **Manage Jenkins** → **System Log**

### SSH Connection Failed

**Problem:** `Permission denied (publickey)` in console output

**Solutions:**
1. Verify SSH key is added to server:
   ```bash
   cat ~/.ssh/authorized_keys | grep jenkins
   ```
2. Test SSH from Jenkins container:
   ```bash
   docker exec -it jenkins ssh -o StrictHostKeyChecking=no root@your-server "whoami"
   ```
3. Check credentials ID matches: `deployment-ssh-key`
4. Verify DEPLOY_USER in Jenkinsfile matches server user

### Docker Build Fails

**Problem:** Build fails during Docker image creation

**Solutions:**
1. Check Dockerfile exists in repository
2. Verify Dockerfile syntax
3. Check build logs for specific error
4. Ensure base images are accessible
5. Check disk space on Jenkins server:
   ```bash
   docker exec jenkins df -h
   ```

### App Not Accessible After Deployment

**Problem:** Build succeeds but app not accessible at subdomain

**Solutions:**
1. Check DNS is configured correctly:
   ```bash
   dig appname.yourdomain.com
   ```
2. Verify subdomain variable in server `.env`:
   ```bash
   cat /root/appdeployment/.env | grep SUBDOMAIN
   ```
3. Check container is running:
   ```bash
   docker ps | grep appname
   ```
4. Verify Traefik labels in docker-compose.yml
5. Check Traefik dashboard for routing rules
6. See [SUBDOMAIN-ROUTING-GUIDE.md](SUBDOMAIN-ROUTING-GUIDE.md) for details

### Container Starts But Stops Immediately

**Problem:** Container starts then exits

**Solutions:**
1. Check container logs:
   ```bash
   docker logs appname
   ```
2. Verify environment variables are set correctly
3. Check database connection (if applicable)
4. Review application startup logs
5. Test container locally first

### HTTP 403 Error: "No valid crumb was included in the request"

**Problem:** Getting 403 error when trying to create new items in Jenkins UI

**Cause:** CSRF protection (crumb issuer) not configured properly

**Solution:**

This has been fixed in the latest jenkins-casc.yaml configuration. If you're still seeing this error:

1. **Restart Jenkins:**
   ```bash
   docker restart jenkins
   ```

2. **Clear browser cache and cookies** for Jenkins URL

3. **Verify crumb issuer is enabled:**
   - Go to **Manage Jenkins** → **Configure Global Security**
   - Under **CSRF Protection**, ensure **Prevent Cross Site Request Forgery exploits** is checked
   - Select **Default Crumb Issuer**
   - Check **Enable proxy compatibility**
   - Click **Save**

4. **If using reverse proxy (Traefik):**
   The configuration now includes `excludeClientIPFromCrumb: true` which is required for proper operation behind a proxy.

5. **Restart Jenkins again:**
   ```bash
   docker restart jenkins
   ```

The jenkins-casc.yaml now includes:
```yaml
security:
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: true
```

This configuration is applied automatically on Jenkins startup.

## Next Steps

After setting up your pipeline:

1. **Configure Subdomain Routing** - See [SUBDOMAIN-ROUTING-GUIDE.md](SUBDOMAIN-ROUTING-GUIDE.md)
2. **Prepare Repository** - See [APP-REPOSITORY-SETUP.md](APP-REPOSITORY-SETUP.md)
3. **Understand Workflow** - See [DEPLOYMENT-WORKFLOW.md](DEPLOYMENT-WORKFLOW.md)
4. **Monitor Deployments** - Check Grafana dashboards
5. **Set Up Backups** - Run `./scripts/setup-cron.sh`

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

## Support

If you encounter issues:
1. Check **Console Output** in Jenkins build
2. Review **Traefik logs**: `docker logs traefik`
3. Check application logs: `docker logs <container-name>`
4. See [TROUBLESHOOTING-521.md](TROUBLESHOOTING-521.md) for common issues
