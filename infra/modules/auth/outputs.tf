output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "issuer_url" {
  value = "https://${aws_cognito_user_pool.main.endpoint}"
}

output "android_client_id" {
  value = aws_cognito_user_pool_client.this["android"].id
}

output "web_client_id" {
  value = aws_cognito_user_pool_client.this["web"].id
}
