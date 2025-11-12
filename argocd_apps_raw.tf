# This file intentionally left without kubernetes_manifest resources.
# We moved the Argo CD Applications into a Helm release (argocd_apps.tf)
# so the plan phase doesn’t fail when the Application CRD isn’t installed yet.
