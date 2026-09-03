# =========================================================
# Ubuntu 24.04 AMI
# =========================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = [
    "099720109477"
  ]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm"
    ]
  }
}


# =========================================================
# Monitoring / Jenkins EC2
# =========================================================

resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"

  subnet_id = aws_subnet.private_monitoring.id

  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash

    set -e

    export DEBIAN_FRONTEND=noninteractive

    # ======================================================
    # Base packages
    # ======================================================

    apt-get update -y

    apt-get install -y \
      ca-certificates \
      curl \
      unzip \
      gnupg \
      git \
      jq \
      fontconfig \
      openjdk-21-jre


    # ======================================================
    # Docker
    # ======================================================

    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker


    # ======================================================
    # AWS CLI v2
    # ======================================================

    cd /tmp

    curl -fsSL \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o awscliv2.zip

    unzip -q awscliv2.zip

    ./aws/install

    rm -rf \
      /tmp/aws \
      /tmp/awscliv2.zip


    # ======================================================
    # kubectl 1.36
    # ======================================================

    KUBECTL_VERSION=$(curl -L -s \
      https://dl.k8s.io/release/stable-1.36.txt)

    curl -LO \
      "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

    install \
      -o root \
      -g root \
      -m 0755 \
      kubectl \
      /usr/local/bin/kubectl

    rm -f kubectl


    # ======================================================
    # Jenkins
    # ======================================================

    mkdir -p /etc/apt/keyrings

    curl -fsSL \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
      | tee \
      /etc/apt/keyrings/jenkins-keyring.asc \
      > /dev/null

    echo \
      "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      | tee \
      /etc/apt/sources.list.d/jenkins.list \
      > /dev/null

    apt-get update -y

    apt-get install -y jenkins

    systemctl enable jenkins
    systemctl start jenkins


    # ======================================================
    # Jenkins -> Docker 권한
    # ======================================================

    usermod -aG docker jenkins

    systemctl restart jenkins


    # ======================================================
    # Version log
    # ======================================================

    {
      echo "===== RIMO Monitoring Server ====="
      java -version
      docker --version
      aws --version
      kubectl version --client
      systemctl is-active jenkins
    } > /var/log/rimo-bootstrap.log 2>&1

  EOF

  tags = {
    Name = "${var.project_name}-monitoring"
  }
}
