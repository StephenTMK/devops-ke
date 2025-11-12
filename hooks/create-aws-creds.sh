#!/usr/bin/env bash
set -euo pipefail

NS="crossplane-system"
SECRET_NAME="aws-creds"

# Ensure kubectl exists on the runner (install a small static build if missing)
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found - installing..."
  curl -sSL -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl
  chmod +x /tmp/kubectl
  KUBECTL=/tmp/kubectl
else
  KUBECTL=kubectl
fi

# Obtain creds from env (Spacelift: set these as Stack Environment Variables or Mounted Variables)
AK="${AWS_ACCESS_KEY_ID:-}"
SK="${AWS_SECRET_ACCESS_KEY:-}"
if [[ -z "$AK" || -z "$SK" ]]; then
  echo "ERROR: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars are required"; exit 1
fi

# Build INI in-memory
INI="[default]
aws_access_key_id = ${AK}
aws_secret_access_key = ${SK}
"

# Create ns if missing (idempotent)
$KUBECTL get ns "$NS" >/dev/null 2>&1 || $KUBECTL create ns "$NS"

# Upsert secret idempotently (avoid exposing content in logs)
if $KUBECTL -n "$NS" get secret "$SECRET_NAME" >/dev/null 2>&1; then
  echo "Secret $NS/$SECRET_NAME exists — patching data..."
  $KUBECTL -n "$NS" create secret generic "$SECRET_NAME" \
    --from-literal=creds="$INI" \
    -o yaml --dry-run=client | $KUBECTL apply -f -
else
  echo "Creating secret $NS/$SECRET_NAME ..."
  $KUBECTL -n "$NS" create secret generic "$SECRET_NAME" \
    --from-literal=creds="$INI" >/dev/null
fi

echo "OK: secret $NS/$SECRET_NAME is present."
