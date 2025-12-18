# Configuración del Bot de Discord

Guía para configurar el bot de Discord que controla el servidor de Minecraft.

## Requisitos Previos

- Cuenta de Discord
- Permisos de administrador en el servidor de Discord donde usarás el bot
- Infraestructura de Terraform desplegada

## Paso 1: Crear Aplicación en Discord

1. Ve a [Discord Developer Portal](https://discord.com/developers/applications)

2. Click en **"New Application"**

3. Nombre: `Minecraft Server` (o el que prefieras)

4. Click en **"Create"**

## Paso 2: Obtener Credenciales

### Application ID
- En la página de tu aplicación, copia el **Application ID**
- Lo usarás para la URL de invitación

### Public Key
- En la sección **General Information**
- Copia el **Public Key**
- Lo necesitas para `discord_public_key` en Terraform

### Bot Token
1. Ve a la sección **Bot** (menú izquierdo)
2. Click en **"Reset Token"** (o "Add Bot" si es nuevo)
3. Copia el **Token** generado
4. ⚠️ **Guárdalo seguro**, solo se muestra una vez
5. Lo necesitas para `discord_bot_token` en Terraform

## Paso 3: Configurar Terraform

Edita `iac/environments/dev/terraform.tfvars`:

```hcl
# Discord Bot
discord_bot_token  = "MTQ0NjE4OTI0MjE1...tu_token_aqui"
discord_public_key = "7b20fac724951da44c605e5095019df498bf542427add8a807a6e580498a0f1c"
```

Aplica los cambios:

```bash
cd iac/environments/dev
terraform apply
```

## Paso 4: Configurar Interactions URL

Después del `terraform apply`, obtén la URL de la función:

```bash
terraform output discord_interactions_url
```

Resultado ejemplo:
```
https://us-central1-tu-proyecto.cloudfunctions.net/minecraft-discord-bot
```

1. Ve a Discord Developer Portal → Tu aplicación
2. Sección **General Information**
3. En **Interactions Endpoint URL**, pega la URL
4. Click en **Save Changes**

> Discord verificará la URL automáticamente. Si falla, revisa los logs de la Cloud Function.

## Paso 5: Registrar Comandos Slash

Los comandos se registran una sola vez. Ejecuta:

```bash
cd iac/modules/discord
chmod +x register_commands.sh
./register_commands.sh
```

O manualmente con curl:

```bash
# Reemplaza YOUR_APP_ID y YOUR_BOT_TOKEN
curl -X POST \
  "https://discord.com/api/v10/applications/YOUR_APP_ID/commands" \
  -H "Authorization: Bot YOUR_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "server",
    "description": "Control del servidor de Minecraft",
    "options": [
      {
        "name": "start",
        "description": "Iniciar el servidor",
        "type": 1
      },
      {
        "name": "stop",
        "description": "Apagar el servidor",
        "type": 1
      },
      {
        "name": "status",
        "description": "Ver estado del servidor",
        "type": 1
      }
    ]
  }'
```

## Paso 6: Invitar Bot al Servidor

Genera URL de invitación:

```bash
terraform output discord_bot_invite_url
```

O construye manualmente:
```
https://discord.com/api/oauth2/authorize?client_id=TU_APP_ID&permissions=2147483648&scope=bot%20applications.commands
```

1. Abre la URL en el navegador
2. Selecciona tu servidor de Discord
3. Autoriza los permisos
4. ¡Listo!

## Uso del Bot

En cualquier canal del servidor de Discord:

| Comando | Descripción |
|---------|-------------|
| `/server start` | Inicia la VM de Minecraft |
| `/server stop` | Apaga la VM |
| `/server status` | Muestra estado e IP |

### Ejemplos de respuestas

**Status (servidor encendido):**
```
🟢 Estado: Online
📍 IP: 34.59.80.125:25565
```

**Status (servidor apagado):**
```
🔴 Estado: Offline
📍 IP: N/A:25565
```

**Start:**
```
🚀 Iniciando servidor... Espera 2-3 minutos.
```

## Solución de Problemas

### "La aplicación no respondió"

**Causa:** Cold start de Cloud Functions (ya debería estar arreglado con respuestas diferidas).

**Verificar:**
```bash
gcloud functions logs read minecraft-discord-bot --region=us-central1 --limit=20
```

### Comando no aparece

**Causa:** Comandos no registrados.

**Solución:** Ejecutar `register_commands.sh` de nuevo. Los comandos globales tardan hasta 1 hora en propagarse.

### "Invalid signature"

**Causa:** `discord_public_key` incorrecto en Terraform.

**Solución:**
1. Verifica el Public Key en Discord Developer Portal
2. Actualiza `terraform.tfvars`
3. `terraform apply`

### Bot no responde en absoluto

1. Verificar que la Cloud Function existe:
```bash
gcloud functions list --region=us-central1
```

2. Ver logs:
```bash
gcloud functions logs read minecraft-discord-bot --region=us-central1
```

3. Verificar Interactions URL en Discord Developer Portal

## Arquitectura

```
Discord                     GCP
┌──────────┐               ┌─────────────────────┐
│  Usuario │               │   Cloud Functions   │
│  /server │──────────────▶│  minecraft-discord  │
│  status  │               │       -bot          │
└──────────┘               └─────────┬───────────┘
                                     │
     ┌───────────────────────────────┘
     ▼
┌─────────────────────┐
│   Compute Engine    │
│   minecraft-server  │
│   (start/stop/get)  │
└─────────────────────┘
```

## Referencias

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Interactions](https://discord.com/developers/docs/interactions/receiving-and-responding)
- [Slash Commands](https://discord.com/developers/docs/interactions/application-commands)
