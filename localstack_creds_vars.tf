variable "enable_crossplane_secret" {
  description = "If true, create the aws-creds-localstack secret in crossplane-system"
  type        = bool
  default     = true
}

variable "aws_access_key_id" {
  description = "AK for LocalStack (set via Stack env var)"
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_access_key_id)) > 0
    error_message = "aws_access_key_id must be set when enable_crossplane_secret=true."
  }
}

variable "aws_secret_access_key" {
  description = "SK for LocalStack (set via Stack env var)"
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = var.enable_crossplane_secret == false || length(trimspace(var.aws_secret_access_key)) > 0
    error_message = "aws_secret_access_key must be set when enable_crossplane_secret=true."
  }
}
