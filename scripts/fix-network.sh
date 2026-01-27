#!/bin/bash

##############################################################################
# Fix Docker Network Labels Issue
# Resolves: "network web was found but has incorrect label"
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Network Label Fix${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if web network exists
if ! docker network inspect web >/dev/null 2>&1; then
    echo -e "${YELLOW}Network 'web' does not exist. Creating...${NC}"
    docker network create web
    echo -e "${GREEN}✓ Network created successfully${NC}"
    exit 0
fi

# Check network label
NETWORK_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")

if [ "$NETWORK_LABEL" == "web" ]; then
    echo -e "${GREEN}✓ Network 'web' has correct labels. No fix needed.${NC}"
    exit 0
fi

echo -e "${YELLOW}Network 'web' has incorrect labels. Fixing...${NC}"
echo ""

# Get all containers connected to the network
echo "Finding containers connected to 'web' network..."
CONNECTED_CONTAINERS=$(docker network inspect web --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

if [ -n "$CONNECTED_CONTAINERS" ]; then
    echo -e "${YELLOW}The following containers will be disconnected:${NC}"
    echo "$CONNECTED_CONTAINERS"
    echo ""

    # Disconnect all containers
    for container in $CONNECTED_CONTAINERS; do
        echo "Disconnecting: $container"
        docker network disconnect -f web "$container" 2>/dev/null || true
    done
    echo -e "${GREEN}✓ All containers disconnected${NC}"
    echo ""
fi

# Remove the network
echo "Removing old network..."
docker network rm web 2>/dev/null || true
echo -e "${GREEN}✓ Old network removed${NC}"
echo ""

# Recreate network using docker-compose (which adds proper labels)
echo "Recreating network with proper labels..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"
docker-compose up -d --no-deps traefik

echo -e "${GREEN}✓ Network recreated with correct labels${NC}"
echo ""

# Reconnect containers if needed
if [ -n "$CONNECTED_CONTAINERS" ]; then
    echo -e "${YELLOW}Reconnecting containers...${NC}"
    for container in $CONNECTED_CONTAINERS; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "Reconnecting: $container"
            docker network connect web "$container" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✓ Containers reconnected${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Fix completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now deploy services:"
echo "  ./scripts/deploy.sh --infrastructure"
echo ""
