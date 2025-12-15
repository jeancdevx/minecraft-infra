#!/usr/bin/env bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
tar -czf "backups/world-$TIMESTAMP.tar.gz" data/world
