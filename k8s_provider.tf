variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Local kubeconfig path (used when k8s_host is empty)"
}

variable "k8s_host" {
  type        = string
  default     = ""
  description = "External API endpoint (e.g. https://7.tcp.eu.ngrok.io:10356)"
}

variable "k8s_token_b64" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Base64-encoded bearer token for the cluster"
}

locals {
  k8s_token_decoded = var.k8s_token_b64 != "" ? base64decode(var.k8s_token_b64) : ""
  k8s_token_trimmed = var.k8s_token_b64 != "" ? trimspace(local.k8s_token_decoded) : ""
  k8s_token_clean   = var.k8s_token_b64 != "" ? replace(replace(local.k8s_token_trimmed, "\r", ""), "\n", "") : null
}

provider "kubernetes" {
  host        = var.k8s_host != "" ? var.k8s_host : null
  token       = local.k8s_token_clean
  insecure    = var.k8s_host != "" ? true : null
  config_path = (var.k8s_host == "" && var.kubeconfig_path != "") ? var.kubeconfig_path : null

  experiments {
    # Needed for kubernetes_manifest (Argo Application CRs)
    manifest_resource = true
  }
}

provider "helm" {
  kubernetes {
    host        = var.k8s_host != "" ? var.k8s_host : null
    token       = local.k8s_token_clean
    insecure    = var.k8s_host != "" ? true : null
    config_path = (var.k8s_host == "" && var.kubeconfig_path != "") ? var.kubeconfig_path : null
  }
}
