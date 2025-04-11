provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "../../modules/networking"

  environment        = "dev"
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = "${var.aws_region}a"
}

module "security" {
  source = "../../modules/security"

  environment = "dev"
  vpc_id      = module.networking.vpc_id
}

module "ec2" {
  source = "../../modules/ec2"

  environment          = "dev"
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = module.networking.public_subnet_id
  security_group_id    = module.security.security_group_id
  instance_profile_name = module.security.instance_profile_name
  elastic_ip_id        = module.networking.elastic_ip_id
}
