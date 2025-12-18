#!/usr/bin/env bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p backups

tar -czf "backups/world-$TIMESTAMP.tar.gz" data/world data/world_nether data/world_the_end data/plugins
