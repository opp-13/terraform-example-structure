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

variable "zone" {
  description = "Zone tag"
  type        = string
  default     = "cicd"
}

variable "environment" {
  description = "Deployment environment (e.g. dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Leave null to fall back to the default AWS credential chain."
  type        = string
  default     = null
}
