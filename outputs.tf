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
