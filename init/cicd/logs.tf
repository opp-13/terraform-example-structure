resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/sesac-cicd"
  retention_in_days = var.log_retention_days
}
