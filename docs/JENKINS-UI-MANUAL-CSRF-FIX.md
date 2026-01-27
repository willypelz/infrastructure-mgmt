# Jenkins CSRF Error - Manual UI Fix Guide

## THE PROBLEM

You're getting 403 CSRF errors even when trying to configure Jenkins itself. This is a catch-22 situation where you need to configure CSRF protection but can't because CSRF protection isn't working.

## SOLUTION: Bypass via Jenkins Container

Since you can't use the UI due to CSRF errors, we'll configure Jenkins directly from inside the container.

### Method 1: Direct Configuration File Edit (RECOMMENDED)

**Step 1: Access Jenkins container**
```bash
docker exec -it jenkins bash
```

**Step 2: Create CSRF configuration script**
```bash
cat > /tmp/fix-csrf.groovy << 'EOFGROOVY'
import jenkins.model.Jenkins
import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.instance

// Enable CSRF with proxy compatibility
def crumbIssuer = new DefaultCrumbIssuer(true)
instance.setCrumbIssuer(crumbIssuer)

// Set Jenkins URL
def locationConfig = instance.getDescriptor("jenkins.model.JenkinsLocationConfiguration")
locationConfig.setUrl("https://jenkins.gmcloudworks.org/")
locationConfig.setAdminAddress("pelumiasefon@gmail.com")
locationConfig.save()

instance.save()

println "✅ CSRF Protection enabled"
println "✅ Jenkins URL set to: https://jenkins.gmcloudworks.org/"
println "✅ Admin email set to: pelumiasefon@gmail.com"
EOFGROOVY
```

**Step 3: Run the Groovy script**
```bash
java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar \
    -s http://localhost:8080/ \
    groovy /tmp/fix-csrf.groovy
```

If that fails with authentication error, try:

```bash
# Find jenkins home
cd /var/jenkins_home

# Run script via init.groovy.d (runs on startup)
mkdir -p init.groovy.d
cp /tmp/fix-csrf.groovy init.groovy.d/
```

**Step 4: Exit container and restart Jenkins**
```bash
exit
docker restart jenkins
```

**Step 5: Wait 45 seconds**
```bash
sleep 45
```

**Step 6: Clear browser cache and test**
- Clear ALL browser cache (Ctrl+Shift+Delete)
- Open incognito window
- Access: https://jenkins.gmcloudworks.org/
- Login and try configuring

---

### Method 2: Edit config.xml Directly

If Method 1 doesn't work, directly edit the configuration file:

**Step 1: Stop Jenkins**
```bash
docker stop jenkins
```

**Step 2: Edit config.xml**
```bash
docker run --rm -v jenkins-data:/data -it alpine sh -c "
  cd /data
  
  # Backup first
  cp config.xml config.xml.backup
  
  # Check if crumbIssuer exists
  if grep -q 'crumbIssuer' config.xml; then
    echo 'Crumb issuer already exists'
  else
    # Add crumbIssuer before </hudson>
    sed -i 's|</hudson>|  <crumbIssuer class=\"hudson.security.csrf.DefaultCrumbIssuer\">\n    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>\n  </crumbIssuer>\n</hudson>|' config.xml
  fi
  
  # Also ensure Jenkins URL is set
  if ! grep -q 'jenkinsUrl' config.xml; then
    sed -i 's|</hudson>|  <jenkinsUrl>https://jenkins.gmcloudworks.org/</jenkinsUrl>\n</hudson>|' config.xml
  fi
  
  echo 'Configuration updated!'
  cat config.xml | grep -A 2 crumbIssuer
"
```

**Step 3: Start Jenkins**
```bash
docker start jenkins
```

**Step 4: Wait and test**
```bash
sleep 45
```

---

### Method 3: Reset Jenkins and Reconfigure

If all else fails, reset Jenkins to clean state:

**Step 1: Backup current config**
```bash
docker exec jenkins tar czf /tmp/jenkins-backup.tar.gz /var/jenkins_home/jobs /var/jenkins_home/users
docker cp jenkins:/tmp/jenkins-backup.tar.gz ./jenkins-backup-$(date +%Y%m%d).tar.gz
```

**Step 2: Stop and remove Jenkins**
```bash
cd /root/appdeployment/infrastructure/jenkins
docker-compose down
```

**Step 3: Remove config but keep data**
```bash
docker exec jenkins bash -c "rm -f /var/jenkins_home/config.xml"
```

**Step 4: Restart with clean config**
```bash
docker-compose --env-file /root/appdeployment/.env up -d
```

This will regenerate config from jenkins-casc.yaml which has CSRF properly configured.

---

## VERIFICATION

After applying any method above:

### 1. Check CSRF is enabled
```bash
docker exec jenkins cat /var/jenkins_home/config.xml | grep -A 2 crumbIssuer
```

Should show:
```xml
<crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
  <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
</crumbIssuer>
```

### 2. Check Jenkins URL
```bash
docker exec jenkins cat /var/jenkins_home/config.xml | grep jenkinsUrl
```

Should show:
```xml
<jenkinsUrl>https://jenkins.gmcloudworks.org/</jenkinsUrl>
```

### 3. Test in browser
- **IMPORTANT:** Clear ALL browser cache first!
- Open incognito/private window
- Go to: https://jenkins.gmcloudworks.org/
- Login
- Go to: Manage Jenkins → System
- Try to click "Save"
- Should work without 403 error! ✅

---

## IMPORTANT: Browser Cache

Even after fixing Jenkins, you MUST clear browser cache:

**Chrome/Firefox:**
1. Press Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
2. Time range: "All time"
3. Check: "Cookies and other site data"
4. Click: "Clear data"

**Or just use:**
- Incognito/Private browsing window (fresh session)

---

## WHY THIS HAPPENS

1. Jenkins starts without CSRF protection configured
2. Your browser caches this state
3. Configuration as Code (CasC) should apply CSRF config
4. But if CasC doesn't load properly, CSRF stays disabled
5. You try to configure via UI → 403 error
6. Catch-22: Can't configure CSRF because CSRF isn't configured

**Solution:** Configure directly via container (bypassing UI)

---

## WHAT WE'RE CONFIGURING

```groovy
// Enable CSRF Protection
crumbIssuer = new DefaultCrumbIssuer(true)
// true = excludeClientIPFromCrumb (required for reverse proxy)

// Set Jenkins URL (required for webhooks, emails, etc.)
jenkinsUrl = "https://jenkins.gmcloudworks.org/"

// Set admin email
adminAddress = "pelumiasefon@gmail.com"
```

---

## QUICK COMMAND REFERENCE

**Check if Jenkins is running:**
```bash
docker ps | grep jenkins
```

**View Jenkins logs:**
```bash
docker logs jenkins --tail 100
```

**Restart Jenkins:**
```bash
docker restart jenkins
```

**Access Jenkins container:**
```bash
docker exec -it jenkins bash
```

**Check CSRF config:**
```bash
docker exec jenkins cat /var/jenkins_home/config.xml | grep -A 2 crumbIssuer
```

---

## RECOMMENDED: Use Method 1

Method 1 is the cleanest and most reliable. It:
- Configures CSRF properly
- Sets Jenkins URL
- Sets admin email
- Doesn't require stopping Jenkins
- Can be verified immediately

---

## IF NOTHING WORKS

Contact me with:
```bash
# Send these outputs:
docker logs jenkins --tail 50
docker exec jenkins cat /var/jenkins_home/config.xml | head -20
docker exec jenkins ls -la /var/jenkins_home/init.groovy.d/
```

---

**Ready to fix? Start with Method 1!**
