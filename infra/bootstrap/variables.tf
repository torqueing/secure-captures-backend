variable "github_owner" {
  description = "GitHub user or organisation that owns the backend repository."
  type        = string
  default     = "torqueing"
}

variable "github_owner_id" {
  description = "Numeric ID of the owner, used in GitHub's newer OIDC subject format."
  type        = string
  default     = "32784211"
}

variable "github_repository" {
  description = "Name of the backend repository allowed to deploy."
  type        = string
  default     = "secure-captures-backend"
}

variable "github_repository_id" {
  description = "Numeric ID of the repository, used in GitHub's newer OIDC subject format."
  type        = string
  default     = "1413932596"
}
