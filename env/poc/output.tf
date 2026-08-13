output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = module.three_tier.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = module.three_tier.bastion_public_ip
}

output "web_server_instance_id" {
  description = "Web server EC2 instance ID"
  value       = module.three_tier.web_server_instance_id
}

output "web_server_private_ip" {
  description = "Web server private IP address"
  value       = module.three_tier.web_server_private_ip
}

output "was_server_instance_id" {
  description = "WAS server EC2 instance ID"
  value       = module.three_tier.was_server_instance_id
}

output "was_server_private_ip" {
  description = "WAS server private IP address"
  value       = module.three_tier.was_server_private_ip
}

output "db_server_instance_id" {
  description = "DB server EC2 instance ID"
  value       = module.three_tier.db_server_instance_id
}

output "db_server_private_ip" {
  description = "DB server private IP address"
  value       = module.three_tier.db_server_private_ip
}

output "redis_server_instance_id" {
  description = "Redis server EC2 instance ID"
  value       = module.three_tier.redis_server_instance_id
}

output "redis_server_private_ip" {
  description = "Redis server private IP address"
  value       = module.three_tier.redis_server_private_ip
}

output "alb_dns_name" {
  description = "ALB DNS name (point your own domain's DNS record at this)"
  value       = module.three_tier.alb_dns_name
}
