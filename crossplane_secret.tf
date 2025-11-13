###############################################################################
# Create the LocalStack test credentials Secret (for ProviderConfig to consume)
# NOTE: This uses literal "test"/"test" as in the LocalStack docs.
###############################################################################
resource "kubernetes_secret_v1" "localstack_aws_secret" {
  metadata {
    name      = "localstack-aws-secret"
    namespace = "crossplane-system"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"
  data = {
    # key must be "creds" and hold INI text (base64 here)
    creds = base64encode(<<-INI
      [default]
      aws_access_key_id = test
      aws_secret_access_key = test
    INI
    )
  }

  lifecycle {
    ignore_changes = [data] # avoid drift if something touches it
  }
}
