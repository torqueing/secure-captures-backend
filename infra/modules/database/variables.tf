variable "table_name" {
  type = string
}

variable "kms_key_arn" {
  description = "Storage key used for server-side encryption."
  type        = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}
