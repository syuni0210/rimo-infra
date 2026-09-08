provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "RIMO"
      ManagedBy = "Terraform"
    }
  }
}
