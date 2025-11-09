resource "kubernetes_namespace" "localstack" {
  metadata {
    name = "localstack"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "localstack" {
  metadata {
    name      = "localstack"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    labels = {
      app = "localstack"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "localstack"
      }
    }

    template {
      metadata {
        labels = {
          app = "localstack"
        }
      }

      spec {
        container {
          name  = "localstack"
          image = "localstack/localstack:latest"

          env {
            name  = "SERVICES"
            value = "s3,sqs,iam,sts,lambda,cloudwatch,logs,apigateway,ssm,secretsmanager,dynamodb,ecr,ec2,ecs"
          }
          env {
            name  = "DEBUG"
            value = "0"
          }

          port {
            container_port = 4566
          }

          readiness_probe {
            http_get {
              path = "/_localstack/health"
              port = 4566
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "localstack" {
  metadata {
    name      = "localstack"
    namespace = kubernetes_namespace.localstack.metadata[0].name
  }

  spec {
    selector = {
      app = "localstack"
    }

    port {
      name        = "edge"
      port        = 4566
      target_port = 4566
      protocol    = "TCP"
    }
  }
}

# Ingress 1: Exact /localstack -> rewrite to "/"
resource "kubernetes_ingress_v1" "localstack_root" {
  metadata {
    name      = "localstack-root"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # Host = argocd.local
    rule {
      host = "argocd.local"

      http {
        path {
          path      = "/localstack"
          path_type = "Exact"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }

    # No host (ngrok wildcard)
    rule {
      http {
        path {
          path      = "/localstack"
          path_type = "Exact"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }
  }
}

# Ingress 2: /localstack/... -> strip prefix and forward (/$1)
resource "kubernetes_ingress_v1" "localstack_subpaths" {
  metadata {
    name      = "localstack-subpaths"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # Host = argocd.local
    rule {
      host = "argocd.local"

      http {
        path {
          path      = "^/localstack/?(.*)"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }

    # No host (ngrok wildcard)
    rule {
      http {
        path {
          path      = "^/localstack/?(.*)"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }
  }
}

# Ingress 3: /localstack/healthz -> force JSON from /_localstack/health
resource "kubernetes_ingress_v1" "localstack_healthz" {
  metadata {
    name      = "localstack-healthz"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"     = "/_localstack/health"
      "nginx.ingress.kubernetes.io/proxy-buffering"    = "off"
      "nginx.ingress.kubernetes.io/configuration-snippet" = <<-NGINX
        proxy_set_header Accept "application/json";
      NGINX
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "argocd.local"

      http {
        path {
          path      = "/localstack/healthz"
          path_type = "Exact"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }

    rule {
      http {
        path {
          path      = "/localstack/healthz"
          path_type = "Exact"

          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port {
                number = 4566
              }
            }
          }
        }
      }
    }
  }
}
