variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "artifacts_dir" {
  description = "Directory holding the zips built by backend/build.mjs."
  type        = string
}

variable "app_version" {
  type    = string
  default = "dev"
}

variable "table_name" {
  type = string
}

variable "table_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "log_retention_days" {
  type = number
}
