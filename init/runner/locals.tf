locals {
  common_tags = {
    Owner       = var.owner
    Zone        = "runner"
    Project     = var.project
    Environment = "terraform"
  }

  name_prefix = "gha-runner"
}
