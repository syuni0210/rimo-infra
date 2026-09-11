# =========================================================
# Jenkins IAM Policy
# Monitoring EC2에서 Jenkins 실행
# =========================================================

resource "aws_iam_policy" "jenkins_deploy" {
  name        = "${var.project_name}-jenkins-deploy-policy"
  description = "Allow Jenkins to push images to ECR, deploy to EKS, upload web artifacts to S3, and deploy web via SSM"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # -----------------------------------------------------
      # ECR Login
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      # -----------------------------------------------------
      # ECR Push
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage"
        ]

        Resource = [
          aws_ecr_repository.auth_api.arn,
          aws_ecr_repository.member_api.arn,
          aws_ecr_repository.tracking_api.arn,
          aws_ecr_repository.route_api.arn,
          aws_ecr_repository.data_api.arn
        ]
      },

      # -----------------------------------------------------
      # Jenkins가 kubeconfig 생성 시 필요
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = aws_eks_cluster.rimo.arn
      },

      # -----------------------------------------------------
      # Jenkins -> Web EC2 SSM 명령 실행
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ssm:SendCommand"
        ]

        Resource = [
          "arn:aws:ssm:ap-northeast-2::document/AWS-RunShellScript",
          "arn:aws:ec2:ap-northeast-2:110844250782:instance/i-0effe371ad87bbf66"
        ]
      },

      # -----------------------------------------------------
      # Jenkins -> SSM 명령 실행 결과 확인
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]

        Resource = "*"
      },

      # -----------------------------------------------------
      # Jenkins -> Web Deploy S3 Bucket 조회
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = "arn:aws:s3:::rimo-web-deploy-110844250782"
      },

      # -----------------------------------------------------
      # Jenkins -> Web Deploy S3 파일 업로드/삭제
      # -----------------------------------------------------
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::rimo-web-deploy-110844250782/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-jenkins-deploy-policy"
  }
}


# =========================================================
# Jenkins Policy -> Monitoring EC2 IAM Role
# =========================================================

resource "aws_iam_role_policy_attachment" "jenkins_deploy" {
  role       = aws_iam_role.monitoring_ec2.name
  policy_arn = aws_iam_policy.jenkins_deploy.arn
}


# =========================================================
# Jenkins -> EKS Access Entry
# =========================================================

resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.rimo.name
  principal_arn = aws_iam_role.monitoring_ec2.arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.rimo
  ]
}


# =========================================================
# Jenkins Kubernetes 권한
# default namespace만 수정 가능
# =========================================================

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.rimo.name
  principal_arn = aws_iam_role.monitoring_ec2.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type = "namespace"

    namespaces = [
      "default"
    ]
  }

  depends_on = [
    aws_eks_access_entry.jenkins
  ]
}