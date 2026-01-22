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
    echo "  --all                Deploy all infrastructure and applications"
    echo "  --infrastructure     Deploy all infrastructure (Traefik, Portainer, Monitoring)"
    echo "  --traefik            Deploy only Traefik reverse proxy"
    echo "  --portainer          Deploy only Portainer (Docker management UI)"
    echo "  --monitoring         Deploy only monitoring stack (Prometheus, Grafana, etc.)"
    echo "  --app APP_NAME       Deploy specific application"
    echo "  --stop APP_NAME      Stop specific application"
    echo "  --restart APP_NAME   Restart specific application"
    echo "  --logs APP_NAME      View logs for specific application"
    echo "  --list               List all available applications"
    echo ""
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --infrastructure"
    echo "  $0 --traefik"
    echo "  $0 --portainer"
    echo "  $0 --monitoring"
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

    # Remove existing network if it exists without proper labels
    if docker network inspect web >/dev/null 2>&1; then
        echo "Checking 'web' network labels..."

        # Check if network has the correct Docker Compose label
        NETWORK_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")

        if [ "$NETWORK_LABEL" != "web" ]; then
            echo -e "${YELLOW}Network 'web' has incorrect labels. Recreating...${NC}"

            # Get all containers connected to the network
            CONNECTED_CONTAINERS=$(docker network inspect web --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

            # Disconnect all containers
            if [ -n "$CONNECTED_CONTAINERS" ]; then
                echo "Disconnecting containers from network..."
                for container in $CONNECTED_CONTAINERS; do
                    echo "  Disconnecting $container..."
                    docker network disconnect -f web "$container" 2>/dev/null || true
                done
            fi

            # Remove the network
            echo "Removing old network..."
            docker network rm web 2>/dev/null || true

            echo -e "${GREEN}✓ Old network removed${NC}"
        else
            echo -e "${GREEN}✓ Network has correct labels${NC}"
        fi
    fi

    # Deploy Traefik (will create network with proper labels)
    echo "Deploying Traefik..."
    cd "$PROJECT_ROOT"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d

    # Deploy Portainer
    echo "Deploying Portainer..."
    cd "$PROJECT_ROOT/infrastructure/portainer"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d

    # Deploy Monitoring
    echo "Deploying Monitoring Stack..."
    cd "$PROJECT_ROOT/infrastructure/monitoring"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d

    echo -e "${GREEN}✓ Infrastructure deployed${NC}"
}

# Function to deploy only Traefik
deploy_traefik() {
    echo -e "${GREEN}Deploying Traefik...${NC}"

    # Check and fix network labels if needed
    if docker network inspect web >/dev/null 2>&1; then
        NETWORK_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")

        if [ "$NETWORK_LABEL" != "web" ]; then
            echo -e "${YELLOW}Network 'web' has incorrect labels. Recreating...${NC}"

            CONNECTED_CONTAINERS=$(docker network inspect web --format='{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

            if [ -n "$CONNECTED_CONTAINERS" ]; then
                echo "Disconnecting containers from network..."
                for container in $CONNECTED_CONTAINERS; do
                    echo "  Disconnecting $container..."
                    docker network disconnect -f web "$container" 2>/dev/null || true
                done
            fi

            docker network rm web 2>/dev/null || true
            echo -e "${GREEN}✓ Old network removed${NC}"
        fi
    fi

    # Deploy Traefik
    cd "$PROJECT_ROOT"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d traefik

    echo -e "${GREEN}✓ Traefik deployed${NC}"
    echo ""
    echo "Access Traefik dashboard at: https://${TRAEFIK_SUBDOMAIN}.${DOMAIN}"
    echo "Default credentials: admin/admin (CHANGE IN PRODUCTION!)"
}

# Function to deploy only Portainer
deploy_portainer() {
    echo -e "${GREEN}Deploying Portainer...${NC}"

    # Ensure network exists
    if ! docker network inspect web >/dev/null 2>&1; then
        echo -e "${YELLOW}Creating 'web' network...${NC}"
        docker network create web
    fi

    cd "$PROJECT_ROOT/infrastructure/portainer"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d

    echo -e "${GREEN}✓ Portainer deployed${NC}"
    echo ""
    echo "Access Portainer at: https://${PORTAINER_SUBDOMAIN}.${DOMAIN}"
    echo "First login will prompt you to create admin user"
}

# Function to deploy only Monitoring stack
deploy_monitoring() {
    echo -e "${GREEN}Deploying Monitoring Stack...${NC}"

    # Ensure network exists
    if ! docker network inspect web >/dev/null 2>&1; then
        echo -e "${YELLOW}Creating 'web' network...${NC}"
        docker network create web
    fi

    cd "$PROJECT_ROOT/infrastructure/monitoring"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d

    echo -e "${GREEN}✓ Monitoring Stack deployed${NC}"
    echo ""
    echo "Services deployed:"
    echo "  - Grafana:        https://${GRAFANA_SUBDOMAIN}.${DOMAIN}"
    echo "  - Prometheus:     https://${PROMETHEUS_SUBDOMAIN}.${DOMAIN}"
    echo "  - Alertmanager:   https://${ALERTMANAGER_SUBDOMAIN}.${DOMAIN}"
    echo ""
    echo "Grafana credentials:"
    echo "  Username: ${GRAFANA_ADMIN_USER}"
    echo "  Password: ${GRAFANA_ADMIN_PASSWORD}"
}

# Function to deploy application
deploy_app() {
    local app_name=$1
    local app_path="$PROJECT_ROOT/apps/$app_name"

    if [ ! -d "$app_path" ]; then
        echo -e "${RED}Error: Application '$app_name' not found${NC}"
        exit 1
    fi

    # Ensure the web network exists
    if ! docker network inspect web >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 'web' network does not exist.${NC}"
        echo -e "${YELLOW}It's recommended to deploy infrastructure first:${NC}"
        echo -e "${YELLOW}  ./scripts/deploy.sh --infrastructure${NC}"
        echo ""
        echo -e "${YELLOW}Creating basic 'web' network for now...${NC}"
        docker network create web
        echo -e "${YELLOW}⚠ Note: This network won't have Docker Compose labels.${NC}"
        echo -e "${YELLOW}⚠ Redeploy infrastructure later to fix this.${NC}"
    else
        # Check if network has correct labels
        NETWORK_LABEL=$(docker network inspect web --format='{{index .Labels "com.docker.compose.network"}}' 2>/dev/null || echo "")
        if [ "$NETWORK_LABEL" != "web" ]; then
            echo -e "${YELLOW}⚠ Network 'web' exists but has incorrect labels.${NC}"
            echo -e "${YELLOW}⚠ This may cause warnings. To fix, run:${NC}"
            echo -e "${YELLOW}  ./scripts/deploy.sh --infrastructure${NC}"
        fi
    fi

    echo -e "${GREEN}Deploying $app_name...${NC}"

    cd "$app_path"
    docker-compose --env-file "$PROJECT_ROOT/.env" up -d --build

    echo -e "${GREEN}✓ $app_name deployed${NC}"

    # Wait for health check
    echo "Waiting for health check..."
    sleep 10

    # Show status
    docker-compose --env-file "$PROJECT_ROOT/.env" ps
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
    docker-compose --env-file "$PROJECT_ROOT/.env" down
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
    docker-compose --env-file "$PROJECT_ROOT/.env" logs -f
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
    --traefik)
        deploy_traefik
        ;;
    --portainer)
        deploy_portainer
        ;;
    --monitoring)
        deploy_monitoring
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
