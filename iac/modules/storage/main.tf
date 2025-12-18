resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-minecraft-backups"
  location      = var.location
  storage_class = "STANDARD"
  
  force_destroy = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = var.labels

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_compute_disk" "minecraft_data" {
  count = var.create_data_disk ? 1 : 0

  name = "${var.project_id}-minecraft-data"
  type = var.data_disk_type
  zone = var.zone
  size = var.data_disk_size_gb

  labels = var.labels

  lifecycle {
    prevent_destroy = false
  }
}

# Config bucket for Minecraft configuration and plugins
resource "google_storage_bucket" "config" {
  name          = "${var.project_id}-minecraft-config"
  location      = var.location
  storage_class = "STANDARD"
  
  force_destroy = false

  versioning {
    enabled = true
  }

  labels = var.labels

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "config_reader" {
  bucket = google_storage_bucket.config.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email}"
}
