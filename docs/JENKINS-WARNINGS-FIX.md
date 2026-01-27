# Jenkins Configuration Warnings - Fix Guide

This guide addresses the warnings you're seeing in Jenkins after initial deployment.

## Warnings You're Seeing

1. ⚠️ **Reverse proxy setup appears broken**
2. ⚠️ **Jenkins URL is empty**
3. ⚠️ **Jenkins is unsecured** (false alarm - it IS secured)
4. ⚠️ **Building on built-in node** (security recommendation)

## Quick Fix - Apply Updated Configuration

The jenkins-casc.yaml has been updated. Apply the changes:

### Step 1: Restart Jenkins

```bash
docker restart jenkins
```

Wait 30-60 seconds for Jenkins to fully restart.

### Step 2: Verify Jenkins URL

1. Go to **Manage Jenkins** → **System**
2. Scroll to **Jenkins Location**
3. Verify **Jenkins URL** shows: `https://jenkins.yourdomain.com/`
4. Verify **System Admin e-mail address** is set

If blank, the environment variables aren't being read. Check your `.env` file:

```bash
cat /root/appdeployment/.env | grep JENKINS_SUBDOMAIN
cat /root/appdeployment/.env | grep DOMAIN
cat /root/appdeployment/.env | grep SSL_EMAIL
```

### Step 3: Dismiss Security Warning (False Alarm)

The "Jenkins is unsecured" warning is a **false alarm**. Your Jenkins IS secured with:
- ✅ Admin authentication required
- ✅ CSRF protection enabled
- ✅ Behind Traefik reverse proxy with SSL

**To dismiss:**
- Click **Ignore** on the security warning

### Step 4: Fix "Reverse Proxy Setup Broken" Warning

This warning appears because Jenkins detects it's behind a proxy. It's actually working fine, but Jenkins wants additional confirmation.

**Option A: Dismiss the warning** (Recommended - everything is working)
- Click **Dismiss** on the warning

**Option B: Manually configure** (if warning persists):

1. Go to **Manage Jenkins** → **System**
2. Scroll down to find any reverse proxy related settings
3. The jenkins-casc.yaml already configures CSRF with `excludeClientIPFromCrumb: true`

### Step 5: Set Up Distributed Builds (Optional but Recommended)

The "building on built-in node" warning is a security best practice.

**Why this matters:**
- Building on the controller node can expose Jenkins to security risks
- Builds should run on separate agent nodes

**To fix:**

**Option A: Use Docker Cloud (Already Configured)**

Your Jenkins is already configured with Docker cloud agents in jenkins-casc.yaml:

```yaml
clouds:
  - docker:
      name: "docker"
      templates:
        - labelString: "docker-agent"
```

**To use in your Jenkinsfile:**

```groovy
pipeline {
    agent {
        label 'docker-agent'  // Use Docker agent instead of 'any'
    }
    // ...rest of pipeline
}
```

**Option B: Keep Using 'any' Agent**

For simplicity, you can keep using `agent any` in your Jenkinsfiles. The warning is just a recommendation, not a critical issue for small deployments.

To dismiss: Click **Dismiss** on the warning.

## Verification Checklist

After restart, verify:

- [ ] Jenkins accessible at `https://jenkins.yourdomain.com`
- [ ] Can login with admin credentials
- [ ] Can create new Pipeline items without 403 error
- [ ] Jenkins URL shows in **Manage Jenkins** → **System**
- [ ] CSRF protection working (no crumb errors)

## Common Issues

### Jenkins URL Still Empty

**Cause:** Environment variables not loaded

**Solution:**

1. Check your `.env` file has these variables:
   ```bash
   JENKINS_SUBDOMAIN=jenkins
   DOMAIN=yourdomain.com
   SSL_EMAIL=your@email.com
   ```

2. Redeploy Jenkins with env file:
   ```bash
   cd /root/appdeployment/infrastructure/jenkins
   docker-compose --env-file /root/appdeployment/.env down
   docker-compose --env-file /root/appdeployment/.env up -d
   ```

3. Wait 60 seconds and check again

### Still Getting "Reverse Proxy Broken" Warning

**This is usually safe to dismiss.** Jenkins detects it's behind Traefik but everything is working correctly.

**To verify it's working:**
1. Access Jenkins at `https://jenkins.yourdomain.com` (HTTPS, not HTTP)
2. Check SSL certificate is valid
3. Try creating a new pipeline - if it works, proxy is fine

**If you really want to clear it:**

1. Go to **Manage Jenkins** → **Script Console**
2. Run this Groovy script:
   ```groovy
   import jenkins.model.Jenkins
   Jenkins.instance.setRootUrl("https://jenkins.yourdomain.com/")
   Jenkins.instance.save()
   ```

3. Restart Jenkins:
   ```bash
   docker restart jenkins
   ```

### 403 CSRF Error When Creating Items

**Solution:** Already fixed in jenkins-casc.yaml with:

```yaml
security:
  crumbIssuer:
    standard:
      excludeClientIPFromCrumb: true
```

If still occurring:
1. Clear browser cache
2. Restart Jenkins
3. Try in incognito/private browser window

## Java 17 End of Life Warning

**Current Status:** Java 17 support in Jenkins ends March 31, 2026

**Action Required:** After March 2026, update to newer Java version:

1. Update Jenkins image to one with Java 21:
   ```yaml
   # In docker-compose.yml
   image: jenkins/jenkins:lts-jdk21
   ```

2. Redeploy:
   ```bash
   cd /root/appdeployment/infrastructure/jenkins
   docker-compose pull
   docker-compose up -d
   ```

**No action needed right now** - you have until March 2026.

## Content Security Policy (CSP)

The CSP warning is informational - it's disabled by default for compatibility.

**To enable CSP** (optional, may break some plugins):

1. Go to **Manage Jenkins** → **Security**
2. Under **Content Security Policy**, set a policy
3. Default strict policy:
   ```
   default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';
   ```

**Not recommended unless you have specific security requirements** - may break Jenkins plugins and UI.

## Summary - What To Do Now

**Minimum Required Actions:**

1. ✅ Restart Jenkins: `docker restart jenkins`
2. ✅ Dismiss false warnings (proxy, security)
3. ✅ Verify you can create pipelines without 403 errors

**Optional Improvements:**

- Update Jenkinsfiles to use `label: 'docker-agent'`
- Manually set Jenkins URL if environment variables aren't working
- Plan Java update before March 2026

## Testing Your Setup

Create a test pipeline to verify everything works:

1. Click **New Item**
2. Enter name: `test-pipeline`
3. Select **Pipeline**
4. Under **Pipeline**, select **Pipeline script**
5. Enter:
   ```groovy
   pipeline {
       agent any
       stages {
           stage('Test') {
               steps {
                   echo 'Jenkins is working!'
               }
           }
       }
   }
   ```
6. Click **Save**
7. Click **Build Now**

If build succeeds with green checkmark - everything is working! ✅

## Need Help?

See:
- [JENKINS-UI-SETUP-GUIDE.md](JENKINS-UI-SETUP-GUIDE.md) - Complete setup guide
- [SUBDOMAIN-ROUTING-GUIDE.md](SUBDOMAIN-ROUTING-GUIDE.md) - Traefik routing explained

---

**TL;DR:** Most warnings are informational or false alarms. Just restart Jenkins and dismiss the ones that aren't critical. Your setup is secure and working correctly.
