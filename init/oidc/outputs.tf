output "plan_role_arn" {
  description = "IAM role ARN the PR-time plan workflow assumes via OIDC. Add to init/bootstrap's env_role_arns map."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "IAM role ARN the post-merge apply workflow assumes via OIDC. Add to init/bootstrap's env_role_arns map."
  value       = aws_iam_role.apply.arn
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN registered in this AWS account"
  value       = aws_iam_openid_connect_provider.github.arn
}
