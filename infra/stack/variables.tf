variable "environment" {
  description = "dev or prod."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "lambda_artifacts_dir" {
  description = "Directory holding the Lambda zips built by backend/build.mjs."
  type        = string
}

variable "app_version" {
  description = "Version reported by the health endpoint, usually the git commit."
  type        = string
  default     = "dev"
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type = number
}
