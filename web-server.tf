# =========================================================
# Web Server Security Group
# =========================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for public web server"
  vpc_id      = aws_vpc.rimo.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# Internet -> Web HTTP
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "HTTP from Internet"
}

# Admin -> Web SSH
resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = var.admin_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  description = "SSH from Admin"
}

# Web outbound
resource "aws_vpc_security_group_egress_rule" "web_all_outbound" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow web server outbound traffic"
}


# =========================================================
# Web Server EC2 Instance (Amazon Linux 2023)
# =========================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web.id]

  # EC2 시작 시 Nginx 설치 및 기본 페이지 생성 스크립트
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Rimo Web Server is Running!</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-web-server"
  }
}


# =========================================================
# Web Server Elastic IP (EIP)
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
  description = "웹 서버에 할당된 고정 IP (EIP)"
  value       = aws_eip.web.public_ip
}