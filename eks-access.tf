# =========================================================
# EKS Access Entry - Monitoring EC2
# Prometheus가 EKS Node/Pod 정보를 조회할 수 있도록
# =========================================================

resource "aws_eks_access_entry" "monitoring" {
  cluster_name  = aws_eks_cluster.rimo.name
  principal_arn = aws_iam_role.monitoring_ec2.arn

  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "monitoring_view" {
  cluster_name  = aws_eks_cluster.rimo.name
  principal_arn = aws_iam_role.monitoring_ec2.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.monitoring
  ]
}
