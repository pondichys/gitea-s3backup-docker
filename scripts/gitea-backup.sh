#!/bin/bash

# Stop on errors
set -e

# Set the Gitea dump file name
GITEA_DUMP_FILE="/tmp/gitea-dump-$(date +%s).zip"

# Check that the environment variable BUCKET_NAME is set
if [[ -z "${BUCKET_NAME}" ]]; then
  echo "Environment variable BUCKET_NAME is not set!"
  exit 1
fi

echo "Running gitea dump as user git"
su - git -c "/app/gitea/gitea dump -c /data/gitea/conf/app.ini --file $GITEA_DUMP_FILE"

echo "Sending backup file to object storage"
s3cmd -c /etc/s3cmd/.s3cfg put "$GITEA_DUMP_FILE" s3://"$BUCKET_NAME"

echo "Cleaning temporary dump files"
rm -f "$GITEA_DUMP_FILE"

echo "Backup complete!"