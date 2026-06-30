#!/bin/bash
# ==========================================================
# lib_common.sh - Shared functions for logging & error handling
# Source this file at the top of every script:
#   source "$(dirname "$0")/lib_common.sh"
# ==========================================================

# Directory where all log files are stored
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"

# Each script gets its own log file named after itself + date
SCRIPT_NAME="$(basename "$0" .sh)"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d).log"

# ---------- Logging functions ----------
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$LOG_FILE" >&2
}

# ---------- Error handling ----------
# Call this after any command you want to validate
# Usage: some_command || die "message"
die() {
    log_error "$1"
    exit 1
}

# Trap unexpected errors anywhere in the script that sources this file
trap 'log_error "Unexpected failure on line $LINENO. Exiting."; exit 1' ERR

# Treat unset variables and failed pipes as errors
set -u
set -o pipefail

# ---------- Helper: rotate logs older than N days ----------
rotate_logs() {
    local days="${1:-7}"
    find "$LOG_DIR" -name "*.log" -mtime +"$days" -delete
    log_info "Rotated logs older than $days days."
}
