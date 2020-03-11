#!/usr/bin/env bash

set -euo pipefail

echo $KEY_FILE | base64 -d > ./gcloud-api-key.json

export GOOGLE_APPLICATION_CREDENTIALS=./gcloud-api-key.json
export KUBERNETES_SERVICE_HOST=

terraform init -input=false