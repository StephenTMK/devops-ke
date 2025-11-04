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
          name  = "awscli"
          image = "amazon/aws-cli:2.15.6"
          command = ["/bin/sh","-c","/bin/sh /script/check.sh"]

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
  depends_on = [aws_s3_object.welcome]
}
