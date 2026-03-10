# =============================================================================
# Kubernetes — Namespace and service account for Wiz remediation
# =============================================================================

resource "kubernetes_namespace" "wiz_remediation" {
  metadata {
    name = var.remediation_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "wiz-remediation"
    }
  }

  depends_on = [aws_eks_node_group.remediation]
}

resource "kubernetes_service_account" "wiz_remediation_runner" {
  metadata {
    name      = "wiz-remediation-runner"
    namespace = kubernetes_namespace.wiz_remediation.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "wiz-remediation"
    }
  }
}
