variable "name_prefix" {
  description = "Prefix for key aliases, for example secure-captures-dev."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion takes effect."
  type        = number
  default     = 30
}
