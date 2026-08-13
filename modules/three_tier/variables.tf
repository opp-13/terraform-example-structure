variable "key_pair_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console) to use for SSH access to all four instances"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for the ALB name (e.g. \"dmz\")"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the ALB is created in (pass the network module's vpc_id)"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (needs at least 2, across different AZs)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB (pass the network module's alb_security_group_id)"
  type        = string
}

variable "domain_name" {
  description = "Domain name to look up an existing ISSUED ACM certificate for. Can be a wildcard (e.g. \"example.com\" or \"*.example.com\") — must match the cert's DomainName exactly."
  type        = string
}

variable "base_domain_name" {
  description = "Apex domain name (never a wildcard, e.g. \"example.com\") used to look up the public Route53 hosted zone and to build the root/www A records."
  type        = string
}

variable "private_dns_zone_name" {
  description = "Private Route53 hosted zone name for internal service discovery. Must match the app's expected hostnames (api/db/redis.<this>), e.g. \"cloud.local\"."
  type        = string
  default     = "cloud.local"
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

variable "redis_subnet_id" {
  description = "Private subnet ID for the Redis server (pass one of the network module's private_subnet_ids)"
  type        = string
}

variable "redis_security_group_id" {
  description = "Security group ID for the Redis server (pass the network module's internal_redis_security_group_id)"
  type        = string
}

variable "redis_user_data" {
  description = "user_data script content for the Redis server. Defaults to scripts/install_redis.sh; pass a value to override."
  type        = string
  default     = null
}
