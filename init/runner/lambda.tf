data "archive_file" "webhook_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/webhook"
  output_path = "${path.module}/files/webhook_lambda.zip"
}

resource "aws_cloudwatch_log_group" "webhook_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-webhook"
  retention_in_days = 14
}

resource "aws_lambda_function" "webhook" {
  function_name    = "${local.name_prefix}-webhook"
  role             = aws_iam_role.webhook_lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 10
  filename         = data.archive_file.webhook_lambda.output_path
  source_code_hash = data.archive_file.webhook_lambda.output_base64sha256

  environment {
    variables = {
      WEBHOOK_SECRET_ARN     = aws_secretsmanager_secret.webhook_hmac.arn
      CODEBUILD_PROJECT_NAME = aws_codebuild_project.gha_runner.name
      RUNNER_LABEL           = var.runner_label
    }
  }

  depends_on = [aws_cloudwatch_log_group.webhook_lambda]
}
