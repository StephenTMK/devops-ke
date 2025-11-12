variable "enable_crossplane_secret" {
  description = "If true, create the aws-creds-localstack Secret (recommended for kind + LocalStack)."
  type        = bool
  default     = true
}

variable "aws_access_key_id" {
  description = "AWS access key id for LocalStack (supply via Spacelift env var)."
  type        = string
  default     = ""
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_access_key_id)) > 0
    error_message = "aws_access_key_id must be set (or disable enable_crossplane_secret)."
  }
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for LocalStack (supply via Spacelift env var)."
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_secret_access_key)) > 0
    error_message = "aws_secret_access_key must be set (or disable enable_crossplane_secret)."
  }
}
