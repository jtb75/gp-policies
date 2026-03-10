# =============================================================================
# IAM — Wiz remediation runner and worker roles
# =============================================================================

# Runner role: assumed by the remediation pod via EKS Pod Identity
resource "aws_iam_role" "remediation_runner" {
  name = "${var.cluster_name}-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# Runner can assume the worker role in target accounts
resource "aws_iam_role_policy" "runner_assume_worker" {
  name = "assume-remediation-worker"
  role = aws_iam_role.remediation_runner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Resource = concat(
        [aws_iam_role.remediation_worker_local.arn],
        [for id in var.remediation_target_account_ids :
          "arn:${data.aws_partition.current.partition}:iam::${id}:role/${var.cluster_name}-worker"
        ]
      )
    }]
  })
}

# Pod Identity association — maps the runner role to the remediation namespace
resource "aws_eks_pod_identity_association" "remediation_runner" {
  cluster_name    = aws_eks_cluster.remediation.name
  namespace       = var.remediation_namespace
  service_account = "wiz-remediation-runner"
  role_arn        = aws_iam_role.remediation_runner.arn
}

# =============================================================================
# Worker role (local account) — has permissions to remediate resources
# =============================================================================

resource "aws_iam_role" "remediation_worker_local" {
  name = "${var.cluster_name}-worker"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_iam_role.remediation_runner.arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Remediation permissions — scoped to the actions our response functions need
resource "aws_iam_role_policy" "remediation_worker_permissions" {
  name = "remediation-permissions"
  role = aws_iam_role.remediation_worker_local.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMTagging"
        Effect = "Allow"
        Action = [
          "iam:TagRole",
          "iam:TagUser",
          "iam:ListRoleTags",
          "iam:ListUserTags",
          "iam:GetRole",
          "iam:GetUser"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMAccessKeyManagement"
        Effect = "Allow"
        Action = [
          "iam:UpdateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Snapshots"
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2AMIs"
        Effect = "Allow"
        Action = [
          "ec2:ModifyImageAttribute",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Instances"
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketPolicy"
        Effect = "Allow"
        Action = [
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutPublicAccessBlock",
          "s3:GetPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSSnapshots"
        Effect = "Allow"
        Action = [
          "rds:ModifyDBSnapshotAttribute",
          "rds:ModifyDBClusterSnapshotAttribute",
          "rds:DescribeDBSnapshotAttributes",
          "rds:DescribeDBClusterSnapshotAttributes"
        ]
        Resource = "*"
      },
      {
        Sid    = "Lambda"
        Effect = "Allow"
        Action = [
          "lambda:GetPolicy",
          "lambda:RemovePermission",
          "lambda:GetFunction",
          "lambda:UpdateFunctionUrlConfig"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecurityGroups"
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}
