variable "enable_crossplane_secret" {
  description = "Create the aws-creds-localstack Secret (set true only in Spacelift or securely)"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "LocalStack AWS access key id (required when enable_crossplane_secret=true)"
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition     = var.enable_crossplane_secret == false || length(trim(var.aws_access_key_id)) > 0
    error_message = "aws_access_key_id must be set when enable_crossplane_secret=true."
  }
}

variable "aws_secret_access_key" {
  description = "LocalStack AWS secret access key (required when enable_crossplane_secret=true)"
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition     = var.enable_crossplane_secret == false || length(trim(var.aws_secret_access_key)) > 0
    error_message = "aws_secret_access_key must be set when enable_crossplane_secret=true."
  }
}
