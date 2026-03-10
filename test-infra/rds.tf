# =============================================================================
# RDS — Test fixtures for backup retention CCR
# =============================================================================

# Triggers: aws_rds_backup_retention (retention < 35 days)
resource "aws_db_instance" "test_low_retention" {
  identifier              = "jtb75-test-low-retention"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "admin"
  password                = "jtb75-test-password-change-me"
  backup_retention_period = 7
  skip_final_snapshot     = true
  apply_immediately       = true
  tags = {
    Purpose = "test-ccr"
  }
}

# PASS: backup retention >= 35 days
resource "aws_db_instance" "test_good_retention" {
  identifier              = "jtb75-test-good-retention"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "admin"
  password                = "jtb75-test-password-change-me"
  backup_retention_period = 35
  skip_final_snapshot     = true
  apply_immediately       = true
  tags = {
    Purpose = "test-ccr"
  }
}
