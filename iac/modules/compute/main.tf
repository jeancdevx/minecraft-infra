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

  dynamic "attached_disk" {
    for_each = var.attached_disk_source != null ? [1] : []
    content {
      source      = var.attached_disk_source
      device_name = var.attached_disk_device_name
      mode        = "READ_WRITE"
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
    # Startup script changes will update the VM metadata on next terraform apply
    # The script runs on every boot and will use the new values
  }
}
