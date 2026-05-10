#!/bin/bash
# ─────────────────────────────────────────
# Paperless Backup Script
# Runs document export + PostgreSQL dump
# ─────────────────────────────────────────

set -e

BACKUP_DIR=/data/paperless/backups
EXPORT_DIR=/data/paperless/export
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
QNAP_BACKUP=/mnt/qnap/data-media/backups/paperless
LOG=/var/log/paperless-backup.log

printf "%s : Starting Paperless backup\n" "$(date "+%d.%m.%Y %T")" >> $LOG

# ── Step 1: Paperless document export ──
printf "%s : Running document export\n" "$(date "+%d.%m.%Y %T")" >> $LOG
docker exec paperless-ngx document_exporter /usr/src/paperless/export >> $LOG 2>&1
printf "%s : Document export complete\n" "$(date "+%d.%m.%Y %T")" >> $LOG

# ── Step 2: PostgreSQL dump ──
printf "%s : Running PostgreSQL dump\n" "$(date "+%d.%m.%Y %T")" >> $LOG
mkdir -p $BACKUP_DIR
docker exec paperless-db pg_dump -U paperless paperless > $BACKUP_DIR/paperless_$TIMESTAMP.sql
# Keep only last 7 dumps
ls -t $BACKUP_DIR/paperless_*.sql | tail -n +8 | xargs -r rm
printf "%s : PostgreSQL dump complete\n" "$(date "+%d.%m.%Y %T")" >> $LOG

# ── Step 3: Rsync to QNAP ──
if ping -c 1 -W 5 192.168.1.100 > /dev/null 2>&1; then
    printf "%s : Rsyncing to QNAP\n" "$(date "+%d.%m.%Y %T")" >> $LOG
    mkdir -p $QNAP_BACKUP
    rsync -av --delete $EXPORT_DIR/ $QNAP_BACKUP/export/ >> $LOG 2>&1
    rsync -av $BACKUP_DIR/ $QNAP_BACKUP/db-dumps/ >> $LOG 2>&1
    printf "%s : Rsync to QNAP complete\n" "$(date "+%d.%m.%Y %T")" >> $LOG
else
    printf "%s : QNAP unreachable, skipping rsync\n" "$(date "+%d.%m.%Y %T")" >> $LOG
fi

printf "%s : Backup complete\n" "$(date "+%d.%m.%Y %T")" >> $LOG
