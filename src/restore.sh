#! /bin/sh

set -u # `-e` omitted intentionally, but i can't remember why exactly :'(
set -o pipefail

source ./env.sh

s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}"

if [ -z "$PASSPHRASE" ]; then
  file_type=".dump.zip"
else
  file_type=".dump.zip.gpg"
fi

if [ $# -eq 1 ]; then
  timestamp="$1"
  key_suffix="elastic_indices_${timestamp}${file_type}"
else
  echo "Finding latest backup..."
  key_suffix=$(
    aws $aws_args s3 ls "${s3_uri_base}/elastic_indices_" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
fi

echo "Fetching backup from S3..."
aws $aws_args s3 cp "${s3_uri_base}/${key_suffix}" "restore${file_type}"

if [ -n "$PASSPHRASE" ]; then
  echo "Decrypting backup..."
  gpg --decrypt --batch --passphrase "$PASSPHRASE" restore.dump.zip.gpg > restore.dump.zip
  rm restore.dump.zip.gpg
fi


unzip restore.dump.zip -d restore_dump_dir
rm restore.dump.zip

multielasticdump \
  --direction=load \
  --match='^.*$' \
  --input=restore_dump_dir \
  --output="http://$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD@$ELASTICSEARCH_HOST"

rm -rf restore_dump_dir

echo "Restore complete."
