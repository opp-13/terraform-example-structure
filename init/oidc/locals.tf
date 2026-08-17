locals {
  common_tags = {
    Owner       = var.owner
    Zone        = "oidc"
    Project     = var.project
    Environment = var.environment
  }
}
