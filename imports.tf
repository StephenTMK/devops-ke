############################
# Import pre-existing objects into state
############################

# Namespaces
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

# Demo app (spacelift-dev)
import {
  to = kubernetes_config_map_v1.hello
  id = "spacelift-dev/hello-from-spacelift"
}
import {
  to = kubernetes_deployment_v1.nginx
  id = "spacelift-dev/nginx-demo"
}
import {
  to = kubernetes_service_v1.nginx
  id = "spacelift-dev/nginx-demo"
}

# LocalStack (namespace: localstack)
import {
  to = kubernetes_deployment_v1.localstack
  id = "localstack/localstack"
}
import {
  to = kubernetes_service_v1.localstack
  id = "localstack/localstack"
}
