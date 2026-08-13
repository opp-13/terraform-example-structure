variable "name" {
  description = "Name of this EC2 instance (also used for the Name tag), e.g. \"bastion\", \"app_server\""
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID the instance launches into (pass one of the network module's public_subnet_ids/private_subnet_ids)"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID attached to the instance (pass one of the network module's *_security_group_id outputs)"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IP. Only instances in a public subnet that need direct internet access (e.g. bastion) should set this to true."
  type        = bool
  default     = false
}

variable "ami" {
  description = "AMI ID to use. Defaults to the latest Amazon Linux 2023 AMI if not set."
  type        = string
  default     = null
}

variable "user_data" {
  description = "user_data script content to run on boot. Leave null for no bootstrap script."
  type        = string
  default     = null
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console) to use for SSH access to the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB. Must be >= the AMI's root snapshot size (current AL2023 AMI needs >= 30GB)."
  type        = number
  default     = 30
}
