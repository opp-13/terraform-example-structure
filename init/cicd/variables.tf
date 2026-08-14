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

variable "github_repo_owner" {
  description = "GitHub organization/user that owns the source repository"
  type        = string
  default     = "opp-13"
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = "aws-terraform-sesac-private"
}

variable "github_branch" {
  description = "Branch that triggers the network_deploy pipeline"
  type        = string
  default     = "main"
}

variable "state_bucket_name" {
  description = "S3 bucket holding Terraform remote state (created by init/bootstrap)"
  type        = string
  default     = "terraform-state-sesac"
}

variable "network_module_path" {
  description = "Relative path (from repo root) of the Terraform module the network deploy pipeline plans/applies"
  type        = string
  default     = "dmz/network"
}

variable "compute_module_path" {
  description = "Relative path (from repo root) of the Terraform module the compute deploy pipeline plans/applies"
  type        = string
  default     = "dmz/compute"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for CodeBuild projects"
  type        = number
  default     = 30
}

variable "codeconnections_arn" {
  description = "ARN of the GitHub CodeConnections connection (output of init/connection, must already be AVAILABLE)"
  type        = string
}
