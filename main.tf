provider "kubernetes" {
  host     = var.k8s_host
  token    = var.k8s_token
  insecure = true
}

resource "kubernetes_config_map" "hello" {
  metadata {
    name      = "hello-from-spacelift"
    namespace = var.k8s_namespace
  }
  data = {
    message = "Hi from local Terraform over ngrok!"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = var.k8s_namespace
    labels = { app = "nginx-demo" }
  }

  spec {
    replicas = 1
    selector { match_labels = { app = "nginx-demo" } }

    template {
      metadata { labels = { app = "nginx-demo" } }
      spec {
        container {
          name  = "nginx"
          image = "nginx:1.25-alpine"
          port { container_port = 80 }
          resources {
            requests { cpu = "50m"  memory = "64Mi" }
            limits   { cpu = "200m" memory = "128Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-demo"
    namespace = var.k8s_namespace
    labels = { app = "nginx-demo" }
  }
  spec {
    selector = { app = "nginx-demo" }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}
