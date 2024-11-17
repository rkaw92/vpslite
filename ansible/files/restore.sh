#!/bin/bash
set -e -u -o pipefail
shopt -s nullglob

if [ "$#" != "3" ]; then
    printf "Restore a single backup file."
    printf "Arguments: <backup_url> <provider> <item>\n"
    printf "Example: ./restore.sh s3://mybackups/vpslite-backup/backup_redis_dump.zst redis dump\n"
    exit 1
fi;

BACKUP_URL="$1"
PROVIDER_NAME="$2"
BACKUPABLE="$3"

PROVIDER_PATH="/srv/backup.d/${PROVIDER_NAME}"

if [ ! -x "$PROVIDER_PATH" ]; then
    printf "Error: backup provider ${PROVIDER_NAME} not found or file is not executable.\n"
    exit 1
fi;

TEMPFILE="$(mktemp --tmpdir=/srv/backup/tmp "restore_${PROVIDER_NAME}_${BACKUPABLE}.XXXX.zst")"
./.backup-download.sh "$BACKUP_URL" "$TEMPFILE"
unzstd <"$TEMPFILE" | "$PROVIDER_PATH" restore "$BACKUPABLE"
rm "$TEMPFILE"
