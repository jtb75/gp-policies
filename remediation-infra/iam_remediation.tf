# =============================================================================
# IAM — Wiz remediation and response roles (official Wiz module)
# =============================================================================

module "remediation_roles" {
  source = "https://wizio-public.s3.amazonaws.com/deployment-v2/aws/wiz-aws-remediationandresponse-k8s-single-account-terraform-module.zip"

  cluster_arn      = aws_eks_cluster.remediation.arn
  namespace        = var.remediation_namespace
  resources_prefix = "Wiz"

  permission_sets = {
    "rem-custom-0009" : [
      "iam:GetRole",
      "iam:TagRole",
      "iam:UpdateAssumeRolePolicy"
    ],
    "rem-custom-0010" : [
      "iam:GetRole",
      "iam:TagRole"
    ],
    "rem-custom-0011" : [
      "iam:GetAccessKeyLastUsed",
      "iam:ListAccessKeys",
      "iam:ListUserTags",
      "iam:TagUser",
      "iam:UpdateAccessKey"
    ]
  }
}
