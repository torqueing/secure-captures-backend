# The Secure Captures functions. Milestone 1 has the API and the Cognito post-confirmation
# trigger; the verifier and janitor arrive with milestone 2.

locals {
  common_env = {
    TABLE_NAME  = var.table_name
    APP_VERSION = var.app_version
  }
}

data "aws_iam_policy_document" "storage_key_via_dynamodb" {
  statement {
    sid       = "UseStorageKeyThroughDynamoDB"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.${var.region}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "api" {
  source_policy_documents = [data.aws_iam_policy_document.storage_key_via_dynamodb.json]

  statement {
    sid       = "ReadWriteTable"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query"]
    resources = [var.table_arn, "${var.table_arn}/index/*"]
  }
}

module "api" {
  source             = "../lambda-function"
  name               = "${var.name_prefix}-api"
  description        = "Secure Captures HTTP API"
  zip_path           = "${var.artifacts_dir}/api.zip"
  environment        = local.common_env
  policy_json        = data.aws_iam_policy_document.api.json
  kms_key_arn        = var.kms_key_arn
  log_retention_days = var.log_retention_days
}

data "aws_iam_policy_document" "post_confirmation" {
  source_policy_documents = [data.aws_iam_policy_document.storage_key_via_dynamodb.json]

  statement {
    sid       = "CreateUserProfile"
    actions   = ["dynamodb:PutItem"]
    resources = [var.table_arn]
  }
}

module "post_confirmation" {
  source             = "../lambda-function"
  name               = "${var.name_prefix}-cognito-post-confirm"
  description        = "Creates the user profile after email confirmation"
  zip_path           = "${var.artifacts_dir}/post-confirmation.zip"
  environment        = local.common_env
  policy_json        = data.aws_iam_policy_document.post_confirmation.json
  kms_key_arn        = var.kms_key_arn
  log_retention_days = var.log_retention_days
  # Cognito waits at most 5 seconds for a trigger.
  timeout = 5
}
