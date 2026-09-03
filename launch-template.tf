# =========================================================
# EKS Worker Node Launch Template
# =========================================================

resource "aws_launch_template" "eks_node" {
  name_prefix = "${var.project_name}-eks-node-"

  # EKS control plane 통신용 Cluster Security Group
  # + RIMO에서 별도로 관리하는 Worker Node Security Group
  vpc_security_group_ids = [
    aws_eks_cluster.rimo.vpc_config[0].cluster_security_group_id,
    aws_security_group.eks_node.id
  ]

  # IMDSv2 사용
  # Pod가 Instance Metadata에 접근해야 하는 경우를 고려하여
  # hop_limit은 2로 설정
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-eks-worker"
    }
  }

  tags = {
    Name = "${var.project_name}-eks-node-launch-template"
  }
}
