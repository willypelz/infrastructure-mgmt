#!/bin/bash

##############################################################################
# Restore Script
# Restore backups from DigitalOcean Spaces or local files
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 [OPTION] [BACKUP_FILE]"
    echo ""
    echo "Options:"
    echo "  --list                List available backups"
    echo "  --list-remote         List backups in DigitalOcean Spaces"
    echo "  --full BACKUP_FILE    Restore full backup"
    echo "  --db BACKUP_FILE      Restore database backup"
    echo "  --download REMOTE     Download backup from Spaces"
    echo ""
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --full backups/full/full-backup-20240122-120000.tar.gz"
    echo "  $0 --db backups/databases/wordpress-db-20240122-120000.sql.gz"
    exit 1
}

# Function to list local backups
list_backups() {
    echo "Full Backups:"
    ls -lh "$PROJECT_ROOT/backups/full/" 2>/dev/null || echo "  No backups found"
    echo ""
    echo "Database Backups:"
    ls -lh "$PROJECT_ROOT/backups/databases/" 2>/dev/null || echo "  No backups found"
}

# Function to list remote backups
list_remote_backups() {
    if [ -z "$DO_SPACES_KEY" ] || [ "$DO_SPACES_KEY" == "your_spaces_access_key" ]; then
        echo -e "${RED}Error: DigitalOcean Spaces not configured${NC}"
        exit 1
    fi

    export AWS_ACCESS_KEY_ID="$DO_SPACES_KEY"
    export AWS_SECRET_ACCESS_KEY="$DO_SPACES_SECRET"

    echo "Remote Full Backups:"
    aws s3 ls "s3://${DO_SPACES_BUCKET}/full-backups/" \
        --recursive \
        --endpoint-url="$DO_SPACES_ENDPOINT" \
        --region="$DO_SPACES_REGION"

    echo ""
    echo "Remote Database Backups:"
    aws s3 ls "s3://${DO_SPACES_BUCKET}/databases/" \
        --recursive \
        --endpoint-url="$DO_SPACES_ENDPOINT" \
        --region="$DO_SPACES_REGION"
}

# Function to restore full backup
restore_full() {
    local backup_file=$1

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found: $backup_file${NC}"
        exit 1
    fi

    echo -e "${YELLOW}⚠ WARNING: This will restore all volumes and configurations${NC}"
    echo -e "${YELLOW}⚠ All current data will be replaced${NC}"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled"
        exit 0
    fi

    # Stop all containers
    echo -e "${YELLOW}Stopping all containers...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose down
    for app in apps/*/; do
        if [ -f "${app}docker-compose.yml" ]; then
            cd "$PROJECT_ROOT/$app"
            docker-compose down
        fi
    done

    # Extract backup
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo -e "${YELLOW}Extracting backup...${NC}"
    tar xzf "$backup_file" -C "$TEMP_DIR"

    # Restore volumes
    echo -e "${YELLOW}Restoring volumes...${NC}"
    for volume_backup in "$TEMP_DIR/volumes/"*.tar.gz; do
        if [ -f "$volume_backup" ]; then
            volume_name=$(basename "$volume_backup" .tar.gz)
            echo "  - Restoring volume: $volume_name"

            # Remove existing volume
            docker volume rm "$volume_name" 2>/dev/null || true

            # Create and restore volume
            docker volume create "$volume_name"
            docker run --rm \
                -v "$volume_name:/data" \
                -v "$TEMP_DIR/volumes:/backup" \
                alpine \
                tar xzf "/backup/${volume_name}.tar.gz" -C /data
        fi
    done

    # Restore configurations
    echo -e "${YELLOW}Restoring configurations...${NC}"
    rsync -av "$TEMP_DIR/config/" "$PROJECT_ROOT/"

    echo -e "${GREEN}✓ Restore completed${NC}"
    echo -e "${YELLOW}You can now start services with: ./scripts/deploy.sh --all${NC}"
}

# Function to restore database
restore_database() {
    local backup_file=$1

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found: $backup_file${NC}"
        exit 1
    fi

    # Determine database type from filename
    if [[ "$backup_file" == *"wordpress-db"* ]]; then
        container="wordpress-db"
        database="$WORDPRESS_DB_NAME"
        user="root"
        password="$WORDPRESS_DB_ROOT_PASSWORD"
        type="mysql"
    elif [[ "$backup_file" == *"nodejs-db"* ]]; then
        container="nodejs-db"
        database="$POSTGRES_DB"
        user="$POSTGRES_USER"
        type="postgres"
    elif [[ "$backup_file" == *"laravel-db"* ]]; then
        container="laravel-db"
        database="$LARAVEL_DB_NAME"
        user="root"
        password="$LARAVEL_DB_ROOT_PASSWORD"
        type="mysql"
    else
        echo -e "${RED}Error: Cannot determine database type from filename${NC}"
        exit 1
    fi

    echo -e "${YELLOW}⚠ WARNING: This will restore $container database${NC}"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled"
        exit 0
    fi

    echo -e "${YELLOW}Restoring $container...${NC}"

    if [ "$type" == "mysql" ]; then
        gunzip < "$backup_file" | docker exec -i "$container" mysql -u "$user" -p"$password" "$database"
    else
        gunzip < "$backup_file" | docker exec -i "$container" psql -U "$user" "$database"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database restored successfully${NC}"
    else
        echo -e "${RED}✗ Database restore failed${NC}"
        exit 1
    fi
}

# Main script
if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    --list)
        list_backups
        ;;
    --list-remote)
        list_remote_backups
        ;;
    --full)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Backup file required${NC}"
            usage
        fi
        restore_full "$2"
        ;;
    --db)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Backup file required${NC}"
            usage
        fi
        restore_database "$2"
        ;;
    *)
        usage
        ;;
esac
