variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "backup_location" {
  description = "Cloud Storage location for backups"
  type        = string
  default     = "US"
}

variable "backup_retention_days" {
  description = "Days to keep backups"
  type        = number
  default     = 30
}

variable "auto_shutdown_minutes" {
  description = "Minutes without players before auto-shutdown"
  type        = number
  default     = 15
}

variable "java_image_tag" {
  description = "Docker image tag for Java version"
  type        = string
  default     = "java21"
}

variable "minecraft_version" {
  description = "Minecraft version (e.g., 1.21.4 or LATEST)"
  type        = string
  default     = "LATEST"
}

variable "server_type" {
  description = "Server type (PAPER, VANILLA, SPIGOT)"
  type        = string
  default     = "PAPER"
}

variable "memory" {
  description = "Memory for Minecraft"
  type        = string
  default     = "10G"
}

variable "max_players" {
  description = "Maximum players"
  type        = number
  default     = 8
}

variable "difficulty" {
  description = "Game difficulty"
  type        = string
  default     = "hard"
}

variable "hardcore" {
  description = "Enable hardcore mode"
  type        = bool
  default     = true
}

variable "view_distance" {
  description = "View distance in chunks"
  type        = number
  default     = 12
}

variable "motd" {
  description = "Server MOTD"
  type        = string
  default     = "§6⚔ §lHardcore Survival §6⚔"
}

variable "whitelist_enabled" {
  description = "Enable whitelist"
  type        = bool
  default     = true
}

variable "rcon_password" {
  description = "RCON password"
  type        = string
  sensitive   = true
}

variable "ops_player" {
  description = "OP player username"
  type        = string
  default     = ""
}

variable "world_seed" {
  description = "World seed"
  type        = string
  default     = ""
}

variable "discord_enabled" {
  description = "Enable Discord bot"
  type        = bool
  default     = false
}

variable "discord_application_id" {
  description = "Discord Application ID"
  type        = string
  default     = ""
}

variable "discord_public_key" {
  description = "Discord Public Key"
  type        = string
  default     = ""
}

variable "discord_bot_token" {
  description = "Discord Bot Token"
  type        = string
  sensitive   = true
  default     = ""
}
