output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = module.bastion.public_ip
}

output "web_server_instance_id" {
  description = "Web server EC2 instance ID"
  value       = module.web_server.instance_id
}

output "web_server_private_ip" {
  description = "Web server private IP address"
  value       = module.web_server.private_ip
}

output "was_server_instance_id" {
  description = "WAS server EC2 instance ID"
  value       = module.was_server.instance_id
}

output "was_server_private_ip" {
  description = "WAS server private IP address"
  value       = module.was_server.private_ip
}

output "db_server_instance_id" {
  description = "DB server EC2 instance ID"
  value       = module.db_server.instance_id
}

output "db_server_private_ip" {
  description = "DB server private IP address"
  value       = module.db_server.private_ip
}
