#!/usr/bin/env bash
set -euo pipefail

NS="crossplane-system"
SECRET="aws-creds"

# Read from either plain env or TF vars that Spacelift injects
K8S_HOST="${K8S_HOST:-${TF_VAR_k8s_host:-}}"
K8S_TOKEN_B64="${K8S_TOKEN_B64:-${TF_VAR_k8s_token_b64:-}}"

AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"

if [[ -z "${K8S_HOST}" || -z "${K8S_TOKEN_B64}" ]]; then
  echo "FATAL: K8S_HOST / K8S_TOKEN_B64 not present. Set Terraform variables 'k8s_host' and 'k8s_token_b64' on the stack (or env K8S_HOST/K8S_TOKEN_B64)." >&2
  exit 1
fi

# download a tiny kubectl binary
KUBECTL=/tmp/kubectl
if ! command -v "$KUBECTL" >/dev/null 2>&1; then
  curl -fsSL -o "$KUBECTL" https://storage.googleapis.com/kubernetes-release/release/v1.28.4/bin/linux/amd64/kubectl
  chmod +x "$KUBECTL"
fi

# build kubeconfig from the token (skip TLS since you’re behind ngrok)
TOKEN="$(printf %s "$K8S_TOKEN_B64" | base64 -d 2>/dev/null | tr -d '\r\n')"
KCFG=/tmp/kubeconfig
cat > "$KCFG" <<YAML
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: "${K8S_HOST}"
    insecure-skip-tls-verify: true
  name: cluster
contexts:
- context:
    cluster: cluster
    user: user
  name: ctx
current-context: ctx
users:
- name: user
  user:
    token: "${TOKEN}"
YAML

# Idempotent create-or-update of the Secret (never stored in TF state)
INI="$(printf "[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n" \
      "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY")"

# If API is reachable, this "apply" is idempotent. If you truly want "skip if exists", uncomment the short-circuit below.
# if "$KUBECTL" --kubeconfig "$KCFG" -n "$NS" get secret "$SECRET" >/dev/null 2>&1; then
#   echo "Secret/$SECRET already exists – skipping."
#   exit 0
# fi

"$KUBECTL" --kubeconfig "$KCFG" -n "$NS" create secret generic "$SECRET" \
  --from-literal=creds="$INI" \
  --dry-run=client -o yaml | "$KUBECTL" --kubeconfig "$KCFG" apply -f -
