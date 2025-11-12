resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
  lifecycle { prevent_destroy = true }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  wait             = true
  timeout          = 600

  # Install CRDs so Argo Application CRs exist
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Serve HTTP for our simple ingress (no TLS passthrough)
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  # Improve health for Crossplane Provider/ProviderRevision
  values = [<<-YAML
configs:
  cm:
    resource.customizations.health.pkg.crossplane.io_Provider: |
      hs = {}
      if obj.status ~= nil and obj.status.conditions ~= nil then
        for _, c in ipairs(obj.status.conditions) do
          if (c.type == "Healthy" or c.type == "Installed") and c.status == "True" then
            hs.status = "Healthy"
            hs.message = c.reason or c.message or "Provider is Healthy"
            return hs
          end
          if (c.type == "Installed" or c.type == "Healthy") and c.status == "False" then
            hs.status = "Degraded"
            hs.message = c.reason or c.message or "Provider not Healthy"
            return hs
          end
        end
        hs.status = "Progressing"
        hs.message = "Waiting for Provider to become Healthy"
        return hs
      end
      hs.status = "Progressing"
      hs.message = "Waiting for Provider status"
      return hs
    resource.customizations.health.pkg.crossplane.io_ProviderRevision: |
      hs = {}
      if obj.status ~= nil and obj.status.conditions ~= nil then
        for _, c in ipairs(obj.status.conditions) do
          if c.type == "Healthy" and c.status == "True" then
            hs.status = "Healthy"
            hs.message = c.reason or c.message or "ProviderRevision Healthy"
            return hs
          end
          if c.type == "Healthy" and c.status == "False" then
            hs.status = "Degraded"
            hs.message = c.reason or c.message or "ProviderRevision Degraded"
            return hs
          end
        end
        hs.status = "Progressing"
        hs.message = "Waiting for ProviderRevision"
        return hs
      end
      hs.status = "Progressing"
      hs.message = "Waiting for ProviderRevision status"
      return hs
YAML
  ]
}
