aws_region         = "ap-northeast-2"
project_name       = "rimo"
cluster_name       = "rimo-eks"
kubernetes_version = "1.36"

admin_cidr = "118.131.22.85/32"

# ALB 생성 후 true로 변경
create_api_dns_record = false
