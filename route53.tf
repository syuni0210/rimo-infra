# =========================================================
# Route53 DNS Record (Alias to ALB)
# =========================================================

# ALB 생성 이후 Route53 Alias 레코드를 생성할지 여부
variable "create_api_dns_record" {
  type        = bool
  description = "ALB 생성 후 api.rimo-app.com Route53 Alias 생성 여부"
  default     = false
}

# Kubernetes Ingress로 생성된 ALB DNS Name
variable "alb_dns_name" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 DNS Name"
  default     = ""
}

# Kubernetes Ingress로 생성된 ALB Hosted Zone ID
variable "alb_zone_id" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 Zone ID"
  default     = ""
}

# ALB 생성 후 2차 Terraform apply 때 생성
resource "aws_route53_record" "api" {
  count = var.create_api_dns_record ? 1 : 0

  zone_id = data.aws_route53_zone.rimo.zone_id
  name    = "api.rimo-app.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
