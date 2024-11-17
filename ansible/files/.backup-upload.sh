#!/bin/bash
set -e -u -o pipefail

. .backuprc

DESTFILENAME=""

case "${CONF_FILE_MODE}" in
    "same")
        DESTFILENAME="backup_${PROVIDER_NAME}_${BACKUPABLE}.zst"
        ;;
    "new")
        # Note different infix: backupid_ vs backup_
        DESTFILENAME="backupid_${BACKUP_ID}_${PROVIDER_NAME}_${BACKUPABLE}.zst"
        ;;
    *)
        printf "Unsupported CONF_FILE_MODE: ${CONF_FILE_MODE}\n"
        exit 1
esac

aws --profile=vpslite s3 cp "$1" "s3://${CONF_BUCKET}/${CONF_PREFIX}${DESTFILENAME}"
