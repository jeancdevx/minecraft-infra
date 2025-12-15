#!/bin/bash

set -e

MC_DIR="/opt/minecraft"
BACKUP_BUCKET="${backup_bucket}"
AUTO_SHUTDOWN_MINUTES="${auto_shutdown_minutes}"

MINECRAFT_VERSION="${minecraft_version}"
SERVER_TYPE="${server_type}"
MEMORY="${memory}"
DIFFICULTY="${difficulty}"
HARDCORE="${hardcore}"
MAX_PLAYERS="${max_players}"
VIEW_DISTANCE="${view_distance}"
MOTD="${motd}"
WHITELIST="${whitelist_enabled}"
OPS_PLAYER="${ops_player}"
RCON_PASSWORD="${rcon_password}"
WORLD_SEED="${world_seed}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

install_docker() {
  if command -v docker &> /dev/null; then
    log "Docker already installed: $(docker --version)"
    return 0
  fi

  log "Installing Docker..."
  
  apt-get update
  apt-get install -y ca-certificates curl

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  log "Docker installed successfully"
}

create_compose_file() {
  log "Creating docker-compose.yml..."
  
  mkdir -p "$MC_DIR/data"

  cat > "$MC_DIR/docker-compose.yml" << EOF
services:
  minecraft:
    image: itzg/minecraft-server:java16
    container_name: minecraft-server
    ports:
      - "25565:25565"
      - "25575:25575"
    environment:
      EULA: "TRUE"
      VERSION: "$MINECRAFT_VERSION"
      TYPE: "$SERVER_TYPE"
      MEMORY: "$MEMORY"
      USE_AIKAR_FLAGS: "true"
      DIFFICULTY: "$DIFFICULTY"
      HARDCORE: "$HARDCORE"
      MAX_PLAYERS: "$MAX_PLAYERS"
      VIEW_DISTANCE: "$VIEW_DISTANCE"
      SPAWN_PROTECTION: "0"
      PVP: "true"
      ALLOW_NETHER: "true"
      GENERATE_STRUCTURES: "true"
      MOTD: "$MOTD"
      WHITELIST: "$WHITELIST"
      OPS: "$OPS_PLAYER"
      ENFORCE_WHITELIST: "true"
      ENABLE_RCON: "true"
      RCON_PASSWORD: "$RCON_PASSWORD"
      RCON_PORT: "25575"
      LEVEL: "world"
      SEED: "$WORLD_SEED"
      MAX_WORLD_SIZE: "29999984"
    volumes:
      - ./data:/data
    restart: unless-stopped
EOF

  log "docker-compose.yml created"
}

install_plugins() {
  log "Installing plugins..."
  
  PLUGINS_DIR="$MC_DIR/data/plugins"
  mkdir -p "$PLUGINS_DIR"
  
  # EssentialsX (commands: /home, /spawn, /tpa, /msg, etc.)
  if [ ! -f "$PLUGINS_DIR/EssentialsX.jar" ]; then
    log "Downloading EssentialsX..."
    curl -L -o "$PLUGINS_DIR/EssentialsX.jar" \
      "https://github.com/EssentialsX/Essentials/releases/download/2.19.7/EssentialsX-2.19.7.jar"
  fi
  
  # EssentialsX Chat (chat formatting)
  if [ ! -f "$PLUGINS_DIR/EssentialsXChat.jar" ]; then
    log "Downloading EssentialsX Chat..."
    curl -L -o "$PLUGINS_DIR/EssentialsXChat.jar" \
      "https://github.com/EssentialsX/Essentials/releases/download/2.19.7/EssentialsXChat-2.19.7.jar"
  fi
  
  # EssentialsX Spawn (spawn management)
  if [ ! -f "$PLUGINS_DIR/EssentialsXSpawn.jar" ]; then
    log "Downloading EssentialsX Spawn..."
    curl -L -o "$PLUGINS_DIR/EssentialsXSpawn.jar" \
      "https://github.com/EssentialsX/Essentials/releases/download/2.19.7/EssentialsXSpawn-2.19.7.jar"
  fi
  
  # Vault (economy/permissions API)
  if [ ! -f "$PLUGINS_DIR/Vault.jar" ]; then
    log "Downloading Vault..."
    curl -L -o "$PLUGINS_DIR/Vault.jar" \
      "https://github.com/milkbowl/Vault/releases/download/1.7.3/Vault.jar"
  fi
  
  log "Plugins installed"
}

