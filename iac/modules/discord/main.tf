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
  output_path = "${path.module}/function.zip"

  source {
    content  = <<-EOF
const { InstancesClient } = require('@google-cloud/compute');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const nacl = require('tweetnacl');

const PROJECT_ID = '${var.project_id}';
const ZONE = '${var.zone}';
const INSTANCE_NAME = '${var.instance_name}';
const DISCORD_PUBLIC_KEY = '${var.discord_public_key}';

// Verify Discord request signature
function verifyDiscordRequest(req) {
  const signature = req.headers['x-signature-ed25519'];
  const timestamp = req.headers['x-signature-timestamp'];
  const body = JSON.stringify(req.body);
  
  if (!signature || !timestamp) return false;
  
  try {
    return nacl.sign.detached.verify(
      Buffer.from(timestamp + body),
      Buffer.from(signature, 'hex'),
      Buffer.from(DISCORD_PUBLIC_KEY, 'hex')
    );
  } catch {
    return false;
  }
}

async function getInstanceStatus() {
  const client = new InstancesClient();
  const [instance] = await client.get({
    project: PROJECT_ID,
    zone: ZONE,
    instance: INSTANCE_NAME,
  });
  return {
    status: instance.status,
    ip: instance.networkInterfaces?.[0]?.accessConfigs?.[0]?.natIP || 'N/A'
  };
}

async function startInstance() {
  const client = new InstancesClient();
  await client.start({
    project: PROJECT_ID,
    zone: ZONE,
    instance: INSTANCE_NAME,
  });
}

async function stopInstance() {
  const client = new InstancesClient();
  await client.stop({
    project: PROJECT_ID,
    zone: ZONE,
    instance: INSTANCE_NAME,
  });
}

exports.discordBot = async (req, res) => {
  // Verify request is from Discord
  if (!verifyDiscordRequest(req)) {
    return res.status(401).send('Invalid signature');
  }

  const { type, data } = req.body;

  // Handle Discord PING (verification)
  if (type === 1) {
    return res.json({ type: 1 });
  }

  // Handle slash commands
  if (type === 2) {
    const command = data.name;
    const subcommand = data.options?.[0]?.name;

    try {
      if (command === 'server') {
        if (subcommand === 'start') {
          const { status, ip } = await getInstanceStatus();
          
          if (status === 'RUNNING') {
            return res.json({
              type: 4,
              data: { content: '✅ El servidor ya está corriendo!\\n📍 IP: ' + ip + ':25565' }
            });
          }
          
          await startInstance();
          return res.json({
            type: 4,
            data: { content: '🚀 Iniciando servidor... Espera 2-3 minutos.' }
          });
        }
        
        if (subcommand === 'stop') {
          const { status } = await getInstanceStatus();
          
          if (status !== 'RUNNING') {
            return res.json({
              type: 4,
              data: { content: '⚠️ El servidor ya está apagado.' }
            });
          }
          
          await stopInstance();
          return res.json({
            type: 4,
            data: { content: '🛑 Apagando servidor...' }
          });
        }
        
        if (subcommand === 'status') {
          const { status, ip } = await getInstanceStatus();
          
          const emoji = status === 'RUNNING' ? '🟢' : '🔴';
          const statusText = status === 'RUNNING' ? 'Online' : 'Offline';
          
          return res.json({
            type: 4,
            data: { 
              content: emoji + ' **Estado:** ' + statusText + '\\n📍 **IP:** ' + ip + ':25565'
            }
          });
        }
      }
      
      return res.json({
        type: 4,
        data: { content: '❓ Comando no reconocido' }
      });
    } catch (error) {
      console.error(error);
      return res.json({
        type: 4,
        data: { content: '❌ Error: ' + error.message }
      });
    }
  }

  res.status(400).send('Unknown interaction type');
};
EOF
    filename = "index.js"
  }

  source {
    content  = <<-EOF
{
  "name": "minecraft-discord-bot",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/compute": "^4.0.0",
    "@google-cloud/secret-manager": "^5.0.0",
    "tweetnacl": "^1.0.3"
  }
}
EOF
    filename = "package.json"
  }
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
      PROJECT_ID    = var.project_id
      ZONE          = var.zone
      INSTANCE_NAME = var.instance_name
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
