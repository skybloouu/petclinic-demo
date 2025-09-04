locals {
  availability_zones = ["${var.region}a", "${var.region}b"]
}

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_main
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name        = "main-vpc"
      Environment = var.environment
    },
    var.vpc_tags
  )
}

# Secondary CIDR for EKS pods
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.vpc_cidr_eks_pods
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name                     = "public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
    Environment              = var.environment
  }
}

# Application (Private) Subnets
resource "aws_subnet" "app" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name        = "app-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Data Subnets (Private)
resource "aws_subnet" "data" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name        = "data-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# EKS Pod Subnets
resource "aws_subnet" "eks_pods" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.eks_pod_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  depends_on = [aws_vpc_ipv4_cidr_block_association.secondary_cidr]

  tags = {
    Name                              = "eks-pod-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    Environment                       = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-igw"
    Environment = var.environment
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(local.availability_zones)
  domain = "vpc"

  tags = {
    Name        = "nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(local.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "nat-gateway-${count.index + 1}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-rt"
    Environment = var.environment
  }
}

# Private Route Tables (one per AZ for high availability)
resource "aws_route_table" "private" {
  count  = length(local.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name        = "private-rt-${count.index + 1}"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "eks_pods" {
  count          = length(local.availability_zones)
  subnet_id      = aws_subnet.eks_pods[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Network ACLs
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "public-nacl"
    Environment = var.environment
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.app[*].id, aws_subnet.data[*].id, aws_subnet.eks_pods[*].id)

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_main
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr_eks_pods
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "private-nacl"
    Environment = var.environment
  }
}
