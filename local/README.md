# Servidor Minecraft Local

Servidor de Minecraft 1.16.5 **Hardcore** con PaperMC, optimizado para 8 jugadores.

## Requisitos

- Docker y Docker Compose
- 4GB RAM mínimo disponible
- Minecraft Java Edition 1.16.5

## Inicio Rápido

```bash
# 1. Copiar variables de entorno
cp .env.example .env

# 2. Editar .env con tu usuario de Minecraft
nano .env

# 3. Levantar el servidor
docker compose up -d

# 4. Ver logs (esperar "Done!")
docker compose logs -f mc
```

## Conectarse

- **Dirección:** `localhost:25565`
- **Versión:** 1.16.5

## Comandos Útiles

```bash
# Ver logs en tiempo real
docker compose logs -f mc

# Detener servidor
docker compose down

# Reiniciar
docker compose restart mc

# Ejecutar comando en consola del server
docker compose exec mc rcon-cli

# Backup manual del mundo
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/world
```

## Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `MEMORY` | 4G | RAM para el servidor |
| `OPS_PLAYER` | - | Tu usuario (admin) |
| `WHITELIST` | false | Activar whitelist |
| `RCON_PASSWORD` | minecraft | Password RCON |
| `WORLD_SEED` | - | Seed del mundo |

## Estructura de Archivos

```
local/
├── docker-compose.yml    # Configuración del servidor
├── .env.example          # Variables de ejemplo
├── .env                  # Tus variables (no commitear)
└── data/                 # Datos persistentes
    ├── world/            # El mundo
    ├── plugins/          # Plugins instalados
    └── server.properties # Config del server
```
