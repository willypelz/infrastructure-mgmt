#!/bin/bash
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "  - /var/log/backup-full.log"
echo "  - /var/log/backup-databases.log"
echo -e "${YELLOW}Logs will be saved to:${NC}"
echo ""

crontab -l | grep -v "^#" | grep backup
echo "Current cron schedule:"
echo ""
echo -e "${GREEN}✓ Cron jobs installed${NC}"

rm "$CRON_FILE"

crontab -l 2>/dev/null | cat - "$CRON_FILE" | sort -u | crontab -
# Install cron jobs

EOF
0 2 * * * $SCRIPT_DIR/backup-full.sh >> /var/log/backup-full.log 2>&1
# Daily full backup (at 2:00 AM UTC)

0 * * * * $SCRIPT_DIR/backup-databases.sh >> /var/log/backup-databases.log 2>&1
# Hourly database backups (at minute 0 of every hour)
cat > "$CRON_FILE" <<EOF

CRON_FILE="/tmp/appdeployment-cron"
# Create cron jobs

chmod +x "$SCRIPT_DIR/backup-full.sh"
chmod +x "$SCRIPT_DIR/backup-databases.sh"
# Make scripts executable

echo "======================================"
echo "Setting up Cron Jobs"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NC='\033[0m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'

set -e

##############################################################################
# Setup Cron Jobs for Automated Backups
##############################################################################

