# Servidor Minecraft Local

Servidor de Minecraft **Paper 1.21.11** con Docker para desarrollo y pruebas.

## Requisitos

- Docker y Docker Compose
- 4GB RAM mínimo disponible
- Minecraft Java Edition 1.21.11

## Inicio Rápido

```bash
# 1. Copiar variables de entorno
cp .env.example .env

# 2. Editar .env con tu configuración
nano .env

# 3. Levantar el servidor
docker compose up -d

# 4. Ver logs (esperar "Done!")
docker compose logs -f minecraft
```

## Conectarse

| Parámetro | Valor |
|-----------|-------|
| **Dirección** | `localhost:25565` |
| **Versión** | 1.21.11 |
| **Tipo** | Paper |

## Comandos Útiles

### Gestión del servidor

```bash
# Ver logs en tiempo real
docker compose logs -f minecraft

# Detener servidor (guarda el mundo)
docker compose down

# Reiniciar
docker compose restart minecraft

# Ver estado
docker compose ps
```

### Consola del servidor

```bash
# Abrir consola RCON
docker compose exec minecraft rcon-cli

# Ejecutar comando directo
docker compose exec minecraft rcon-cli list
docker compose exec minecraft rcon-cli whitelist add NombreJugador
docker compose exec minecraft rcon-cli op NombreJugador
```

### Backups

```bash
# Backup manual del mundo
./backup.sh

# O manualmente
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/world
```

## Variables de Entorno

Edita `.env` para configurar:

| Variable | Default | Descripción |
|----------|---------|-------------|
| `MEMORY` | 4G | RAM para el servidor |
| `OPS_PLAYER` | - | Tu usuario de Minecraft (admin) |
| `WHITELIST` | false | Activar lista blanca |
| `RCON_PASSWORD` | minecraft | Contraseña RCON |
| `WORLD_SEED` | - | Seed del mundo (vacío = aleatorio) |

## Estructura de Archivos

```
local/
├── docker-compose.yml    # Configuración del servidor
├── .env.example          # Variables de ejemplo
├── .env                  # Tus variables (NO commitear)
├── backup.sh             # Script de backup
└── data/                 # Datos persistentes (gitignored)
    ├── world/            # El mundo
    ├── world_nether/     # El Nether
    ├── world_the_end/    # El End
    ├── plugins/          # Plugins instalados
    └── server.properties # Configuración generada
```

## Diferencias con Cloud

| Aspecto | Local | Cloud |
|---------|-------|-------|
| Persistencia | `./data/` | Disco 50GB SSD |
| Backups | Manual | Automático cada 4h |
| Memoria | 4GB | 10GB |
| Auto-shutdown | No | Sí (15 min sin jugadores) |
| Discord Bot | No | Sí |

## Solución de Problemas

### El servidor no inicia

```bash
# Ver logs de error
docker compose logs minecraft

# Verificar que Docker está corriendo
docker info

# Verificar puertos
netstat -tlnp | grep 25565
```

### No puedo conectar

1. Verifica que el servidor haya iniciado (`Done!` en logs)
2. Usa la versión correcta de Minecraft (1.21.4)
3. Si usas whitelist, agrégarte: `rcon-cli whitelist add TuNombre`

### El mundo no guarda

```bash
# Forzar guardado
docker compose exec minecraft rcon-cli save-all

# Verificar permisos de ./data
ls -la data/
```
