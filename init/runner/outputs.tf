output "webhook_url" {
  description = "GitHub webhook Payload URL - register this in repo Settings -> Webhooks with the 'Workflow jobs' event"
  value       = "${aws_apigatewayv2_api.webhook.api_endpoint}/webhook"
}

output "webhook_hmac_secret" {
  description = "Webhook HMAC secret - paste into the GitHub webhook's 'Secret' field"
  value       = random_password.webhook_hmac.result
  sensitive   = true
}

output "codebuild_project_name" {
  description = "CodeBuild project name backing the ephemeral GitHub Actions runner"
  value       = aws_codebuild_project.gha_runner.name
}

output "github_token_secret_name" {
  description = "Secrets Manager secret name to populate manually with a GitHub PAT after apply"
  value       = aws_secretsmanager_secret.gha_token.name
}
