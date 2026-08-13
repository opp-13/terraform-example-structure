module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name_prefix
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  # nat gw는 vpc에 한개만 사용
  # one_nat_gateway_per_az = true
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags  = { Name = "${var.name_prefix}-public" }
  private_subnet_tags = { Name = "${var.name_prefix}-private" }
}

# Bastion Security Group (public) - SSH from anywhere
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${var.name_prefix}-bastion-sg"
  description = "Bastion host - SSH from internet"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.bastion_ssh_cidr
      description = "SSH from anywhere"
    }
  }

  egress_rules = {
    all = {
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  }
}

# Internal Security Group (private) - SSH + MySQL from within the VPC
module "internal_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${var.name_prefix}-internal-sg"
  description = "Private resources - SSH and MySQL from within the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
      description = "SSH from within the VPC"
    }
    mysql = {
      from_port   = 3306
      to_port     = 3306
      ip_protocol = "tcp"
      cidr_ipv4   = var.vpc_cidr
      description = "MySQL from within the VPC"
    }
  }

  egress_rules = {
    all = {
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  }
}
