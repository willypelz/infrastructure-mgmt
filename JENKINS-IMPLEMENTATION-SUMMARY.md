# Complete Setup Summary - Jenkins CI/CD Integration

## ✅ What Has Been Created

### 1. Jenkins Infrastructure (`infrastructure/jenkins/`)

**Files Created:**
- `docker-compose.yml` - Jenkins and Docker-in-Docker services
- `jenkins-casc.yaml` - Configuration as Code for automated setup
- `plugins.txt` - Required Jenkins plugins
- `README.md` - Detailed documentation

### 2. Example Jenkinsfiles (`infrastructure/jenkins/jenkinsfiles/`)

**Templates for each application:**
- `Jenkinsfile.nodejs` - Node.js Express API pipeline
- `Jenkinsfile.react` - React SPA pipeline
- `Jenkinsfile.laravel` - PHP Laravel pipeline
- `Jenkinsfile.flask` - Flask API pipeline
- `Jenkinsfile.wordpress` - WordPress pipeline

### 3. Deployment Script Updates

**Modified `scripts/deploy.sh`:**
- Added `--jenkins` option to deploy Jenkins
- Added Jenkins to `--infrastructure` deployment
- New `deploy_jenkins()` function

### 4. Setup Helper Script

**Created `scripts/setup-jenkins.sh`:**
- Generates SSH keys for deployments
- Displays access credentials
- Shows webhook URL
- Tests SSH connectivity

### 5. Documentation

**New Documentation Files:**
- `docs/JENKINS-QUICK-START.md` - Quick reference guide
- `docs/JENKINS-SETUP.md` - Detailed step-by-step setup
- `infrastructure/jenkins/README.md` - Jenkins-specific documentation

**Updated Files:**
- `.env.example` - Added Jenkins environment variables
- `README.md` - Added Jenkins section and updated architecture

---

## 🎯 What You Need To Do Now

### Step 1: Deploy Jenkins

On your **deployment server**:

```bash
# 1. Update your .env file
cd /root/infrastructure-mgmt
nano .env

# Add these lines:
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=YourSecurePasswordHere123!

# 2. Deploy Jenkins
./scripts/deploy.sh --jenkins

# 3. Run setup helper
./scripts/setup-jenkins.sh
```

### Step 2: Configure DNS

Add this DNS A record to your domain:

| Subdomain | Type | Value |
|-----------|------|-------|
| jenkins | A | Your Server IP |

Wait 5-10 minutes for DNS propagation.

### Step 3: Access Jenkins

Open your browser:
```
https://jenkins.yourdomain.com
```

Login with:
- Username: `admin` (or what you set in .env)
- Password: (from your .env file)

### Step 4: Add Credentials in Jenkins

#### 4.1 Add Deployment Server Host

1. Go to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**
4. Select **Secret text**
5. Fill in:
   - Secret: `your-server-ip-address`
   - ID: `deployment-server-host`
   - Description: `Deployment Server Host`
6. Click **OK**

#### 4.2 Add SSH Key

1. Get the private key:
```bash
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa
```

2. In Jenkins UI:
   - Go to **Manage Jenkins** → **Credentials**
   - Click **System** → **Global credentials**
   - Click **Add Credentials**
   - Select **SSH Username with private key**
   - Fill in:
     - ID: `deployment-ssh-key`
     - Username: `root` (or your deployment user)
     - Private Key: Paste the entire key including header/footer
   - Click **OK**

3. Add public key to deployment server:
```bash
# Get public key
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub

# Add to authorized_keys on deployment server
echo "paste-public-key-here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 5: Add Jenkinsfile to Each Repository

For **each** of your 5 GitHub repositories, add a Jenkinsfile:

#### Repository: nodejs-express-api

```bash
cd /path/to/nodejs-express-api
curl https://raw.githubusercontent.com/willypelz/appdeployment/main/infrastructure/jenkins/jenkinsfiles/Jenkinsfile.nodejs -o Jenkinsfile

# Or manually copy from infrastructure/jenkins/jenkinsfiles/Jenkinsfile.nodejs

git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

#### Repository: react-spa

```bash
cd /path/to/react-spa
# Copy Jenkinsfile.react content to Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

#### Repository: php-laravel

```bash
cd /path/to/php-laravel
# Copy Jenkinsfile.laravel content to Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

#### Repository: flask-api

```bash
cd /path/to/flask-api
# Copy Jenkinsfile.flask content to Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

#### Repository: wordpress-docker-app

```bash
cd /path/to/wordpress-docker-app
# Copy Jenkinsfile.wordpress content to Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins CI/CD pipeline"
git push
```

### Step 6: Configure GitHub Webhooks

For **each** repository:

1. Go to repository on GitHub
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL:** `https://jenkins.yourdomain.com/github-webhook/`
   - **Content type:** `application/json`
   - **Which events:** Just the push event
   - **Active:** ✓ (checked)
4. Click **Add webhook**

Repeat for all 5 repositories:
- https://github.com/willypelz/wordpress-docker-app
- https://github.com/willypelz/nodejs-express-api
- https://github.com/willypelz/php-laravel
- https://github.com/willypelz/react-spa
- https://github.com/willypelz/flask-api

