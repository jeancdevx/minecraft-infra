variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.name_prefix))
    error_message = "Name prefix must be lowercase, start with a letter, and max 31 characters."
  }
}

variable "region" {
  description = "GCP region for the static IP"
  type        = string
}

variable "network" {
  description = "Network name"
  type        = string
  default     = "default"
}

variable "tcp_ports" {
  description = "TCP ports to allow for game traffic"
  type        = list(string)
  default     = []
}

variable "udp_ports" {
  description = "UDP ports to allow"
  type        = list(string)
  default     = []
}

variable "source_ranges" {
  description = "Source IP ranges for game traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_iap_ssh" {
  description = "Enable SSH via IAP (secure, recommended)"
  type        = bool
  default     = true
}

variable "enable_direct_ssh" {
  description = "Enable direct SSH from internet (less secure)"
  type        = bool
  default     = false
}

variable "ssh_source_ranges" {
  description = "Source IP ranges for direct SSH (only if enable_direct_ssh=true)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
