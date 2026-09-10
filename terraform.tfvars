aws_region         = "ap-northeast-2"
project_name       = "rimo"
cluster_name       = "rimo-eks"
kubernetes_version = "1.36"

admin_cidr = "118.131.22.85/32"

# ALB 생성 후 true로 변경
create_api_dns_record = true

alb_dns_name = "k8s-default-rimoapii-8122f239d4-987844665.ap-northeast-2.elb.amazonaws.com"
alb_zone_id  = "ZWKZPGTI48KDX"
