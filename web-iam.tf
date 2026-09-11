# =========================================================
# Web EC2 IAM Role
# =========================================================

resource "aws_iam_role" "web" {
  name = "${var.project_name}-web-role"

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
    Name = "${var.project_name}-web-role"
  }
}


# =========================================================
# Systems Manager
# SSH 없이 Web EC2 관리
# =========================================================

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# =========================================================
# React 배포 파일 S3 Read 권한
# =========================================================

resource "aws_iam_role_policy" "web_s3_read" {
  name = "${var.project_name}-web-s3-read"
  role = aws_iam_role.web.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.web_deploy.arn
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "${aws_s3_bucket.web_deploy.arn}/*"
        ]
      }
    ]
  })
}


# =========================================================
# EC2 Instance Profile
# =========================================================

resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-instance-profile"
  role = aws_iam_role.web.name
}
