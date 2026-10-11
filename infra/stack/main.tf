# The whole Secure Captures backend for one environment. envs/dev and envs/prod call this
# with different variables only.

data "aws_region" "current" {}

locals {
  name_prefix = "secure-captures-${var.environment}"
  prod        = var.environment == "prod"
}

module "kms" {
  source      = "../modules/kms"
  name_prefix = local.name_prefix
}

module "database" {
  source              = "../modules/database"
  table_name          = local.name_prefix
  kms_key_arn         = module.kms.storage_key_arn
  deletion_protection = local.prod
}

module "storage" {
  source        = "../modules/storage"
  name_prefix   = local.name_prefix
  kms_key_arn   = module.kms.storage_key_arn
  force_destroy = !local.prod
}

module "lambdas" {
  source             = "../modules/lambdas"
  name_prefix        = local.name_prefix
  region             = data.aws_region.current.region
  artifacts_dir      = var.lambda_artifacts_dir
  app_version        = var.app_version
  table_name         = module.database.table_name
  table_arn          = module.database.table_arn
  kms_key_arn        = module.kms.storage_key_arn
  log_retention_days = var.log_retention_days
}

module "auth" {
  source                        = "../modules/auth"
  name_prefix                   = local.name_prefix
  post_confirmation_lambda_arn  = module.lambdas.post_confirmation.function_arn
  post_confirmation_lambda_name = module.lambdas.post_confirmation.function_name
  deletion_protection           = local.prod
  threat_protection             = local.prod
}

module "api" {
  source               = "../modules/api"
  name_prefix          = local.name_prefix
  issuer_url           = module.auth.issuer_url
  client_ids           = [module.auth.android_client_id, module.auth.web_client_id]
  lambda_invoke_arn    = module.lambdas.api.invoke_arn
  lambda_function_name = module.lambdas.api.function_name
  kms_key_arn          = module.kms.storage_key_arn
  log_retention_days   = var.log_retention_days
}

module "monitoring" {
  source      = "../modules/monitoring"
  name_prefix = local.name_prefix
  alarm_email = var.alarm_email
  kms_key_arn = module.kms.storage_key_arn
  api_id      = module.api.api_id
  lambda_function_names = [
    module.lambdas.api.function_name,
    module.lambdas.post_confirmation.function_name,
  ]
}
