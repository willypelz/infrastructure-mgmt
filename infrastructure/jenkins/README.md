# Jenkins CI/CD Infrastructure

This directory contains the Jenkins setup for automated deployments of your applications.

## Overview

Jenkins is configured with:
- **Configuration as Code (CasC)**: Automated setup via `jenkins-casc.yaml`
- **Docker support**: Build and deploy Docker containers
- **GitHub integration**: Webhook support for automatic builds
- **Pre-configured pipelines**: One for each application repository

## Quick Start

### 1. Add Jenkins Configuration to .env

Add these variables to your `.env` file:

```bash
# Jenkins Configuration
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=your_secure_password_here
```

### 2. Deploy Jenkins

```bash
# Deploy only Jenkins
./scripts/deploy.sh --jenkins

# Or deploy all infrastructure including Jenkins
./scripts/deploy.sh --infrastructure
```

### 3. Access Jenkins

Once deployed, access Jenkins at: `https://jenkins.yourdomain.com`

Login with the credentials you set in your `.env` file.

## Pre-configured Pipelines

Jenkins comes with **react-spa** pre-configured as a working example:

- **react-spa** - https://github.com/willypelz/react-spa.git ✅ **(Pre-configured)**

**Additional applications should be configured via Jenkins UI for better scalability.**

### Application Repositories

1. **react-spa** - https://github.com/willypelz/react-spa.git *(ready to use)*
2. **wordpress-docker-app** - https://github.com/willypelz/wordpress-docker-app.git
3. **nodejs-express-api** - https://github.com/willypelz/nodejs-express-api.git
4. **php-laravel** - https://github.com/willypelz/php-laravel.git
5. **flask-api** - https://github.com/willypelz/flask-api.git

## Adding More Applications

To add additional applications via Jenkins UI:

📖 **[Follow the comprehensive UI Setup Guide →](../docs/JENKINS-UI-SETUP-GUIDE.md)**

This guide covers:
- Setting up credentials
- Creating pipeline jobs via UI
- Configuring Git repositories
- Setting up GitHub webhooks
- App-specific configurations
- Troubleshooting

### Quick Steps

1. Access Jenkins at `https://jenkins.yourdomain.com`
2. Click **New Item** → Enter app name → Select **Pipeline**
3. Configure **Pipeline from SCM** with your GitHub repository URL
4. Set **Script Path** to `Jenkinsfile`
5. Save and build

**See detailed walkthrough:** [docs/JENKINS-UI-SETUP-GUIDE.md](../docs/JENKINS-UI-SETUP-GUIDE.md)

## Setting Up GitHub Webhooks

For automatic deployments on git push, configure webhooks in each repository:

1. Go to your GitHub repository → Settings → Webhooks
2. Click "Add webhook"
3. Set Payload URL: `https://jenkins.yourdomain.com/github-webhook/`
4. Content type: `application/json`
5. Select "Just the push event"
6. Click "Add webhook"

## Required Jenkinsfile in Each Repository

Each application repository needs a `Jenkinsfile` in its root. Examples are provided in the `jenkinsfiles/` directory.

### Jenkinsfile Structure

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "your-app-name"
        DEPLOY_HOST = "your-server-ip"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    // Deploy to server
                }
            }
        }
    }
}
```

## SSH Key Setup for Deployments

To deploy to your server, Jenkins needs SSH access:

### 1. Generate SSH Key in Jenkins

```bash
docker exec -it jenkins ssh-keygen -t rsa -b 4096 -f /var/jenkins_home/.ssh/id_rsa -N ""
```

### 2. Copy Public Key to Deployment Server

```bash
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub
```

Add this key to your server's `~/.ssh/authorized_keys`

### 3. Add SSH Credentials in Jenkins

1. Go to Jenkins → Manage Jenkins → Credentials
2. Add new SSH credential with the private key
3. ID: `deployment-ssh-key`

## Docker Access

Jenkins has access to the Docker daemon via the mounted socket. This allows it to:
- Build Docker images
- Push images to registries
- Deploy containers

## Environment Variables

Jenkins can access these environment variables from your `.env` file:
- `DOMAIN` - Your main domain
- `DOCKER_NETWORK` - Docker network name (default: web)
- All application-specific variables

## Plugins Installed

See `plugins.txt` for the complete list. Key plugins include:
- Git & GitHub integration
- Docker pipeline support
- Blue Ocean UI
- Configuration as Code
- Workflow aggregator (Pipeline)

## Troubleshooting

### Jenkins not starting
```bash
docker logs jenkins
```

### Reset Jenkins admin password
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Rebuild Jenkins
```bash
cd infrastructure/jenkins
docker-compose down -v
docker-compose up -d
```

## Security Notes

1. **Change default password**: Always set a strong `JENKINS_ADMIN_PASSWORD`
2. **SSL/TLS**: Traefik handles SSL termination
3. **Firewall**: Port 50000 is for Jenkins agents (close if not using)
4. **Credentials**: Store sensitive data in Jenkins credentials store

## Architecture

```
┌─────────────┐
│   Traefik   │ (SSL/TLS, Reverse Proxy)
└──────┬──────┘
       │
┌──────▼──────┐
│   Jenkins   │ (CI/CD Server)
└──────┬──────┘
       │
┌──────▼──────┐
│ Docker DinD │ (Docker in Docker)
└─────────────┘
```

## Backup

Jenkins data is stored in the `jenkins-data` Docker volume. To backup:

```bash
docker run --rm -v jenkins-data:/data -v $(pwd):/backup alpine tar czf /backup/jenkins-backup.tar.gz -C /data .
```

To restore:

```bash
docker run --rm -v jenkins-data:/data -v $(pwd):/backup alpine tar xzf /backup/jenkins-backup.tar.gz -C /data
```

## Next Steps

1. Add `Jenkinsfile` to each application repository
2. Configure GitHub webhooks
3. Set up Docker registry credentials (if using private registry)
4. Configure notification settings (email, Slack, etc.)
5. Set up backup automation
