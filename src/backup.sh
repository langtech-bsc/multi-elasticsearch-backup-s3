#! /bin/sh

set -eu
set -o pipefail

source ./env.sh

echo "Creating backup of $ELASTICSEARCH_HOST indices..."

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")

sanitized_host=$(echo "$ELASTICSEARCH_HOST" | sed 's|https\?://||' | tr '.' '_' )
dump_folder="elastic_indices_$timestamp"

mkdir -p $dump_folder

multielasticdump \
  --direction=dump \
  --match='^.*$' \
  --input="http://$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD@$ELASTICSEARCH_HOST" \
  --output=$dump_folder

zip_file_name="$dump_folder.dump.zip"

zip -r -j $zip_file_name $dump_folder/*

s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}/$zip_file_name"

if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  rm -f "$zip_file_name.gpg"
  gpg --symmetric --batch --passphrase "$PASSPHRASE" $zip_file_name
  rm $zip_file_name
  local_file="$zip_file_name.gpg"
  s3_uri="${s3_uri_base}.gpg"
else
  local_file="$zip_file_name"
  s3_uri="$s3_uri_base"
fi

echo "Uploading backup to $S3_BUCKET..."
aws $aws_args s3 cp "$local_file" "$s3_uri"
rm "$local_file"

echo "Backup complete."

if [ -n "$BACKUP_KEEP_DAYS" ]; then
  sec=$((86400*BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
  backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $S3_BUCKET..."
  aws $aws_args s3api list-objects \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}" \
    --query "${backups_query}" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws $aws_args s3 rm s3://"${S3_BUCKET}"/'KEY'
  echo "Removal complete."
fi
