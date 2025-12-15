output "id" {
  description = "Instance ID"
  value       = google_compute_instance.this.id
}

output "instance_id" {
  description = "Server-assigned unique instance ID"
  value       = google_compute_instance.this.instance_id
}

output "name" {
  description = "Instance name"
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "Self link URI"
  value       = google_compute_instance.this.self_link
}

output "zone" {
  description = "Zone where instance is located"
  value       = google_compute_instance.this.zone
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address (null if no external IP)"
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}

output "status" {
  description = "Current status"
  value       = google_compute_instance.this.current_status
}
