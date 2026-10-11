output "web_bucket" {
  value = { id = aws_s3_bucket.web.id, arn = aws_s3_bucket.web.arn }
}

output "incoming_bucket" {
  value = { id = aws_s3_bucket.incoming.id, arn = aws_s3_bucket.incoming.arn }
}

output "vault_bucket" {
  value = { id = aws_s3_bucket.vault.id, arn = aws_s3_bucket.vault.arn }
}

output "logs_bucket" {
  value = { id = aws_s3_bucket.logs.id, arn = aws_s3_bucket.logs.arn }
}
