terraform {
 backend "s3" {
   bucket = "cliente-a-tfstate"
   key = "global/s3/terraform-tfstate"
   region = "us-east-1"
   dynamodb_table = "cliente-a-statke-locking"
   encrypt = true
 }
}

terraform {
  required_providers {
    ansible = {
      version = "~> 1.1.0"
      source  = "ansible/ansible"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

# # create an S3 bucket to store tfstate

# # resource "aws_s3_bucket" "terraform-state" {
# #   bucket = "terraform-state-cliente-a"

# #   lifecycle {
# #     prevent_destroy = false
# #   }
# # }

# # resource "aws_s3_bucket_versioning" "versioning_test" {
# #   bucket = aws_s3_bucket.terraform-state.id
# #   versioning_configuration {
# #     status = "Enabled"
# #   }
# # }

# # resource "aws_s3_bucket_server_side_encryption_configuration" "side_cfg_test" {
# #   bucket = aws_s3_bucket.terraform-state.id
# #   rule {
# #     apply_server_side_encryption_by_default {
# #       sse_algorithm = "AES256"
# #     }
# #   }
# # }



# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name               = "ClienteA-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  enable_deletion_protection = false

  tags   = {
    Name = "ClienteA-alb"
  }
}

# create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "ClienteA-tg"
  target_type = "ip"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create a listener on port 80 with redirect action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# create a listener on port 443 with forward action
resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn  = aws_lb.application_load_balancer.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# Attaching EC2 instance to Target Group

resource "aws_alb_target_group_attachment" "ec2_attach" {
  target_id        = aws_instance.webserver.private_ip
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  port             = 80
}

# terraform aws data hosted zone
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

# create a record set in route 53
# terraform aws route 53 record
resource "aws_route53_record" "site_domain" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}

# create SSH key for ssh connection

resource "aws_key_pair" "cliente_a" {
  key_name = "cliente_a"
  public_key = tls_private_key.cliente_a.public_key_openssh
}


 resource "tls_private_key" "cliente_a" {
   algorithm = "RSA"
   rsa_bits = 4096
 }



resource "local_file" "cliente_a" {
   content  = tls_private_key.cliente_a.private_key_pem
   filename = "cliente_a"
 }


# create EC2 instance
resource "aws_instance" "webserver" {
    ami                    = var.ami
    instance_type          = var.instance_type
    key_name               = aws_key_pair.cliente_a.key_name
    tags = {
    Name = "Cliente A WebApp"
  } 
      provisioner "local-exec" {
       command = "export DD_API_KEY=4cea7749ac94be1db7f9d4c9a7d23c44 DD_SITE='datadoghq.com' bash -c '$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)'"
      }
    vpc_security_group_ids = var.vpc_security_group_ids
    subnet_id              = var.subnet_id
}

# create a null resource to use rf vars in bash

resource "null_resource" "provisione" {

  provisioner "local-exec" {
    command = "export dns_public=${aws_instance.webserver.public_dns}"
    interpreter = [ "bash", "-c" ]
  }
}

# Add created ec2 instance to ansible inventory
resource "ansible_host" "webserver" {
  name                           = aws_instance.webserver.public_dns
  groups                         = ["nginx"]
  variables = {
    ansible_user                 = "ubuntu",
    ansible_ssh_private_key_file = "cliente_a",
    ansible_python_interpreter   = "/usr/bin/python3",
  }
}


