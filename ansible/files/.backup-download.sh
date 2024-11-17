#!/bin/bash
set -e -u -o pipefail

. .backuprc

if [ -z "$1" -o -z "$2" ]; then
    printf "Arguments: <s3fileurl> <tempfile>\n" >&2
    exit 1
fi;

aws --profile=vpslite s3 cp "$1" "$2"
