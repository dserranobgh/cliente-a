terraform {
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }

    }
}

provider "aws" {
    region = "us-east-1"
}

module "ec2_alb" {
  source = "../modules/ec2_alb"
  key_name = var.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  ami = var.ami
  instance_type = var.instance_type
  name = var.name
  security_groups = var.security_groups
  certificate_arn = var.certificate_arn
  subnets = var.subnets
  vpc_id = var.vpc_id
  private_key_path = var.private_key_path
}

module "r53" {
  source = "../modules/r53"
  record_name = var.record_name
  domain_name = var.domain_name
  alb_dns_name = module.ec2_alb.alb_dns_name
  alb_hosted_zone_id = module.ec2_alb.alb_hosted_zone_id
}
