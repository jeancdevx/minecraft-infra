output "bucket_name" {
  description = "Name of the backup bucket"
  value       = google_storage_bucket.backups.name
}

output "bucket_url" {
  description = "URL of the backup bucket"
  value       = google_storage_bucket.backups.url
}

output "bucket_self_link" {
  description = "Self link of the bucket"
  value       = google_storage_bucket.backups.self_link
}

output "data_disk_name" {
  description = "Name of the persistent data disk"
  value       = var.create_data_disk ? google_compute_disk.minecraft_data[0].name : null
}

output "data_disk_self_link" {
  description = "Self link of the persistent data disk"
  value       = var.create_data_disk ? google_compute_disk.minecraft_data[0].self_link : null
}

output "config_bucket_name" {
  description = "Name of the config bucket"
  value       = google_storage_bucket.config.name
}
