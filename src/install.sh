#! /bin/sh

set -eux
set -o pipefail

apk update

# install zip
apk add zip

# install npm
apk add --update npm

# install gpg
apk add gnupg

apk add aws-cli

# install go-cron
apk add curl
curl -L https://github.com/ivoronin/go-cron/releases/download/v0.0.5/go-cron_0.0.5_linux_${TARGETARCH}.tar.gz -O
tar xvf go-cron_0.0.5_linux_${TARGETARCH}.tar.gz
rm go-cron_0.0.5_linux_${TARGETARCH}.tar.gz
mv go-cron /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron
apk del curl

# install elasticsearch-dump
npm install elasticdump -g

# cleanup
rm -rf /var/cache/apk/*
