terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.13.0"
    }
  }

  # Remote state (uncomment for production)
  # backend "gcs" {
  #   bucket = "minecraft-terraform-state"
  #   prefix = "environments/dev"
  # }
}