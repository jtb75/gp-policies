# =============================================================================
# RDS Networking — Minimal VPC + subnet group for test RDS instances
# =============================================================================

resource "aws_vpc" "test_rds" {
  cidr_block = "10.251.0.0/16"
  tags = {
    Name = "jtb75-test-rds-vpc"
  }
}

resource "aws_subnet" "test_rds" {
  count             = 2
  vpc_id            = aws_vpc.test_rds.id
  cidr_block        = cidrsubnet("10.251.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "jtb75-test-rds-${count.index}"
  }
}

resource "aws_db_subnet_group" "test" {
  name       = "jtb75-test-rds-subnets"
  subnet_ids = aws_subnet.test_rds[*].id
  tags = {
    Name = "jtb75-test-rds-subnets"
  }
}
