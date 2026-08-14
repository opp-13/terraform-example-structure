data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# -----------------------------------------------
# Lint role (invoked as a Lint stage inside network_deploy/compute_deploy) - logs only. GitHub
# auth is handled by codepipeline_service's Source action, not by this project, so no connection
# permission needed.
# -----------------------------------------------
resource "aws_iam_role" "codebuild_lint" {
  name               = "sesac-codebuild-lint"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_lint" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.codebuild.arn, "${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  # source.type/artifacts.type = "CODEPIPELINE" still means this project reads/writes its
  # source and (empty) output via the pipeline's S3 artifact bucket, regardless of GitHub auth.
  statement {
    sid       = "PipelineArtifacts"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "codebuild_lint" {
  name   = "sesac-codebuild-lint"
  role   = aws_iam_role.codebuild_lint.id
  policy = data.aws_iam_policy_document.codebuild_lint.json
}

# -----------------------------------------------
# Plan role (CodePipeline Plan stage) - read-only on AWS resources + write access
# only to the network module's state/lock object and the artifact bucket
# -----------------------------------------------
resource "aws_iam_role" "codebuild_plan" {
  name               = "sesac-codebuild-plan"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy_attachment" "codebuild_plan_readonly" {
  role       = aws_iam_role.codebuild_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "codebuild_plan" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.codebuild.arn, "${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    resources = [var.codeconnections_arn]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  # Read/write the network module's state object AND its S3 native lock companion object
  # (terraform plan still needs to acquire/release the lock even though it doesn't write state).
  statement {
    sid       = "NetworkStateAndLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/network/*"]
  }

  statement {
    sid       = "PipelineArtifacts"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "codebuild_plan" {
  name   = "sesac-codebuild-plan"
  role   = aws_iam_role.codebuild_plan.id
  policy = data.aws_iam_policy_document.codebuild_plan.json
}

# -----------------------------------------------
# Apply role (CodePipeline Apply stage, after manual approval) - scoped to exactly the
# EC2 networking actions dmz/network manages. No AdministratorAccess / PowerUserAccess.
# -----------------------------------------------
resource "aws_iam_role" "codebuild_apply" {
  name               = "sesac-codebuild-apply"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_apply" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.codebuild.arn, "${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    resources = [var.codeconnections_arn]
  }

  statement {
    sid       = "Sts"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "NetworkStateAndLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/network/*"]
  }

  statement {
    sid       = "PipelineArtifactsRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
  }

  # EC2 doesn't support resource-level ARN restriction for most VPC/networking actions,
  # so this is scoped by action (only what dmz/network's resources need) rather than by resource.
  statement {
    sid = "NetworkWrite"
    actions = [
      "ec2:DescribeVpcs", "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:DescribeSubnets", "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
      "ec2:DescribeInternetGateways", "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:DescribeNatGateways", "ec2:CreateNatGateway", "ec2:DeleteNatGateway",
      "ec2:DescribeAddresses", "ec2:AllocateAddress", "ec2:ReleaseAddress",
      "ec2:AssociateAddress", "ec2:DisassociateAddress",
      "ec2:DescribeRouteTables", "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute", "ec2:ReplaceRoute",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable", "ec2:ReplaceRouteTableAssociation",
      "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags",
      "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_apply" {
  name   = "sesac-codebuild-apply"
  role   = aws_iam_role.codebuild_apply.id
  policy = data.aws_iam_policy_document.codebuild_apply.json
}

# -----------------------------------------------
# Plan role (CodePipeline Plan stage, dmz/compute) - read-only on AWS resources + write access
# only to the compute module's state/lock object, read access to network's state (remote_state),
# and the artifact bucket
# -----------------------------------------------
resource "aws_iam_role" "codebuild_plan_compute" {
  name               = "sesac-codebuild-plan-compute"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy_attachment" "codebuild_plan_compute_readonly" {
  role       = aws_iam_role.codebuild_plan_compute.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "codebuild_plan_compute" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.codebuild.arn, "${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    resources = [var.codeconnections_arn]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ComputeStateAndLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/compute/*"]
  }

  # dmz/compute reads dmz/network's outputs via terraform_remote_state - read-only.
  statement {
    sid       = "NetworkStateRead"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/network/*"]
  }

  statement {
    sid       = "PipelineArtifacts"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "codebuild_plan_compute" {
  name   = "sesac-codebuild-plan-compute"
  role   = aws_iam_role.codebuild_plan_compute.id
  policy = data.aws_iam_policy_document.codebuild_plan_compute.json
}

# -----------------------------------------------
# Apply role (CodePipeline Apply stage, after manual approval, dmz/compute) - scoped to exactly
# the EC2 instance-lifecycle actions dmz/compute manages. No AdministratorAccess / PowerUserAccess.
# -----------------------------------------------
resource "aws_iam_role" "codebuild_apply_compute" {
  name               = "sesac-codebuild-apply-compute"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_apply_compute" {
  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.codebuild.arn, "${aws_cloudwatch_log_group.codebuild.arn}:*"]
  }

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    resources = [var.codeconnections_arn]
  }

  statement {
    sid       = "Sts"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ComputeStateAndLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/compute/*"]
  }

  statement {
    sid       = "NetworkStateRead"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/network/*"]
  }

  statement {
    sid       = "PipelineArtifactsRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
  }

  # EC2 doesn't support resource-level ARN restriction for most instance-lifecycle actions,
  # so this is scoped by action (only what dmz/compute's bastion instance needs) rather than by resource.
  statement {
    sid = "ComputeWrite"
    actions = [
      "ec2:DescribeInstances", "ec2:RunInstances", "ec2:TerminateInstances",
      "ec2:DescribeInstanceAttribute", "ec2:ModifyInstanceAttribute",
      "ec2:DescribeImages", "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVpcs",
      "ec2:DescribeVolumes", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags",
      "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_apply_compute" {
  name   = "sesac-codebuild-apply-compute"
  role   = aws_iam_role.codebuild_apply_compute.id
  policy = data.aws_iam_policy_document.codebuild_apply_compute.json
}

# -----------------------------------------------
# CodePipeline service role
# -----------------------------------------------
resource "aws_iam_role" "codepipeline_service" {
  name               = "sesac-codepipeline-service"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_service" {
  statement {
    sid     = "StartBuilds"
    actions = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = [
      aws_codebuild_project.lint_network.arn,
      aws_codebuild_project.lint_compute.arn,
      aws_codebuild_project.plan.arn,
      aws_codebuild_project.apply.arn,
      aws_codebuild_project.plan_compute.arn,
      aws_codebuild_project.apply_compute.arn,
    ]
  }

  statement {
    sid       = "UseConnection"
    actions   = ["codeconnections:UseConnection", "codeconnections:GetConnection", "codeconnections:GetConnectionToken"]
    resources = [var.codeconnections_arn]
  }

  statement {
    sid     = "ArtifactBucket"
    actions = ["s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.pipeline_artifacts.arn,
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_service" {
  name   = "sesac-codepipeline-service"
  role   = aws_iam_role.codepipeline_service.id
  policy = data.aws_iam_policy_document.codepipeline_service.json
}
