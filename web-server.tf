# =========================================================
# Web Server Security Group
# =========================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web EC2 behind ALB"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}


# =========================================================
# Web ALB -> Web EC2 HTTP
# =========================================================

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id

  referenced_security_group_id = aws_security_group.web_alb.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "HTTP from Web ALB"
}


# =========================================================
# Admin -> Web SSH
# 현재는 SSM을 사용할 예정이지만 기존 설정 유지
# =========================================================

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = var.admin_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  description = "SSH from Admin"
}


# =========================================================
# Web EC2 outbound
# =========================================================

resource "aws_vpc_security_group_egress_rule" "web_all_outbound" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow web server outbound traffic"
}


# =========================================================
# Amazon Linux 2023 AMI
# =========================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}


# =========================================================
# Web Server EC2
# =========================================================

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # SSH 대신 Systems Manager 사용
  iam_instance_profile = aws_iam_instance_profile.web.name

  user_data = <<-EOF
              #!/bin/bash

              dnf install -y nginx unzip

              # AWS CLI가 없는 경우 설치 시도
              if ! command -v aws >/dev/null 2>&1; then
                dnf install -y awscli2 || true
              fi

              # React SPA 새로고침 대응
              mkdir -p /etc/nginx/default.d

              cat > /etc/nginx/default.d/rimo-spa.conf <<'NGINX'
              location / {
                  try_files $uri $uri/ /index.html;
              }
              NGINX

              # 초기 확인용 페이지
              cat > /usr/share/nginx/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                <meta charset="UTF-8">
                <title>RIMO</title>
              </head>
              <body>
                <h1>Rimo Web Server is Running!</h1>
              </body>
              </html>
              HTML

              systemctl enable nginx
              systemctl restart nginx

              systemctl enable amazon-ssm-agent || true
              systemctl restart amazon-ssm-agent || true
              EOF

  depends_on = [
    aws_iam_role_policy_attachment.web_ssm,
    aws_iam_role_policy.web_s3_read
  ]

  tags = {
    Name = "${var.project_name}-web-server"
  }
}


# =========================================================
# Web Server Elastic IP
#
# 현재 기존 구조를 유지하기 위해 남겨둠.
# 실제 사용자 접속은 EIP가 아니라 ALB를 통해 이루어짐.
# =========================================================

resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-web-eip"
  }
}


# =========================================================
# Outputs
# =========================================================

output "web_server_eip" {
  description = "Web EC2 Elastic IP"
  value       = aws_eip.web.public_ip
}

output "web_instance_id" {
  description = "Web EC2 Instance ID"
  value       = aws_instance.web.id
}
