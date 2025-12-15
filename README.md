# Minecraft Hardcore Server - Google Cloud

Servidor de Minecraft 1.16.5 **Hardcore** para 8 jugadores, desplegado en Google Cloud Platform con sistema on-demand (se enciende solo, se apaga solo).

## 🎯 Características

- **Modo Hardcore** - Una vida, máxima emoción
- **PaperMC** - Rendimiento optimizado + plugins
- **On-Demand** - Solo paga cuando juegas
- **Backups automáticos** - Nunca pierdas tu mundo
- **IP/Dominio propio** - Fácil de recordar

## 📊 Especificaciones

| Recurso | Valor |
|---------|-------|
| VM | e2-standard-4 (4 vCPU, 16GB RAM) |
| Memoria Minecraft | 10GB |
| Jugadores | 8 simultáneos |
| View Distance | 12 chunks |
| Región | us-central1 (o cercana) |

## 💰 Costos Estimados

Con créditos GCP (~$270 USD, expiran Feb 2026):

| Componente | Costo/mes |
|------------|-----------|
| VM (on-demand ~4h/día) | ~$18 |
| Storage + Backups | ~$1 |
| **Total** | **~$19/mes** |

**Duración:** ~14 meses con créditos

---

## 🗺️ Roadmap

### ✅ Fase 0 - Preparación
- [x] Cuenta GCP configurada
- [x] Docker instalado localmente
- [x] Repositorio creado

### ✅ Fase 1 - Servidor Local
- [x] Docker Compose con PaperMC
- [x] Modo Hardcore configurado
- [x] Variables de entorno
- [x] Documentación local

### 🔄 Fase 2 - Deploy en GCP
- [ ] Crear proyecto GCP
- [ ] Terraform: VM e2-standard-4
- [ ] Terraform: Firewall (25565/tcp)
- [ ] Terraform: IP estática
- [ ] Script de startup

### ⏳ Fase 3 - Persistencia
- [ ] Disco persistente SSD
- [ ] Cloud Storage para backups
- [ ] Script de backup automático
- [ ] Política de snapshots

### ⏳ Fase 4 - On-Demand
- [ ] Cloud Function: start-server
- [ ] Cloud Function: stop-server (watchdog)
- [ ] Cloud Scheduler
- [ ] DNS (opcional)

### ⏳ Fase 5 - Personalización
- [ ] Plugins: EssentialsX, LuckPerms
- [ ] Mensajes de bienvenida
- [ ] Efectos y títulos
- [ ] Sistema de rankings

---

## 📁 Estructura del Proyecto

```
minecraft-infra/
├── README.md                 # Este archivo
├── local/
│   ├── docker-compose.yml    # Servidor local
│   ├── .env.example          # Variables de ejemplo
│   └── README.md             # Docs locales
└── infra/
    └── gcp/                  # (Próximamente)
        ├── main.tf
        ├── variables.tf
        └── functions/
```

---

## 🚀 Inicio Rápido (Local)

```bash
cd local
cp .env.example .env
# Editar .env con tu usuario
docker compose up -d
docker compose logs -f mc
```

Conectar: `localhost:25565` (Minecraft 1.16.5)

---

## 🔗 Referencias

- [itzg/minecraft-server](https://docker-minecraft-server.readthedocs.io/) - Imagen Docker
- [PaperMC](https://papermc.io/) - Servidor optimizado
- [Aikar's Flags](https://docs.papermc.io/paper/aikars-flags) - Optimización JVM
- [GCP Free Tier](https://cloud.google.com/free) - Créditos gratuitos
