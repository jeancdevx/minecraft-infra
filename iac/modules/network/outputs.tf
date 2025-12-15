output "static_ip" {
  description = "Static IP address"
  value       = google_compute_address.this.address
}

output "static_ip_name" {
  description = "Static IP resource name"
  value       = google_compute_address.this.name
}

output "static_ip_self_link" {
  description = "Static IP self link"
  value       = google_compute_address.this.self_link
}

output "network_tag" {
  description = "Network tag for firewall rules"
  value       = var.name_prefix
}

output "firewall_ingress_name" {
  description = "Game ingress firewall rule name"
  value       = google_compute_firewall.ingress.name
}

output "firewall_iap_ssh_name" {
  description = "IAP SSH firewall rule name (null if disabled)"
  value       = var.enable_iap_ssh ? google_compute_firewall.iap_ssh[0].name : null
}
