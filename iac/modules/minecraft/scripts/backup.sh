#!/bin/bash
set -e

DATA_DIR="/mnt/minecraft-data"
BACKUP_BUCKET="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="world-backup-$TIMESTAMP.tar.gz"

# Fallback if data dir doesn't exist
if [ ! -d "$DATA_DIR" ]; then
  DATA_DIR="/opt/minecraft/data"
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP: $1"
}

log "Starting backup..."

docker exec minecraft-server rcon-cli save-off || true
docker exec minecraft-server rcon-cli save-all || true
sleep 5

cd "$DATA_DIR"
tar -czf "/tmp/$BACKUP_FILE" world

docker exec minecraft-server rcon-cli save-on || true

if [ -n "$BACKUP_BUCKET" ]; then
  gsutil cp "/tmp/$BACKUP_FILE" "gs://$BACKUP_BUCKET/backups/$BACKUP_FILE"
  log "Backup uploaded to gs://$BACKUP_BUCKET/backups/$BACKUP_FILE"
else
  mkdir -p "$DATA_DIR/backups"
  mv "/tmp/$BACKUP_FILE" "$DATA_DIR/backups/$BACKUP_FILE"
fi

rm -f "/tmp/$BACKUP_FILE"
log "Backup completed: $BACKUP_FILE"
