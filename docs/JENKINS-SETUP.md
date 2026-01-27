# Jenkins Setup Guide for Application Repositories

This guide will help you add Jenkinsfiles to each of your application repositories for automated CI/CD deployments.

## Repository Setup Instructions

You need to add a `Jenkinsfile` to the root of each repository. Example Jenkinsfiles are provided in `infrastructure/jenkins/jenkinsfiles/`.

### 1. Node.js Express API
**Repository:** https://github.com/willypelz/nodejs-express-api.git

Copy `jenkinsfiles/Jenkinsfile.nodejs` to the root of your repository as `Jenkinsfile`.

```bash
# In your nodejs-express-api repository
cp /path/to/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.nodejs ./Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### 2. React SPA
**Repository:** https://github.com/willypelz/react-spa.git

Copy `jenkinsfiles/Jenkinsfile.react` to the root of your repository as `Jenkinsfile`.

```bash
# In your react-spa repository
cp /path/to/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.react ./Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### 3. PHP Laravel
**Repository:** https://github.com/willypelz/php-laravel.git

Copy `jenkinsfiles/Jenkinsfile.laravel` to the root of your repository as `Jenkinsfile`.

```bash
# In your php-laravel repository
cp /path/to/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.laravel ./Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### 4. Flask API
**Repository:** https://github.com/willypelz/flask-api.git

Copy `jenkinsfiles/Jenkinsfile.flask` to the root of your repository as `Jenkinsfile`.

```bash
# In your flask-api repository
cp /path/to/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.flask ./Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### 5. WordPress Docker App
**Repository:** https://github.com/willypelz/wordpress-docker-app.git

Copy `jenkinsfiles/Jenkinsfile.wordpress` to the root of your repository as `Jenkinsfile`.

```bash
# In your wordpress-docker-app repository
cp /path/to/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.wordpress ./Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

## Jenkins Credentials Setup

### 1. Add Deployment Server Host Credential

1. Go to Jenkins → Manage Jenkins → Credentials
2. Click on "System" → "Global credentials"
3. Click "Add Credentials"
4. Select "Secret text"
5. Secret: `your-server-ip-or-hostname`
6. ID: `deployment-server-host`
7. Description: `Deployment Server Host`
8. Click "OK"

### 2. Add SSH Deployment Key

#### Generate SSH Key in Jenkins Container

```bash
# Enter Jenkins container
docker exec -it jenkins bash

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f /var/jenkins_home/.ssh/id_rsa -N ""

# Display public key
cat /var/jenkins_home/.ssh/id_rsa.pub
```

#### Add Public Key to Deployment Server

```bash
# On your deployment server
echo "ssh-rsa AAAA... jenkins@jenkins" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Add Private Key to Jenkins

1. Copy the private key:
   ```bash
   docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa
   ```

2. In Jenkins UI:
   - Go to Manage Jenkins → Credentials
   - Click "System" → "Global credentials"
   - Click "Add Credentials"
   - Kind: "SSH Username with private key"
   - ID: `deployment-ssh-key`
   - Username: `root` (or your deployment user)
   - Private Key: Paste the private key
   - Click "OK"

### 3. Test SSH Connection

```bash
# From Jenkins container
docker exec -it jenkins ssh root@your-deployment-server "echo 'SSH connection successful'"
```

## GitHub Webhook Setup

For each repository, configure a webhook to trigger Jenkins builds:

### Steps for Each Repository:

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL:** `https://jenkins.yourdomain.com/github-webhook/`
   - **Content type:** `application/json`
   - **Which events:** Select "Just the push event"
   - **Active:** Check this box
4. Click **Add webhook**

Repeat this for all 5 repositories:
- https://github.com/willypelz/wordpress-docker-app
- https://github.com/willypelz/nodejs-express-api
- https://github.com/willypelz/php-laravel
- https://github.com/willypelz/react-spa
- https://github.com/willypelz/flask-api

## Pipeline Customization

### Environment Variables

Each Jenkinsfile uses these environment variables:

```groovy
environment {
    APP_NAME = 'your-app-name'
    DOCKER_IMAGE = "${APP_NAME}"
    DEPLOY_USER = 'root'
    DEPLOY_HOST = credentials('deployment-server-host')
    DEPLOY_PATH = '/root/infrastructure-mgmt/apps/${APP_NAME}'
}
```

### Modify for Your Setup

