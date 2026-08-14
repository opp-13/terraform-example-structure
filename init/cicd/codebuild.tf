# -----------------------------------------------
# Lint (invoked as a stage inside network_deploy/compute_deploy, right after Source - see
# codepipeline.tf. Not a standalone PR-triggered pipeline: an earlier standalone
# aws_codebuild_webhook + CODECONNECTIONS auth kept failing with "Access denied to connection"
# regardless of IAM/connection/GitHub App configuration, so lint moved under CodePipeline.
#
# Split into one project per layer (LINT_DIRS override), same reasoning as plan/apply being
# split: a broken dmz/compute must not fail the Lint stage of a dmz/network-only deploy, and
# vice versa - the two pipelines are triggered independently by path, so their Lint gate must
# be independent too.
# -----------------------------------------------
resource "aws_codebuild_project" "lint_network" {
  name          = "sesac-lint-network"
  description   = "terraform fmt/validate/tflint/checkov for dmz/network, run before plan"
  service_role  = aws_iam_role.codebuild_lint.arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "LINT_DIRS"
      value = var.network_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

resource "aws_codebuild_project" "lint_compute" {
  name          = "sesac-lint-compute"
  description   = "terraform fmt/validate/tflint/checkov for dmz/compute, run before plan"
  service_role  = aws_iam_role.codebuild_lint.arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "LINT_DIRS"
      value = var.compute_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

# -----------------------------------------------
# Plan (CodePipeline stage, read-only IAM role, dry run for dmz/network)
# -----------------------------------------------
resource "aws_codebuild_project" "plan" {
  name          = "sesac-network-plan"
  description   = "terraform plan (read-only) for ${var.network_module_path}"
  service_role  = aws_iam_role.codebuild_plan.arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_MODULE_PATH"
      value = var.network_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-plan.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

# -----------------------------------------------
# Apply (CodePipeline stage, after manual approval)
# -----------------------------------------------
resource "aws_codebuild_project" "apply" {
  name          = "sesac-network-apply"
  description   = "terraform apply (post-approval) for ${var.network_module_path}"
  service_role  = aws_iam_role.codebuild_apply.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_MODULE_PATH"
      value = var.network_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-apply.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

# -----------------------------------------------
# Plan (CodePipeline stage, read-only IAM role, dry run for dmz/compute)
# -----------------------------------------------
resource "aws_codebuild_project" "plan_compute" {
  name          = "sesac-compute-plan"
  description   = "terraform plan (read-only) for ${var.compute_module_path}"
  service_role  = aws_iam_role.codebuild_plan_compute.arn
  build_timeout = 15

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_MODULE_PATH"
      value = var.compute_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-plan.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

# -----------------------------------------------
# Apply (CodePipeline stage, after manual approval, for dmz/compute)
# -----------------------------------------------
resource "aws_codebuild_project" "apply_compute" {
  name          = "sesac-compute-apply"
  description   = "terraform apply (post-approval) for ${var.compute_module_path}"
  service_role  = aws_iam_role.codebuild_apply_compute.arn
  build_timeout = 30

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_MODULE_PATH"
      value = var.compute_module_path
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-apply.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}
