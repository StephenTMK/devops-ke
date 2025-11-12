############################
# NO SECRETS IN TF STATE
# We DO NOT create Kubernetes Secrets from Terraform to avoid leaking into tfstate.
# Crossplane ProviderConfig still expects a Secret named:
#   - namespace: crossplane-system
#   - name: aws-creds-localstack
#   - key:  creds   (INI format)
#
# This file keeps only inputs and a guard that fails if someone tries to enable creation here.
############################

variable "enable_crossplane_secret" {
  description = "Must remain false. If set true, plan will fail (to keep secrets out of TF state)."
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "LocalStack AWS access key id (provided via secure env, not used by TF)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "LocalStack AWS secret access key (provided via secure env, not used by TF)."
  type        = string
  default     = ""
  sensitive   = true
}

# Hard guard: never allow secret creation from TF in this repo.
locals {
  _secret_creation_guard = var.enable_crossplane_secret ? tobool("fail") : true
}

# Optional: emit a helpful message at plan/apply time if someone toggles the flag.
resource "null_resource" "no_tf_secret" {
  triggers = {
    guard = tostring(local._secret_creation_guard)
  }
}
