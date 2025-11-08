resource "kubernetes_manifest" "app_crossplane" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane
  namespace: argocd
spec:
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
YAML
  )
  depends_on = [time_sleep.wait_for_argocd_crds]
}

resource "kubernetes_manifest" "app_crossplane_aws_localstack" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-aws-localstack
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: crossplane-system
  source:
    repoURL: "https://github.com/you/spacelift-tf-test.git"
    targetRevision: "main"
    path: "infra/crossplane-aws-localstack"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - ServerSideApply=true
YAML
  )
  depends_on = [time_sleep.wait_for_argocd_crds]
}
