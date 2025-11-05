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

resource "kubernetes_config_map_v1" "s3_check" {
  metadata {
    name      = "s3-check"
    namespace = kubernetes_namespace.localstack.metadata[0].name
  }
  data = {
    "check.sh" = <<-SCRIPT
      #!/usr/bin/env sh
      set -euo pipefail
      echo "Listing buckets via $${LS_URL}"
      aws --endpoint-url "$${LS_URL}" s3 ls
      echo "Reading object..."
      aws --endpoint-url "$${LS_URL}" s3 cp s3://demo-bucket-localstack-001/hello.txt -
      echo "All good."
    SCRIPT
  }
}

resource "kubernetes_job_v1" "s3_check" {
  metadata {
    name      = "s3-check"
    namespace = kubernetes_namespace.localstack.metadata[0].name
  }
  spec {
    backoff_limit = 0
    template {
      metadata {
        labels = {
          job = "s3-check"
        }
      }
      spec {
        restart_policy = "Never"
        container {
          name    = "awscli"
          image   = "amazon/aws-cli:2.15.6"
          command = ["/bin/sh", "-c", "/bin/sh /script/check.sh"]
          env {
            name  = "AWS_ACCESS_KEY_ID"
            value = "test"
          }
          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = "test"
          }
          env {
            name  = "AWS_REGION"
            value = "us-east-1"
          }
          env {
            name  = "LS_URL"
            value = "http://localstack.localstack.svc.cluster.local:4566"
          }
          volume_mount {
            name       = "script"
            mount_path = "/script"
          }
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map_v1.s3_check.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [
    aws_s3_object.welcome
  ]
}
