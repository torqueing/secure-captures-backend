# The four buckets from the specification's "S3 layout". Names end in the account ID
# because bucket names are global.

data "aws_caller_identity" "current" {}

locals {
  suffix = data.aws_caller_identity.current.account_id

  # Buckets whose data is encrypted with the storage key and logged to the logs bucket.
  data_buckets = {
    web      = aws_s3_bucket.web
    incoming = aws_s3_bucket.incoming
    vault    = aws_s3_bucket.vault
  }
  all_buckets = merge(local.data_buckets, { logs = aws_s3_bucket.logs })
}

resource "aws_s3_bucket" "web" {
  bucket        = "${var.name_prefix}-web-${local.suffix}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket" "incoming" {
  bucket        = "${var.name_prefix}-incoming-${local.suffix}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket" "vault" {
  bucket              = "${var.name_prefix}-vault-${local.suffix}"
  force_destroy       = var.force_destroy
  object_lock_enabled = true
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name_prefix}-logs-${local.suffix}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "all" {
  for_each                = local.all_buckets
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "all" {
  for_each = local.all_buckets
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  for_each = local.data_buckets
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# S3 server access logs can only be delivered to a bucket using SSE-S3.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "vault" {
  bucket = aws_s3_bucket.vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "web" {
  bucket = aws_s3_bucket.web.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Object Lock is switched on so retention can be added later without recreating the
# bucket; no default retention applies (spec open question 9).

resource "aws_s3_bucket_logging" "data" {
  for_each      = local.data_buckets
  bucket        = each.value.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3/${each.key}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  rule {
    id     = "expire-unverified-uploads"
    status = "Enabled"
    filter {}
    expiration {
      days = 1
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vault" {
  bucket     = aws_s3_bucket.vault.id
  depends_on = [aws_s3_bucket_versioning.vault]
  rule {
    # Deleted photos must be gone within a day, old versions included (UK GDPR).
    id     = "purge-deleted-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "web" {
  bucket     = aws_s3_bucket.web.id
  depends_on = [aws_s3_bucket_versioning.web]
  rule {
    id     = "expire-old-site-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = var.log_retention_days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Every bucket refuses plain HTTP; the logs bucket also accepts S3 access log delivery.
data "aws_iam_policy_document" "bucket" {
  for_each = local.all_buckets

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []
    content {
      sid       = "S3AccessLogDelivery"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${each.value.arn}/s3/*"]
      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.suffix]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "all" {
  for_each   = local.all_buckets
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.bucket[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.all]
}
