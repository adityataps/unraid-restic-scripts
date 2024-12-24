#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

DEFAULT_SCHEDULE="0 4 * * *" # Every day at 04:00
COMMAND="bash /boot/config/scripts/restic/backup.sh >> /boot/config/scripts/restic/cron.log 2>&1"

CRON_JOB="${1:-$DEFAULT_SCHEDULE} $COMMAND"

# Check if cron job already exists
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") && echo "Cron job already exists." && exit 0

# Add the cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo -e "Backup scheduled successfully.\n$CRON_JOB"

# Rotate logs
if [[ -f /etc/logrotate.d/restic ]]; then
    echo "Logrotate configuration for Restic already exists."
else
    cat > /etc/logrotate.d/restic <<EOF
/boot/config/scripts/restic/cron.log {
	weekly                 # Rotate the log file weekly
	rotate 4               # Keep 4 old log files
	compress               # Compress old log files (e.g., cron.log.1.gz)
	delaycompress          # Delay compression until the next rotation
	missingok              # Don’t throw an error if the file is missing
	notifempty             # Don’t rotate if the log is empty
	create 644 root root   # Recreate the log file with these permissions
}
EOF
	echo "Logrotate configured for Restic."
fi
