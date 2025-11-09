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
    labels = { app = "localstack" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "localstack" }
    }

    template {
      metadata { labels = { app = "localstack" } }

      spec {
        container {
          name  = "localstack"
          image = "localstack/localstack:latest"

          env { name = "SERVICES" value = "s3,sqs,iam,sts,lambda,cloudwatch,logs,apigateway,ssm,secretsmanager,dynamodb,ecr,ec2,ecs" }
          env { name = "DEBUG"    value = "0" }

          port { container_port = 4566 }

          readiness_probe {
            http_get { path = "/_localstack/health" port = 4566 }
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
    selector = { app = "localstack" }
    port {
      name        = "edge"
      port        = 4566
      target_port = 4566
      protocol    = "TCP"
    }
  }
}

# Single ingress for /localstack and all subpaths.
# Regex strips the /localstack prefix and forwards remainder as $2.
resource "kubernetes_ingress_v1" "localstack_ingress" {
  metadata {
    name      = "localstack"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # argocd.local host
    rule {
      host = "argocd.local"
      http {
        path {
          path      = "/localstack(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port { number = 4566 }
            }
          }
        }
      }
    }

    # wildcard host (no Host match)
    rule {
      http {
        path {
          path      = "/localstack(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.localstack.metadata[0].name
              port { number = 4566 }
            }
          }
        }
      }
    }
  }

  depends_on = [ time_sleep.wait_k8s_api ]
}

# Health endpoint: rewrite /localstack/healthz -> /_localstack/health.
# (configuration-snippet removed because snippets are disabled by the ingress admin)
resource "kubernetes_ingress_v1" "localstack_healthz" {
  metadata {
    name      = "localstack-healthz"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/_localstack/health"
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
              port { number = 4566 }
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
              port { number = 4566 }
            }
          }
        }
      }
    }
  }

  depends_on = [ time_sleep.wait_k8s_api ]
}
