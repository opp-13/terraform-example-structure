# Empty container - a human populates this with a fine-grained GitHub PAT after apply
# (see README). Terraform must never set secret_string here: a PAT literal in a .tf file
# would be plan-visible and end up in state.
resource "aws_secretsmanager_secret" "gha_token" {
  name        = "${local.name_prefix}/github-token"
  description = "GitHub PAT (or App token) used to mint self-hosted runner registration tokens. Populated manually after apply."
}

# HMAC secret for verifying the GitHub webhook signature - Terraform *can* own this one,
# since it's generated, not GitHub-issued. A human copies the value into the GitHub
# webhook's "Secret" field.
resource "random_password" "webhook_hmac" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "webhook_hmac" {
  name        = "${local.name_prefix}/webhook-hmac"
  description = "HMAC secret for verifying X-Hub-Signature-256 on the GitHub workflow_job webhook"
}

resource "aws_secretsmanager_secret_version" "webhook_hmac" {
  secret_id     = aws_secretsmanager_secret.webhook_hmac.id
  secret_string = random_password.webhook_hmac.result
}
