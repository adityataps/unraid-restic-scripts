#!/bin/bash

DEFAULT_SCHEDULE="0 4 * * *" # Every day at 04:00
COMMAND="$(pwd)/backup.sh"

CRON_JOB="${1:-$DEFAULT_SCHEDULE} $COMMAND"

# Check if cron job already exists
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") && echo "Cron job already exists." && exit 0

# Add the cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo -e "Backup scheduled successfully.\n$CRON_JOB"
