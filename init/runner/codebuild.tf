resource "aws_cloudwatch_log_group" "gha_runner" {
  name              = "/codebuild/${local.name_prefix}"
  retention_in_days = 14
}

resource "aws_codebuild_project" "gha_runner" {
  name          = local.name_prefix
  description   = "Ephemeral GitHub Actions self-hosted runner (just-in-time, backed by CodeBuild)"
  service_role  = aws_iam_role.gha_runner.arn
  build_timeout = var.build_timeout_minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = var.compute_type
    image        = var.runner_image
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "GITHUB_REPO_OWNER"
      value = var.github_org
    }

    environment_variable {
      name  = "GITHUB_REPO_NAME"
      value = var.github_repo
    }

    environment_variable {
      name  = "RUNNER_VERSION"
      value = var.runner_version
    }

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = var.terraform_version
    }

    # Default label set for a manually-started build (e.g. testing); the webhook Lambda
    # overrides this per-invocation with the queued job's actual labels.
    environment_variable {
      name  = "RUNNER_LABELS"
      value = var.runner_label
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/files/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.gha_runner.name
    }
  }

  concurrent_build_limit = var.max_concurrent_runners
}
