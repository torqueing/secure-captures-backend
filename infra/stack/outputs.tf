output "api_url" {
  value = module.api.api_url
}

output "user_pool_id" {
  value = module.auth.user_pool_id
}

output "android_client_id" {
  value = module.auth.android_client_id
}

output "web_client_id" {
  value = module.auth.web_client_id
}

output "table_name" {
  value = module.database.table_name
}

output "buckets" {
  value = {
    web      = module.storage.web_bucket.id
    incoming = module.storage.incoming_bucket.id
    vault    = module.storage.vault_bucket.id
    logs     = module.storage.logs_bucket.id
  }
}

output "kms_key_arns" {
  value = {
    storage         = module.kms.storage_key_arn
    upload_wrap     = module.kms.upload_wrap_key_arn
    receipt_signing = module.kms.receipt_signing_key_arn
  }
}

output "alarm_topic_arn" {
  value = module.monitoring.alarm_topic_arn
}
