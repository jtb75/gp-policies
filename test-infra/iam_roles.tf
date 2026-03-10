# =============================================================================
# IAM Roles — Test fixtures for tag enforcement and trust relationship CCRs
# =============================================================================

# Shared assume role policy for roles that don't need special trust
data "aws_iam_policy_document" "self_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Trust policy pointing to an untrusted external account
data "aws_iam_policy_document" "untrusted_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.untrusted_account_id}:root"]
    }
  }
}

# Trust policy open to any AWS account (wildcard)
data "aws_iam_policy_document" "public_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

# Trust policy pointing to a trusted external account (345678901234 from globals)
data "aws_iam_policy_document" "trusted_external_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::345678901234:root"]
    }
  }
}

# -----------------------------------------------------------------------------
# Tag enforcement: name-based matching roles (FAIL — missing required tags)
# -----------------------------------------------------------------------------

# Triggers: aws_consumer_role_missing_type_tag (contains "consumer", no type:consumer tag)
resource "aws_iam_role" "test_consumer_no_tag" {
  name               = "jtb75-test-consumer-role"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_deploy_role_missing_type_tag (contains "deploy-", no type:deployment tag)
resource "aws_iam_role" "test_deploy_no_tag" {
  name               = "jtb75-test-deploy-pipeline"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_support_saml_role_missing_type_tag (contains "support-saml", no type:support tag)
resource "aws_iam_role" "test_support_saml_no_tag" {
  name               = "jtb75-test-support-saml-readonly"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_administrator_role_missing_type_tag (exact name "Administrator", no type:support tag)
resource "aws_iam_role" "test_administrator_no_tag" {
  name               = "Administrator"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_service_linked_role_missing_type_tag (path /service-role/, no type:service tag)
resource "aws_iam_role" "test_service_path_no_tag" {
  name               = "jtb75-test-codebuild-service"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# -----------------------------------------------------------------------------
# Tag enforcement: globals list-based matching roles (FAIL — missing required tags)
# -----------------------------------------------------------------------------

# Triggers: aws_support_role_missing_type_tag (name in kbs_support_roles)
resource "aws_iam_role" "test_kbs_support_no_tag" {
  name               = "KBSSupportRole"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_vendor_role_missing_type_tag (name in kbs_vendor_roles)
resource "aws_iam_role" "test_kbs_vendor_no_tag" {
  name               = "VendorMonitoringRole"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_service_role_missing_type_tag (name in kbs_service_roles)
resource "aws_iam_role" "test_kbs_service_no_tag" {
  name               = "AppDeploymentRole"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# -----------------------------------------------------------------------------
# Tag enforcement: PASS examples (correctly tagged roles)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "test_consumer_tagged" {
  name               = "jtb75-test-consumer-tagged"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
    type    = "consumer"
  }
}

resource "aws_iam_role" "test_deploy_tagged" {
  name               = "jtb75-test-deploy-tagged"
  assume_role_policy = data.aws_iam_policy_document.self_trust.json
  tags = {
    Purpose = "test-ccr"
    type    = "deployment"
  }
}

# -----------------------------------------------------------------------------
# Trust relationship rules
# -----------------------------------------------------------------------------

# Triggers: aws_role_untrusted_trust (trusts untrusted account)
resource "aws_iam_role" "test_untrusted_trust" {
  name               = "jtb75-test-untrusted-trust"
  assume_role_policy = data.aws_iam_policy_document.untrusted_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_role_untrusted_trust (trusts wildcard "*")
resource "aws_iam_role" "test_public_trust" {
  name               = "jtb75-test-public-trust"
  assume_role_policy = data.aws_iam_policy_document.public_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# Triggers: aws_vendor_role_auto_tag (trusts known external account, missing type:vendor tag)
resource "aws_iam_role" "test_vendor_auto_tag" {
  name               = "jtb75-test-vendor-external-trust"
  assume_role_policy = data.aws_iam_policy_document.trusted_external_trust.json
  tags = {
    Purpose = "test-ccr"
  }
}

# PASS: trusts external account AND has type:vendor tag
resource "aws_iam_role" "test_vendor_tagged_trust" {
  name               = "jtb75-test-vendor-tagged-trust"
  assume_role_policy = data.aws_iam_policy_document.trusted_external_trust.json
  tags = {
    Purpose = "test-ccr"
    type    = "vendor"
  }
}
