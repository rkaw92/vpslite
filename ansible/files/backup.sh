#!/bin/bash
# Note: we're not using -e because we continue on individual task failures.
set -u -o pipefail
shopt -s nullglob

. .backuprc

## Logic

genid() {
    printf "$(date -u +"%Y%m%d%H%M")XX_$(head -c 4 /dev/urandom | xxd -p)"
}

now() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

BACKUP_ID="$(genid)"
BATCH_START="$(now)"

REPORT_FILE_PART="$(mktemp --tmpdir=/srv/backup lastbackup.report.XXXX.tsv.part)"

printf "backup_id\ttask_start\ttask_end\tprovider\titem\tstatus\n" >"$REPORT_FILE_PART"

for PROVIDER_PATH in /srv/backup.d/*; do
    # Skip non-files and non-executables
    [ -f "$PROVIDER_PATH" -a -x "$PROVIDER_PATH" ] || continue
    PROVIDER_NAME="$(basename "$PROVIDER_PATH")"
    "$PROVIDER_PATH" list | while read -r BACKUPABLE; do
        # Ignore empty lines resulting from trailing \n
        [ -n "$BACKUPABLE" ] || continue
        TASK_START="$(now)"
        # Pipe the backup into a new temporary file
        TEMPFILE="$(mktemp --tmpdir=/srv/backup/tmp "backup_${PROVIDER_NAME}_${BACKUPABLE}.XXXX.zst")"
        TASK_STATUS="$?"
        if [ "$TASK_STATUS" != "0" ]; then
            printf "${BACKUP_ID}\t${TASK_START}\t${TASK_END}\t${PROVIDER_NAME}\t${BACKUPABLE}\t${TASK_STATUS}\n" >>"$REPORT_FILE_PART"
            continue
        fi;
        "$PROVIDER_PATH" backup "$BACKUPABLE" | zstd $CONF_ZSTD_FLAGS >"$TEMPFILE"
        TASK_STATUS="$?"
        if [ "$TASK_STATUS" != "0" ]; then
            printf "${BACKUP_ID}\t${TASK_START}\t${TASK_END}\t${PROVIDER_NAME}\t${BACKUPABLE}\t${TASK_STATUS}\n" >>"$REPORT_FILE_PART"
            rm "$TEMPFILE"
            continue
        fi;
        # Upload the temporary file to the backup destination
        export BACKUP_ID PROVIDER_NAME BACKUPABLE
        ./.backup-upload.sh "$TEMPFILE"
        TASK_STATUS="$?"
        TASK_END="$(now)"
        printf "${BACKUP_ID}\t${TASK_START}\t${TASK_END}\t${PROVIDER_NAME}\t${BACKUPABLE}\t${TASK_STATUS}\n" >>"$REPORT_FILE_PART"
        rm "$TEMPFILE"
    done
done

mv "$REPORT_FILE_PART" /srv/backup/lastbackup.report.tsv
