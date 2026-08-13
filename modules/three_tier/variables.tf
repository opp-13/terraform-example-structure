variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console) to use for SSH access to all four instances"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Public subnet ID for the bastion instance (pass the network module's public_subnet_ids[n])"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID for the bastion instance (pass the network module's bastion_security_group_id)"
  type        = string
}

variable "bastion_user_data" {
  description = "user_data script content for the bastion instance. Defaults to scripts/install_bastion.sh; pass a value to override."
  type        = string
  default     = null
}

variable "web_subnet_id" {
  description = "Private subnet ID for the web server (pass one of the network module's private_subnet_ids)"
  type        = string
}

variable "web_security_group_id" {
  description = "Security group ID for the web server (pass the network module's web_security_group_id)"
  type        = string
}

variable "web_user_data" {
  description = "user_data script content for the web server. Defaults to scripts/install_web.sh; pass a value to override."
  type        = string
  default     = null
}

variable "was_subnet_id" {
  description = "Private subnet ID for the WAS server (pass one of the network module's private_subnet_ids)"
  type        = string
}

variable "was_security_group_id" {
  description = "Security group ID for the WAS server (pass the network module's internal_api_security_group_id)"
  type        = string
}

variable "was_user_data" {
  description = "user_data script content for the WAS server. Defaults to scripts/install_was.sh; pass a value to override."
  type        = string
  default     = null
}

variable "db_subnet_id" {
  description = "Private subnet ID for the DB server (pass one of the network module's private_subnet_ids)"
  type        = string
}

variable "db_security_group_id" {
  description = "Security group ID for the DB server (pass the network module's internal_mysql_security_group_id)"
  type        = string
}

variable "db_user_data" {
  description = "user_data script content for the DB server. Defaults to scripts/install_mysql.sh; pass a value to override."
  type        = string
  default     = null
}
