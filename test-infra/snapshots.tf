# =============================================================================
# EC2 Snapshots — Test fixtures for untrusted sharing CCRs
# =============================================================================

# Create an EBS volume to snapshot
resource "aws_ebs_volume" "test_source" {
  availability_zone = "${var.region}a"
  size              = 1
  tags = {
    Name    = "jtb75-test-snapshot-source"
    Purpose = "test-ccr"
  }
}

# Create a snapshot from the volume
resource "aws_ebs_snapshot" "test_snapshot" {
  volume_id = aws_ebs_volume.test_source.id
  tags = {
    Name    = "jtb75-test-snapshot"
    Purpose = "test-ccr"
  }
}

# Triggers: aws_snapshot_untrusted_sharing (shared with untrusted account)
resource "aws_snapshot_create_volume_permission" "test_untrusted" {
  snapshot_id = aws_ebs_snapshot.test_snapshot.id
  account_id  = "999999999999" # Fake account — snapshot API doesn't validate
}

# Second snapshot for PASS case (no sharing)
resource "aws_ebs_snapshot" "test_snapshot_clean" {
  volume_id = aws_ebs_volume.test_source.id
  tags = {
    Name    = "jtb75-test-snapshot-clean"
    Purpose = "test-ccr"
  }
}
