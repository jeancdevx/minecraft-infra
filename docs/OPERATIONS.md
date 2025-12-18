# Guía de Operaciones

Manual de operaciones para el servidor de Minecraft en GCP.

## Comandos Rápidos

### SSH al servidor

```bash
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap
```

### Ver logs

```bash
# Logs del contenedor
sudo docker logs minecraft-server -f

# Logs de auto-shutdown
sudo tail -f /var/log/minecraft-autoshutdown.log

# Logs de backup
sudo tail -f /var/log/minecraft-backup.log
```

### Estado del servidor

```bash
# Ver contenedor
sudo docker ps

# Estadísticas de recursos
sudo docker stats minecraft-server

# Uso de disco
df -h /mnt/minecraft-data
```

---

## Operaciones Comunes

### Reiniciar el servidor Minecraft

```bash
# Solo el contenedor (rápido)
sudo docker restart minecraft-server

# O con docker-compose
cd /opt/minecraft && sudo docker compose restart
```

### Agregar jugador a whitelist

```bash
sudo docker exec minecraft-server rcon-cli whitelist add NombreJugador
```

### Hacer OP a un jugador

```bash
sudo docker exec minecraft-server rcon-cli op NombreJugador
```

### Enviar mensaje a todos

```bash
sudo docker exec minecraft-server rcon-cli say "Servidor reiniciará en 5 minutos"
```

### Backup manual

```bash
sudo /opt/minecraft/backup.sh minecraft-server-dev-minecraft-backups
```

---

## Mantenimiento

### Actualizar versión de Minecraft

1. Editar `terraform.tfvars`:
```hcl
minecraft_version = "1.21.5"
java_image_tag    = "java21"
```

2. Aplicar cambios:
```bash
terraform apply
```

3. La VM se recreará pero el mundo persiste en el disco.

### Actualizar plugins

1. Subir nuevos plugins a GCS:
```bash
gsutil cp NuevoPlugin.jar gs://minecraft-server-dev-minecraft-config/plugins/
```

2. Reiniciar el servidor:
```bash
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap \
  --command='sudo docker restart minecraft-server'
```

### Actualizar scripts (backup/autoshutdown)

1. Editar scripts localmente:
```bash
vim iac/modules/minecraft/scripts/backup.sh
```

2. Subir a GCS:
```bash
gsutil cp iac/modules/minecraft/scripts/backup.sh \
  gs://minecraft-server-dev-minecraft-config/scripts/
```

3. Reiniciar VM para que descargue los nuevos scripts:
```bash
gcloud compute instances reset minecraft-server --zone=us-central1-a
```

---

## Restaurar Backup

### Paso 1: Listar backups disponibles

```bash
gsutil ls -l gs://minecraft-server-dev-minecraft-backups/backups/ | tail -20
```

### Paso 2: Detener el servidor

```bash
gcloud compute ssh minecraft-server --zone=us-central1-a --tunnel-through-iap
sudo docker stop minecraft-server
```

### Paso 3: Descargar y extraer backup

```bash
cd /mnt/minecraft-data
sudo rm -rf world world_nether world_the_end

# Reemplazar YYYYMMDD-HHMMSS con el timestamp del backup deseado
sudo gsutil cp gs://minecraft-server-dev-minecraft-backups/backups/world-backup-YYYYMMDD-HHMMSS.tar.gz /tmp/
sudo tar -xzf /tmp/world-backup-*.tar.gz
sudo chown -R 1000:1000 world* plugins/
```

### Paso 4: Iniciar servidor

```bash
sudo docker start minecraft-server
sudo docker logs minecraft-server -f
```

---

## Recuperación de Desastres

### Si la VM no inicia

```bash
# Ver logs de startup
gcloud compute instances get-serial-port-output minecraft-server --zone=us-central1-a

# Forzar recreación
terraform taint module.minecraft.module.compute.google_compute_instance.this
terraform apply
```

### Si el disco está corrupto

```bash
# El disco persistente tiene snapshots automáticos (si configurados)
# O restaurar desde backup de GCS
```

### Si perdiste el mundo

1. Verificar backups en GCS
2. Seguir proceso de "Restaurar Backup"
3. Si no hay backups, el mundo se perdió

---

## Monitoreo

### Verificar auto-shutdown

```bash
# Ver logs de auto-shutdown
sudo cat /var/log/minecraft-autoshutdown.log | tail -50

# El cron se ejecuta cada 15 minutos
sudo cat /etc/cron.d/minecraft
```

### Verificar backups

```bash
# Listar últimos backups
gsutil ls -l gs://minecraft-server-dev-minecraft-backups/backups/ | tail -10

# El cron de backup se ejecuta cada 4 horas
```

### Ver uso de recursos

```bash
# En la VM
sudo docker stats minecraft-server --no-stream

# Desde local
gcloud compute instances describe minecraft-server --zone=us-central1-a \
  --format='get(status,cpuPlatform)'
```

---

## Costos

### Ver costos actuales

1. Ir a [GCP Billing](https://console.cloud.google.com/billing)
2. Filtrar por proyecto
3. Ver breakdown por servicio

### Optimizar costos

- **Auto-shutdown funciona:** Verifica `/var/log/minecraft-autoshutdown.log`
- **No dejar VM encendida sin uso:** Si nadie juega, debe apagarse sola
- **Retention de backups:** Configurado a 30 días por defecto

---

## Seguridad

### Cambiar RCON password

1. Editar `terraform.tfvars`:
```hcl
rcon_password = "nuevo_password_seguro"
```

2. Aplicar:
```bash
terraform apply
```

### Regenerar Discord bot token

1. Ir a Discord Developer Portal
2. Regenerar token
3. Actualizar en Terraform:
```hcl
discord_bot_token = "nuevo_token"
```

4. Aplicar:
```bash
terraform apply
```

---

## Contacto de Emergencia

Si el servidor tiene problemas críticos:

1. **Detener inmediatamente:**
```bash
gcloud compute instances stop minecraft-server --zone=us-central1-a
```

2. **Verificar que hay backup reciente:**
```bash
gsutil ls -l gs://minecraft-server-dev-minecraft-backups/backups/ | tail -5
```

3. **Investigar logs antes de reiniciar**
