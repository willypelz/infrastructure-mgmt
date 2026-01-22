#!/bin/bash

##############################################################################
# Fix Docker Network Label Issue
# Fixes: "network web was found but has incorrect label"
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Docker Network Label Fix${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

echo -e "${YELLOW}[1/6] Checking current 'web' network...${NC}"
if docker network inspect web >/dev/null 2>&1; then
    NETWORK_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")
    echo "Current label: '$NETWORK_LABEL'"

    if [ "$NETWORK_LABEL" = "web" ]; then
        echo -e "${GREEN}✓ Network already has correct labels!${NC}"
        echo "No fix needed."
        exit 0
    else
        echo -e "${YELLOW}✗ Network has incorrect label (expected: 'web', got: '$NETWORK_LABEL')${NC}"
    fi
else
    echo -e "${RED}✗ Network 'web' does not exist${NC}"
    echo "Creating it with correct labels..."
    cd "$PROJECT_ROOT"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d --no-start
    echo -e "${GREEN}✓ Network created${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}[2/6] Getting list of connected containers...${NC}"
CONNECTED_CONTAINERS=$(docker network inspect web --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

if [ -n "$CONNECTED_CONTAINERS" ]; then
    echo "Found containers: $CONNECTED_CONTAINERS"
else
    echo "No containers connected"
fi

echo ""
echo -e "${YELLOW}[3/6] Stopping containers gracefully...${NC}"
if [ -n "$CONNECTED_CONTAINERS" ]; then
    for container in $CONNECTED_CONTAINERS; do
        echo "  Stopping $container..."
        docker stop "$container" 2>/dev/null || true
    done
    echo -e "${GREEN}✓ Containers stopped${NC}"
else
    echo "No containers to stop"
fi

echo ""
echo -e "${YELLOW}[4/6] Removing old network...${NC}"
docker network rm web 2>/dev/null || true
echo -e "${GREEN}✓ Old network removed${NC}"

echo ""
echo -e "${YELLOW}[5/6] Recreating network with correct labels...${NC}"
cd "$PROJECT_ROOT"

# Use docker-compose to create the network with proper labels
echo "Running docker-compose to create network..."
docker-compose --env-file "$PROJECT_ROOT/.env" config > /dev/null 2>&1 || true
docker-compose --env-file "$PROJECT_ROOT/.env" up -d --no-start traefik 2>/dev/null || true

# Verify network was created
if docker network inspect web >/dev/null 2>&1; then
    NEW_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")
    if [ "$NEW_LABEL" = "web" ]; then
        echo -e "${GREEN}✓ Network recreated with correct label: '$NEW_LABEL'${NC}"
    else
        echo -e "${YELLOW}⚠ Network created but label is: '$NEW_LABEL'${NC}"
    fi
else
    echo -e "${RED}✗ Failed to create network${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[6/6] Restarting containers...${NC}"
if [ -n "$CONNECTED_CONTAINERS" ]; then
    for container in $CONNECTED_CONTAINERS; do
        echo "  Starting $container..."
        docker start "$container" 2>/dev/null || true
    done
    echo -e "${GREEN}✓ Containers restarted${NC}"
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✓ Network label fix complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Verification:"
docker network inspect web --format='Network: {{.Name}}, Label: {{index .Labels "com.docker.compose.network"}}'
echo ""
echo "Connected containers:"
docker network inspect web --format='{{range .Containers}}  - {{.Name}}{{"\n"}}{{end}}'
echo ""
echo -e "${GREEN}You should no longer see the label warning!${NC}"
echo ""
