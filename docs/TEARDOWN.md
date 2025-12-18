# Destrucción de Infraestructura

Guía para eliminar completamente la infraestructura cuando ya no se necesite.

## Local

### Detener el servidor

```bash
cd local
docker compose down
```

### Eliminar datos del mundo

```bash
# ⚠️ ESTO ELIMINA EL MUNDO PERMANENTEMENTE
rm -rf local/data
```

### Eliminar imágenes Docker (opcional)

```bash
docker rmi itzg/minecraft-server:java21
docker system prune -a
```

---

## Cloud (GCP)

### Paso 1: Hacer backup final (recomendado)

Antes de destruir, guarda el mundo por si quieres restaurarlo en el futuro:

```bash
# SSH al servidor
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap

# Crear backup
sudo /opt/minecraft/backup.sh minecraft-server-dev-minecraft-backups

# Descargar backup a tu máquina local
exit
gsutil cp gs://minecraft-server-dev-minecraft-backups/backups/$(gsutil ls gs://minecraft-server-dev-minecraft-backups/backups/ | tail -1 | xargs basename) ./
```

### Paso 2: Destruir infraestructura (conservando datos)

Por defecto, el disco persistente NO se elimina:

```bash
cd iac/environments/dev
terraform destroy
```

Esto elimina:
- ✅ VM (minecraft-server)
- ✅ Cloud Functions (discord-bot, starter)
- ✅ Firewall rules
- ✅ IP estática
- ✅ Service accounts
- ❌ Disco persistente (mundo)
- ❌ Buckets de Storage (backups, config)

### Paso 3: Eliminar disco persistente (opcional)

Si quieres eliminar también el disco con el mundo:

```bash
# Opción A: Desde gcloud
gcloud compute disks delete minecraft-server-dev-minecraft-data --zone=us-central1-a

# Opción B: Modificar Terraform y re-destruir
# 1. Editar iac/modules/storage/main.tf
# 2. Cambiar prevent_destroy = false
# 3. terraform destroy
```

### Paso 4: Eliminar buckets de Storage

```bash
# Ver contenido antes de eliminar
gsutil ls gs://minecraft-server-dev-minecraft-backups/
gsutil ls gs://minecraft-server-dev-minecraft-config/

# Eliminar buckets (⚠️ IRREVERSIBLE)
gsutil -m rm -r gs://minecraft-server-dev-minecraft-backups
gsutil -m rm -r gs://minecraft-server-dev-minecraft-config

# O desde Terraform (requiere force_destroy = true en el recurso)
```

### Paso 5: Limpiar estado de Terraform

```bash
cd iac/environments/dev
rm -rf .terraform
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
```

### Paso 6: Verificar que no queda nada

```bash
# Listar todos los recursos del proyecto
gcloud compute instances list
gcloud compute disks list
gcloud storage buckets list
gcloud functions list --region=us-central1

# Ver costos pendientes
# https://console.cloud.google.com/billing
```

---

## Destrucción Completa (Nuclear Option)

Si quieres eliminar TODO sin preocuparte por recursos individuales:

### Opción A: Eliminar proyecto GCP completo

```bash
# ⚠️ ELIMINA TODO EL PROYECTO Y SUS RECURSOS
gcloud projects delete TU_PROYECTO_ID
```

### Opción B: Script de limpieza

```bash
#!/bin/bash
# ⚠️ EJECUTAR CON PRECAUCIÓN

PROJECT_ID="minecraft-server-dev"
ZONE="us-central1-a"
REGION="us-central1"

# Detener y eliminar VM
gcloud compute instances delete minecraft-server --zone=$ZONE --quiet

# Eliminar disco persistente
gcloud compute disks delete minecraft-server-dev-minecraft-data --zone=$ZONE --quiet

# Eliminar Cloud Functions
gcloud functions delete minecraft-discord-bot --region=$REGION --quiet
gcloud functions delete minecraft-server-starter --region=$REGION --quiet

# Eliminar buckets
gsutil -m rm -r gs://$PROJECT_ID-minecraft-backups
gsutil -m rm -r gs://$PROJECT_ID-minecraft-config
gsutil -m rm -r gs://$PROJECT_ID-function-source
gsutil -m rm -r gs://$PROJECT_ID-discord-bot-source

# Eliminar IP estática
gcloud compute addresses delete minecraft-server-ip --region=$REGION --quiet

# Eliminar firewall rules
gcloud compute firewall-rules delete minecraft-server-ingress --quiet
gcloud compute firewall-rules delete minecraft-server-iap-ssh --quiet

# Eliminar service accounts
gcloud iam service-accounts delete minecraft-starter@$PROJECT_ID.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete minecraft-discord-bot@$PROJECT_ID.iam.gserviceaccount.com --quiet

# Eliminar secrets
gcloud secrets delete discord-bot-token --quiet

echo "Limpieza completada"
```

---

## Después de destruir

### Eliminar bot de Discord

1. Ve a [Discord Developer Portal](https://discord.com/developers/applications)
2. Selecciona tu aplicación
3. Click en **Delete App** (al final de General Information)

### Cancelar billing (si aplica)

1. Ve a [GCP Billing](https://console.cloud.google.com/billing)
2. Desvincula el proyecto o cierra la cuenta de billing

### Limpiar archivos locales

```bash
# Eliminar credenciales de GCP (opcional)
rm -rf ~/.config/gcloud

# Eliminar repositorio
cd ..
rm -rf minecraft-infra
```

---

## Restaurar después de destruir

Si conservaste el disco persistente o los backups, puedes restaurar:

### Desde disco persistente

```bash
# El disco sigue existiendo, solo haz:
terraform apply

# El mundo se restaura automáticamente
```

### Desde backup

```bash
# 1. Desplegar infraestructura nueva
terraform apply

# 2. SSH y restaurar
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap
sudo docker stop minecraft-server
cd /mnt/minecraft-data
sudo gsutil cp gs://BUCKET/backups/BACKUP.tar.gz /tmp/
sudo tar -xzf /tmp/BACKUP.tar.gz
sudo docker start minecraft-server
```
