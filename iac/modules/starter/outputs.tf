output "starter_url" {
  description = "URL to start the Minecraft server"
  value       = google_cloudfunctions2_function.starter.url
}

output "function_name" {
  description = "Name of the starter function"
  value       = google_cloudfunctions2_function.starter.name
}
