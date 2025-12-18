locals {
  function_name = "minecraft-discord-bot"
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "discord_bot_token" {
  secret_id = "discord-bot-token"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "discord_bot_token" {
  secret      = google_secret_manager_secret.discord_bot_token.id
  secret_data = var.discord_bot_token
}

resource "google_service_account" "discord_bot" {
  account_id   = "minecraft-discord-bot"
  display_name = "Minecraft Discord Bot"
  project      = var.project_id
}

resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.discord_bot.email}"
}

resource "google_secret_manager_secret_iam_member" "bot_token_access" {
  secret_id = google_secret_manager_secret.discord_bot_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.discord_bot.email}"
}

resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-discord-bot-source"
  location = var.region
  uniform_bucket_level_access = true
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "discord-bot-${data.archive_file.function.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function.output_path
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/function.zip"
}

resource "google_cloudfunctions2_function" "discord_bot" {
  name     = local.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "nodejs20"
    entry_point = "discordBot"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "512M"
    timeout_seconds       = 60
    service_account_email = google_service_account.discord_bot.email
    
    environment_variables = {
      PROJECT_ID         = var.project_id
      ZONE               = var.zone
      INSTANCE_NAME      = var.instance_name
      DISCORD_PUBLIC_KEY = var.discord_public_key
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.run,
  ]
}

resource "google_cloud_run_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.discord_bot.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
