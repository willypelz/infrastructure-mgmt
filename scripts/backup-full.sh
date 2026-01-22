#!/bin/bash

##############################################################################
# Full Backup Script (Daily)
# Backs up all Docker volumes and configurations to DigitalOcean Spaces
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
BACKUP_DIR="$PROJECT_ROOT/backups/full"
mkdir -p "$BACKUP_DIR"

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="full-backup-${TIMESTAMP}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"

echo "======================================"
echo "Full System Backup - $TIMESTAMP"
echo "======================================"

# Create temporary directory for backup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Backup Docker volumes
echo -e "${YELLOW}Backing up Docker volumes...${NC}"
VOLUMES_DIR="$TEMP_DIR/volumes"
mkdir -p "$VOLUMES_DIR"

# Get list of all volumes
VOLUMES=$(docker volume ls -q)

for volume in $VOLUMES; do
    echo "  - Backing up volume: $volume"
    docker run --rm \
        -v "$volume:/data" \
        -v "$VOLUMES_DIR:/backup" \
        alpine \
        tar czf "/backup/${volume}.tar.gz" -C /data .
done

# Backup configurations
echo -e "${YELLOW}Backing up configurations...${NC}"
CONFIG_DIR="$TEMP_DIR/config"
mkdir -p "$CONFIG_DIR"

# Copy important configs (excluding node_modules, vendor, etc.)
rsync -av \
    --exclude 'node_modules' \
    --exclude 'vendor' \
    --exclude '.git' \
    --exclude 'backups' \
    --exclude 'logs' \
    --exclude '*.log' \
    "$PROJECT_ROOT/" \
    "$CONFIG_DIR/" \
    2>/dev/null || true

# Create final backup archive
echo -e "${YELLOW}Creating backup archive...${NC}"
tar czf "$BACKUP_FILE" -C "$TEMP_DIR" .

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE ($BACKUP_SIZE)${NC}"
else
    echo -e "${RED}✗ Failed to create backup archive${NC}"
    exit 1
fi

# Upload to DigitalOcean Spaces
if [ ! -z "$DO_SPACES_KEY" ] && [ "$DO_SPACES_KEY" != "your_spaces_access_key" ]; then
    echo -e "${YELLOW}Uploading to DigitalOcean Spaces...${NC}"

    # Configure AWS CLI for DO Spaces
    export AWS_ACCESS_KEY_ID="$DO_SPACES_KEY"
    export AWS_SECRET_ACCESS_KEY="$DO_SPACES_SECRET"

    aws s3 cp "$BACKUP_FILE" \
        "s3://${DO_SPACES_BUCKET}/full-backups/$(date +%Y)/$(date +%m)/" \
        --endpoint-url="$DO_SPACES_ENDPOINT" \
        --region="$DO_SPACES_REGION"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup uploaded to Spaces${NC}"
    else
        echo -e "${RED}✗ Failed to upload backup${NC}"
    fi
else
    echo -e "${YELLOW}⚠ DigitalOcean Spaces not configured, skipping upload${NC}"
fi

# Clean up old local backups (keep last 30 days)
echo -e "${YELLOW}Cleaning up old local backups...${NC}"
find "$BACKUP_DIR" -name "full-backup-*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS:-30} -delete
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Generate backup report
REPORT_FILE="$BACKUP_DIR/backup-report-$(date +%Y%m%d).txt"
cat > "$REPORT_FILE" <<EOF
Backup Report
=============
Date: $(date)
Backup File: $BACKUP_NAME
Size: $BACKUP_SIZE
Status: Success

Volumes Backed Up:
$(echo "$VOLUMES" | sed 's/^/  - /')

Configuration Directories:
  - Infrastructure configs
  - Application configs
  - Environment files
  - Docker compose files
EOF

echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"

echo "======================================"
echo -e "${GREEN}Full backup completed successfully${NC}"
echo "======================================"
