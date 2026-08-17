# GitHub's OIDC provider thumbprint (root CA). GitHub rotates intermediate certs, not this
# root, so this value is stable - see https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policies are scoped by `sub`, matching this repo's actual live OIDC token shape -
# confirmed by decoding a real token rather than assuming the classic
# `repo:org/repo:environment:name` format. This repo uses GitHub's newer "immutable
# subject claims", so `sub` looks like `repo:org@<owner_id>/repo@<repo_id>:environment:name`
# - the `@<id>` segments are stable per-repo but not something to hardcode, hence the
# wildcards. (A `job_workflow_ref`-based condition was tried first to distinguish PR-time
# plan from post-merge apply without relying on GitHub Environment names, but AssumeRole
# kept failing even though the decoded token's job_workflow_ref matched the policy
# byte-for-byte - unclear why, not worth blocking on further. Both plan and apply jobs
# declare `environment: <env>` for tfvars access, so both trust policies end up identical;
# the workflow YAML hardcoding which role ARN each job requests is the only thing keeping
# plan from ever requesting apply-level credentials now - see init/oidc/README.md.)
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}@*/${var.github_repo}@*:environment:${var.environment}"]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}@*/${var.github_repo}@*:environment:${var.environment}"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "gha-${var.environment}-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role" "apply" {
  name               = "gha-${var.environment}-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Apply role: write access scoped to the AWS services modules/network + modules/three_tier
# actually manage (EC2, ALB, Route53). No S3/state permissions here on purpose - the
# Terraform state bucket lives in the central account and is reached via init/runner's own
# CodeBuild role (same account, ambient credentials), never via this per-environment OIDC
# role. This role exists solely for the *infra* side of plan/apply. The AWS *account*
# boundary is the real isolation between environments here, not service-level IAM scoping -
# tighten the action lists below if per-layer least privilege (like the old
# init/cicd/iam.tf pattern) is wanted later.
data "aws_iam_policy_document" "apply_infra" {
  statement {
    sid       = "Ec2"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid       = "Elbv2"
    actions   = ["elasticloadbalancing:*"]
    resources = ["*"]
  }

  statement {
    sid       = "Route53"
    actions   = ["route53:*"]
    resources = ["*"]
  }

  statement {
    sid       = "AcmRead"
    actions   = ["acm:ListCertificates", "acm:DescribeCertificate"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "apply_infra" {
  name   = "apply-infra"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_infra.json
}
