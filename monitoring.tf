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
    # Base Packages
    # ======================================================

    apt-get update -y

    apt-get install -y \
      ca-certificates \
      curl \
      wget \
      unzip \
      gnupg \
      git \
      jq \
      fontconfig \
      apt-transport-https \
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

    usermod -aG docker jenkins

    systemctl restart jenkins


    # ======================================================
    # Prometheus
    # ======================================================

    PROMETHEUS_VERSION="3.14.0"

    useradd \
      --system \
      --no-create-home \
      --shell /usr/sbin/nologin \
      prometheus || true

    mkdir -p \
      /etc/prometheus \
      /var/lib/prometheus

    cd /tmp

    wget -q \
      https://github.com/prometheus/prometheus/releases/download/v$${PROMETHEUS_VERSION}/prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz

    tar \
      -xzf \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz

    cp \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64/prometheus \
      /usr/local/bin/

    cp \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64/promtool \
      /usr/local/bin/

    cp -r \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64/consoles \
      /etc/prometheus/ || true

    cp -r \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64/console_libraries \
      /etc/prometheus/ || true

    rm -rf \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64 \
      prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz


    # ======================================================
    # Prometheus Config
    # ======================================================

    cat > /etc/prometheus/prometheus.yml <<'PROMEOF'
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:

      - job_name: "prometheus"
        static_configs:
          - targets:
              - "localhost:9090"

    PROMEOF


    chown -R \
      prometheus:prometheus \
      /etc/prometheus \
      /var/lib/prometheus

    chown prometheus:prometheus \
      /usr/local/bin/prometheus \
      /usr/local/bin/promtool


    # ======================================================
    # Prometheus systemd
    # ======================================================

    cat > /etc/systemd/system/prometheus.service <<'SERVICEEOF'
    [Unit]
    Description=Prometheus Monitoring
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=prometheus
    Group=prometheus

    Type=simple

    ExecStart=/usr/local/bin/prometheus \
      --config.file=/etc/prometheus/prometheus.yml \
      --storage.tsdb.path=/var/lib/prometheus \
      --web.console.templates=/etc/prometheus/consoles \
      --web.console.libraries=/etc/prometheus/console_libraries \
      --web.listen-address=0.0.0.0:9090

    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICEEOF


    systemctl daemon-reload

    systemctl enable prometheus
    systemctl start prometheus


    # ======================================================
    # Grafana Repository
    # ======================================================

    mkdir -p /etc/apt/keyrings

    wget \
      -q \
      -O /etc/apt/keyrings/grafana.asc \
      https://apt.grafana.com/gpg-full.key

    chmod 644 \
      /etc/apt/keyrings/grafana.asc

    echo \
      "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" \
      > /etc/apt/sources.list.d/grafana.list


    # ======================================================
    # Grafana
    # ======================================================

    apt-get update -y

    apt-get install -y grafana

    systemctl enable grafana-server
    systemctl start grafana-server


    # ======================================================
    # Grafana -> Prometheus Data Source
    # ======================================================

    mkdir -p \
      /etc/grafana/provisioning/datasources

    cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'GRAFANAEOF'
    apiVersion: 1

    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://localhost:9090
        isDefault: true
        editable: true
    GRAFANAEOF

    systemctl restart grafana-server


    # ======================================================
    # Installation Check
    # ======================================================

    {
      echo "================================"
      echo "RIMO Monitoring Server"
      echo "================================"

      echo ""
      echo "Java:"
      java -version

      echo ""
      echo "Docker:"
      docker --version

      echo ""
      echo "AWS CLI:"
      aws --version

      echo ""
      echo "kubectl:"
      kubectl version --client

      echo ""
      echo "Prometheus:"
      prometheus --version

      echo ""
      echo "Jenkins:"
      systemctl is-active jenkins

      echo ""
      echo "Prometheus Service:"
      systemctl is-active prometheus

      echo ""
      echo "Grafana:"
      systemctl is-active grafana-server

    } > /var/log/rimo-bootstrap.log 2>&1

  EOF

  tags = {
    Name = "${var.project_name}-monitoring"
  }
}
