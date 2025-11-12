variable "argocd_host" {
  description = "Hostname for Argo CD UI (map to your nginx controller via /etc/hosts or DNS)"
  type        = string
  default     = "argocd.local"
}

resource "kubernetes_ingress_v1" "argocd" {
  metadata {
    name      = "argocd"
    namespace = "argocd"
    annotations = {
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # host rule
    rule {
      host = var.argocd_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend { service { name = "argocd-server" port { number = 80 } } }
        }
      }
    }

    # wildcard (works with raw ngrok host header too)
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend { service { name = "argocd-server" port { number = 80 } } }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}
