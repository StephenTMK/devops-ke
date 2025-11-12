resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.6.2"
  namespace  = "argocd"
  wait       = true
  timeout    = 600

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_for_argocd_ready
  ]

  values = [<<-YAML
applications:
  # 0) Install Crossplane core via its Helm chart
  - name: crossplane
    namespace: argocd
    project: default
    destination:
      server: https://kubernetes.default.svc
      namespace: crossplane-system
    source:
      repoURL: https://charts.crossplane.io/stable
      chart: crossplane
      targetRevision: 1.15.0
      helm:
        releaseName: crossplane
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
        - ServerSideApply=true
    metadata:
      annotations:
        argocd.argoproj.io/sync-wave: "-3"

  # 1) Install Crossplane AWS providers (from your repo)
  - name: crossplane-providers
    namespace: argocd
    project: default
    destination:
      server: https://kubernetes.default.svc
      namespace: crossplane-system
    source:
      repoURL: https://github.com/StephenTMK/devops-ke
      targetRevision: main
      path: infra/crossplane-aws-localstack/providers
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - ServerSideApply=true
    metadata:
      annotations:
        argocd.argoproj.io/sync-wave: "-2"

  # 2) ProviderConfig wiring (no creds in Git; Secret is created by TF when enabled)
  - name: crossplane-aws-providerconfig
    namespace: argocd
    project: default
    destination:
      server: https://kubernetes.default.svc
      namespace: crossplane-system
    source:
      repoURL: https://github.com/StephenTMK/devops-ke
      targetRevision: main
      path: infra/crossplane-aws-localstack/providerconfig
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - ServerSideApply=true
    metadata:
      annotations:
        argocd.argoproj.io/sync-wave: "-1"

  # 3) Example resources (S3 bucket via LocalStack)
  - name: crossplane-aws-localstack
    namespace: argocd
    project: default
    destination:
      server: https://kubernetes.default.svc
      namespace: crossplane-system
    source:
      repoURL: https://github.com/StephenTMK/devops-ke
      targetRevision: main
      path: infra/crossplane-aws-localstack/resources
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - ServerSideApply=true
    metadata:
      annotations:
        argocd.argoproj.io/sync-wave: "1"
YAML
  ]
}