create_backup_script() {
  log "Creating backup script..."

  cat > "$MC_DIR/backup.sh" << 'BACKUP_EOF'
#!/bin/bash
set -e

MC_DIR="/opt/minecraft"
BACKUP_BUCKET="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="world-backup-$TIMESTAMP.tar.gz"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP: $1"
}

log "Starting backup..."

docker exec minecraft-server rcon-cli save-off || true
docker exec minecraft-server rcon-cli save-all || true
sleep 5

cd "$MC_DIR/data"
tar -czf "/tmp/$BACKUP_FILE" world

docker exec minecraft-server rcon-cli save-on || true

if [ -n "$BACKUP_BUCKET" ]; then
  gsutil cp "/tmp/$BACKUP_FILE" "gs://$BACKUP_BUCKET/backups/$BACKUP_FILE"
  log "Backup uploaded to gs://$BACKUP_BUCKET/backups/$BACKUP_FILE"
else
  mv "/tmp/$BACKUP_FILE" "$MC_DIR/backups/$BACKUP_FILE"
fi

rm -f "/tmp/$BACKUP_FILE"
log "Backup completed: $BACKUP_FILE"
BACKUP_EOF

  chmod +x "$MC_DIR/backup.sh"
  mkdir -p "$MC_DIR/backups"

  log "Backup script created"
}

create_autoshutdown_script() {
  log "Creating auto-shutdown script..."

  cat > "$MC_DIR/autoshutdown.sh" << 'SHUTDOWN_EOF'
#!/bin/bash
# Auto-shutdown when no players for X minutes

MC_DIR="/opt/minecraft"
STATE_FILE="$MC_DIR/.empty_since"
SHUTDOWN_AFTER_MINUTES="$1"

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
  if [ -f "$MC_DIR/.shutting_down" ]; then
    log "Shutdown already in progress"
    exit 0
  fi
  
  log "Shutdown threshold reached - stopping server"
  touch "$MC_DIR/.shutting_down"
  
  # Backup before shutdown
  "$MC_DIR/backup.sh" "$2" || true
  
  # Stop the VM (use full path)
  /sbin/shutdown -h now
fi
SHUTDOWN_EOF

  chmod +x "$MC_DIR/autoshutdown.sh"
  log "Auto-shutdown script created"
}

setup_backup_cron() {
  log "Setting up cron jobs..."

  cat > /etc/cron.d/minecraft << EOF
# Minecraft world backup - every 4 hours
0 */4 * * * root $MC_DIR/backup.sh $BACKUP_BUCKET >> /var/log/minecraft-backup.log 2>&1

# Auto-shutdown check - every 5 minutes
*/5 * * * * root $MC_DIR/autoshutdown.sh $AUTO_SHUTDOWN_MINUTES $BACKUP_BUCKET >> /var/log/minecraft-autoshutdown.log 2>&1
EOF

  chmod 644 /etc/cron.d/minecraft

  systemctl enable cron
  systemctl start cron

  log "Cron jobs configured"
}

start_server() {
  log "Starting Minecraft server..."
  cd "$MC_DIR"
  docker compose pull
  docker compose up -d
  log "Server started"
}

main() {
  log "=== Minecraft Server Startup ==="
  
  # Clean up any stale shutdown flags
  rm -f "$MC_DIR/.shutting_down" "$MC_DIR/.empty_since"
  
  install_docker
  create_compose_file
  install_plugins
  create_backup_script
  create_autoshutdown_script
  setup_backup_cron
  start_server
  
  EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  
  log "=== Startup Complete ==="
  log "Server: $EXTERNAL_IP:25565"
  log "Backups: Every 4 hours to gs://$BACKUP_BUCKET"
  log "Auto-shutdown: After $AUTO_SHUTDOWN_MINUTES minutes without players"
}

main
