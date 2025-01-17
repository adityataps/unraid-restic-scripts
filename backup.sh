#!/bin/bash

### 0. Source .env variables
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_PATH="$SCRIPT_DIR/.env"
# shellcheck source=.env
touch "$ENV_FILE_PATH" && source "$ENV_FILE_PATH"

exec > >(tee -a "$SCRIPT_DIR/logs/cron.log") 2>&1
printf '\n\n\n==========\n'

### 1. Setup logrotate
mkdir -p "$SCRIPT_DIR/logs"
if [[ -f /etc/logrotate.d/restic ]]; then
  echo "Logrotate configuration for Restic already exists."
else
  cat >/etc/logrotate.d/restic <<EOF
$SCRIPT_DIR/logs/cron.log {
	weekly
	rotate 4
	compress
	delaycompress
	missingok
	notifempty
	create 644 root root
}
EOF
  echo "Logrotate configured for Restic."
fi

### 2. Backup
date
echo 'Backing up shares to Restic repository...'
docker run \
  --rm \
  --name='restic-backup' \
  --net='homelab' \
  --pids-limit 2048 \
  -e TZ="America/New_York" \
  -e HOST_OS="Unraid" \
  -e HOST_HOSTNAME="HomeLab" \
  -e HOST_CONTAINERNAME="restic" \
  -e RESTIC_REPOSITORY="$RESTIC_REPOSITORY" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -l net.unraid.docker.managed=dockerman \
  -l net.unraid.docker.icon='https://raw.githubusercontent.com/nwithan8/unraid_templates/master/images/restic-icon.png' \
  -v '/mnt/user/appdata/restic/password':'/pass':'rw' \
  -v '/mnt/user/aditya/':'/data/aditya/':'rw' \
  -v '/mnt/user/lydia/':'/data/lydia/':'rw' \
  -v '/mnt/user/shared/':'/data/shared/':'rw' \
  --hostname unraid 'restic/restic:latest' \
  --password-file /pass backup /data || {
  echo 'Could not back up to Restic.'
  exit 1
}
echo 'Finished backing up shares to Restic repository.'

### 3. Prune backups
echo 'Pruning backups...'
docker run \
  --rm \
  --name='restic-prune' \
  --net='homelab' \
  --pids-limit 2048 \
  -e TZ="America/New_York" \
  -e HOST_OS="Unraid" \
  -e HOST_HOSTNAME="HomeLab" \
  -e HOST_CONTAINERNAME="restic" \
  -e RESTIC_REPOSITORY="$RESTIC_REPOSITORY" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -l net.unraid.docker.managed=dockerman \
  -l net.unraid.docker.icon='https://raw.githubusercontent.com/nwithan8/unraid_templates/master/images/restic-icon.png' \
  -v '/mnt/user/appdata/restic/password':'/pass':'rw' \
  -v '/mnt/user/aditya/':'/data/aditya/':'rw' \
  -v '/mnt/user/lydia/':'/data/lydia/':'rw' \
  -v '/mnt/user/shared/':'/data/shared/':'rw' \
  --hostname unraid 'restic/restic:latest' \
  --password-file /pass forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune || {
  echo 'Could not prune Restic backups.'
  exit 1
}
echo 'Pruned backups.'
