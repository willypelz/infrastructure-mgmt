#!/bin/bash

##############################################################################
# Database Backup Script (Hourly)
# Backs up all application databases to DigitalOcean Spaces
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

# Backup directory
BACKUP_DIR="$PROJECT_ROOT/backups/databases"
mkdir -p "$BACKUP_DIR"

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DATE=$(date +%Y%m%d)

echo "======================================"
echo "Database Backup - $TIMESTAMP"
echo "======================================"

# Function to backup MySQL/MariaDB
backup_mysql() {
    local container=$1
    local database=$2
    local user=$3
    local password=$4
    local backup_file="$BACKUP_DIR/${container}-${TIMESTAMP}.sql.gz"

    echo -e "${YELLOW}Backing up $container...${NC}"

    docker exec "$container" mysqldump \
        -u "$user" \
        -p"$password" \
        "$database" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        | gzip > "$backup_file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $container backed up to $backup_file${NC}"
        echo "$backup_file"
    else
        echo -e "${RED}✗ Failed to backup $container${NC}"
        return 1
    fi
}

# Function to backup PostgreSQL
backup_postgres() {
    local container=$1
    local database=$2
    local user=$3
    local backup_file="$BACKUP_DIR/${container}-${TIMESTAMP}.sql.gz"

    echo -e "${YELLOW}Backing up $container...${NC}"

    docker exec "$container" pg_dump \
        -U "$user" \
        "$database" \
        | gzip > "$backup_file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $container backed up to $backup_file${NC}"
        echo "$backup_file"
    else
        echo -e "${RED}✗ Failed to backup $container${NC}"
        return 1
    fi
}

# Backup WordPress database
if docker ps | grep -q wordpress-db; then
    backup_mysql "wordpress-db" \
        "$WORDPRESS_DB_NAME" \
        "$WORDPRESS_DB_USER" \
        "$WORDPRESS_DB_PASSWORD"
fi

# Backup Node.js PostgreSQL database
if docker ps | grep -q nodejs-db; then
    backup_postgres "nodejs-db" \
        "$POSTGRES_DB" \
        "$POSTGRES_USER"
fi

# Backup Laravel database
if docker ps | grep -q laravel-db; then
    backup_mysql "laravel-db" \
        "$LARAVEL_DB_NAME" \
        "$LARAVEL_DB_USER" \
        "$LARAVEL_DB_PASSWORD"
fi

# Upload to DigitalOcean Spaces
if [ ! -z "$DO_SPACES_KEY" ] && [ "$DO_SPACES_KEY" != "your_spaces_access_key" ]; then
    echo -e "${YELLOW}Uploading to DigitalOcean Spaces...${NC}"

    # Configure AWS CLI for DO Spaces
    export AWS_ACCESS_KEY_ID="$DO_SPACES_KEY"
    export AWS_SECRET_ACCESS_KEY="$DO_SPACES_SECRET"

    for backup_file in "$BACKUP_DIR"/*-${TIMESTAMP}.sql.gz; do
        if [ -f "$backup_file" ]; then
            aws s3 cp "$backup_file" \
                "s3://${DO_SPACES_BUCKET}/databases/$(date +%Y)/$(date +%m)/" \
                --endpoint-url="$DO_SPACES_ENDPOINT" \
                --region="$DO_SPACES_REGION"

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Uploaded $(basename $backup_file)${NC}"
            else
                echo -e "${RED}✗ Failed to upload $(basename $backup_file)${NC}"
            fi
        fi
    done
fi

# Clean up old local backups (keep last 7 days)
echo -e "${YELLOW}Cleaning up old local backups...${NC}"
find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +${DB_BACKUP_RETENTION_DAYS:-7} -delete
echo -e "${GREEN}✓ Cleanup complete${NC}"

echo "======================================"
echo -e "${GREEN}Database backup completed${NC}"
echo "======================================"
