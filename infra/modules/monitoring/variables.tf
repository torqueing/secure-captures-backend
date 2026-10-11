variable "name_prefix" {
  type = string
}

variable "alarm_email" {
  description = "Address that receives alarm emails. Empty creates no subscription."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  type = string
}

variable "lambda_function_names" {
  type = list(string)
}

variable "api_id" {
  type = string
}
