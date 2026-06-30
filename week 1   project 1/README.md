# Shell Scripting Automation Project

A beginner-friendly Bash automation toolkit with three production-style scripts
(backup, cleanup, deploy), a shared logging/error-handling library, and a
cron-job installer.

## Folder Structure
```
shell-automation-project/
├── scripts/
│   ├── lib_common.sh     # shared logging + error handling functions
│   ├── backup.sh         # compresses & archives a folder, rotates old backups
│   ├── cleanup.sh        # deletes old temp/log files and empty folders
│   ├── deploy.sh         # pulls code, installs deps, restarts service, auto-rollback
│   └── setup_cron.sh     # installs the cron schedule for backup/cleanup
├── logs/                 # auto-created; one log file per script per day
├── backups/              # auto-created; where backup archives are stored
└── config/                # reserved for any future config files
```

## Step-by-Step Setup

### 1. Get the files onto your machine
Download/copy the `shell-automation-project` folder to your Linux/macOS machine
(or WSL on Windows).

### 2. Make scripts executable
```bash
cd shell-automation-project/scripts
chmod +x *.sh
```

### 3. Test the backup script manually
```bash
./backup.sh /path/to/folder/you/want/to/backup /path/to/where/backups/go 7
```
- 1st argument: the folder to back up
- 2nd argument: where to store the `.tar.gz` archive
- 3rd argument (optional, default 7): delete backups older than this many days

Check the result:
```bash
ls -la ../backups
cat ../logs/backup_$(date +%Y%m%d).log
```

### 4. Test the cleanup script manually
```bash
./cleanup.sh /tmp 10 --dry-run
```
- 1st argument: folder to clean
- 2nd argument: delete `.tmp`/`.log`/`.bak` files older than this many days
- `--dry-run` (optional): shows what WOULD be deleted without deleting anything.
  Remove this flag to actually delete files.

### 5. Test the deploy script (only if you have a real app/service)
```bash
./deploy.sh /path/to/your/app your-service-name
```
This will:
1. Snapshot the current app folder (for rollback safety)
2. `git pull` the latest code (if it's a git repo)
3. Run `npm install` (if a `package.json` exists)
4. Restart the named systemd service
5. Automatically roll back to the snapshot if any step fails

If you don't have a real app yet, you can skip this step — it's safe to leave unused.

### 6. Automate everything with cron
Open `setup_cron.sh` and edit the three variables at the top:
```bash
SOURCE_TO_BACKUP="/home/yourname/myproject"
BACKUP_DESTINATION="$PROJECT_DIR/backups"
CLEANUP_TARGET="/tmp"
```
Then run it once:
```bash
./setup_cron.sh
```
This installs two cron jobs:
- **Backup** — runs every day at 2:00 AM
- **Cleanup** — runs every Sunday at 3:30 AM

Verify the cron jobs were installed:
```bash
crontab -l
```

### 7. Monitor logs over time
Every script writes timestamped logs to `logs/<script>_<date>.log`. Errors are
also printed to stderr so cron can email them to you if your system has mail
configured. To remove logs older than 14 days automatically, `backup.sh`
already calls the log-rotation helper each time it runs.

## How Error Handling Works
`lib_common.sh` is sourced by every script and provides:
- `log_info`, `log_warn`, `log_error` — consistent timestamped logging to both
  screen and a log file
- `die "message"` — logs an error and exits immediately (used after any risky
  command, e.g. `mkdir ... || die "..."`)
- `set -u` and `set -o pipefail` — the scripts stop on undefined variables and
  on failures inside piped commands
- A global `trap ... ERR` — catches any unexpected command failure anywhere in
  the script and logs the exact line number before exiting

This means a half-finished, silently-broken backup or deployment should never
happen — the scripts fail loudly and log exactly what went wrong.

## Purpose & Use

**Problem it solves:** Manually backing up folders, clearing out temp/log
clutter, and deploying code updates are repetitive chores that are easy to
forget or get wrong under pressure.

**What this project gives you:**
- **backup.sh** — protects your data by creating dated, compressed archives
  and automatically discarding ones that are too old to need.
- **cleanup.sh** — keeps disk usage under control by removing stale temp/log
  files and empty directories, with a safe `--dry-run` preview mode.
- **deploy.sh** — gives you a repeatable, safer way to push code updates with
  automatic rollback if something breaks mid-deployment.
- **lib_common.sh** — ensures every script behaves consistently: clear logs,
  predictable error messages, and no silent failures.
- **setup_cron.sh** — turns the above into a "set it and forget it" system
  using cron, Linux's built-in task scheduler.

**Who it's for:** Beginners learning Bash scripting, cron, log management, and
error handling, as well as anyone running a small personal server, side
project, or home lab who wants reliable, hands-off backups and cleanup without
paying for or learning a heavier DevOps tool.