If your deployment path or user is different:

1. Change `DEPLOY_USER` from `root` to your user
2. Change `DEPLOY_PATH` to match your server structure
3. Update the deployment commands in the "Deploy to Server" stage

### Add Environment-Specific Variables

For different environments (staging, production):

```groovy
environment {
    APP_NAME = 'nodejs-express-api'
    ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
    DOCKER_IMAGE = "${APP_NAME}-${ENVIRONMENT}"
    DEPLOY_HOST = "${env.BRANCH_NAME == 'main' ? 
                    credentials('prod-server-host') : 
                    credentials('staging-server-host')}"
}
```

## Testing Your Pipeline

### 1. Manual Trigger

1. Go to Jenkins dashboard
2. Navigate to **Applications** folder
3. Click on your application pipeline
4. Click **Build Now**
5. Watch the build progress

### 2. Automatic Trigger (via Git Push)

```bash
# In your application repository
git add .
git commit -m "Test Jenkins deployment"
git push
```

Jenkins should automatically start a build.

## Pipeline Stages Explained

### 1. Checkout
Pulls the latest code from your repository.

### 2. Validate
Checks for required files (package.json, composer.json, etc.)

### 3. Build Docker Image
Creates a Docker image from your Dockerfile with build number and latest tags.

### 4. Test
Runs your application tests (if available).

### 5. Deploy to Server
- Transfers Docker image to deployment server
- Deploys using your existing deployment scripts
- Handles docker-compose configuration

### 6. Health Check
Verifies that the deployed container is running.

## Troubleshooting

### Build Fails at Validation Stage

**Problem:** package.json or composer.json has syntax errors

**Solution:**
```bash
# For Node.js
node -e "JSON.parse(require('fs').readFileSync('package.json'))"

# For PHP
composer validate
```

### SSH Connection Failed

**Problem:** Jenkins can't connect to deployment server

**Solution:**
1. Verify SSH key is in authorized_keys
2. Check firewall rules
3. Test manually: `docker exec -it jenkins ssh user@host`

### Docker Image Transfer Fails

**Problem:** Image is too large or network timeout

**Solution:**
1. Use a Docker registry (Docker Hub, AWS ECR, etc.)
2. Modify Jenkinsfile to push/pull from registry instead of transfer

Example:
```groovy
stage('Push to Registry') {
    steps {
        script {
            docker.withRegistry('https://registry.example.com', 'registry-credentials') {
                docker.image("${DOCKER_IMAGE}:${BUILD_NUMBER}").push()
                docker.image("${DOCKER_IMAGE}:latest").push()
            }
        }
    }
}
```

### Build Number Not Incrementing

**Problem:** Jenkins isn't tracking builds properly

**Solution:** Use Git commit SHA instead:
```groovy
environment {
    GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
    DOCKER_IMAGE = "${APP_NAME}:${GIT_COMMIT_SHORT}"
}
```

## Advanced Configuration

### Multi-Branch Pipeline

For automatic detection of branches:

1. In Jenkins, create a "Multibranch Pipeline" instead
2. Configure to scan your GitHub organization/user
3. Each branch gets its own pipeline

### Slack/Email Notifications

Add to the `post` section:

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "Deployment successful: ${APP_NAME} #${BUILD_NUMBER}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "Deployment failed: ${APP_NAME} #${BUILD_NUMBER}"
        )
    }
}
```

### Rollback Capability

Add a rollback stage:

```groovy
stage('Rollback') {
    when {
        expression { currentBuild.result == 'FAILURE' }
    }
    steps {
        script {
            sh '''
                ssh ${DEPLOY_USER}@${DEPLOY_HOST} "
                    docker tag ${DOCKER_IMAGE}:previous ${DOCKER_IMAGE}:latest
                    cd /root/infrastructure-mgmt && ./scripts/deploy.sh --app ${APP_NAME}
                "
            '''
        }
    }
}
```

## Next Steps

1. ✅ Deploy Jenkins infrastructure
2. ✅ Add Jenkinsfiles to all repositories
3. ✅ Configure Jenkins credentials
4. ✅ Set up GitHub webhooks
5. ✅ Test deployments
6. 📝 Add monitoring and notifications
7. 📝 Set up backup for Jenkins data
8. 📝 Configure multi-environment deployments

## Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [GitHub Integration](https://plugins.jenkins.io/github/)
