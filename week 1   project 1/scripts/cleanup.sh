#!/bin/bash
# ==========================================================
# cleanup.sh - Cleans temporary files, old logs, and empty
#              directories from a target directory.
#
# Usage:
#   ./cleanup.sh /path/to/target [days_old] [--dry-run]
#
# Example:
#   ./cleanup.sh /tmp/myapp 10
#   ./cleanup.sh /tmp/myapp 10 --dry-run
# ==========================================================
    

    
source "$(dirname "$0")/lib_common.sh"

TARGET_DIR="${1:-}"
DAYS_OLD="${2:-7}"
DRY_RUN="${3:-}"

if [[ -z "$TARGET_DIR" ]]; then
    die "Usage: $0 <target_dir> [days_old] [--dry-run]"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
    die "Target directory '$TARGET_DIR' does not exist."
fi

log_info "Starting cleanup of '$TARGET_DIR' (files older than $DAYS_OLD days)"

# ---------- Find candidate files ----------
FILES_FOUND=$(find "$TARGET_DIR" -type f \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" \) -mtime +"$DAYS_OLD")

if [[ -z "$FILES_FOUND" ]]; then
    log_info "No files matched cleanup criteria."
else
    while IFS= read -r file; do
        if [[ "$DRY_RUN" == "--dry-run" ]]; then
            log_info "[DRY RUN] Would delete: $file"
        else
            rm -f "$file" && log_info "Deleted: $file" || log_warn "Failed to delete: $file"
        fi
    done <<< "$FILES_FOUND"
fi

# ---------- Remove empty directories ----------
EMPTY_DIRS=$(find "$TARGET_DIR" -type d -empty)
if [[ -n "$EMPTY_DIRS" ]]; then
    while IFS= read -r dir; do
        if [[ "$DRY_RUN" == "--dry-run" ]]; then
            log_info "[DRY RUN] Would remove empty directory: $dir"
        else
            rmdir "$dir" 2>/dev/null && log_info "Removed empty directory: $dir"
        fi
    done <<< "$EMPTY_DIRS"
fi

log_info "Cleanup job finished."
exit 0
