output "server_ip" {
  description = "Minecraft server IP"
  value       = module.minecraft.server_ip
}

output "server_address" {
  description = "Connect with this address in Minecraft"
  value       = module.minecraft.server_address
}

output "ssh_command" {
  description = "SSH into the server (via IAP)"
  value       = module.minecraft.ssh_command
}

output "logs_command" {
  description = "View Minecraft logs"
  value       = module.minecraft.logs_command
}

output "instance_status" {
  description = "VM status"
  value       = module.minecraft.instance_status
}

output "backup_bucket" {
  description = "Backup bucket name"
  value       = module.minecraft.backup_bucket
}

output "backup_command" {
  description = "Manually trigger backup"
  value       = module.minecraft.backup_command
}

output "starter_url" {
  description = "URL to start the server (visit when server is off)"
  value       = module.minecraft.starter_url
}

output "discord_interactions_url" {
  description = "Set this as Interactions Endpoint URL in Discord Developer Portal"
  value       = var.discord_enabled ? module.discord[0].interactions_endpoint_url : null
}

output "discord_bot_invite_url" {
  description = "URL to invite the bot to your Discord server"
  value       = var.discord_enabled ? module.discord[0].bot_invite_url : null
}
