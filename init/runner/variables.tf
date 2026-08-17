variable "aws_profile" {
  description = "Named AWS CLI profile to use for the account this runner infra lives in (the central/tooling account). Leave null to fall back to the default AWS credential chain."
  type        = string
  default     = null
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

variable "github_org" {
  description = "GitHub organization or user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without owner)"
  type        = string
}

variable "runner_label" {
  description = "GitHub Actions runner label these ephemeral CodeBuild runners register with. Must match `runs-on: [self-hosted, <this label>]` in the workflow YAML - the interface contract between this module and .github/workflows/*."
  type        = string
  default     = "codebuild-ephemeral"
}

variable "runner_version" {
  description = "actions/runner release version to install in the buildspec"
  type        = string
  default     = "2.336.0"
}

variable "terraform_version" {
  description = "Terraform release version to install in the buildspec - the CodeBuild base image doesn't ship one"
  type        = string
  default     = "1.13.4"
}

variable "compute_type" {
  description = "CodeBuild compute size for the runner project"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "runner_image" {
  description = "CodeBuild container image for the runner project"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "build_timeout_minutes" {
  description = "Max minutes a single ephemeral runner build may run - bounds the cost of a stuck/orphaned build"
  type        = number
  default     = 60
}

variable "max_concurrent_runners" {
  description = "CodeBuild project concurrent_build_limit - cost/quota guardrail against a burst of queued jobs"
  type        = number
  default     = 5
}

variable "webhook_throttle_burst_limit" {
  description = "API Gateway burst limit (concurrent requests) for the webhook route - cost/DoS guardrail"
  type        = number
  default     = 10
}

variable "webhook_throttle_rate_limit" {
  description = "API Gateway steady-state requests/second for the webhook route - cost/DoS guardrail"
  type        = number
  default     = 5
}

variable "reaper_schedule_expression" {
  description = "EventBridge schedule expression for the orphaned-runner-registration cleanup Lambda"
  type        = string
  default     = "rate(30 minutes)"
}

variable "state_bucket_arn" {
  description = "ARN of the central Terraform state S3 bucket (from init/bootstrap). This runner lives in the same (central) account as the bucket, so its own role is granted direct S3 access for all environments' state - CI jobs never need a separate cross-account path just to reach the backend."
  type        = string
  default     = "arn:aws:s3:::terraform-state-example-s6john"
}
