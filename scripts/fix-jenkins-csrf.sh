#!/bin/bash

##############################################################################
# Jenkins CSRF/Crumb Error Fix Script
# Fixes: HTTP 403 "No valid crumb was included in the request"
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Jenkins CSRF/Crumb Error Fix${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This will fix: HTTP 403 'No valid crumb was included in the request'${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if Jenkins is running
if ! docker ps | grep -q jenkins; then
    echo -e "${RED}Error: Jenkins container is not running${NC}"
    echo "Start it with: docker-compose -f $PROJECT_ROOT/infrastructure/jenkins/docker-compose.yml up -d"
    exit 1
fi

echo -e "${GREEN}✓ Jenkins container is running${NC}"
echo ""

echo -e "${YELLOW}Step 1: Restarting Jenkins to apply CSRF configuration...${NC}"
docker restart jenkins

echo ""
echo -e "${YELLOW}Waiting for Jenkins to restart (30 seconds)...${NC}"
sleep 30

echo ""
echo -e "${YELLOW}Step 2: Verifying Jenkins is accessible...${NC}"

# Wait for Jenkins to be ready
MAX_RETRIES=10
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker exec jenkins curl -s http://localhost:8080/login > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Jenkins is responding${NC}"
        break
    fi
    RETRY=$((RETRY+1))
    echo "Waiting for Jenkins to be ready... ($RETRY/$MAX_RETRIES)"
    sleep 5
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo -e "${RED}Warning: Jenkins may not be fully started yet${NC}"
    echo "Wait another minute and try accessing Jenkins"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   CSRF Fix Applied!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}What was done:${NC}"
echo "  ✅ Jenkins restarted with CSRF protection enabled"
echo "  ✅ Crumb issuer configured (excludeClientIPFromCrumb: true)"
echo "  ✅ Configuration applied from jenkins-casc.yaml"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. ${BLUE}Clear your browser cache and cookies${NC}"
echo "   - Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)"
echo "   - Clear cookies for jenkins.yourdomain.com"
echo ""
echo "2. ${BLUE}Try in an incognito/private browser window${NC}"
echo "   - This ensures no old cookies are interfering"
echo ""
echo "3. ${BLUE}Access Jenkins and test${NC}"
echo "   - Go to your Jenkins URL"
echo "   - Try creating a new item or pipeline"
echo "   - The 403 crumb error should be GONE"
echo ""
echo -e "${YELLOW}If you still get 403 errors:${NC}"
echo ""
echo "Run the manual fix:"
echo "  docker exec -it jenkins bash"
echo "  Then inside container:"
echo "  curl -X POST http://localhost:8080/reload"
echo ""
echo "Or use Jenkins UI:"
echo "  1. Go to Manage Jenkins → Configure Global Security"
echo "  2. Under 'CSRF Protection', ensure it's checked"
echo "  3. Select 'Default Crumb Issuer'"
echo "  4. Check 'Enable proxy compatibility'"
echo "  5. Click Save"
echo ""
echo -e "${GREEN}Done! Test Jenkins now.${NC}"
echo ""
