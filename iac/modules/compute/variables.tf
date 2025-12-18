variable "name" {
  description = "Name of the instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "Name must be lowercase, start with a letter, and only contain letters, numbers, and hyphens."
  }
}

variable "machine_type" {
  description = "Machine type (e.g., e2-standard-4)"
  type        = string
  default     = "e2-medium"
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "network" {
  description = "Network to attach the instance to"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork to attach the instance to"
  type        = string
  default     = null
}

variable "network_tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "external_ip" {
  description = "External IP address (null for ephemeral, static IP address to assign)"
  type        = string
  default     = null
}

variable "boot_disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_disk_size_gb >= 10
    error_message = "Boot disk must be at least 10 GB."
  }
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-ssd"

  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.boot_disk_type)
    error_message = "Boot disk type must be pd-standard, pd-ssd, or pd-balanced."
  }
}

variable "boot_disk_auto_delete" {
  description = "Delete boot disk when instance is deleted"
  type        = bool
  default     = true
}

variable "startup_script" {
  description = "Startup script content"
  type        = string
  default     = null
}

variable "metadata" {
  description = "Metadata key/value pairs"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email (null for default compute service account)"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/compute.readonly",
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}

variable "scheduling_automatic_restart" {
  description = "Automatically restart if terminated by GCP"
  type        = bool
  default     = true
}

variable "scheduling_on_host_maintenance" {
  description = "Behavior on host maintenance (MIGRATE or TERMINATE)"
  type        = string
  default     = "MIGRATE"
}

variable "scheduling_preemptible" {
  description = "Use preemptible VM (cheaper but can be terminated)"
  type        = bool
  default     = false
}

variable "allow_stopping_for_update" {
  description = "Allow stopping instance for updates"
  type        = bool
  default     = true
}

variable "attached_disk_source" {
  description = "Self link of disk to attach (optional)"
  type        = string
  default     = null
}

variable "attached_disk_device_name" {
  description = "Device name for attached disk"
  type        = string
  default     = "minecraft-data"
}
