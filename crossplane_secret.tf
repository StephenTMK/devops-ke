############################
# Toggleable Crossplane AWS creds Secret
# - Default: disabled (no Secret created)
# - When enabled, creates:
#     Secret:  crossplane-system/aws-creds-localstack
#     Key:     creds   (INI format expected by Upbound AWS Provider)
############################

variable "enable_crossplane_secret" {
  description = "Create the crossplane-system/aws-creds-localstack Secret if true"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key id for LocalStack (set via TF_VAR_aws_access_key_id in CI)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for LocalStack (set via TF_VAR_aws_secret_access_key in CI)"
  type        = string
  default     = ""
  sensitive   = true
}

# Build INI content only when enabled. Using coalesce to fall back to "test"
# for LocalStack if no values are injected via environment.
locals {
  aws_creds_ini = var.enable_crossplane_secret ? <<-EOT
    [default]
    aws_access_key_id = ${coalesce(var.aws_access_key_id, "test")}
    aws_secret_access_key = ${coalesce(var.aws_secret_access_key, "test")}
  EOT
  : null
}

# NOTE:
# - Use `data` (provider encodes to base64). `string_data` is not supported here.
# - Namespace must be crossplane-system to match your ProviderConfig reference.
resource "kubernetes_secret_v1" "aws_creds_localstack" {
  count = var.enable_crossplane_secret ? 1 : 0

  metadata {
    name      = "aws-creds-localstack"
    namespace = "crossplane-system"
    labels = {
      "app.kubernetes.io/part-of" = "crossplane"
    }
  }

  type = "Opaque"

  data = {
    creds = local.aws_creds_ini
  }
}
