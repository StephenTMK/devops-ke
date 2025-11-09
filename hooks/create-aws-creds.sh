#!/usr/bin/env bash
set -euo pipefail

NS="crossplane-system"
SECRET="aws-creds"

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"
: "${K8S_HOST:?K8S_HOST is required}"
: "${K8S_TOKEN_B64:?K8S_TOKEN_B64 is required}"

# 1) Minimal kubectl (Linux amd64) — no dependencies
KUBECTL=/tmp/kubectl
if ! command -v "$KUBECTL" >/dev/null 2>&1; then
  curl -fsSL -o "$KUBECTL" https://storage.googleapis.com/kubernetes-release/release/v1.28.4/bin/linux/amd64/kubectl
  chmod +x "$KUBECTL"
fi

# 2) Build a throwaway kubeconfig from env (TLS disabled since you tunnel)
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

# 3) Create/patch the Secret FROM ENV (never touches Git or TF state)
INI="$(printf "[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n" \
      "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY")"

"$KUBECTL" --kubeconfig "$KCFG" -n "$NS" create secret generic "$SECRET" \
  --from-literal=creds="$INI" \
  --dry-run=client -o yaml | "$KUBECTL" --kubeconfig "$KCFG" apply -f -
