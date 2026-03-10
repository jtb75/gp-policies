# Temporary: remove kubernetes resources from state without destroying them.
# The Outpost Lite Helm workflow manages namespace and service account.
# Delete this file after one successful apply.

removed {
  from = kubernetes_namespace.wiz_remediation
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_service_account.wiz_remediation_runner
  lifecycle {
    destroy = false
  }
}
