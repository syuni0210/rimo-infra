# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "rimo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# =========================================================
# Internet Gateway
# =========================================================

resource "aws_internet_gateway" "rimo" {
  vpc_id = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# =========================================================
# Public Subnet A
# ap-northeast-2a
# ALB / NAT Gateway A
# =========================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-public-a"
    "kubernetes.io/role/elb" = "1"
  }
}


# =========================================================
# Public Subnet B
# ap-northeast-2c
# ALB / NAT Gateway B
# =========================================================

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}


# =========================================================
# Private Application Subnet A
# EKS Worker Node
# ap-northeast-2a
# =========================================================

resource "aws_subnet" "private_app_a" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "${var.project_name}-private-app-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# =========================================================
# Private Application Subnet B
# EKS Worker Node
# ap-northeast-2c
# =========================================================

resource "aws_subnet" "private_app_b" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name                              = "${var.project_name}-private-app-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# =========================================================
# Private Cache Subnet A
# ElastiCache Redis
# ap-northeast-2a
# =========================================================

resource "aws_subnet" "private_cache_a" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-cache-a"
  }
}

# =========================================================
# Private Cache Subnet B
# ElastiCache Redis (이중화용)
# ap-northeast-2c
# =========================================================

resource "aws_subnet" "private_cache_b" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.22.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-cache-b"
  }
}


# =========================================================
# Private Monitoring Subnet
# Jenkins / Prometheus / Grafana
# =========================================================

resource "aws_subnet" "private_monitoring" {
  vpc_id                  = aws_vpc.rimo.id
  cidr_block              = "10.0.31.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-monitoring"
  }
}


# =========================================================
# Public Route Table
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rimo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rimo.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}


resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# =========================================================
# NAT Gateway A
# =========================================================

resource "aws_eip" "nat_a" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.rimo
  ]

  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }
}


resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.rimo
  ]

  tags = {
    Name = "${var.project_name}-nat-a"
  }
}


# =========================================================
# NAT Gateway B
# =========================================================

resource "aws_eip" "nat_b" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.rimo
  ]

  tags = {
    Name = "${var.project_name}-nat-eip-b"
  }
}


resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  depends_on = [
    aws_internet_gateway.rimo
  ]

  tags = {
    Name = "${var.project_name}-nat-b"
  }
}


# =========================================================
# Private App Route Table A
# Private App A -> NAT Gateway A
# =========================================================

resource "aws_route_table" "private_app_a" {
  vpc_id = aws_vpc.rimo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.project_name}-private-app-a-rt"
  }
}


resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app_a.id
}


# =========================================================
# Private App Route Table B
# Private App B -> NAT Gateway B
# =========================================================

resource "aws_route_table" "private_app_b" {
  vpc_id = aws_vpc.rimo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "${var.project_name}-private-app-b-rt"
  }
}


resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_app_b.id
}


# =========================================================
# Cache Route Table
#
# ElastiCache는 외부 인터넷에 직접 접근할 필요가 없으므로
# Default Route를 만들지 않는다.
# =========================================================

resource "aws_route_table" "private_cache" {
  vpc_id = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-private-cache-rt"
  }
}

# Cache Subnet A 연결
resource "aws_route_table_association" "private_cache_a" {
  subnet_id      = aws_subnet.private_cache_a.id
  route_table_id = aws_route_table.private_cache.id
}

# Cache Subnet B 연결
resource "aws_route_table_association" "private_cache_b" {
  subnet_id      = aws_subnet.private_cache_b.id
  route_table_id = aws_route_table.private_cache.id
}

# =========================================================
# Monitoring Route Table
# Monitoring Server -> NAT Gateway A
# =========================================================

resource "aws_route_table" "private_monitoring" {
  vpc_id = aws_vpc.rimo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.project_name}-private-monitoring-rt"
  }
}


resource "aws_route_table_association" "private_monitoring" {
  subnet_id      = aws_subnet.private_monitoring.id
  route_table_id = aws_route_table.private_monitoring.id
}