### Step 7: Test Your First Deployment

1. Go to Jenkins: `https://jenkins.yourdomain.com`
2. Click on **Applications** folder
3. Click on one of the pipelines (e.g., **nodejs-express-api**)
4. Click **Build Now**
5. Watch the build progress in the console output

If successful, try automatic deployment:
```bash
cd /path/to/nodejs-express-api
echo "Test" >> README.md
git add README.md
git commit -m "Test Jenkins auto-deployment"
git push
```

Jenkins should automatically start a build!

---

## 📋 Complete Environment Variables

Add these to your `.env` file:

```bash
# Domain Configuration
DOMAIN=yourdomain.com
SSL_EMAIL=your-email@example.com

# Jenkins Configuration
JENKINS_SUBDOMAIN=jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=change_this_secure_password

# ... rest of your existing variables
```

---

## 🔧 Troubleshooting Common Issues

### Issue 1: "network web was found but has incorrect label"

**Solution:**
```bash
./scripts/deploy.sh --traefik  # This will fix the network
./scripts/deploy.sh --jenkins  # Then redeploy Jenkins
```

### Issue 2: Jenkins not accessible after deployment

**Check:**
```bash
# Is Jenkins running?
docker ps | grep jenkins

# Check logs
docker logs jenkins

# Is DNS configured?
nslookup jenkins.yourdomain.com
```

### Issue 3: Build fails with "SSH connection failed"

**Solution:**
1. Verify SSH key is in authorized_keys:
```bash
cat ~/.ssh/authorized_keys | grep jenkins
```

2. Test from Jenkins container:
```bash
docker exec jenkins ssh root@your-server-ip "echo 'Connection successful'"
```

3. Check firewall allows SSH from Jenkins server

### Issue 4: GitHub webhook not triggering builds

**Check:**
1. In GitHub repo → Settings → Webhooks → Recent Deliveries
2. Look for error messages
3. Verify webhook URL is correct: `https://jenkins.yourdomain.com/github-webhook/`
4. Ensure Jenkins is publicly accessible

### Issue 5: Docker build fails in Jenkins

**Check Dockerfile exists in repository:**
```bash
# In your app repository
ls -la Dockerfile
```

**Verify package.json/composer.json is valid:**
```bash
# For Node.js
node -e "JSON.parse(require('fs').readFileSync('package.json'))"

# For PHP
composer validate
```

---

## 🎓 Understanding the Pipeline

### Pipeline Stages

1. **Checkout** - Pulls latest code from GitHub
2. **Validate** - Checks for required files and syntax
3. **Build** - Creates Docker image with version tag
4. **Test** - Runs application tests (if available)
5. **Deploy** - Transfers image and deploys to server
6. **Health Check** - Verifies container is running

### Pipeline Flow

```
GitHub Push → Webhook → Jenkins
                           ↓
                    Checkout Code
                           ↓
                    Validate Files
                           ↓
                  Build Docker Image
                           ↓
                      Run Tests
                           ↓
              Transfer Image to Server
                           ↓
                Deploy with Script
                           ↓
                   Health Check
                           ↓
             ✅ Success / ❌ Failure
```

---

## 📚 Documentation Reference

| Document | Purpose |
|----------|---------|
| `docs/JENKINS-QUICK-START.md` | Quick reference for common tasks |
| `docs/JENKINS-SETUP.md` | Detailed step-by-step setup guide |
| `infrastructure/jenkins/README.md` | Jenkins-specific documentation |
| `README.md` | Main project documentation |

---

## ✨ What's Next?

### Immediate Tasks
- [x] Deploy Jenkins infrastructure
- [ ] Configure DNS for jenkins subdomain
- [ ] Add credentials in Jenkins UI
- [ ] Add Jenkinsfile to repositories
- [ ] Configure GitHub webhooks
- [ ] Test first deployment

### Future Enhancements
- [ ] Add Slack/Email notifications
- [ ] Set up staging/production environments
- [ ] Configure automated testing
- [ ] Add rollback capabilities
- [ ] Set up Jenkins backup automation
- [ ] Add code quality checks (SonarQube)
- [ ] Implement blue-green deployments

---

## 🆘 Getting Help

If you encounter issues:

1. **Check logs:** `docker logs jenkins -f`
2. **Review documentation:** See files listed above
3. **Verify configuration:** Check `jenkins-casc.yaml`
4. **Test manually:** Try deploying without Jenkins first
5. **Check GitHub webhook deliveries:** Look for errors

---

## 🎉 Summary

You now have a complete CI/CD pipeline with:

✅ **Jenkins server** running with Docker support
✅ **Pre-configured pipelines** for all 5 applications
✅ **GitHub webhook integration** for automatic deployments
✅ **SSH-based deployment** to your server
✅ **Automated testing and health checks**
✅ **Configuration as Code** for reproducible setup

Every time you push to GitHub, Jenkins will automatically:
1. Build a new Docker image
2. Run tests
3. Deploy to your server
4. Verify the deployment

**Happy Deploying! 🚀**
