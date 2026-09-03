# =========================================================
# ALB Security Group
# =========================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "HTTP from Internet"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS from Internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}


# =========================================================
# EKS Worker Node Security Group
# =========================================================

resource "aws_security_group" "eks_node" {
  name        = "${var.project_name}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-eks-node-sg"
  }
}

# Worker Node / Pod 간 내부 통신
resource "aws_vpc_security_group_ingress_rule" "eks_node_internal" {
  security_group_id = aws_security_group.eks_node.id

  referenced_security_group_id = aws_security_group.eks_node.id
  ip_protocol                  = "-1"

  description = "Allow communication between EKS worker nodes"
}

# ALB -> Pod backend
# target-type ip 사용 시 NodePort 범위 대신 실제 backend port 허용
resource "aws_vpc_security_group_ingress_rule" "eks_node_from_alb" {
  security_group_id = aws_security_group.eks_node.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow ALB to backend Pods"
}

# Monitoring EC2 -> EKS
resource "aws_vpc_security_group_ingress_rule" "eks_node_from_monitoring" {
  security_group_id = aws_security_group.eks_node.id

  referenced_security_group_id = aws_security_group.monitoring.id
  ip_protocol                  = "-1"

  description = "Allow monitoring server to EKS nodes"
}

resource "aws_vpc_security_group_egress_rule" "eks_node_all_outbound" {
  security_group_id = aws_security_group.eks_node.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow EKS worker outbound traffic"
}


# =========================================================
# Redis Security Group
# =========================================================

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id = aws_security_group.redis.id

  referenced_security_group_id = aws_security_group.eks_node.id

  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"

  description = "Allow Redis access from EKS worker nodes"
}


# =========================================================
# Monitoring Security Group
# =========================================================

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-monitoring-sg"
  description = "Security group for monitoring EC2"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-monitoring-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "monitoring_all_outbound" {
  security_group_id = aws_security_group.monitoring.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow monitoring outbound traffic"
}
