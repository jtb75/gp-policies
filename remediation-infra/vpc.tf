# =============================================================================
# VPC — Dedicated network for the EKS cluster
# =============================================================================

resource "aws_vpc" "remediation" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Public subnets (for NAT gateway and load balancers)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.remediation.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Private subnets (for EKS nodes and remediation pods)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.remediation.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Internet gateway
resource "aws_internet_gateway" "remediation" {
  vpc_id = aws_vpc.remediation.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Elastic IP for NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

# NAT gateway (single AZ to reduce cost)
resource "aws_nat_gateway" "remediation" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.cluster_name}-nat"
  }
  depends_on = [aws_internet_gateway.remediation]
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.remediation.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation.id
  }
  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table (egress through NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.remediation.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.remediation.id
  }
  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
