resource "google_compute_address" "this" {
  name         = "${var.name_prefix}-ip"
  address_type = "EXTERNAL"
  region       = var.region
  labels       = var.labels
}

resource "google_compute_firewall" "ingress" {
  name        = "${var.name_prefix}-ingress"
  network     = var.network
  description = "Allow game traffic"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = var.tcp_ports
  }

  dynamic "allow" {
    for_each = length(var.udp_ports) > 0 ? [1] : []
    content {
      protocol = "udp"
      ports    = var.udp_ports
    }
  }

  source_ranges = var.source_ranges
  target_tags   = [var.name_prefix]
}

resource "google_compute_firewall" "iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  name        = "${var.name_prefix}-iap-ssh"
  network     = var.network
  description = "Allow SSH via IAP tunnel only"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.name_prefix]
}

resource "google_compute_firewall" "direct_ssh" {
  count = var.enable_direct_ssh ? 1 : 0

  name        = "${var.name_prefix}-direct-ssh"
  network     = var.network
  description = "Allow direct SSH (less secure)"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = [var.name_prefix]
}
