data "archive_file" "reaper_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/reaper"
  output_path = "${path.module}/files/reaper_lambda.zip"
}

resource "aws_cloudwatch_log_group" "reaper_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-reaper"
  retention_in_days = 14
}

resource "aws_lambda_function" "reaper" {
  function_name    = "${local.name_prefix}-reaper"
  role             = aws_iam_role.reaper_lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.reaper_lambda.output_path
  source_code_hash = data.archive_file.reaper_lambda.output_base64sha256

  environment {
    variables = {
      GITHUB_TOKEN_SECRET_ARN = aws_secretsmanager_secret.gha_token.arn
      GITHUB_REPO_OWNER       = var.github_org
      GITHUB_REPO_NAME        = var.github_repo
      RUNNER_NAME_PREFIX      = "codebuild-"
    }
  }

  depends_on = [aws_cloudwatch_log_group.reaper_lambda]
}

resource "aws_cloudwatch_event_rule" "reaper_schedule" {
  name                = "${local.name_prefix}-reaper"
  description         = "Periodically remove offline/stale GitHub self-hosted runner registrations left behind by builds that died before deregistering"
  schedule_expression = var.reaper_schedule_expression
}

resource "aws_cloudwatch_event_target" "reaper" {
  rule = aws_cloudwatch_event_rule.reaper_schedule.name
  arn  = aws_lambda_function.reaper.arn
}

resource "aws_lambda_permission" "reaper_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reaper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reaper_schedule.arn
}
