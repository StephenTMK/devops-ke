variable "enable_crossplane_secret" {
  type        = bool
  default     = false
  description = "If true, create the aws-creds-localstack Secret from provided values."
}

variable "aws_access_key_id" {
  type        = string
  sensitive   = true
  description = "LocalStack AWS access key id (required when enable_crossplane_secret = true)."
  validation {
    condition     = (!var.enable_crossplane_secret) || (length(trimspace(var.aws_access_key_id)) > 0)
    error_message = "aws_access_key_id must be non-empty when enable_crossplane_secret = true."
  }
}

variable "aws_secret_access_key" {
  type        = string
  sensitive   = true
  description = "LocalStack AWS secret access key (required when enable_crossplane_secret = true)."
  validation {
    condition     = (!var.enable_crossplane_secret) || (length(trimspace(var.aws_secret_access_key)) > 0)
    error_message = "aws_secret_access_key must be non-empty when enable_crossplane_secret = true."
  }
}
