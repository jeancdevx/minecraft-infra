output "server_ip" {
  description = "Server IP address for Minecraft client"
  value       = module.network.static_ip
}

output "server_address" {
  description = "Full server address (IP:port) for Minecraft client"
  value       = "${module.network.static_ip}:25565"
}

output "instance_name" {
  description = "VM instance name"
  value       = module.compute.name
}

output "instance_zone" {
  description = "VM instance zone"
  value       = module.compute.zone
}

output "instance_status" {
  description = "VM current status"
  value       = module.compute.status
}

output "ssh_command" {
  description = "gcloud command to SSH into the server (via IAP)"
  value       = "gcloud compute ssh ${module.compute.name} --zone=${module.compute.zone} --tunnel-through-iap"
}

output "logs_command" {
  description = "Command to view Minecraft server logs"
  value       = "gcloud compute ssh ${module.compute.name} --zone=${module.compute.zone} --tunnel-through-iap --command='sudo docker logs minecraft-server -f'"
}

output "backup_bucket" {
  description = "Cloud Storage bucket for backups"
  value       = module.storage.bucket_name
}

output "backup_command" {
  description = "Command to manually trigger a backup"
  value       = "gcloud compute ssh ${module.compute.name} --zone=${module.compute.zone} --tunnel-through-iap --command='sudo /opt/minecraft/backup.sh ${module.storage.bucket_name}'"
}

output "starter_url" {
  description = "URL to start the server (when stopped)"
  value       = module.starter.starter_url
}
