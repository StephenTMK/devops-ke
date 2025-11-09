# Small warm-up to give the API server / admission webhooks time to settle
resource "time_sleep" "wait_k8s_api" {
  create_duration = "45s"
}
