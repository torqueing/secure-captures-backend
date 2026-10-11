# The three key types from the specification's "Keys" table. Private key material never
# leaves KMS; which roles may use each key is granted by IAM in the modules that need it.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  # Lets IAM policies in this account grant use of the key.
  account_root_statement = {
    Sid       = "AccountAdministration"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
    Action    = "kms:*"
    Resource  = "*"
  }
}

# Encrypts S3, DynamoDB, SQS, SNS and CloudWatch Logs data.
resource "aws_kms_key" "storage" {
  description             = "${var.name_prefix} storage encryption"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = var.deletion_window_in_days

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      local.account_root_statement,
      {
        Sid       = "CloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${local.region}.amazonaws.com" }
        Action    = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
        Resource  = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:*"
          }
        }
      },
      {
        # CloudWatch alarms publish to the encrypted SNS alarm topic.
        Sid       = "CloudWatchAlarmsToSns"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "storage" {
  name          = "alias/${var.name_prefix}-storage"
  target_key_id = aws_kms_key.storage.key_id
}

# The app wraps each per-photo key with this key's public half; only the verifier can unwrap.
resource "aws_kms_key" "upload_wrap" {
  description              = "${var.name_prefix} upload key wrapping (RSA-OAEP-SHA-256)"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "RSA_4096"
  deletion_window_in_days  = var.deletion_window_in_days
  policy                   = jsonencode({ Version = "2012-10-17", Statement = [local.account_root_statement] })
}

resource "aws_kms_alias" "upload_wrap" {
  name          = "alias/${var.name_prefix}-upload-wrap"
  target_key_id = aws_kms_key.upload_wrap.key_id
}

# Signs verification receipts; its public half is published for independent checks.
resource "aws_kms_key" "receipt_signing" {
  description              = "${var.name_prefix} receipt signing (ECDSA P-256)"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = var.deletion_window_in_days
  policy                   = jsonencode({ Version = "2012-10-17", Statement = [local.account_root_statement] })
}

resource "aws_kms_alias" "receipt_signing" {
  name          = "alias/${var.name_prefix}-receipt-signing"
  target_key_id = aws_kms_key.receipt_signing.key_id
}
