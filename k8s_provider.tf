variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Local kubeconfig path (used when k8s_host is empty)"
}

variable "k8s_host" {
  type        = string
  default     = ""
  description = "External API endpoint (https://0.tcp.in.ngrok.io:<port>). Leave empty for local kubeconfig."
}

variable "k8s_token_b64" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Base64-encoded bearer token (single line)."
}

locals {
  k8s_token_clean = (
    var.k8s_token_b64 != ""
  ) ? regexreplace(trimspace(base64decode(var.k8s_token_b64)), "\\r|\\n", "") : null
}

provider "kubernetes" {
  host        = var.k8s_host != "" ? var.k8s_host : null
  token       = local.k8s_token_clean
  insecure    = var.k8s_host != "" ? true : null
  config_path = (var.k8s_host == "" && var.kubeconfig_path != "") ? var.kubeconfig_path : null
}
