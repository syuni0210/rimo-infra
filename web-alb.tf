# =========================================================
# Web ALB Security Group
# =========================================================

resource "aws_security_group" "web_alb" {
  name        = "${var.project_name}-web-alb-sg"
  description = "Security group for Web ALB"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-web-alb-sg"
  }
}

# Internet -> ALB HTTP
resource "aws_vpc_security_group_ingress_rule" "web_alb_http" {
  security_group_id = aws_security_group.web_alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "HTTP from Internet"
}

# Internet -> ALB HTTPS
resource "aws_vpc_security_group_ingress_rule" "web_alb_https" {
  security_group_id = aws_security_group.web_alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS from Internet"
}

resource "aws_vpc_security_group_egress_rule" "web_alb_all_outbound" {
  security_group_id = aws_security_group.web_alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow Web ALB outbound"
}


# =========================================================
# Web Application Load Balancer
# =========================================================

resource "aws_lb" "web" {
  name               = "${var.project_name}-web-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.web_alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${var.project_name}-web-alb"
  }
}


# =========================================================
# Web Target Group
# =========================================================

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.rimo.id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-web-tg"
  }
}


# =========================================================
# EC2 -> Target Group
# =========================================================

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}


# =========================================================
# HTTP :80 -> HTTPS :443
# =========================================================

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# =========================================================
# HTTPS :443 -> Web EC2
# =========================================================

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.rimo.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}


# =========================================================
# Outputs
# =========================================================

output "web_alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "web_url" {
  value = "https://www.rimo-app.com"
}
