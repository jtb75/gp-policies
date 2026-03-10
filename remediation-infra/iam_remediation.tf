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
    "rem-aws-ec2-031" : [
      "tag:TagResources",
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateTags"
    ],
    "rem-aws-iam-025" : [
      "tag:TagResources",
      "iam:CreatePolicyVersion",
      "iam:TagUser",
      "iam:TagPolicy",
      "iam:PutRolePolicy",
      "iam:PutGroupPolicy",
      "iam:PutUserPolicy",
      "iam:TagRole"
    ],
    "rem-aws-iam-045" : [
      "tag:TagResources",
      "iam:GetAccessKeyLastUsed",
      "iam:UpdateAccessKey",
      "iam:ListAccessKeys"
    ],
    "rem-aws-iam-223" : [
      "iam:TagRole",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteRole"
    ],
    "rem-aws-rds-002" : [
      "tag:TagResources",
      "rds:AddTagsToResource",
      "rds:DescribeDBInstances",
      "rds:ModifyDBInstance"
    ],
    "rem-aws-rds-003" : [
      "tag:TagResources",
      "rds:ModifyDBSnapshotAttribute",
      "rds:AddTagsToResource",
      "rds:DescribeDBSnapshotAttributes"
    ],
    "rem-aws-s3-046" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketPolicy",
      "s3:GetBucketTagging",
      "s3:GetBucketPublicAccessBlock"
    ]
  }
}
