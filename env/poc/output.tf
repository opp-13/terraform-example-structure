output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = module.bastion.instance_id
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = module.bastion.public_ip
}

output "app_server_instance_id" {
  description = "App server EC2 instance ID"
  value       = module.app_server.instance_id
}

output "app_server_private_ip" {
  description = "App server private IP address"
  value       = module.app_server.private_ip
}
