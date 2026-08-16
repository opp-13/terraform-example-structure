output "connection_arn" {
  description = "CodeConnections (GitHub) connection ARN - pass this into init/cicd as var.codeconnections_arn"
  value       = aws_codeconnections_connection.github.arn
}

output "connection_status" {
  description = "Connection status - must be AVAILABLE (not PENDING) before init/cicd's webhook/pipeline will work"
  value       = aws_codeconnections_connection.github.connection_status
}
