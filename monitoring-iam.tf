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
