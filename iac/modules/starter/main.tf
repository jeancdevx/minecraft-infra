locals {
  function_name = "minecraft-server-starter"
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

resource "google_service_account" "starter" {
  account_id   = "minecraft-starter"
  display_name = "Minecraft Server Starter"
  project      = var.project_id
}

resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.starter.email}"
}

resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-function-source"
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "minecraft-starter-${filemd5(data.archive_file.function.output_path)}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function.output_path
}

data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/function.zip"

  source {
    content  = <<-EOF
      const { InstancesClient } = require('@google-cloud/compute');

      const projectId = '${var.project_id}';
      const zone = '${var.zone}';
      const instanceName = '${var.instance_name}';

      exports.startServer = async (req, res) => {
        // CORS headers
        res.set('Access-Control-Allow-Origin', '*');
        if (req.method === 'OPTIONS') {
          res.set('Access-Control-Allow-Methods', 'GET, POST');
          res.status(204).send('');
          return;
        }

        try {
          const client = new InstancesClient();
          
          // Check current status
          const [instance] = await client.get({
            project: projectId,
            zone: zone,
            instance: instanceName,
          });

          if (instance.status === 'RUNNING') {
            res.json({ 
              status: 'already_running',
              message: 'Server is already running',
              ip: instance.networkInterfaces[0].accessConfigs[0].natIP
            });
            return;
          }

          // Start the instance
          await client.start({
            project: projectId,
            zone: zone,
            instance: instanceName,
          });

          res.json({ 
            status: 'starting',
            message: 'Server is starting. Wait 2-3 minutes.',
          });
        } catch (error) {
          console.error(error);
          res.status(500).json({ 
            status: 'error',
            message: error.message 
          });
        }
      };
    EOF
    filename = "index.js"
  }

  source {
    content  = <<-EOF
      {
        "name": "minecraft-starter",
        "version": "1.0.0",
        "dependencies": {
          "@google-cloud/compute": "^4.0.0"
        }
      }
    EOF
    filename = "package.json"
  }
}

resource "google_cloudfunctions2_function" "starter" {
  name     = local.function_name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "nodejs20"
    entry_point = "startServer"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.starter.email
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
  service  = google_cloudfunctions2_function.starter.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
