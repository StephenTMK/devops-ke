provider "kubernetes" {
  host     = var.k8s_host
  token    = var.k8s_token
  insecure = true
}

# Simple smoke test ConfigMap
resource "kubernetes_config_map" "hello" {
  metadata {
    name      = "hello-from-spacelift"
    namespace = var.k8s_namespace
  }
  data = {
    message = "Hi from local Terraform over ngrok!"
  }
}

# --- nginx Deployment ---
resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = var.k8s_namespace
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
          name  = "nginx"
          image =  "nginxinc/nginx-unprivileged:1.25-alpine" 
          image_pull_policy = "IfNotPresent"  # ← ADDED: Prevent pull issues

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

# --- ClusterIP Service ---
resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = var.k8s_namespace
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
