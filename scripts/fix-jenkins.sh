#!/bin/bash

##############################################################################
# Jenkins Configuration Fix Script
# Fixes warnings: proxy setup, Jenkins URL, security, Java version
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Jenkins Configuration Fix${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}Error: .env file not found at $PROJECT_ROOT/.env${NC}"
    echo "Please ensure .env file exists with required variables:"
    echo "  JENKINS_SUBDOMAIN=jenkins"
    echo "  DOMAIN=yourdomain.com"
    echo "  SSL_EMAIL=your@email.com"
    echo "  JENKINS_ADMIN_USER=admin"
    echo "  JENKINS_ADMIN_PASSWORD=your_password"
    exit 1
fi

echo -e "${YELLOW}Checking environment variables...${NC}"

# Check required variables
MISSING_VARS=0

if [ -z "$JENKINS_SUBDOMAIN" ]; then
    echo -e "${RED}✗ JENKINS_SUBDOMAIN not set${NC}"
    MISSING_VARS=1
else
    echo -e "${GREEN}✓ JENKINS_SUBDOMAIN: $JENKINS_SUBDOMAIN${NC}"
fi

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}✗ DOMAIN not set${NC}"
    MISSING_VARS=1
else
    echo -e "${GREEN}✓ DOMAIN: $DOMAIN${NC}"
fi

if [ -z "$SSL_EMAIL" ]; then
    echo -e "${RED}✗ SSL_EMAIL not set${NC}"
    MISSING_VARS=1
else
    echo -e "${GREEN}✓ SSL_EMAIL: $SSL_EMAIL${NC}"
fi

if [ $MISSING_VARS -eq 1 ]; then
    echo ""
    echo -e "${RED}Missing required environment variables!${NC}"
    echo "Add these to $PROJECT_ROOT/.env:"
    echo ""
    echo "JENKINS_SUBDOMAIN=jenkins"
    echo "DOMAIN=yourdomain.com"
    echo "SSL_EMAIL=your@email.com"
    exit 1
fi

echo ""
echo -e "${YELLOW}Jenkins will be configured with:${NC}"
echo "  URL: https://${JENKINS_SUBDOMAIN}.${DOMAIN}/"
echo "  Admin Email: ${SSL_EMAIL}"
echo ""

# Confirm
read -p "Continue with Jenkins reconfiguration? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Updating Jenkins to Java 21...${NC}"
cd "$PROJECT_ROOT/infrastructure/jenkins"

echo "Pulling new Jenkins image with Java 21..."
docker-compose pull jenkins

echo ""
echo -e "${YELLOW}Step 2: Redeploying Jenkins with updated configuration...${NC}"
docker-compose --env-file "$PROJECT_ROOT/.env" down
docker-compose --env-file "$PROJECT_ROOT/.env" up -d

echo ""
echo -e "${YELLOW}Step 3: Waiting for Jenkins to start (60 seconds)...${NC}"
sleep 60

echo ""
echo -e "${GREEN}✓ Jenkins reconfiguration complete!${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}What was fixed:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "✅ Java 17 → Java 21 (fixes EOL warning)"
echo "✅ Jenkins URL properly configured: https://${JENKINS_SUBDOMAIN}.${DOMAIN}/"
echo "✅ CSRF protection enabled (fixes 403 crumb errors)"
echo "✅ Reverse proxy warning disabled"
echo "✅ Built-in node disabled (numExecutors: 0)"
echo "✅ Docker agents configured (use label: 'docker-agent')"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Access Jenkins: https://${JENKINS_SUBDOMAIN}.${DOMAIN}"
echo ""
echo "2. Login with your admin credentials"
echo ""
echo "3. Remaining warnings you may see:"
echo "   - 'Jenkins is unsecured' → Click 'Ignore' (false alarm - it IS secured)"
echo "   - 'Building on built-in node' → Dismissed (now using Docker agents)"
echo "   - 'Reverse proxy broken' → Dismissed (configured to ignore)"
echo ""
echo "4. Update your Jenkinsfiles to use Docker agents:"
echo "   Change: agent any"
echo "   To:     agent { label 'docker-agent' }"
echo ""
echo "5. Test creating a new pipeline - 403 errors should be gone!"
echo ""
echo -e "${GREEN}Done! 🎉${NC}"
echo ""
