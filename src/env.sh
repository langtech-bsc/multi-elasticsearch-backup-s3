if [ -z "$S3_BUCKET" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

# if [ -z "$ELASTICSEARCH_USER" ]; then
#   echo "You need to set the ELASTICSEARCH_USER environment variable."
#   exit 1
# fi

# if [ -z "$ELASTICSEARCH_PASSWORD" ]; then
#   echo "You need to set the ELASTICSEARCH_PASSWORD environment variable."
#   exit 1
# fi

if [ -z "$S3_ENDPOINT" ]; then
  aws_args=""
else
  aws_args="--endpoint-url $S3_ENDPOINT"
fi

if [ -n "$S3_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
fi
if [ -n "$S3_SECRET_ACCESS_KEY" ]; then
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
fi
export AWS_DEFAULT_REGION=$S3_REGION
export ESPASSWORD=$ELASTICSEARCH_PASSWORD