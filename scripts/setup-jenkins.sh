#!/bin/bash

##############################################################################
# Jenkins Initial Setup Script
# Helps configure Jenkins after first deployment
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Jenkins Initial Setup Helper${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Jenkins is running
if ! docker ps | grep -q jenkins; then
    echo -e "${RED}Error: Jenkins container is not running${NC}"
    echo "Please deploy Jenkins first:"
    echo "  ./scripts/deploy.sh --jenkins"
    exit 1
fi

echo -e "${GREEN}✓ Jenkins container is running${NC}"
echo ""

# Generate SSH key if it doesn't exist
echo -e "${YELLOW}Setting up SSH key for deployments...${NC}"
docker exec jenkins bash -c "
    if [ ! -f /var/jenkins_home/.ssh/id_rsa ]; then
        mkdir -p /var/jenkins_home/.ssh
        ssh-keygen -t rsa -b 4096 -f /var/jenkins_home/.ssh/id_rsa -N ''
        chmod 700 /var/jenkins_home/.ssh
        chmod 600 /var/jenkins_home/.ssh/id_rsa
        echo 'SSH key generated successfully'
    else
        echo 'SSH key already exists'
    fi
"

echo ""
echo -e "${GREEN}✓ SSH key configured${NC}"
echo ""

# Display public key
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSH Public Key${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Add this public key to your deployment server's ~/.ssh/authorized_keys:"
echo ""
docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub
echo ""
echo -e "${YELLOW}To add to your server, run:${NC}"
echo "  ssh root@your-server \"echo '$(docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys\""
echo ""

# Get Jenkins initial admin password (if exists)
if docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Initial Admin Password${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "If you need the initial admin password:"
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Not available (using CasC)"
    echo ""
fi

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Display access information
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Access Information${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Jenkins URL:     ${GREEN}https://${JENKINS_SUBDOMAIN:-jenkins}.${DOMAIN}${NC}"
echo -e "Username:        ${GREEN}${JENKINS_ADMIN_USER:-admin}${NC}"
echo -e "Password:        ${GREEN}${JENKINS_ADMIN_PASSWORD}${NC}"
echo ""
echo -e "GitHub Webhook:  ${GREEN}https://${JENKINS_SUBDOMAIN:-jenkins}.${DOMAIN}/github-webhook/${NC}"
echo ""

# Display repositories
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Configured Repositories${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "The following pipelines are pre-configured:"
echo ""
echo "  1. wordpress-docker-app"
echo "     https://github.com/willypelz/wordpress-docker-app.git"
echo ""
echo "  2. nodejs-express-api"
echo "     https://github.com/willypelz/nodejs-express-api.git"
echo ""
echo "  3. php-laravel"
echo "     https://github.com/willypelz/php-laravel.git"
echo ""
echo "  4. react-spa"
echo "     https://github.com/willypelz/react-spa.git"
echo ""
echo "  5. flask-api"
echo "     https://github.com/willypelz/flask-api.git"
echo ""

# Next steps
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Add the SSH public key to your deployment server"
echo ""
echo "2. Configure Jenkins credentials:"
echo "   - Go to Manage Jenkins → Credentials"
echo "   - Add 'deployment-server-host' (Secret text with your server IP)"
echo "   - Add 'deployment-ssh-key' (SSH key with the private key)"
echo ""
echo "3. Add Jenkinsfile to each repository:"
echo "   Example Jenkinsfiles are in: infrastructure/jenkins/jenkinsfiles/"
echo ""
echo "4. Set up GitHub webhooks in each repository:"
echo "   Webhook URL: https://${JENKINS_SUBDOMAIN:-jenkins}.${DOMAIN}/github-webhook/"
echo ""
echo "5. Test your first deployment:"
echo "   - Go to Jenkins dashboard"
echo "   - Click on a pipeline under 'Applications'"
echo "   - Click 'Build Now'"
echo ""
echo -e "${GREEN}For detailed instructions, see:${NC}"
echo "  docs/JENKINS-SETUP.md"
echo ""

# Offer to test SSH connection
echo -e "${YELLOW}Would you like to test SSH connection to your deployment server? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter your deployment server IP or hostname:"
    read -r deploy_host

    echo ""
    echo "Enter the deployment user (default: root):"
    read -r deploy_user
    deploy_user=${deploy_user:-root}

    echo ""
    echo -e "${YELLOW}Testing SSH connection...${NC}"

    if docker exec jenkins ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${deploy_user}@${deploy_host}" "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH connection successful!${NC}"
    else
        echo -e "${RED}✗ SSH connection failed${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "1. Ensure the SSH public key is added to ${deploy_host}:~/.ssh/authorized_keys"
        echo "2. Check if SSH port 22 is open on ${deploy_host}"
        echo "3. Verify firewall rules allow connections from this server"
        echo ""
        echo "To manually add the key, run:"
        echo "  ssh ${deploy_user}@${deploy_host} \"mkdir -p ~/.ssh && echo '$(docker exec jenkins cat /var/jenkins_home/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys\""
    fi
fi

echo ""
echo -e "${GREEN}Setup helper completed!${NC}"
echo ""
