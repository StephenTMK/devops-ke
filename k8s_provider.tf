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

variable "k8s_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Bearer token for the Kubernetes API (used when k8s_host is set)"
}

variable "k8s_ca" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Base64 cluster CA (optional when k8s_host is set)"
}

provider "kubernetes" {
  host  = var.k8s_host  != "" ? var.k8s_host  : null
  token = var.k8s_token != "" ? var.k8s_token : null

  cluster_ca_certificate = (
    var.k8s_host != "" && var.k8s_ca != ""
  ) ? base64decode(var.k8s_ca) : null

  insecure = (
    var.k8s_host != ""
  ) ? true : null

  config_path = (
    var.k8s_host == "" && var.kubeconfig_path != ""
  ) ? var.kubeconfig_path : null
}
