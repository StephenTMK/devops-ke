# Bring pre-existing namespaces under state so OpenTofu stops trying to create them.
# (Spacelift will apply these "import blocks" during plan/apply.)

import {
  to = kubernetes_namespace.demo
  id = "spacelift-dev"
}

import {
  to = kubernetes_namespace.argocd
  id = "argocd"
}

import {
  to = kubernetes_namespace.localstack
  id = "localstack"
}
