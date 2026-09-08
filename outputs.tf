output "vpc_id" {
  description = "RIMO VPC ID"
  value       = aws_vpc.rimo.id
}

output "public_subnet_a_id" {
  description = "Public Subnet A ID"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "Public Subnet B ID"
  value       = aws_subnet.public_b.id
}

output "private_app_a_id" {
  description = "Private Application Subnet A ID"
  value       = aws_subnet.private_app_a.id
}

output "private_app_b_id" {
  description = "Private Application Subnet B ID"
  value       = aws_subnet.private_app_b.id
}

output "private_cache_id" {
  description = "Private Cache Subnet ID"
  value       = aws_subnet.private_cache.id
}

output "private_monitoring_id" {
  description = "Private Monitoring Subnet ID"
  value       = aws_subnet.private_monitoring.id
}

output "nat_gateway_a_eip" {
  description = "NAT Gateway A Elastic IP"
  value       = aws_eip.nat_a.public_ip
}

output "nat_gateway_b_eip" {
  description = "NAT Gateway B Elastic IP"
  value       = aws_eip.nat_b.public_ip
}

output "monitoring_instance_id" {
  description = "Monitoring EC2 Instance ID"
  value       = aws_instance.monitoring.id
}

output "monitoring_private_ip" {
  description = "Monitoring EC2 Private IP"
  value       = aws_instance.monitoring.private_ip
}

output "rimo_acm_certificate_arn" {
  description = "ACM certificate ARN for RIMO"
  value       = aws_acm_certificate.rimo.arn
}

output "rimo_waf_web_acl_arn" {
  description = "WAF Web ACL ARN for RIMO"
  value       = aws_wafv2_web_acl.rimo.arn
}

output "alb_security_group_id" {
  description = "Security Group ID for RIMO ALB"
  value       = aws_security_group.alb.id
}

# =========================================================
# Redis
# =========================================================

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}


# =========================================================
# AWS Load Balancer Controller IAM Role
# =========================================================

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}


# =========================================================
# ECR Repository URLs
# =========================================================

output "auth_api_ecr_url" {
  value = aws_ecr_repository.auth_api.repository_url
}

output "data_api_ecr_url" {
  value = aws_ecr_repository.data_api.repository_url
}

output "member_api_ecr_url" {
  value = aws_ecr_repository.member_api.repository_url
}

output "route_api_ecr_url" {
  value = aws_ecr_repository.route_api.repository_url
}

output "tracking_api_ecr_url" {
  value = aws_ecr_repository.tracking_api.repository_url
}


# =========================================================
# EKS
# =========================================================

output "eks_cluster_name" {
  value = aws_eks_cluster.rimo.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.rimo.endpoint
}

# =========================================================
# Route 53
# =========================================================

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID for RIMO"
  value       = data.aws_route53_zone.rimo.zone_id
}
