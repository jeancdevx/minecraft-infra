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
