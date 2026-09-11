# =========================================================
# Route53 DNS Record
# =========================================================


# =========================================================
# API DNS
# api.rimo-app.com -> EKS ALB
# =========================================================

variable "create_api_dns_record" {
  type        = bool
  description = "ALB 생성 후 api.rimo-app.com Route53 Alias 생성 여부"
  default     = false
}

variable "alb_dns_name" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 DNS Name"
  default     = ""
}

variable "alb_zone_id" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 Zone ID"
  default     = ""
}

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


# =========================================================
# Web DNS
# www.rimo-app.com -> Web ALB
# =========================================================

resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.rimo.zone_id
  name    = "www.rimo-app.com"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}
