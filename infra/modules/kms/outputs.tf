output "storage_key_arn" {
  value = aws_kms_key.storage.arn
}

output "upload_wrap_key_arn" {
  value = aws_kms_key.upload_wrap.arn
}

output "receipt_signing_key_arn" {
  value = aws_kms_key.receipt_signing.arn
}
