#!/bin/bash
# ==========================================================
# backup.sh - Backs up a source directory into a timestamped
#             compressed archive, with rotation of old backups.
#
# Usage:
#   ./backup.sh /path/to/source /path/to/backup_dir [days_to_keep]
#
# Example:
#   ./backup.sh /home/user/project /home/user/backups 7
# ==========================================================
 

 
source "$(dirname "$0")/lib_common.sh"

# ---------- Input validation ----------
SOURCE_DIR="${1:-}"
BACKUP_DIR="${2:-}"
KEEP_DAYS="${3:-7}"

if [[ -z "$SOURCE_DIR" || -z "$BACKUP_DIR" ]]; then
    die "Usage: $0 <source_dir> <backup_dir> [days_to_keep]"
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    die "Source directory '$SOURCE_DIR' does not exist."
fi

mkdir -p "$BACKUP_DIR" || die "Could not create backup directory '$BACKUP_DIR'."

# ---------- Perform backup ----------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="backup_$(basename "$SOURCE_DIR")_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

log_info "Starting backup of '$SOURCE_DIR' -> '$ARCHIVE_PATH'"

tar -czf "$ARCHIVE_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" \
    || die "Backup failed while creating archive."

# ---------- Verify backup ----------
if [[ -f "$ARCHIVE_PATH" ]]; then
    SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    log_info "Backup completed successfully. Size: $SIZE"
else
    die "Backup archive was not created."
fi

# ---------- Rotate old backups ----------
log_info "Removing backups older than $KEEP_DAYS days from '$BACKUP_DIR'"
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +"$KEEP_DAYS" -print -delete | while read -r f; do
    log_info "Deleted old backup: $f"
done

rotate_logs 14

log_info "Backup job finished."
exit 0
