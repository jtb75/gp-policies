# =============================================================================
# S3 Buckets — Test fixtures for untrusted sharing and encryption CCRs
# =============================================================================

# Triggers: aws_s3_bucket_untrusted_sharing (bucket policy grants access to untrusted account)
resource "aws_s3_bucket" "test_untrusted_sharing" {
  bucket        = "jtb75-test-untrusted-sharing-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Purpose = "test-ccr"
  }
}

resource "aws_s3_bucket_policy" "test_untrusted_sharing" {
  bucket = aws_s3_bucket.test_untrusted_sharing.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowUntrustedAccount"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.test_untrusted_sharing.arn}/*"
      }
    ]
  })
}

# Triggers: aws_s3_classified_bucket_encryption (classified bucket without encryption)
resource "aws_s3_bucket" "test_classified_no_encryption" {
  bucket        = "jtb75-test-classified-noenc-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Purpose             = "test-ccr"
    data-classification = "confidential"
  }
}

# PASS: classified bucket WITH encryption
resource "aws_s3_bucket" "test_classified_encrypted" {
  bucket        = "jtb75-test-classified-enc-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Purpose             = "test-ccr"
    data-classification = "confidential"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_classified_encrypted" {
  bucket = aws_s3_bucket.test_classified_encrypted.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# PASS: bucket with policy sharing to trusted internal account only
resource "aws_s3_bucket" "test_trusted_sharing" {
  bucket        = "jtb75-test-trusted-sharing-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Purpose = "test-ccr"
  }
}

resource "aws_s3_bucket_policy" "test_trusted_sharing" {
  bucket = aws_s3_bucket.test_trusted_sharing.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowTrustedAccount"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.test_trusted_sharing.arn}/*"
      }
    ]
  })
}
