variable "project" {
  description = "Project name"
  type        = string
  default     = "init"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "john"
}

variable "zone" {
  description = "Zone tag, also used as the network module's name_prefix"
  type        = string
  default     = "dmz"
}

variable "environment" {
  description = "Deployment environment (e.g. dev/poc/prod)"
  type        = string
  default     = "poc"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Leave null to fall back to the default AWS credential chain."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console) to use for SSH access to the bastion"
  type        = string
}

variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}

variable "bastion_root_volume_size" {
  description = "Bastion root EBS volume size in GB"
  type        = number
  default     = 16
}

variable "app_server_instance_type" {
  description = "App server instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_server_root_volume_size" {
  description = "App server root EBS volume size in GB"
  type        = number
  default     = 16
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "bastion_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion security group"
  type        = string
  default     = "0.0.0.0/0"
}
