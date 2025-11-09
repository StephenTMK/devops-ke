locals {
  # Only render when enabled; otherwise null so nothing is created.
  aws_creds_ini = var.enable_crossplane_secret ? (
    <<-EOT
    [default]
    aws_access_key_id = ${var.aws_access_key_id}
    aws_secret_access_key = ${var.aws_secret_access_key}
    EOT
  ) : null
}

resource "kubernetes_secret_v1" "aws_creds_localstack" {
  count = var.enable_crossplane_secret ? 1 : 0

  metadata {
    name      = "aws-creds-localstack"
    namespace = "crossplane-system"
    annotations = {
      "argocd.argoproj.io/compare-options" = "IgnoreExtraneous"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "spacelift"
    }
  }

  type = "Opaque"
  data = {
    creds = base64encode(trimspace(local.aws_creds_ini))
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [metadata]
  }
}
