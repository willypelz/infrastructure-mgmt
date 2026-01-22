#!/bin/bash

##############################################################################
# Application Deployment Script
# Deploy individual applications or all applications
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please copy .env.example to .env and configure it"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 [OPTION] [APP_NAME]"
    echo ""
    echo "Options:"
    echo "  --all              Deploy all infrastructure and applications"
    echo "  --infrastructure   Deploy only infrastructure (Traefik, Portainer, Monitoring)"
    echo "  --app APP_NAME     Deploy specific application"
    echo "  --stop APP_NAME    Stop specific application"
    echo "  --restart APP_NAME Restart specific application"
    echo "  --logs APP_NAME    View logs for specific application"
    echo "  --list             List all available applications"
    echo ""
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --infrastructure"
    echo "  $0 --app wordpress"
    echo "  $0 --logs nodejs-api"
    exit 1
}

# Function to check DNS
check_dns() {
    local subdomain=$1
    local domain=$2

    echo -e "${YELLOW}Checking DNS for ${subdomain}.${domain}...${NC}"

    if host "${subdomain}.${domain}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS configured${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ DNS not found. Make sure ${subdomain}.${domain} points to this server${NC}"
        return 1
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    echo -e "${GREEN}Deploying infrastructure...${NC}"

    # Create network
    docker network inspect web >/dev/null 2>&1 || docker network create web

    # Deploy Traefik
    echo "Deploying Traefik..."
    cd "$PROJECT_ROOT"
    docker-compose up -d

    # Deploy Portainer
    echo "Deploying Portainer..."
    cd "$PROJECT_ROOT/infrastructure/portainer"
    docker-compose up -d

    # Deploy Monitoring
    echo "Deploying Monitoring Stack..."
    cd "$PROJECT_ROOT/infrastructure/monitoring"
    docker-compose up -d

    echo -e "${GREEN}✓ Infrastructure deployed${NC}"
}

# Function to deploy application
deploy_app() {
    local app_name=$1
    local app_path="$PROJECT_ROOT/apps/$app_name"

    if [ ! -d "$app_path" ]; then
        echo -e "${RED}Error: Application '$app_name' not found${NC}"
        exit 1
    fi

    echo -e "${GREEN}Deploying $app_name...${NC}"

    cd "$app_path"
    docker-compose up -d --build

    echo -e "${GREEN}✓ $app_name deployed${NC}"

    # Wait for health check
    echo "Waiting for health check..."
    sleep 10

    # Show status
    docker-compose ps
}

# Function to stop application
stop_app() {
    local app_name=$1
    local app_path="$PROJECT_ROOT/apps/$app_name"

    if [ ! -d "$app_path" ]; then
        echo -e "${RED}Error: Application '$app_name' not found${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Stopping $app_name...${NC}"
    cd "$app_path"
    docker-compose down
    echo -e "${GREEN}✓ $app_name stopped${NC}"
}

# Function to restart application
restart_app() {
    local app_name=$1
    stop_app "$app_name"
    deploy_app "$app_name"
}

# Function to show logs
show_logs() {
    local app_name=$1
    local app_path="$PROJECT_ROOT/apps/$app_name"

    if [ ! -d "$app_path" ]; then
        echo -e "${RED}Error: Application '$app_name' not found${NC}"
        exit 1
    fi

    cd "$app_path"
    docker-compose logs -f
}

# Function to list applications
list_apps() {
    echo "Available applications:"
    for app in "$PROJECT_ROOT/apps/"*; do
        if [ -d "$app" ]; then
            basename "$app"
        fi
    done
}

# Main script
if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    --all)
        deploy_infrastructure
        for app in "$PROJECT_ROOT/apps/"*; do
            if [ -d "$app" ]; then
                deploy_app "$(basename "$app")"
            fi
        done
        echo -e "${GREEN}✓ All services deployed${NC}"
        ;;
    --infrastructure)
        deploy_infrastructure
        ;;
    --app)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Application name required${NC}"
            usage
        fi
        deploy_app "$2"
        ;;
    --stop)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Application name required${NC}"
            usage
        fi
        stop_app "$2"
        ;;
    --restart)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Application name required${NC}"
            usage
        fi
        restart_app "$2"
        ;;
    --logs)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Application name required${NC}"
            usage
        fi
        show_logs "$2"
        ;;
    --list)
        list_apps
        ;;
    *)
        usage
        ;;
esac
