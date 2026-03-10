# =============================================================================
# IAM Users — Test fixtures for type tag and access key rotation CCRs
# =============================================================================

# Triggers: aws_missing_type_tag (IAM user with no type tag)
resource "aws_iam_user" "test_no_type_tag" {
  name = "jtb75-test-user-no-tag"
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_missing_type_tag (IAM user with invalid type tag value)
resource "aws_iam_user" "test_bad_type_tag" {
  name = "jtb75-test-user-bad-tag"
  tags = {
    Purpose = "test-ccr"
    type    = "invalid-value"
  }
}

# PASS: IAM user with valid type tag
resource "aws_iam_user" "test_valid_type_tag" {
  name = "jtb75-test-user-valid-tag"
  tags = {
    Purpose = "test-ccr"
    type    = "user"
  }
}

# Triggers: aws_user_aws_managed_policy (user with AWS managed policy)
resource "aws_iam_user" "test_managed_policy" {
  name = "jtb75-test-user-managed-policy"
  tags = {
    Purpose = "test-ccr"
    type    = "user"
  }
}

resource "aws_iam_user_policy_attachment" "test_managed_policy" {
  user       = aws_iam_user.test_managed_policy.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Users with access keys for rotation testing
# Note: Keys are created with today's date — they won't trigger rotation
# rules immediately, but will after the threshold passes (25-90 days).

resource "aws_iam_user" "test_service_user" {
  name = "jtb75-test-service-user"
  tags = {
    Purpose = "test-ccr"
    type    = "service"
  }
}

resource "aws_iam_access_key" "test_service_key" {
  user = aws_iam_user.test_service_user.name
}

resource "aws_iam_user" "test_vendor_user" {
  name = "jtb75-test-vendor-user"
  tags = {
    Purpose = "test-ccr"
    type    = "vendor"
  }
}

resource "aws_iam_access_key" "test_vendor_key" {
  user = aws_iam_user.test_vendor_user.name
}

resource "aws_iam_user" "test_human_user" {
  name = "jtb75-test-human-user"
  tags = {
    Purpose = "test-ccr"
    type    = "user"
  }
}

resource "aws_iam_access_key" "test_human_key" {
  user = aws_iam_user.test_human_user.name
}

resource "aws_iam_user" "test_untagged_user" {
  name = "jtb75-test-untagged-user"
  tags = {
    Purpose = "test-ccr"
  }
}

resource "aws_iam_access_key" "test_untagged_key" {
  user = aws_iam_user.test_untagged_user.name
}
