variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the function"
  type        = string
}

variable "zone" {
  description = "GCP zone where the instance is located"
  type        = string
}

variable "instance_name" {
  description = "Name of the Minecraft server instance"
  type        = string
}
