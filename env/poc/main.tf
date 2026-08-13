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


module "bastion" {
  source = "../../modules/compute"

  name                        = "bastion"
  subnet_id                   = module.network.public_subnet_ids[0]
  security_group_id           = module.network.bastion_security_group_id
  associate_public_ip_address = true
  user_data                   = file("${path.module}/scripts/install_mysql.sh")

  key_pair_name    = var.key_pair_name
  instance_type    = var.bastion_instance_type
  root_volume_size = var.bastion_root_volume_size
}

module "app_server" {
  source = "../../modules/compute"

  name                        = "app_server"
  subnet_id                   = module.network.private_subnet_ids[0]
  security_group_id           = module.network.internal_security_group_id
  associate_public_ip_address = false

  key_pair_name    = var.key_pair_name
  instance_type    = var.app_server_instance_type
  root_volume_size = var.app_server_root_volume_size
}
