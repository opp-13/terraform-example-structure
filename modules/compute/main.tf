# associate_public_ip_address = true로 두는 인스턴스는 map_public_ip_on_launch = false인
# 서브넷(modules/network 참고)에 위치할 수 있으므로, 이 값을 통해 명시적으로 공인 IP를 켜야 함.
module "instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = var.name

  ami                         = coalesce(var.ami, data.aws_ami.al2023.id)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data

  root_block_device = [
    {
      volume_size = var.root_volume_size
      volume_type = "gp3"
    }
  ]
}
