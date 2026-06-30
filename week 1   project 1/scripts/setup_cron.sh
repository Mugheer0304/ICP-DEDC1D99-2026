#!/bin/bash
# ==========================================================
# setup_cron.sh - Installs cron jobs for backup.sh and
#                 cleanup.sh automatically.
#
# Usage:
#   ./setup_cron.sh
#
# Edit the variables below before running.
# ==========================================================

source "$(dirname "$0")/lib_common.sh"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_DIR/scripts"

# ---- CONFIGURE THESE PATHS FOR YOUR SYSTEM ----
SOURCE_TO_BACKUP="/home/$(whoami)/myproject"
BACKUP_DESTINATION="$PROJECT_DIR/backups"
CLEANUP_TARGET="/tmp"
# ------------------------------------------------

CRON_BACKUP="0 2 * * * $SCRIPTS_DIR/backup.sh $SOURCE_TO_BACKUP $BACKUP_DESTINATION 7 >> $PROJECT_DIR/logs/cron_backup.log 2>&1"
CRON_CLEANUP="30 3 * * 0 $SCRIPTS_DIR/cleanup.sh $CLEANUP_TARGET 10 >> $PROJECT_DIR/logs/cron_cleanup.log 2>&1"

log_info "Installing cron jobs..."

( crontab -l 2>/dev/null | grep -v "$SCRIPTS_DIR/backup.sh" ; echo "$CRON_BACKUP" ) | crontab - \
    || die "Failed to install backup cron job."

( crontab -l 2>/dev/null | grep -v "$SCRIPTS_DIR/cleanup.sh" ; echo "$CRON_CLEANUP" ) | crontab - \
    || die "Failed to install cleanup cron job."

log_info "Cron jobs installed successfully:"
log_info "  Backup  -> daily at 2:00 AM"
log_info "  Cleanup -> weekly on Sunday at 3:30 AM"
log_info "Run 'crontab -l' to verify."
