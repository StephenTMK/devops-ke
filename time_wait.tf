resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "45s"
}
