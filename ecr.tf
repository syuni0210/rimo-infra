# =========================================================
# ECR Repositories
# =========================================================

resource "aws_ecr_repository" "auth_api" {
  name                 = "${var.project_name}/auth-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-auth-api-ecr"
  }
}

resource "aws_ecr_repository" "member_api" {
  name                 = "${var.project_name}/member-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-member-api-ecr"
  }
}

resource "aws_ecr_repository" "tracking_api" {
  name                 = "${var.project_name}/tracking-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-tracking-api-ecr"
  }
}

resource "aws_ecr_repository" "route_api" {
  name                 = "${var.project_name}/route-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-route-api-ecr"
  }
}

resource "aws_ecr_repository" "data_api" {
  name                 = "${var.project_name}/data-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-data-api-ecr"
  }
}
