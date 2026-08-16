# GitHub's OIDC provider thumbprint (root CA). GitHub rotates intermediate certs, not this
# root, so this value is stable - see https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policies are scoped down to the GitHub *Environment* name (via the OIDC token's
# `sub` claim), not just the repo - so a job that only cleared the plan-gate can't assume
# the apply role, even though both roles trust the same repo.
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
      values   = ["repo:${var.github_org}/${var.github_repo}:environment:${var.environment}-plan"]
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
      values   = ["repo:${var.github_org}/${var.github_repo}:environment:${var.environment}-apply"]
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
