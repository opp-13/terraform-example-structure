provider "aws" {
  region  = var.region
  profile = var.aws_profile

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

# Instance
# name/subnet_id/security_group_id/instance_type/user_data


module "three_tier" {
  source = "../../modules/three_tier"

  key_pair_name = var.key_pair_name

  bastion_subnet_id         = module.network.public_subnet_ids[0]
  bastion_security_group_id = module.network.bastion_security_group_id

  web_subnet_id         = module.network.private_subnet_ids[0] # frontend-a
  web_security_group_id = module.network.web_security_group_id

  was_subnet_id         = module.network.private_subnet_ids[2] # backend-a
  was_security_group_id = module.network.internal_api_security_group_id

  db_subnet_id         = module.network.private_subnet_ids[4] # db-a
  db_security_group_id = module.network.internal_mysql_security_group_id

  redis_subnet_id         = module.network.private_subnet_ids[2] # backend-a, was_server와 동일 서브넷
  redis_security_group_id = module.network.internal_redis_security_group_id

  name_prefix            = var.zone
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  alb_security_group_id  = module.network.alb_security_group_id
  domain_name            = var.domain_name
}