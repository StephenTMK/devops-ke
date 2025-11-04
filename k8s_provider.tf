variable "kubeconfig_path" {
  description = "Local kubeconfig path (used when k8s_host is empty)"
  type        = string
  default     = ""
}

variable "k8s_host" {
  description = "External API endpoint (https://0.tcp.in.ngrok.io:<port>). Leave empty for local kubeconfig."
  type        = string
  default     = ""
}

variable "k8s_token" {
  description = "Bearer token for the Kubernetes API (used when k8s_host is set)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "k8s_ca" {
  description = "Base64 cluster CA (optional when k8s_host is set)"
  type        = string
  default     = ""
  sensitive   = true
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
