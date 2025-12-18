#!/bin/bash

set -e

MC_DIR="/opt/minecraft"
DATA_DIR="/mnt/minecraft-data"
DATA_DISK_DEVICE="/dev/disk/by-id/google-minecraft-data"
BACKUP_BUCKET="${backup_bucket}"
CONFIG_BUCKET="${config_bucket}"
AUTO_SHUTDOWN_MINUTES="${auto_shutdown_minutes}"
JAVA_IMAGE_TAG="${java_image_tag}"

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

mount_data_disk() {
  log "Setting up data disk..."
  
  mkdir -p "$DATA_DIR"
  
  if [ ! -e "$DATA_DISK_DEVICE" ]; then
    log "Data disk not found at $DATA_DISK_DEVICE, using local storage"
    DATA_DIR="$MC_DIR/data"
    mkdir -p "$DATA_DIR"
    return 0
  fi
  
  if mountpoint -q "$DATA_DIR"; then
    log "Data disk already mounted at $DATA_DIR"
    return 0
  fi
  
  if ! blkid "$DATA_DISK_DEVICE" | grep -q "TYPE="; then
    log "Formatting data disk..."
    mkfs.ext4 -F "$DATA_DISK_DEVICE"
  fi
  
  mount "$DATA_DISK_DEVICE" "$DATA_DIR"
  
  if ! grep -q "minecraft-data" /etc/fstab; then
    echo "$DATA_DISK_DEVICE $DATA_DIR ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  log "Data disk mounted at $DATA_DIR"
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

  sudo usermod -aG docker $USER

  log "Docker installed successfully"
}

create_compose_file() {
  log "Creating docker-compose.yml..."
  
  mkdir -p "$MC_DIR"
  mkdir -p "$DATA_DIR"

  cat > "$MC_DIR/docker-compose.yml" << EOF
services:
  minecraft:
    image: itzg/minecraft-server:$JAVA_IMAGE_TAG
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
      - $DATA_DIR:/data
    restart: unless-stopped
EOF

  log "docker-compose.yml created (data at $DATA_DIR)"
}

install_plugins() {
  log "Syncing plugins from GCS..."
  
  PLUGINS_DIR="$DATA_DIR/plugins"
  mkdir -p "$PLUGINS_DIR"
  
  # Sync plugins from config bucket (if exists)
  if gsutil ls "gs://$CONFIG_BUCKET/plugins/" &>/dev/null; then
    log "Downloading plugins from gs://$CONFIG_BUCKET/plugins/..."
    gsutil -m rsync -r "gs://$CONFIG_BUCKET/plugins/" "$PLUGINS_DIR/"
    log "Plugins synced from GCS"
  else
    log "No plugins in GCS, installing defaults..."
    
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
  fi
  
  log "Plugins ready"
}

download_scripts() {
  log "Downloading management scripts from GCS..."
  
  gsutil cp "gs://$CONFIG_BUCKET/scripts/backup.sh" "$MC_DIR/backup.sh"
  gsutil cp "gs://$CONFIG_BUCKET/scripts/autoshutdown.sh" "$MC_DIR/autoshutdown.sh"
  
  chmod +x "$MC_DIR/backup.sh" "$MC_DIR/autoshutdown.sh"
  
  log "Scripts downloaded from GCS"
}

setup_backup_cron() {
  log "Setting up cron jobs..."

  cat > /etc/cron.d/minecraft << EOF
# Minecraft world backup - every 4 hours
0 */4 * * * root $MC_DIR/backup.sh $BACKUP_BUCKET >> /var/log/minecraft-backup.log 2>&1

# Auto-shutdown check - every 15 minutes
*/15 * * * * root $MC_DIR/autoshutdown.sh $AUTO_SHUTDOWN_MINUTES $BACKUP_BUCKET >> /var/log/minecraft-autoshutdown.log 2>&1
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
  
  # Mount persistent data disk first
  mount_data_disk
  
  # Clean up any stale shutdown flags
  rm -f "$DATA_DIR/.shutting_down" "$DATA_DIR/.empty_since"
  
  install_docker
  create_compose_file
  install_plugins
  download_scripts
  setup_backup_cron
  start_server
  
  EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  
  log "=== Startup Complete ==="
  log "Server: $EXTERNAL_IP:25565"
  log "Data: $DATA_DIR"
  log "Backups: Every 4 hours to gs://$BACKUP_BUCKET"
  log "Auto-shutdown: After $AUTO_SHUTDOWN_MINUTES minutes without players"
}

main
