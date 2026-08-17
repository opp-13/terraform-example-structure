terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # `key` is intentionally omitted: this module is applied once per environment
  # (dev/stage/prod), each against a different target AWS account, so the state key
  # can't be a single literal. Supply it per-environment via partial configuration:
  #   terraform init -backend-config="key=oidc/<environment>/terraform.tfstate"
  backend "s3" {
    bucket       = "terraform-state-example-s6john"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
