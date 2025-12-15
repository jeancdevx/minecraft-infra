output "interactions_endpoint_url" {
  description = "URL to set as Interactions Endpoint in Discord Developer Portal"
  value       = google_cloudfunctions2_function.discord_bot.url
}

output "bot_invite_url" {
  description = "URL to invite the bot to your Discord server"
  value       = "https://discord.com/api/oauth2/authorize?client_id=${var.discord_application_id}&permissions=2147483648&scope=bot%20applications.commands"
}
