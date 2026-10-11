provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project     = "Secure Captures"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

module "secure_captures" {
  source               = "../../stack"
  environment          = "dev"
  lambda_artifacts_dir = "${path.root}/../../../backend/dist"
  app_version          = var.app_version
  alarm_email          = var.alarm_email
  log_retention_days   = 30
}
