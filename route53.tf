# =========================================================
# Route53 DNS Record (Alias to ALB)
# =========================================================

data "aws_route53_zone" "rimo" {
  name         = "rimo-app.com"
  private_zone = false
}

variable "alb_dns_name" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 DNS Name"
}

variable "alb_zone_id" {
  type        = string
  description = "Kubernetes Ingress로 생성된 ALB의 Zone ID"
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.rimo.zone_id
  name    = "api.rimo-app.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}