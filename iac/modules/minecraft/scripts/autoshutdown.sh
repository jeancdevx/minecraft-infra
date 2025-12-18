#!/bin/bash
# Auto-shutdown when no players for X minutes

MC_DIR="/opt/minecraft"
DATA_DIR="/mnt/minecraft-data"
STATE_FILE="$DATA_DIR/.empty_since"
SHUTDOWN_AFTER_MINUTES="$1"

# Fallback if data dir doesn't exist
if [ ! -d "$DATA_DIR" ]; then
  DATA_DIR="/opt/minecraft/data"
  STATE_FILE="$DATA_DIR/.empty_since"
fi

# Skip if auto-shutdown is disabled
if [ "$SHUTDOWN_AFTER_MINUTES" = "0" ] || [ -z "$SHUTDOWN_AFTER_MINUTES" ]; then
  exit 0
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] AUTOSHUTDOWN: $1"
}

get_player_count() {
  # Check if container is running
  if ! docker ps --format '{{.Names}}' | grep -q "minecraft-server"; then
    echo "-1"
    return
  fi
  
  # Get player count via RCON (strip ANSI color codes)
  RESULT=$(docker exec minecraft-server rcon-cli list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
  
  if [ $? -ne 0 ] || [ -z "$RESULT" ]; then
    echo "-1"
    return
  fi
  
  # Parse: "There are X out of maximum Y players online"
  if echo "$RESULT" | grep -q "There are"; then
    COUNT=$(echo "$RESULT" | awk '/There are/ {print $3}')
    if [ -n "$COUNT" ] && [[ "$COUNT" =~ ^[0-9]+$ ]]; then
      echo "$COUNT"
    else
      echo "-1"
    fi
  else
    echo "-1"
  fi
}

PLAYERS=$(get_player_count)

# Validate PLAYERS is a number
if ! [[ "$PLAYERS" =~ ^-?[0-9]+$ ]]; then
  log "Invalid player count: '$PLAYERS', skipping check"
  exit 0
fi

if [ "$PLAYERS" = "-1" ]; then
  log "Server not ready, skipping check"
  exit 0
fi

if [ "$PLAYERS" -gt 0 ]; then
  log "Players online: $PLAYERS - resetting timer"
  rm -f "$STATE_FILE"
  exit 0
fi

# No players online
if [ ! -f "$STATE_FILE" ]; then
  date +%s > "$STATE_FILE"
  log "No players - starting shutdown timer"
  exit 0
fi

EMPTY_SINCE=$(cat "$STATE_FILE")
NOW=$(date +%s)
EMPTY_MINUTES=$(( (NOW - EMPTY_SINCE) / 60 ))

log "No players for $EMPTY_MINUTES minutes (shutdown after $SHUTDOWN_AFTER_MINUTES)"

if [ "$EMPTY_MINUTES" -ge "$SHUTDOWN_AFTER_MINUTES" ]; then
  # Check if already shutting down
  if [ -f "$DATA_DIR/.shutting_down" ]; then
    log "Shutdown already in progress"
    exit 0
  fi
  
  log "Shutdown threshold reached - stopping server"
  touch "$DATA_DIR/.shutting_down"
  
  # Backup before shutdown
  "$MC_DIR/backup.sh" "$2" || true
  
  # Stop the VM (use full path)
  /sbin/shutdown -h now
fi
