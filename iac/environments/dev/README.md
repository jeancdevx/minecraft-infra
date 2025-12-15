# Minecraft Server - Entorno de Desarrollo

## Prerrequisitos

### 1. Instalar Herramientas

```bash
# Terraform (https://developer.hashicorp.com/terraform/downloads)
# Verificar instalación:
terraform version
# Requerido: >= 1.0

# Google Cloud SDK (https://cloud.google.com/sdk/docs/install)
# Verificar instalación:
gcloud version
```

### 2. Configurar Google Cloud

#### 2.1 Crear/Seleccionar Proyecto

```bash
# Ver proyectos existentes
gcloud projects list

# Crear nuevo proyecto (opcional)
gcloud projects create minecraft-server-dev --name="Minecraft Server Dev"

# Seleccionar proyecto
gcloud config set project YOUR_PROJECT_ID
```

#### 2.2 Habilitar Billing

1. Ir a: https://console.cloud.google.com/billing
2. Vincular tu proyecto al billing account con los créditos

#### 2.3 Habilitar APIs Requeridas

```bash
# Compute Engine API (VMs, Firewall, IPs)
gcloud services enable compute.googleapis.com

# Verificar que está habilitada
gcloud services list --enabled | grep compute
```

### 3. Autenticación

Terraform usa Application Default Credentials (ADC) - el método recomendado por Google.

```bash
# Login con tu cuenta Google
gcloud auth login

# Crear credenciales para Terraform
gcloud auth application-default login

# Verificar autenticación
gcloud auth application-default print-access-token
```

## Despliegue

### Paso 1: Configurar Variables

```bash
cd infra/environments/dev

# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

**Valores requeridos en `terraform.tfvars`:**

```hcl
project_id    = "tu-proyecto-id"      # ID del proyecto GCP
rcon_password = "password-seguro"      # Mínimo 8 caracteres
ops_player    = "TuUsuarioMinecraft"   # Tu nombre en Minecraft
```

### Paso 2: Inicializar Terraform

```bash
terraform init
```

Esto descarga los providers necesarios (google ~> 5.0).

### Paso 3: Revisar Plan

```bash
terraform plan
```

Verifica que se crearán:
- 1 `google_compute_address` (IP estática)
- 2 `google_compute_firewall` (Minecraft + SSH)
- 1 `google_compute_instance` (VM)

### Paso 4: Aplicar

```bash
terraform apply
```

Escribe `yes` cuando te pregunte.

**Tiempo estimado:** ~2-3 minutos

### Paso 5: Obtener IP del Servidor

```bash
terraform output server_address
# Output: 35.xxx.xxx.xxx:25565
```

## Conexión

### Minecraft

1. Abrir Minecraft Java Edition **1.16.5**
2. Multijugador → Agregar servidor
3. Dirección: `<IP>:25565` (la que obtuviste arriba)

**Primera conexión:** El servidor tarda ~1-2 minutos en iniciar completamente. Si dice "Can't connect", espera un momento.

### SSH (Administración)

```bash
# Conectar a la VM
gcloud compute ssh minecraft-server --zone=us-central1-a

# Ver logs de Minecraft
sudo docker logs minecraft-server -f

# Ejecutar comando RCON
sudo docker exec minecraft-server rcon-cli list
```

## Comandos Útiles

```bash
# Ver estado del servidor
terraform output

# SSH rápido
$(terraform output -raw ssh_command)

# Ver logs
$(terraform output -raw logs_command)

# Reiniciar servidor Minecraft (sin recrear VM)
gcloud compute ssh minecraft-server --zone=us-central1-a \
  --command="sudo docker restart minecraft-server"

# Detener VM (ahorra dinero)
gcloud compute instances stop minecraft-server --zone=us-central1-a

# Iniciar VM
gcloud compute instances start minecraft-server --zone=us-central1-a
```

## Destruir Infraestructura

```bash
# ⚠️ CUIDADO: Esto borra TODO incluyendo el mundo
terraform destroy
```

Si quieres conservar el mundo, primero haz backup:

```bash
gcloud compute ssh minecraft-server --zone=us-central1-a \
  --command="sudo tar -czf /tmp/world-backup.tar.gz -C /opt/minecraft/data world"

gcloud compute scp minecraft-server:/tmp/world-backup.tar.gz ./world-backup.tar.gz --zone=us-central1-a
```

## Troubleshooting

### "Error 403: Compute Engine API not enabled"

```bash
gcloud services enable compute.googleapis.com
```

### "Error 403: Required permission"

```bash
gcloud auth application-default login
```

### "Can't connect to server"

1. Verificar que la VM está corriendo:
   ```bash
   gcloud compute instances describe minecraft-server --zone=us-central1-a --format="value(status)"
   ```

2. Verificar que Docker está corriendo:
   ```bash
   gcloud compute ssh minecraft-server --zone=us-central1-a --command="sudo docker ps"
   ```

3. Ver logs para errores:
   ```bash
   gcloud compute ssh minecraft-server --zone=us-central1-a --command="sudo docker logs minecraft-server"
   ```

## Costos

| Recurso | Costo/hora | Costo/mes (24/7) |
|---------|------------|------------------|
| e2-standard-4 | ~$0.134 | ~$97 |
| SSD 50GB | - | ~$8.50 |
| IP estática (en uso) | $0 | $0 |
| **Total 24/7** | - | **~$105** |

**Con uso típico (~4 horas/día):**
- VM: ~$0.134 × 4h × 30 = ~$16/mes
- Total: ~$25/mes

## Referencias

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [google_compute_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
- [google_compute_firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)
- [GCP Authentication](https://cloud.google.com/docs/authentication/provide-credentials-adc)
