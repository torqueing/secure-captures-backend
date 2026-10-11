variable "name_prefix" {
  type = string
}

variable "post_confirmation_lambda_arn" {
  type = string
}

variable "post_confirmation_lambda_name" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "threat_protection" {
  description = "Cognito threat protection (needs the Plus tier, billed per active user)."
  type        = bool
  default     = false
}
