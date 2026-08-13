module "bastion" {
  source = "../compute"

  name                        = "bastion"
  subnet_id                   = var.bastion_subnet_id
  security_group_id           = var.bastion_security_group_id
  associate_public_ip_address = true
  user_data                   = coalesce(var.bastion_user_data, file("${path.module}/scripts/install_bastion.sh"))

  key_pair_name = var.key_pair_name
}

module "web_server" {
  source = "../compute"

  name                        = "web_server"
  subnet_id                   = var.web_subnet_id
  security_group_id           = var.web_security_group_id
  associate_public_ip_address = false
  user_data                   = coalesce(var.web_user_data, file("${path.module}/scripts/install_web.sh"))

  key_pair_name = var.key_pair_name
}

module "was_server" {
  source = "../compute"

  name                        = "was_server"
  subnet_id                   = var.was_subnet_id
  security_group_id           = var.was_security_group_id
  associate_public_ip_address = false
  user_data                   = coalesce(var.was_user_data, file("${path.module}/scripts/install_was.sh"))

  key_pair_name = var.key_pair_name
}

module "db_server" {
  source = "../compute"

  name                        = "db_server"
  subnet_id                   = var.db_subnet_id
  security_group_id           = var.db_security_group_id
  associate_public_ip_address = false
  user_data                   = coalesce(var.db_user_data, file("${path.module}/scripts/install_mysql.sh"))

  key_pair_name = var.key_pair_name
}

module "redis_server" {
  source = "../compute"

  name                        = "redis_server"
  subnet_id                   = var.redis_subnet_id
  security_group_id           = var.redis_security_group_id
  associate_public_ip_address = false
  user_data                   = coalesce(var.redis_user_data, file("${path.module}/scripts/install_redis.sh"))

  key_pair_name = var.key_pair_name
}
