variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
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
  description = "Minutes without players before auto-shutdown (0 to disable)"
  type        = number
  default     = 15

  validation {
    condition     = var.auto_shutdown_minutes >= 0 && var.auto_shutdown_minutes <= 120
    error_message = "Auto-shutdown minutes must be between 0 and 120."
  }
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"
}

variable "boot_disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "game_source_ranges" {
  description = "IP ranges allowed for game connections (Minecraft port)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "minecraft_version" {
  description = "Minecraft version"
  type        = string
  default     = "1.16.5"
}

variable "server_type" {
  description = "Server type: VANILLA, PAPER, SPIGOT, PURPUR"
  type        = string
  default     = "PAPER"

  validation {
    condition     = contains(["VANILLA", "PAPER", "SPIGOT", "PURPUR"], upper(var.server_type))
    error_message = "Server type must be VANILLA, PAPER, SPIGOT, or PURPUR."
  }
}

variable "memory" {
  description = "Memory allocated to Java (e.g., 4G, 8G, 10G)"
  type        = string
  default     = "10G"

  validation {
    condition     = can(regex("^[0-9]+[GM]$", var.memory))
    error_message = "Memory must be in format like 4G or 4096M."
  }
}

variable "max_players" {
  description = "Maximum concurrent players"
  type        = number
  default     = 8

  validation {
    condition     = var.max_players >= 1 && var.max_players <= 100
    error_message = "Max players must be between 1 and 100."
  }
}

variable "difficulty" {
  description = "Game difficulty: peaceful, easy, normal, hard"
  type        = string
  default     = "hard"

  validation {
    condition     = contains(["peaceful", "easy", "normal", "hard"], lower(var.difficulty))
    error_message = "Difficulty must be peaceful, easy, normal, or hard."
  }
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

  validation {
    condition     = var.view_distance >= 2 && var.view_distance <= 32
    error_message = "View distance must be between 2 and 32."
  }
}

variable "motd" {
  description = "Server message of the day"
  type        = string
  default     = "§6⚔ §lHardcore Survival §6⚔"
}

variable "whitelist_enabled" {
  description = "Enable player whitelist"
  type        = bool
  default     = true
}

variable "rcon_password" {
  description = "RCON password for remote console"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.rcon_password) >= 8
    error_message = "RCON password must be at least 8 characters."
  }
}

variable "ops_player" {
  description = "Minecraft username to grant OP permissions"
  type        = string
  default     = ""
}

variable "world_seed" {
  description = "World generation seed (empty for random)"
  type        = string
  default     = ""
}
