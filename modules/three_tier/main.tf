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

# frodo-crud1-front(nginx)/frodo-crud1-api가 기대하는 내부 호스트네임
# (api.cloud.local, db.cloud.local, redis.cloud.local)을 풀어주는 private hosted zone
resource "aws_route53_zone" "private" {
  name = var.private_dns_zone_name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${var.private_dns_zone_name}"
  type    = "A"
  ttl     = 60
  records = [module.was_server.private_ip]
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.private_dns_zone_name}"
  type    = "A"
  ttl     = 60
  records = [module.db_server.private_ip]
}

resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "redis.${var.private_dns_zone_name}"
  type    = "A"
  ttl     = 60
  records = [module.redis_server.private_ip]
}

# ALB 삭제 API 호출이 끝나도 AWS가 ENI를 비동기로 정리하는 데 시간이 걸려서,
# 그 직후 바로 IGW/서브넷을 지우려 하면 "ENI가 아직 붙어있다"며 막히는 경우가 있음.
# module.alb가 이 리소스에 의존하게 해서, destroy 시 ALB가 먼저 지워지고
# 이 리소스가 destroy_duration만큼 대기한 뒤에야 나머지(네트워크 쪽)가 지워지도록 함.
resource "time_sleep" "wait_for_alb_eni_cleanup" {
  destroy_duration = "2m"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name    = "${var.name_prefix}-alb"
  vpc_id  = var.vpc_id
  subnets = var.public_subnet_ids

  create_security_group = false
  security_groups        = [var.alb_security_group_id]

  depends_on = [time_sleep.wait_for_alb_eni_cleanup]

  target_groups = {
    web = {
      name_prefix = "web-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = module.web_server.instance_id
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.this.arn
      forward         = { target_group_key = "web" }
    }
  }

  route53_records = {
    root = {
      zone_id = data.aws_route53_zone.public.zone_id
      name    = var.base_domain_name
      type    = "A"
    }
    www = {
      zone_id = data.aws_route53_zone.public.zone_id
      name    = "www.${var.base_domain_name}"
      type    = "A"
    }
  }
}
