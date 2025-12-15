resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.network_tags

  boot_disk {
    auto_delete = var.boot_disk_auto_delete

    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.external_ip != null ? [1] : []
      content {
        nat_ip = var.external_ip
      }
    }
  }

  metadata_startup_script = var.startup_script

  metadata = var.metadata

  scheduling {
    automatic_restart   = var.scheduling_automatic_restart
    on_host_maintenance = var.scheduling_on_host_maintenance
    preemptible         = var.scheduling_preemptible
  }

  labels = var.labels

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  allow_stopping_for_update = var.allow_stopping_for_update

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}
