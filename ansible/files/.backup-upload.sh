#!/bin/bash
set -e -u -o pipefail

. .backuprc

aws --profile=vpslite s3 cp "$1" "s3://${CONF_BUCKET}/${CONF_PREFIX}${BACKUP_DEST_FILENAME}"
