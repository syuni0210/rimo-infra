# =========================================================
# Route 53 Hosted Zone
# =========================================================

data "aws_route53_zone" "rimo" {
  name         = "rimo-app.com"
  private_zone = false
}


# =========================================================
# ACM Certificate
# rimo-app.com + *.rimo-app.com
# =========================================================

resource "aws_acm_certificate" "rimo" {
  domain_name = "rimo-app.com"

  subject_alternative_names = [
    "*.rimo-app.com"
  ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-certificate"
  }
}


# =========================================================
# Route 53 DNS Validation Records
# =========================================================

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.rimo.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.rimo.zone_id

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]

  ttl = 60

  allow_overwrite = true
}


# =========================================================
# ACM Certificate Validation
# =========================================================

resource "aws_acm_certificate_validation" "rimo" {
  certificate_arn = aws_acm_certificate.rimo.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation :
    record.fqdn
  ]
}


# =========================================================
