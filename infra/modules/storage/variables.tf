variable "name_prefix" {
  description = "Prefix for bucket names, for example secure-captures-dev."
  type        = string
}

variable "kms_key_arn" {
  description = "Storage key for SSE-KMS on the web, incoming and vault buckets."
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets. Only for dev."
  type        = bool
  default     = false
}
