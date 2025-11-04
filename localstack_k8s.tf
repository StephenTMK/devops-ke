# --- Namespace ---
resource "kubernetes_namespace" "localstack" {
  metadata {
    name = "localstack"
  }
}

# --- Deployment ---
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

# --- Service ---
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

# --- Ingress ---
# Path-based route: https://<your-ngrok-host>/localstack -> Service localstack:4566
# Regex + rewrite strip the "/localstack" prefix before forwarding.
resource "kubernetes_ingress_v1" "localstack" {
  metadata {
    name      = "localstack"
    namespace = kubernetes_namespace.localstack.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # Hostless rule: matches ANY Host header (works with rotating ngrok URLs)
    rule {
      http {
        path {
          path      = "/localstack(/|$)(.*)"
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
