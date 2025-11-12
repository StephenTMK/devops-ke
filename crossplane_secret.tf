# Creates Secret only when enabled. Nothing is committed to git.
resource "kubernetes_secret_v1" "aws_creds_localstack" {
  count = var.enable_crossplane_secret ? 1 : 0

  metadata {
    name      = "aws-creds-localstack"
    namespace = "crossplane-system"
    labels = {
      "app.kubernetes.io/part-of" = "crossplane"
    }
  }

  # IMPORTANT: INI CONTENT IN PLAIN TEXT. Crossplane expects this format.
  string_data = {
    creds = <<-EOT
      [default]
      aws_access_key_id = ${var.aws_access_key_id}
      aws_secret_access_key = ${var.aws_secret_access_key}
    EOT
  }

  type = "Opaque"
}
