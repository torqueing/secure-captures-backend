variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "zip_path" {
  description = "Bundle built by backend/build.mjs."
  type        = string
}

variable "runtime" {
  description = "Newest Node.js LTS runtime Lambda supports."
  type        = string
  default     = "nodejs24.x"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "timeout" {
  type    = number
  default = 10
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "policy_json" {
  description = "Extra IAM policy for this function only."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Storage key for the log group and environment variables."
  type        = string
}

variable "log_retention_days" {
  type = number
}
