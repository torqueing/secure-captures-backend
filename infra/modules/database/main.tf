# Single table holding users, devices, captures and enrolment challenges.
# See "Data model" in the specification for the key layout.
resource "aws_dynamodb_table" "main" {
  name                        = var.table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "captureId"
    type = "S"
  }

  # Finds a capture from its ID (the verifier only knows the S3 key).
  global_secondary_index {
    name            = "captureId"
    projection_type = "ALL"
    key_schema {
      attribute_name = "captureId"
      key_type       = "HASH"
    }
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
}
