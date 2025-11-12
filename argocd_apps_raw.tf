# 0) Crossplane core via Argo CD (install Helm chart first)
resource "kubernetes_manifest" "app_crossplane_core" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-3"
spec:
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
YAML
  )
  depends_on = [time_sleep.wait_for_argocd_ready]
}

# 1) Providers & ControllerConfig (wave -2)
resource "kubernetes_manifest" "app_crossplane_providers" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-providers
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
spec:
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
YAML
  )
  depends_on = [kubernetes_manifest.app_crossplane_core]
}

# 2) ProviderConfig (Secret referenced) (wave -1)
resource "kubernetes_manifest" "app_crossplane_providerconfig" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-aws-providerconfig
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
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
YAML
  )
  depends_on = [kubernetes_manifest.app_crossplane_providers]
}

# 3) Example resources (e.g. S3 bucket) (wave +1)
resource "kubernetes_manifest" "app_crossplane_bucket" {
  manifest = yamldecode(<<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-aws-localstack
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
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
YAML
  )
  depends_on = [kubernetes_manifest.app_crossplane_providerconfig]
}
