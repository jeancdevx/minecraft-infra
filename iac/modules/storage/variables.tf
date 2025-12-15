variable "project_id" {
  description = "GCP Project ID (used for bucket naming)"
  type        = string
}

variable "location" {
  description = "Bucket location (region or multi-region)"
  type        = string
  default     = "US"
}

variable "retention_days" {
  description = "Days to keep backups before deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention must be between 1 and 365 days."
  }
}

variable "service_account_email" {
  description = "Service account email that needs write access"
  type        = string
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}
