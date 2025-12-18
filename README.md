# Minecraft Server Infrastructure

Servidor de Minecraft **Paper 1.21.4** desplegado en Google Cloud Platform con sistema on-demand, backups automáticos y bot de Discord para control.

## Características

- **Paper 1.21.4** con Java 21
- **On-Demand** - Se enciende/apaga automáticamente
- **Disco Persistente** - El mundo sobrevive recreaciones de VM
- **Backups Automáticos** - Cada 4 horas a Cloud Storage
- **Bot de Discord** - Control del servidor con `/server start|stop|status`
- **Auto-shutdown** - Se apaga después de 15 minutos sin jugadores

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Google Cloud Platform                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────────────────────────────┐   │
│  │   Discord    │    │         Compute Engine                │   │
│  │   Bot (CF)   │───▶│  ┌────────────────────────────────┐  │   │
│  └──────────────┘    │  │     minecraft-server (VM)      │  │   │
│                      │  │  ┌────────────────────────┐    │  │   │
│  ┌──────────────┐    │  │  │   Docker Container     │    │  │   │
│  │   Starter    │───▶│  │  │   itzg/minecraft:java21│    │  │   │
│  │   API (CF)   │    │  │  └────────────────────────┘    │  │   │
│  └──────────────┘    │  │            ▲                   │  │   │
│                      │  │            │ mount             │  │   │
│                      │  │  ┌─────────┴────────┐          │  │   │
│                      │  │  │ /mnt/minecraft-  │          │  │   │
│                      │  │  │ data (50GB SSD)  │          │  │   │
│                      │  │  └──────────────────┘          │  │   │
│                      │  └────────────────────────────────┘  │   │
│                      └──────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────┐                │
│  │              Cloud Storage                   │                │
│  │  ┌─────────────────┐  ┌─────────────────┐   │                │
│  │  │ config bucket   │  │ backups bucket  │   │                │
│  │  │ - plugins/      │  │ - world backups │   │                │
│  │  │ - scripts/      │  └─────────────────┘   │                │
│  │  └─────────────────┘                        │                │
│  └─────────────────────────────────────────────┘                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Estructura del Proyecto

```
minecraft-infra/
├── README.md                    # Este archivo
├── local/                       # Desarrollo local
│   ├── docker-compose.yml       # Servidor local
│   ├── .env.example             # Variables de ejemplo
│   └── README.md                # Documentación local
└── iac/                         # Infrastructure as Code
    ├── environments/
    │   └── dev/                 # Ambiente de desarrollo
    │       ├── main.tf
    │       ├── variables.tf
    │       └── terraform.tfvars
    └── modules/
        ├── minecraft/           # Módulo principal
        │   ├── templates/
        │   │   └── startup.sh.tpl
        │   └── scripts/
        │       ├── backup.sh
        │       └── autoshutdown.sh
        ├── compute/             # VM
        ├── network/             # Firewall, IP
        ├── storage/             # Buckets, disco
        ├── discord/             # Bot de Discord
        │   └── src/
        │       └── index.js
        └── starter/             # API HTTP starter
```

## Guías

- [Desarrollo Local](./local/README.md)
- [Despliegue en Cloud](./iac/README.md)
- [Operaciones](./docs/OPERATIONS.md)

## Quick Start

### Opción 1: Local (desarrollo)

```bash
cd local
cp .env.example .env
docker compose up -d
# Conectar a localhost:25565
```

### Opción 2: Cloud (producción)

```bash
cd iac/environments/dev
terraform init
terraform apply
# Conectar a la IP mostrada en el output
```

## Costos Estimados (GCP)

| Componente | Costo/hora | Costo/mes (4h/día) |
|------------|------------|-------------------|
| VM e2-standard-4 | ~$0.13 | ~$16 |
| Disco 50GB SSD | - | ~$8 |
| Storage backups | - | ~$1 |
| **Total** | | **~$25/mes** |

## Recursos

- [itzg/minecraft-server](https://docker-minecraft-server.readthedocs.io/)
- [PaperMC](https://papermc.io/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
