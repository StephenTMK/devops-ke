# Give the API and webhooks time to settle (used by LocalStack ingresses)
resource "time_sleep" "wait_k8s_api" {
  create_duration = "45s"
}

# Give Argo a moment after Helm to ensure CRDs/controllers are ready
resource "time_sleep" "wait_for_argocd_ready" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}
