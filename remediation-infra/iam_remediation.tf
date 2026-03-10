# =============================================================================
# IAM — Wiz remediation and response roles (official Wiz module)
# =============================================================================

module "remediation_roles" {
  source = "https://wizio-public.s3.amazonaws.com/deployment-v2/aws/wiz-aws-remediationandresponse-k8s-single-account-terraform-module.zip"

  cluster_arn      = aws_eks_cluster.remediation.arn
  namespace        = var.remediation_namespace
  resources_prefix = "Wiz"

  permission_sets = {
    "rem-aws-ebs-007" : [
      "tag:TagResources",
      "ec2:ModifySnapshotAttribute",
      "ec2:DescribeSnapshotAttribute",
      "ec2:CreateTags"
    ],
    "rem-custom-0008" : [
      "iam:GetRole",
      "iam:TagRole"
    ]
  }
}
