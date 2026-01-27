# Jenkins CI/CD Integration - Quick Reference

## Overview

Jenkins has been added to your infrastructure for automated CI/CD deployments from your GitHub repositories.

## Quick Start

### 1. Deploy Jenkins

```bash
# Deploy Jenkins only
./scripts/deploy.sh --jenkins

# Or deploy all infrastructure (including Jenkins)
./scripts/deploy.sh --infrastructure
```

### 2. Initial Setup

```bash
# Run the setup helper
./scripts/setup-jenkins.sh
```

This script will:
- ✅ Generate SSH keys for deployments
- ✅ Display access credentials
- ✅ Show the webhook URL for GitHub
- ✅ Test SSH connection to your deployment server

### 3. Configure Environment Variables

Add to your `.env` file:

```bash
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=your_secure_password_here
```

## Repository Setup

### Add Jenkinsfile to Each Repository

Copy the appropriate Jenkinsfile from `infrastructure/jenkins/jenkinsfiles/` to each repository:

| Repository | Jenkinsfile Template |
|------------|---------------------|
| nodejs-express-api | Jenkinsfile.nodejs |
| react-spa | Jenkinsfile.react |
| php-laravel | Jenkinsfile.laravel |
| flask-api | Jenkinsfile.flask |
| wordpress-docker-app | Jenkinsfile.wordpress |

Example:
```bash
# In your nodejs-express-api repository
curl https://raw.githubusercontent.com/yourusername/infrastructure/main/jenkins/jenkinsfiles/Jenkinsfile.nodejs -o Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### Configure GitHub Webhooks

For each repository:

1. Go to Settings → Webhooks → Add webhook
2. Payload URL: `https://jenkins.yourdomain.com/github-webhook/`
3. Content type: `application/json`
4. Select: "Just the push event"
5. Click "Add webhook"

## Jenkins Credentials

### Required Credentials in Jenkins

1. **deployment-server-host** (Secret text)
   - Your deployment server IP or hostname

2. **deployment-ssh-key** (SSH Username with private key)
   - SSH private key for deployment server access
   - Username: `root` (or your deployment user)

### How to Add Credentials

1. Go to Jenkins → Manage Jenkins → Credentials
2. Click on "System" → "Global credentials"
3. Click "Add Credentials"
4. Fill in the details and save

## Access Information

- **Jenkins URL:** `https://jenkins.yourdomain.com`
- **Username:** Set in `JENKINS_ADMIN_USER`
- **Password:** Set in `JENKINS_ADMIN_PASSWORD`
- **Webhook URL:** `https://jenkins.yourdomain.com/github-webhook/`

## Pre-configured Pipelines

Jenkins comes with pre-configured pipelines for all your applications:

- Applications/wordpress-docker-app
- Applications/nodejs-express-api
- Applications/php-laravel
- Applications/react-spa
- Applications/flask-api

## How It Works

1. **Push to GitHub** → Webhook triggers Jenkins
2. **Jenkins builds** → Checks out code, validates, builds Docker image
3. **Runs tests** → Executes application tests (if available)
4. **Deploys** → Transfers image to server and deploys
5. **Health check** → Verifies deployment success

## Deployment Flow

```
Developer Push
      ↓
GitHub Webhook
      ↓
Jenkins Pipeline
      ↓
Build Docker Image
      ↓
Run Tests
      ↓
Transfer to Server
      ↓
Deploy with Scripts
      ↓
Health Check
      ↓
✅ Success / ❌ Failure
```

## Common Commands

```bash
# Deploy Jenkins
./scripts/deploy.sh --jenkins

# Setup Jenkins credentials and SSH
./scripts/setup-jenkins.sh

# View Jenkins logs
docker logs jenkins -f

# Restart Jenkins
docker restart jenkins

# Enter Jenkins container
docker exec -it jenkins bash

# Get Jenkins admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Troubleshooting

### Jenkins Not Accessible

```bash
# Check if Jenkins is running
docker ps | grep jenkins

# Check logs
docker logs jenkins

# Verify network
docker network inspect web
```

### Build Failures

1. Check Jenkins build console output
2. Verify Dockerfile exists in repository
3. Check package.json/composer.json syntax
4. Ensure all dependencies are specified

### Deployment Failures

1. Verify SSH credentials are configured
2. Test SSH connection: `docker exec jenkins ssh user@host`
3. Check deployment server has Docker installed
4. Verify deployment scripts exist on server

## File Structure

```
infrastructure/jenkins/
├── docker-compose.yml          # Jenkins service definition
├── jenkins-casc.yaml          # Configuration as Code
├── plugins.txt                # Jenkins plugins
├── README.md                  # Detailed documentation
└── jenkinsfiles/              # Example Jenkinsfiles
    ├── Jenkinsfile.nodejs
    ├── Jenkinsfile.react
    ├── Jenkinsfile.laravel
    ├── Jenkinsfile.flask
    └── Jenkinsfile.wordpress
```

## Documentation

- **Detailed Setup:** `infrastructure/jenkins/README.md`
- **Step-by-Step Guide:** `docs/JENKINS-SETUP.md`
- **Main README:** `README.md`

## Next Steps

1. ✅ Deploy Jenkins infrastructure
2. ✅ Run setup script
3. ✅ Add credentials in Jenkins UI
4. ✅ Add Jenkinsfile to each repository
5. ✅ Configure GitHub webhooks
6. ✅ Test first deployment
7. 📝 Monitor builds and optimize
8. 📝 Add notifications (Slack, Email)
9. 📝 Set up multi-environment deployments
10. 📝 Configure backup for Jenkins data

## Support

For issues or questions:
1. Check `docs/JENKINS-SETUP.md` for detailed instructions
2. Review Jenkins logs: `docker logs jenkins`
3. Verify configuration in `jenkins-casc.yaml`
4. Check GitHub webhook delivery status

---

**Note:** Jenkins is configured with Configuration as Code (CasC), meaning most settings are automated. Manual configuration is only needed for credentials and repository-specific settings.
