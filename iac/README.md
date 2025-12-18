# Infraestructura Cloud (Terraform)

Despliegue del servidor de Minecraft en Google Cloud Platform usando Terraform.

## Requisitos

### Herramientas

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Cuenta de GCP con billing habilitado

### Permisos GCP

El usuario o service account necesita estos roles:
- `roles/compute.admin`
- `roles/storage.admin`
- `roles/cloudfunctions.admin`
- `roles/iam.serviceAccountAdmin`
- `roles/secretmanager.admin`

## Estructura

```
iac/
├── environments/
│   └── dev/                     # Ambiente de desarrollo
│       ├── main.tf              # Configuración principal
│       ├── variables.tf         # Definición de variables
│       ├── terraform.tfvars     # Valores de variables
│       └── outputs.tf           # Outputs
└── modules/
    ├── minecraft/               # Módulo orquestador
    │   ├── templates/
    │   │   └── startup.sh.tpl   # Script de inicio de VM
    │   └── scripts/
    │       ├── backup.sh        # Script de backup
    │       └── autoshutdown.sh  # Script de auto-apagado
    ├── compute/                 # VM de Minecraft
    ├── network/                 # Firewall e IP estática
    ├── storage/                 # Buckets y disco persistente
    ├── discord/                 # Bot de Discord
    │   └── src/
    │       └── index.js
    └── starter/                 # API HTTP para iniciar servidor
```

## Despliegue Inicial

### 1. Autenticarse en GCP

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project TU_PROYECTO_ID
```

### 2. Configurar variables

```bash
cd iac/environments/dev

# Editar terraform.tfvars
cat > terraform.tfvars << 'EOF'
project_id        = "tu-proyecto-id"
region            = "us-central1"
zone              = "us-central1-a"
minecraft_version = "1.21.4"
java_image_tag    = "java21"
memory            = "10G"
ops_player        = "tu_usuario_minecraft"
rcon_password     = "tu_password_seguro"
discord_bot_token = "tu_token_de_discord"       # Si usas Discord
discord_public_key = "tu_public_key_de_discord" # Si usas Discord
EOF
```

### 3. Inicializar y desplegar

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verificar despliegue

```bash
# Ver outputs
terraform output

# SSH a la VM
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap

# Ver logs del servidor
sudo docker logs minecraft-server -f
```

## Outputs Importantes

Después del `terraform apply`:

| Output | Descripción |
|--------|-------------|
| `server_ip` | IP pública del servidor |
| `server_address` | IP:Puerto para conectar |
| `ssh_command` | Comando para SSH |
| `logs_command` | Comando para ver logs |
| `backup_command` | Comando para backup manual |
| `starter_url` | URL para iniciar servidor vía HTTP |
| `discord_interactions_url` | URL para configurar bot de Discord |

## Gestión del Servidor

### Iniciar/Apagar desde Discord

```
/server start   # Inicia el servidor
/server stop    # Apaga el servidor
/server status  # Ver estado e IP
```

### Iniciar vía HTTP

```bash
curl -X POST https://us-central1-TU_PROYECTO.cloudfunctions.net/minecraft-server-starter
```

### SSH y comandos

```bash
# SSH
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap

# Ver logs
sudo docker logs minecraft-server -f

# Ejecutar comando RCON
sudo docker exec minecraft-server rcon-cli list
sudo docker exec minecraft-server rcon-cli whitelist add Jugador

# Backup manual
sudo /opt/minecraft/backup.sh minecraft-server-dev-minecraft-backups
```

## Buckets de GCS

### Config Bucket

Contiene plugins y scripts descargados al inicio:

```
gs://PROJECT_ID-minecraft-config/
├── plugins/
│   ├── EssentialsX.jar
│   ├── EssentialsXChat.jar
│   ├── EssentialsXSpawn.jar
│   └── Vault.jar
└── scripts/
    ├── backup.sh
    └── autoshutdown.sh
```

**Agregar un plugin:**
```bash
gsutil cp MiPlugin.jar gs://PROJECT_ID-minecraft-config/plugins/
# Reiniciar servidor para cargar
```

**Actualizar scripts:**
```bash
gsutil cp scripts/backup.sh gs://PROJECT_ID-minecraft-config/scripts/
```

### Backups Bucket

Backups automáticos cada 4 horas:

```bash
# Listar backups
gsutil ls -l gs://PROJECT_ID-minecraft-backups/backups/ | tail -10

# Descargar backup
gsutil cp gs://PROJECT_ID-minecraft-backups/backups/world-backup-YYYYMMDD-HHMMSS.tar.gz /tmp/
```

## Restaurar Backup

```bash
# 1. SSH al servidor
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap

# 2. Detener servidor
sudo docker stop minecraft-server

# 3. Descargar backup
sudo gsutil cp gs://PROJECT_ID-minecraft-backups/backups/BACKUP.tar.gz /tmp/

# 4. Restaurar
cd /mnt/minecraft-data
sudo rm -rf world world_nether world_the_end
sudo tar -xzf /tmp/BACKUP.tar.gz

# 5. Iniciar servidor
sudo docker start minecraft-server
```

## Destruir Infraestructura

⚠️ **El disco persistente NO se destruye por defecto** para proteger el mundo.

```bash
# Destruir todo EXCEPTO el disco
terraform destroy

# Para destruir TODO (incluyendo mundo):
# 1. Editar storage/main.tf, cambiar prevent_destroy a false
# 2. terraform destroy
```

## Variables Principales

| Variable | Descripción | Default |
|----------|-------------|---------|
| `project_id` | ID del proyecto GCP | - |
| `region` | Región GCP | us-central1 |
| `minecraft_version` | Versión de Minecraft | 1.21.4 |
| `java_image_tag` | Tag de imagen Docker | java21 |
| `memory` | RAM para Minecraft | 10G |
| `machine_type` | Tipo de VM | e2-standard-4 |
| `ops_player` | Usuario admin | - |
| `auto_shutdown_minutes` | Minutos sin jugadores | 15 |

## Solución de Problemas

### El servidor no inicia

```bash
# Ver logs del startup script
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap \
  --command='sudo journalctl -u google-startup-scripts -f'

# Ver logs de Docker
sudo docker logs minecraft-server
```

### Bot de Discord no responde

1. Verificar que la URL de interacciones esté configurada en Discord Developer Portal
2. Ver logs de la Cloud Function:
```bash
gcloud functions logs read minecraft-discord-bot --region=us-central1
```

### Backup falló

```bash
# Ejecutar backup manual
sudo /opt/minecraft/backup.sh PROJECT_ID-minecraft-backups

# Ver logs de backup
sudo cat /var/log/minecraft-backup.log
```
