variable "name_prefix" {
  type = string
}

variable "issuer_url" {
  description = "Cognito user pool issuer URL."
  type        = string
}

variable "client_ids" {
  description = "Cognito app client IDs whose tokens the API accepts."
  type        = list(string)
}

variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "log_retention_days" {
  type = number
}

# HTTP APIs throttle per stage, not per user; WAF adds a per-IP limit in milestone 5.
variable "throttle_rate" {
  description = "Steady-state requests per second for the whole stage."
  type        = number
  default     = 50
}

variable "throttle_burst" {
  type    = number
  default = 100
}
