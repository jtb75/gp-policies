# =============================================================================
# Outputs — Values needed for Wiz R&R configuration
# =============================================================================

output "cluster_name" {
  value = aws_eks_cluster.remediation.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.remediation.endpoint
}

output "cluster_certificate_authority" {
  value     = aws_eks_cluster.remediation.certificate_authority[0].data
  sensitive = true
}

output "runner_role_arn" {
  description = "ARN of the Pod Identity runner role — configure this in Wiz R&R deployment"
  value       = module.remediation_roles.runner_role_arn
}

output "remediation_role_arns" {
  description = "ARNs of per-action remediation roles"
  value       = module.remediation_roles.remediation_role_arns
}

output "remediation_namespace" {
  value = var.remediation_namespace
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.remediation.name} --region ${var.region}"
}

output "vpc_id" {
  value = aws_vpc.remediation.id
}
