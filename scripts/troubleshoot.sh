#!/bin/bash

##############################################################################
# Troubleshooting Script for 521 Error (Web Server Down)
# This script diagnoses and attempts to fix connectivity issues
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Web Server Troubleshooting${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Checking Docker service...${NC}"
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}Docker is not running. Starting Docker...${NC}"
    systemctl start docker
    sleep 5
else
    echo -e "${GREEN}✓ Docker is running${NC}"
fi

echo ""
echo -e "${YELLOW}[2/8] Checking container status...${NC}"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${YELLOW}[3/8] Checking Traefik container...${NC}"
if docker ps | grep -q traefik; then
    echo -e "${GREEN}✓ Traefik is running${NC}"
    docker logs traefik --tail 50
else
    echo -e "${RED}✗ Traefik is NOT running${NC}"
    echo "Attempting to start Traefik..."
    cd "$PROJECT_ROOT"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d
fi

echo ""
echo -e "${YELLOW}[4/8] Checking Node.js API container...${NC}"
if docker ps | grep -q nodejs-api; then
    echo -e "${GREEN}✓ Node.js API is running${NC}"
    echo "Recent logs:"
    docker logs nodejs-api --tail 30
else
    echo -e "${RED}✗ Node.js API is NOT running${NC}"

    # Check if it exists but stopped
    if docker ps -a | grep -q nodejs-api; then
        echo "Container exists but is stopped. Checking logs..."
        docker logs nodejs-api --tail 50

        echo ""
        echo "Attempting to restart..."
        docker start nodejs-api
    else
        echo "Container doesn't exist. Need to deploy."
    fi
fi

echo ""
echo -e "${YELLOW}[5/8] Checking database connectivity...${NC}"
if docker ps | grep -q nodejs-db; then
    echo -e "${GREEN}✓ PostgreSQL database is running${NC}"

    # Test database connection
    if docker exec nodejs-db pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Database is accepting connections${NC}"
    else
        echo -e "${RED}✗ Database is not ready${NC}"
    fi
else
    echo -e "${RED}✗ PostgreSQL database is NOT running${NC}"
fi

echo ""
echo -e "${YELLOW}[6/8] Checking network connectivity...${NC}"
if docker network inspect web >/dev/null 2>&1; then
    echo -e "${GREEN}✓ 'web' network exists${NC}"
    echo "Containers on 'web' network:"
    docker network inspect web --format '{{range .Containers}}{{.Name}} {{end}}'
else
    echo -e "${RED}✗ 'web' network does not exist${NC}"
    echo "Creating network..."
    docker network create web
fi

echo ""
echo -e "${YELLOW}[7/8] Testing internal connectivity...${NC}"
if docker ps | grep -q nodejs-api; then
    echo "Testing Node.js API health endpoint from within container..."
    if docker exec nodejs-api curl -f http://localhost:3000/health 2>/dev/null; then
        echo -e "${GREEN}✓ API responds to health checks${NC}"
    else
        echo -e "${RED}✗ API does not respond to health checks${NC}"
        echo "This could indicate:"
        echo "  - Application crashed"
        echo "  - Port 3000 not listening"
        echo "  - Health endpoint not implemented"
    fi
fi

echo ""
echo -e "${YELLOW}[8/8] Checking firewall rules...${NC}"
echo "Open ports on this server:"
ufw status | grep -E "80|443|ALLOW" || echo "UFW may not be configured"

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Diagnosis Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Summary
CONTAINERS_RUNNING=$(docker ps --format '{{.Names}}' | wc -l)
CONTAINERS_TOTAL=$(docker ps -a --format '{{.Names}}' | wc -l)

echo "Total containers: $CONTAINERS_TOTAL"
echo "Running containers: $CONTAINERS_RUNNING"
echo ""

if docker ps | grep -q nodejs-api && docker ps | grep -q traefik; then
    echo -e "${GREEN}✓ Both Traefik and Node.js API are running${NC}"
    echo ""
    echo "If you're still getting 521 errors, check:"
    echo "1. DNS is pointing to this server IP"
    echo "2. Cloudflare SSL/TLS mode is set to 'Full' or 'Full (strict)'"
    echo "3. Origin server certificate is valid"
    echo "4. Check Traefik logs for routing issues"
    echo ""
    echo "Run this to see Traefik logs:"
    echo "  docker logs traefik -f"
else
    echo -e "${RED}✗ Critical services are not running${NC}"
    echo ""
    echo "Recommended actions:"
    echo "1. Deploy infrastructure:"
    echo "   ./scripts/deploy.sh --infrastructure"
    echo ""
    echo "2. Deploy Node.js API:"
    echo "   ./scripts/deploy.sh --app nodejs-express-api"
fi

echo ""
echo -e "${BLUE}================================${NC}"
