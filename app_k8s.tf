variable "k8s_namespace" {
  description = "Namespace for demo app"
  type        = string
  default     = "spacelift-dev"
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = var.k8s_namespace
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_config_map_v1" "hello" {
  metadata {
    name      = "hello-from-spacelift"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  data = {
    message = "Hi from local Terraform over kind!"
  }
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = {
      app = "nginx-demo"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx-demo"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx-demo"
        }
      }
      spec {
        container {
          name               = "nginx"
          image              = "nginxinc/nginx-unprivileged:1.25-alpine"
          image_pull_policy  = "IfNotPresent"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels = {
      app = "nginx-demo"
    }
  }
  spec {
    selector = {
      app = "nginx-demo"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
