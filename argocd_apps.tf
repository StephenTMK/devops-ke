resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = "1.6.2"
  namespace        = "argocd"
  create_namespace = false
  wait             = true
  timeout          = 600

  depends_on = [time_sleep.wait_for_argocd_crds]

  values = [<<-YAML
applications:
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
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true

  - name: crossplane-aws-localstack
    namespace: argocd
    project: default
    destination:
      server: https://kubernetes.default.svc
      namespace: crossplane-system
    source:
      repoURL: https://github.com/you/spacelift-tf-test.git
      targetRevision: main
      path: infra/crossplane-aws-localstack
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - ServerSideApply=true
YAML
  ]
}
