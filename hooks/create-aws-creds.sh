#!/usr/bin/env bash
set -euo pipefail

NS="crossplane-system"
SECRET="aws-creds"

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"

INI=$(printf "[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n" \
      "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY")

kubectl -n "$NS" create secret generic "$SECRET" \
  --from-literal=creds="$INI" \
  --dry-run=client -o yaml | kubectl apply -f -
