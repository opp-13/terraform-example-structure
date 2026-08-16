variable "project" {
  description = "Project name"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "zone" {
  description = "Zone tag, also used as the network module's name_prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev/poc/prod)"
  type        = string
}

variable "mangedby" {
  description = "Resource manager"
  type        = string
  default     = "terraform"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Leave null to fall back to the default AWS credential chain."
  type        = string
}

variable "oidc_role_arn" {
  description = "IAM role ARN to assume via GitHub OIDC web-identity federation for this environment's actual resource deployment (CI only, from init/oidc's apply_role_arn/plan_role_arn output). Leave null for local applies, which use var.aws_profile instead."
  type        = string
  default     = null
}

variable "web_identity_token_file" {
  description = "Path to a file containing the GitHub Actions OIDC ID token (CI only, paired with var.oidc_role_arn). Leave null for local applies."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets to create, each with its own name and CIDR"
  type = list(object({
    name = string
    cidr = string
  }))
}

variable "bastion_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion security group"
  type        = string
}

