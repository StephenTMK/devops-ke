# This file should be processed first due to naming convention

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Import block for existing namespace
import {
  to = kubernetes_namespace.demo
  id = "spacelift-dev"
}

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
