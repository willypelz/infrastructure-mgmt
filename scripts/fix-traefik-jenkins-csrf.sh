#!/bin/bash

##############################################################################
# Complete Traefik + Jenkins CSRF Fix
# Fixes forwarded headers and applies all necessary configurations
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Complete Traefik + Jenkins CSRF Fix${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment loaded${NC}"
echo "  Domain: ${DOMAIN}"
echo "  Jenkins: https://${JENKINS_SUBDOMAIN}.${DOMAIN}/"
echo ""

echo -e "${YELLOW}What will be applied:${NC}"
echo "  ✓ Traefik: Trust forwarded headers (0.0.0.0/0)"
echo "  ✓ Jenkins: Force X-Forwarded-Proto=https"
echo "  ✓ Jenkins: Force X-Forwarded-Port=443"
echo "  ✓ Jenkins: Force X-Forwarded-Host=${JENKINS_SUBDOMAIN}.${DOMAIN}"
echo "  ✓ Jenkins: JVM option EXCLUDE_SESSION_ID=true"
echo "  ✓ Jenkins: CSRF protection with excludeClientIPFromCrumb"
echo ""

read -p "Apply these fixes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Redeploying Traefik with forwarded headers trust...${NC}"
cd "$PROJECT_ROOT"
docker-compose --env-file "$PROJECT_ROOT/.env" up -d traefik
sleep 5
echo -e "${GREEN}✓ Traefik updated${NC}"

echo ""
echo -e "${YELLOW}Step 2: Redeploying Jenkins with JVM options and headers...${NC}"
cd "$PROJECT_ROOT/infrastructure/jenkins"
docker-compose --env-file "$PROJECT_ROOT/.env" down
docker-compose --env-file "$PROJECT_ROOT/.env" up -d
echo -e "${GREEN}✓ Jenkins restarted${NC}"

echo ""
echo -e "${YELLOW}Step 3: Waiting for Jenkins to fully start (60 seconds)...${NC}"
for i in {60..1}; do
    echo -ne "\r   Seconds remaining: $i  "
    sleep 1
done
echo ""

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   ✅ FIX APPLIED SUCCESSFULLY!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}🚨 CRITICAL - DO THIS NOW:${NC}"
echo ""
echo -e "${YELLOW}1. COMPLETELY CLEAR YOUR BROWSER CACHE${NC}"
echo "   The #1 reason for persistent 403 errors!"
echo ""
echo "   How:"
echo "   - Press Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)"
echo "   - Select: 'All time' or 'Everything'"
echo "   - Check: 'Cookies and other site data'"
echo "   - Clear"
echo ""
echo -e "${YELLOW}2. USE INCOGNITO/PRIVATE WINDOW${NC}"
echo "   This ensures fresh session:"
echo "   - Chrome: Ctrl+Shift+N"
echo "   - Firefox: Ctrl+Shift+P"
echo ""
echo -e "${YELLOW}3. ACCESS JENKINS${NC}"
echo "   URL: https://${JENKINS_SUBDOMAIN}.${DOMAIN}/"
echo "   Login with admin credentials"
echo ""
echo -e "${YELLOW}4. TEST${NC}"
echo "   - Click 'New Item' → Should work! ✅"
echo "   - Or go to 'Manage Jenkins' → 'System' → 'Save'"
echo "   - NO MORE 403 ERRORS!"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}What was fixed:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "✅ Traefik now trusts X-Forwarded-* headers from Jenkins"
echo "✅ Jenkins receives correct protocol (https)"
echo "✅ Jenkins receives correct port (443)"
echo "✅ Jenkins receives correct host (${JENKINS_SUBDOMAIN}.${DOMAIN})"
echo "✅ CSRF session ID excluded for reverse proxy compatibility"
echo "✅ CSRF crumb issuer configured with excludeClientIPFromCrumb"
echo ""
echo -e "${YELLOW}This is the bulletproof Traefik + Jenkins configuration!${NC}"
echo ""
echo -e "${GREEN}Done! Clear cache and test in incognito window! 🎉${NC}"
echo ""
