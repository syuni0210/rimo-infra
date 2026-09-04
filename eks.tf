# =========================================================
# EKS Cluster
# =========================================================

resource "aws_eks_cluster" "rimo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids = [
      aws_subnet.private_app_a.id,
      aws_subnet.private_app_b.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true

    # 현재 Terraform / kubectl 작업 PC 공인 IP만 허용
    public_access_cidrs = [
      "118.131.22.85/32"
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks
  ]

  tags = {
    Name = var.cluster_name
  }
}


# =========================================================
# EKS Managed Node Group
# =========================================================

resource "aws_eks_node_group" "rimo" {
  cluster_name    = aws_eks_cluster.rimo.name
  node_group_name = "rimo-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn

  subnet_ids = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  instance_types = [
    "t3.medium"
  ]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks_node.id
    version = aws_launch_template.eks_node.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]

  tags = {
    Name = "${var.project_name}-eks-node-group"
  }
}
