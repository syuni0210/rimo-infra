# =========================================================
# Monitoring EC2 IAM Role
# =========================================================

resource "aws_iam_role" "monitoring_ec2" {
  name = "${var.project_name}-monitoring-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-monitoring-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-monitoring-instance-profile"
  role = aws_iam_role.monitoring_ec2.name
}

# =========================================================
# Monitoring EC2 - CloudWatch 읽기 전용 권한
# (Grafana에서 AWS 인프라 지표를 CloudWatch로 조회하기 위해)
# =========================================================

resource "aws_iam_role_policy_attachment" "monitoring_cloudwatch_readonly" {
  role       = aws_iam_role.monitoring_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
