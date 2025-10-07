#!/bin/bash

SNAPSHOT=${1:-latest}

source /boot/config/scripts/restic/.env
docker run \
	--rm \
	--name='restic-list' \
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
  	-v '/mnt/user/immich/':'/data/immich/':'rw' \
	--hostname unraid 'restic/restic:latest' \
  	--password-file /pass ls "$SNAPSHOT" 
