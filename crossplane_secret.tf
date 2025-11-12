###############################################################################
# Crossplane AWS credentials Secret (optional)
# - NO secrets are committed to Git.
# - Secret is only created when var.enable_crossplane_secret = true.
###############################################################################

variable "enable_crossplane_secret" {
  description = "If true, create crossplane-system/aws-creds-localstack from the provided variables."
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key ID to put in the Secret (required when enable_crossplane_secret = true)."
  type        = string
  default     = ""
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_access_key_id)) > 0
    error_message = "aws_access_key_id must be set (non-empty) when enable_crossplane_secret=true."
  }
}

variable "aws_secret_access_key" {
  description = "AWS secret access key to put in the Secret (required when enable_crossplane_secret = true)."
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_secret_access_key)) > 0
    error_message = "aws_secret_access_key must be set (non-empty) when enable_crossplane_secret=true."
  }
}

# Compose the INI content only if we are creating the Secret.
locals {
  aws_creds_ini = <<-EOT
    [default]
    aws_access_key_id = ${var.aws_access_key_id}
    aws_secret_access_key = ${var.aws_secret_access_key}
  EOT
}

# Create the Secret only when enabled.
resource "kubernetes_secret_v1" "aws_creds_localstack" {
  count = var.enable_crossplane_secret ? 1 : 0

  metadata {
    name      = "aws-creds-localstack"
    namespace = "crossplane-system"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Use data (base64) because some provider versions don't support string_data.
  type = "Opaque"
  data = {
    creds = base64encode(local.aws_creds_ini)
  }

  # If some external reconciler edits the secret, don't flap.
  lifecycle {
    ignore_changes = [data]
  }
}
