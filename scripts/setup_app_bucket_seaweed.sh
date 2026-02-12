#!/bin/bash
set -eEu -o pipefail

APP=""
SECRET=""
WITH_LOCK=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app=*) APP="${1#*=}"; shift 1;;
        --secret=*) SECRET="${1#*=}"; shift 1;;
        --with-versioning) WITH_LOCK=1; shift 1;;
        *) echo "unknown option: $1" >&2; exit 1;;
    esac
done

if [ -z "${APP:-}" ]; then
    echo "Missing --app"
    exit 1
fi

if [ -z "${SECRET:-}" ]; then
    echo "Missing --secret"
    exit 1
fi

BUCKET=${APP//_/-}
IDENTITY=${APP//_/-}

MASTER="localhost:9333"

# Create bucket
if [ "$WITH_LOCK" -eq 1 ]; then
    weed shell -master=$MASTER <<EOF
s3.bucket.create -name $BUCKET -owner $IDENTITY -withLock
EOF
else
    weed shell -master=$MASTER <<EOF
s3.bucket.create -name $BUCKET -owner $IDENTITY
EOF
fi

# Create IAM identity
weed shell -master=$MASTER <<EOF
s3.iam.create -name $IDENTITY -access_key $IDENTITY -secret_key $SECRET
EOF

echo "Bucket and IAM identity created for $APP"
