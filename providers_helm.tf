provider "helm" {
  alias = "alt"
  kubernetes {
    host        = var.k8s_host != "" ? var.k8s_host : null
    token       = local.k8s_token_clean
    insecure    = var.k8s_host != "" ? true : null
    config_path = (var.k8s_host == "" && var.kubeconfig_path != "") ? var.kubeconfig_path : null
  }
}
