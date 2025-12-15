locals {
  server_name = "minecraft-server"
  
  labels = {
    app         = "minecraft"
    version     = replace(var.minecraft_version, ".", "-")
    server_type = lower(var.server_type)
    managed_by  = "terraform"
  }
}

module "network" {
  source = "../network"

  name_prefix = local.server_name
  region      = var.region
  network     = var.network

  tcp_ports     = ["25565"]
  source_ranges = var.game_source_ranges

  enable_iap_ssh    = true
  enable_direct_ssh = false

  labels = local.labels
}

module "storage" {
  source = "../storage"

  project_id            = var.project_id
  location              = var.backup_location
  retention_days        = var.backup_retention_days
  service_account_email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  labels = local.labels
}

data "google_project" "current" {
  project_id = var.project_id
}

module "compute" {
  source = "../compute"

  name         = local.server_name
  zone         = var.zone
  machine_type = var.machine_type
  network      = var.network
  network_tags = [module.network.network_tag]
  external_ip  = module.network.static_ip

  boot_disk_image   = var.boot_disk_image
  boot_disk_size_gb = var.disk_size_gb
  boot_disk_type    = var.disk_type

  startup_script = templatefile("${path.module}/templates/startup.sh.tpl", {
    minecraft_version     = var.minecraft_version
    server_type           = var.server_type
    memory                = var.memory
    max_players           = var.max_players
    difficulty            = var.difficulty
    hardcore              = var.hardcore
    view_distance         = var.view_distance
    motd                  = var.motd
    rcon_password         = var.rcon_password
    ops_player            = var.ops_player
    world_seed            = var.world_seed
    whitelist_enabled     = var.whitelist_enabled
    backup_bucket         = module.storage.bucket_name
    auto_shutdown_minutes = var.auto_shutdown_minutes
  })

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = local.labels

  allow_stopping_for_update = true
}

module "starter" {
  source = "../starter"

  project_id    = var.project_id
  region        = var.region
  zone          = var.zone
  instance_name = local.server_name
}

