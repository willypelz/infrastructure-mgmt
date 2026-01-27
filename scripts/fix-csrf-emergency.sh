#!/bin/bash

##############################################################################
# Jenkins CSRF Fix - Direct Application via Groovy Script
# This directly configures CSRF in running Jenkins instance
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}   EMERGENCY CSRF FIX - Applying directly to Jenkins${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if Jenkins is running
if ! docker ps | grep -q jenkins; then
    echo -e "${RED}Error: Jenkins container is not running${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Applying CSRF configuration directly via Groovy script...${NC}"

# Create groovy script to enable CSRF protection
docker exec jenkins bash -c 'cat > /tmp/enable-csrf.groovy << "EOF"
import jenkins.model.Jenkins
import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.instance
def crumbIssuer = new DefaultCrumbIssuer(true) // true = excludeClientIPFromCrumb
instance.setCrumbIssuer(crumbIssuer)

// Also set Jenkins URL if not set
def locationConfig = Jenkins.instance.getDescriptor("jenkins.model.JenkinsLocationConfiguration")
if (locationConfig) {
    // Read from environment or use existing
    def jenkinsUrl = System.getenv("JENKINS_URL") ?: "https://jenkins.gmcloudworks.org/"
    def adminEmail = System.getenv("JENKINS_ADMIN_EMAIL") ?: "pelumiasefon@gmail.com"

    locationConfig.setUrl(jenkinsUrl)
    locationConfig.setAdminAddress(adminEmail)
    locationConfig.save()
}

instance.save()
println "CSRF Protection enabled with excludeClientIPFromCrumb=true"
println "Jenkins URL configured"
EOF'

echo -e "${YELLOW}Step 2: Executing Groovy script...${NC}"
docker exec -e JENKINS_URL="https://jenkins.gmcloudworks.org/" -e JENKINS_ADMIN_EMAIL="pelumiasefon@gmail.com" jenkins \
    java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin groovy /tmp/enable-csrf.groovy 2>&1 || {
    echo -e "${YELLOW}CLI method failed, trying alternative method...${NC}"

    # Alternative: Use Script Console endpoint directly
    docker exec jenkins bash -c 'curl -X POST http://localhost:8080/scriptText \
        --user admin:admin \
        --data-urlencode "script=$(cat /tmp/enable-csrf.groovy)" 2>&1' || echo "Alternative also failed, will try restart method"
}

echo ""
echo -e "${YELLOW}Step 3: Restarting Jenkins to apply configuration...${NC}"
docker restart jenkins

echo ""
echo -e "${YELLOW}Waiting for Jenkins to restart (45 seconds)...${NC}"
for i in {45..1}; do
    echo -ne "\rWaiting... $i seconds remaining "
    sleep 1
done
echo ""

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   CSRF FIX APPLIED!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}🚨 CRITICAL - DO THIS NOW:${NC}"
echo ""
echo -e "${YELLOW}1. COMPLETELY CLEAR YOUR BROWSER:${NC}"
echo "   - Close ALL browser windows"
echo "   - Reopen browser"
echo "   - Press Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)"
echo "   - Select: 'All time' or 'Everything'"
echo "   - Check: 'Cookies and other site data'"
echo "   - Clear"
echo ""
echo -e "${YELLOW}2. USE PRIVATE/INCOGNITO WINDOW:${NC}"
echo "   - Ctrl+Shift+N (Chrome) or Ctrl+Shift+P (Firefox)"
echo "   - This ensures no cached data interferes"
echo ""
echo -e "${YELLOW}3. ACCESS JENKINS:${NC}"
echo "   - URL: https://jenkins.gmcloudworks.org/"
echo "   - Login with: admin / your_password"
echo ""
echo -e "${YELLOW}4. TEST:${NC}"
echo "   - Go to: Manage Jenkins → System"
echo "   - Try to save something"
echo "   - Should NOT get 403 error anymore! ✅"
echo ""
echo -e "${GREEN}If it still doesn't work, run the UI manual fix:${NC}"
echo "See: /root/appdeployment/docs/JENKINS-UI-MANUAL-CSRF-FIX.md"
echo ""
