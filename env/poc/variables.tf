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
  default = "terraform"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Leave null to fall back to the default AWS credential chain."
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console) to use for SSH access to the bastion"
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

variable "domain_name" {
  description = "Domain name to look up an existing ISSUED ACM certificate for (e.g. \"example.com\" or \"*.example.com\")"
  type        = string
}
