# --- webhook Lambda: verifies the GitHub signature and starts a CodeBuild build ---

data "aws_iam_policy_document" "webhook_lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webhook_lambda" {
  name               = "${local.name_prefix}-webhook"
  assume_role_policy = data.aws_iam_policy_document.webhook_lambda_assume.json
}

data "aws_iam_policy_document" "webhook_lambda" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.webhook_lambda.arn}:*"]
  }

  statement {
    sid       = "StartRunnerBuild"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.gha_runner.arn]
  }

  statement {
    sid       = "ReadWebhookSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.webhook_hmac.arn]
  }
}

resource "aws_iam_role_policy" "webhook_lambda" {
  name   = "${local.name_prefix}-webhook"
  role   = aws_iam_role.webhook_lambda.id
  policy = data.aws_iam_policy_document.webhook_lambda.json
}

# --- CodeBuild service role: the ephemeral runner's own AWS identity ---
# Deliberately narrow - the real terraform plan/apply credentials come from a SEPARATE
# per-environment OIDC assume-role done *inside* the job (init/oidc), not from this role.

data "aws_iam_policy_document" "gha_runner_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gha_runner" {
  name               = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.gha_runner_assume.json
}

data "aws_iam_policy_document" "gha_runner" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.gha_runner.arn, "${aws_cloudwatch_log_group.gha_runner.arn}:*"]
  }

  statement {
    sid       = "ReadGithubCredential"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.gha_token.arn]
  }

  # This runner is shared across every environment's jobs but lives in the SAME account
  # as the state bucket, so it gets direct (same-account, no bucket policy needed) access
  # to the whole bucket - the Terraform S3 backend rides on this ambient role automatically
  # (no OIDC assume-role involved). Actual *infra* changes (ec2/elb/route53 in each target
  # account) still go through the per-environment OIDC role from init/oidc, kept separate
  # on purpose - see init/oidc/README.md.
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [var.state_bucket_arn]
  }

  statement {
    sid       = "StateReadWrite"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.state_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "gha_runner" {
  name   = local.name_prefix
  role   = aws_iam_role.gha_runner.id
  policy = data.aws_iam_policy_document.gha_runner.json
}

# --- reaper Lambda: periodically removes stale offline runner registrations ---

data "aws_iam_policy_document" "reaper_lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "reaper_lambda" {
  name               = "${local.name_prefix}-reaper"
  assume_role_policy = data.aws_iam_policy_document.reaper_lambda_assume.json
}

data "aws_iam_policy_document" "reaper_lambda" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.reaper_lambda.arn}:*"]
  }

  statement {
    sid       = "ReadGithubCredential"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.gha_token.arn]
  }
}

resource "aws_iam_role_policy" "reaper_lambda" {
  name   = "${local.name_prefix}-reaper"
  role   = aws_iam_role.reaper_lambda.id
  policy = data.aws_iam_policy_document.reaper_lambda.json
}
