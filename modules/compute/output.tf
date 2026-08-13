output "instance_id" {
  description = "EC2 instance ID"
  value       = module.instance.id
}

output "public_ip" {
  description = "Public IP address, if associate_public_ip_address is true"
  value       = module.instance.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = module.instance.private_ip
}
