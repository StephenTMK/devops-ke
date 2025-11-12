#!/usr/bin/env bash
set -euo pipefail

# Skip if not desired
: "${CREATE_CROSSPLANE_SECRET:=true}"
if [[ "${CREATE_CROSSPLANE_SECRET}" != "true" ]]; then
  echo "[info] Skipping crossplane secret creation (CREATE_CROSSPLANE_SECRET!=true)"
  exit 0
fi

# Get kubectl if missing
if ! command -v kubectl >/dev/null 2>&1; then
  echo "[info] Installing kubectl"
  curl -sSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.27.6/bin/linux/amd64/kubectl
  chmod +x /usr/local/bin/kubectl
fi

# Build kubeconfig from env if needed
if [[ -n "${K8S_HOST:-}" && -n "${K8S_TOKEN_B64:-}" ]]; then
  echo "[info] Building ephemeral kubeconfig"
  K8S_TOKEN="$(printf %s "${K8S_TOKEN_B64}" | base64 -d)"
  export KUBECONFIG="${PWD}/.kubeconfig"
  kubectl config set-cluster kind --server="${K8S_HOST}" --insecure-skip-tls-verify=true >/dev/null
  kubectl config set-credentials spacelift --token="${K8S_TOKEN}" >/dev/null
  kubectl config set-context ctx --cluster=kind --user=spacelift >/dev/null
  kubectl config use-context ctx >/dev/null
fi

# Namespace
kubectl get ns crossplane-system >/dev/null 2>&1 || kubectl create ns crossplane-system

# Values (default to LocalStack test creds if not supplied)
AK="${AWS_ACCESS_KEY_ID:-test}"
SK="${AWS_SECRET_ACCESS_KEY:-test}"

# Apply Secret without storing in TF state
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: aws-creds-localstack
  namespace: crossplane-system
type: Opaque
stringData:
  creds: |
    [default]
    aws_access_key_id = ${AK}
    aws_secret_access_key = ${SK}
EOF

echo "[ok] Secret crossplane-system/aws-creds-localstack ensured"
