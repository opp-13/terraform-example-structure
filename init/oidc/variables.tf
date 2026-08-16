variable "environment" {
  description = "Environment name this OIDC/IAM setup targets (dev/stage/prod/...). Must match the GitHub Environment name prefix used in the workflow YAML (<environment>-plan, <environment>-apply)."
  type        = string
}

variable "env_aws_profile" {
  description = "Named AWS CLI profile for this environment's target AWS account. Leave null to fall back to the default AWS credential chain."
  type        = string
  default     = null
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without owner)"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "john"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "init"
}
