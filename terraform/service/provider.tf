provider "aws" {
  region  = var.aws_region
  profile = var.aws_account
  default_tags {
    tags = {
      Environment = var.env,
      ManagedBy   = "Terraform",
      Repo        = var.repo,
      Contact     = var.contact,
    }
  }
}