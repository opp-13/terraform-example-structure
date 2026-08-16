provider "aws" {
  region  = "ap-northeast-2"
  profile = var.aws_profile

  default_tags {
    tags = local.common_tags
  }
}
