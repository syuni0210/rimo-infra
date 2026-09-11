# =========================================================
# Current AWS Account
# =========================================================

data "aws_caller_identity" "current" {}


# =========================================================
# React Build Artifact Bucket
# =========================================================

resource "aws_s3_bucket" "web_deploy" {
  bucket = "${var.project_name}-web-deploy-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-web-deploy"
  }
}


# =========================================================
# Public Access Block
# React 파일은 공개 S3 URL이 아니라 EC2가 IAM으로 가져감
# =========================================================

resource "aws_s3_bucket_public_access_block" "web_deploy" {
  bucket = aws_s3_bucket.web_deploy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# =========================================================
# Versioning
# =========================================================

resource "aws_s3_bucket_versioning" "web_deploy" {
  bucket = aws_s3_bucket.web_deploy.id

  versioning_configuration {
    status = "Enabled"
  }
}


# =========================================================
# Output
# =========================================================

output "web_deploy_bucket_name" {
  description = "React build artifact S3 bucket"
  value       = aws_s3_bucket.web_deploy.bucket
}
