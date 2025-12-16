module "minecraft" {
  source = "../../modules/minecraft"

  project_id = var.project_id
  region     = var.region
  zone       = var.zone

  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb

  backup_location       = var.backup_location
  backup_retention_days = var.backup_retention_days

  auto_shutdown_minutes = var.auto_shutdown_minutes

  java_image_tag    = var.java_image_tag
  minecraft_version = var.minecraft_version
  server_type       = var.server_type
  memory            = var.memory
  max_players       = var.max_players
  difficulty        = var.difficulty
  hardcore          = var.hardcore
  view_distance     = var.view_distance
  motd              = var.motd
  whitelist_enabled = var.whitelist_enabled

  rcon_password = var.rcon_password
  ops_player    = var.ops_player
  world_seed    = var.world_seed
}

module "discord" {
  source = "../../modules/discord"
  count  = var.discord_enabled ? 1 : 0

  project_id             = var.project_id
  region                 = var.region
  zone                   = var.zone
  instance_name          = "minecraft-server"
  discord_application_id = var.discord_application_id
  discord_public_key     = var.discord_public_key
  discord_bot_token      = var.discord_bot_token
}
