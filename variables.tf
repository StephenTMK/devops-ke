variable "k8s_host" {
  description = "External API endpoint (https://host:port via ngrok)"
  type        = string
}

variable "k8s_token" {
  description = "ServiceAccount bearer token"
  type        = string
  sensitive   = true
}

variable "k8s_namespace" {
  description = "Namespace to target"
  type        = string
  default     = "spacelift-dev"
}
