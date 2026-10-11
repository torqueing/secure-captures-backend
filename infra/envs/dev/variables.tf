variable "app_version" {
  type    = string
  default = "dev"
}

variable "alarm_email" {
  description = "Where alarm emails go."
  type        = string
  default     = ""
}
