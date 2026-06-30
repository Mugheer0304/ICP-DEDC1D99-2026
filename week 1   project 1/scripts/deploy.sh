#!/bin/bash
# ==========================================================
# deploy.sh - Simple deployment script: pulls latest code,
#             installs dependencies, restarts a service, and
#             rolls back automatically if anything fails.
#
# Usage:
#   ./deploy.sh /path/to/app_dir [service_name]
#
# Example:
#   ./deploy.sh /home/user/myapp myapp.service
# ==========================================================

source "$(dirname "$0")/lib_common.sh"

APP_DIR="${1:-}"
SERVICE_NAME="${2:-}"
BACKUP_BEFORE_DEPLOY="/tmp/${SCRIPT_NAME}_pre_deploy_backup.tar.gz"

if [[ -z "$APP_DIR" ]]; then
    die "Usage: $0 <app_dir> [service_name]"
fi

if [[ ! -d "$APP_DIR" ]]; then
    die "App directory '$APP_DIR' does not exist."
fi

cd "$APP_DIR" || die "Could not enter app directory '$APP_DIR'."

# ---------- Step 1: Backup current state for rollback ----------
log_info "Creating pre-deploy snapshot for rollback safety..."
tar -czf "$BACKUP_BEFORE_DEPLOY" . || die "Failed to create pre-deploy backup."

# ---------- Step 2: Pull latest code (if git repo) ----------
if [[ -d ".git" ]]; then
    log_info "Pulling latest changes from git..."
    if ! git pull origin main >> "$LOG_FILE" 2>&1; then
        log_error "git pull failed. Rolling back is not needed (no changes applied)."
        die "Deployment aborted due to git pull failure."
    fi
else
    log_warn "No .git directory found. Skipping code pull step."
fi

# ---------- Step 3: Install dependencies (example: npm) ----------
if [[ -f "package.json" ]]; then
    log_info "Installing dependencies with npm..."
    if ! npm install >> "$LOG_FILE" 2>&1; then
        log_error "Dependency install failed. Rolling back..."
        tar -xzf "$BACKUP_BEFORE_DEPLOY" -C "$APP_DIR"
        die "Deployment rolled back due to failed dependency install."
    fi
else
    log_warn "No package.json found. Skipping dependency install."
fi

# ---------- Step 4: Restart service ----------
if [[ -n "$SERVICE_NAME" ]]; then
    log_info "Restarting service '$SERVICE_NAME'..."
    if command -v systemctl &> /dev/null; then
        if ! sudo systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
            log_error "Service restart failed. Rolling back..."
            tar -xzf "$BACKUP_BEFORE_DEPLOY" -C "$APP_DIR"
            die "Deployment rolled back due to failed service restart."
        fi
        log_info "Service '$SERVICE_NAME' restarted successfully."
    else
        log_warn "systemctl not available. Skipping service restart."
    fi
else
    log_warn "No service name provided. Skipping restart step."
fi

# ---------- Cleanup snapshot ----------
rm -f "$BACKUP_BEFORE_DEPLOY"

log_info "Deployment completed successfully."
exit 0
