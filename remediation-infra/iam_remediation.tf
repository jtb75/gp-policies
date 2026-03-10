# =============================================================================
# IAM — Wiz remediation and response roles (official Wiz module)
# =============================================================================

module "remediation_roles" {
  source = "https://wizio-public.s3.amazonaws.com/deployment-v2/aws/wiz-aws-remediationandresponse-k8s-single-account-terraform-module.zip"

  cluster_arn      = aws_eks_cluster.remediation.arn
  namespace        = var.remediation_namespace
  resources_prefix = "Wiz"

  permission_sets = {
    "rem-aws-ebs-005" : [
      "tag:TagResources",
      "ec2:DescribeSnapshots",
      "ec2:CreateSnapshot",
      "ec2:CreateTags"
    ],
    "rem-aws-ebs-006" : [
      "ec2:DescribeVolumes",
      "ec2:DeleteVolume"
    ],
    "rem-aws-ebs-007" : [
      "tag:TagResources",
      "ec2:ModifySnapshotAttribute",
      "ec2:DescribeSnapshotAttribute",
      "ec2:CreateTags"
    ],
    "rem-aws-ebs-009" : [
      "tag:TagResources",
      "ec2:DescribeVolumes",
      "ec2:ModifyVolume"
    ],
    "rem-aws-ec2-004" : [
      "tag:TagResources",
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:CreateTags",
      "ec2:DescribeInstances"
    ],
    "rem-aws-ec2-031" : [
      "tag:TagResources",
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateTags"
    ],
    "rem-aws-ec2-response-001" : [
      "tag:TagResources",
      "ec2:StopInstances",
      "ec2:DescribeInstances"
    ],
    "rem-aws-ec2-response-002" : [
      "tag:TagResources",
      "ec2:RebootInstances",
      "ec2:DescribeInstances"
    ],
    "rem-aws-ec2-response-003" : [
      "ec2:TerminateInstances",
      "ec2:DescribeInstances"
    ],
    "rem-aws-ec2-response-004" : [
      "tag:TagResources",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:DescribeInstances"
    ],
    "rem-aws-ec2-response-005" : [
      "tag:TagResources",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:DescribeAutoScalingGroups"
    ],
    "rem-aws-ec2-response-006" : [
      "tag:TagResources",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:DescribeIamInstanceProfileAssociations"
    ],
    "rem-aws-ec2-response-007" : [
      "tag:TagResources",
      "ec2:CreateTags",
      "ec2:RevokeSecurityGroupEgress"
    ],
    "rem-aws-ec2-response-008" : [
      "tag:TagResources",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DescribeTargetHealth"
    ],
    "rem-aws-ecs-response-001" : [
      "tag:TagResources",
      "ecs:DescribeServices",
      "ecs:TagResource",
      "ecs:UpdateService"
    ],
    "rem-aws-ecs-response-002" : [
      "ecs:TagResource",
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ],
    "rem-aws-iam-001" : [
      "iam:GetAccountPasswordPolicy",
      "iam:UpdateAccountPasswordPolicy"
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
    "rem-aws-iam-087" : [
      "tag:TagResources",
      "lambda:RemovePermission",
      "lambda:GetPolicy"
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
    "rem-aws-kms-002" : [
      "tag:TagResources",
      "kms:TagResource",
      "kms:CancelKeyDeletion"
    ],
    "rem-aws-lambda-response-001" : [
      "lambda:DeleteFunction"
    ],
    "rem-aws-lambda-response-002" : [
      "tag:TagResources",
      "lambda:PutFunctionConcurrency"
    ],
    "rem-aws-lambda-response-003" : [
      "tag:TagResources",
      "lambda:RemovePermission",
      "lambda:GetPolicy"
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
    "rem-aws-redshift-002" : [
      "tag:TagResources",
      "redshift:ModifyCluster",
      "redshift:DescribeClusters",
      "redshift:CreateTags"
    ],
    "rem-aws-s3-001" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutBucketLogging",
      "s3:CreateBucket",
      "s3:GetBucketTagging",
      "s3:GetBucketLogging",
      "sts:GetCallerIdentity"
    ],
    "rem-aws-s3-002" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:GetBucketVersioning",
      "s3:GetBucketTagging"
    ],
    "rem-aws-s3-003" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutBucketAcl",
      "s3:GetBucketTagging",
      "s3:GetBucketAcl"
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
    ],
    "rem-aws-s3-048" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutLifecycleConfiguration",
      "s3:GetBucketTagging"
    ],
    "rem-aws-s3-response-012" : [
      "tag:TagResources",
      "s3:PutBucketTagging",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging"
    ]
  }
}
