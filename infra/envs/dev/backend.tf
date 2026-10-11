# The state bucket comes from infra/bootstrap; pass it at init time:
#   terraform init -backend-config="bucket=<state_bucket output>"
terraform {
  backend "s3" {
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
