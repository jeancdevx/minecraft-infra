variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone where instance is located"
  type        = string
}

variable "instance_name" {
  description = "Name of the Minecraft server instance"
  type        = string
}

variable "discord_application_id" {
  description = "Discord Application ID"
  type        = string
}

variable "discord_public_key" {
  description = "Discord Application Public Key"
  type        = string
}

variable "discord_bot_token" {
  description = "Discord Bot Token"
  type        = string
  sensitive   = true
}
