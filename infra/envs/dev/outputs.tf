output "api_url" {
  value = module.secure_captures.api_url
}

output "user_pool_id" {
  value = module.secure_captures.user_pool_id
}

output "android_client_id" {
  value = module.secure_captures.android_client_id
}

output "web_client_id" {
  value = module.secure_captures.web_client_id
}

output "table_name" {
  value = module.secure_captures.table_name
}

output "buckets" {
  value = module.secure_captures.buckets
}

output "kms_key_arns" {
  value = module.secure_captures.kms_key_arns
}

output "alarm_topic_arn" {
  value = module.secure_captures.alarm_topic_arn
}
