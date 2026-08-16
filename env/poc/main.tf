provider "aws" {
  region = var.region
  # Local human applies use aws_profile; CI jobs instead set oidc_role_arn (and leave
  # aws_profile unset), assuming an init/oidc role via the GitHub Actions OIDC token -
  # never both at once.
  profile = var.oidc_role_arn == null ? var.aws_profile : null

  dynamic "assume_role_with_web_identity" {
    for_each = var.oidc_role_arn == null ? [] : [1]
    content {
      role_arn                = var.oidc_role_arn
      web_identity_token_file = var.web_identity_token_file
    }
  }

  default_tags {
    tags = local.common_tags
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix         = var.zone
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnets     = var.private_subnets
  bastion_ssh_cidr    = var.bastion_ssh_cidr
}
