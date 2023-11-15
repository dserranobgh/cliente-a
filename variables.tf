#EC2 variables

variable "ami" {}

variable "instance_type" {}

variable "vpc_security_group_ids" {}

variable "subnet_id" {}

variable "security_groups" {}

variable "subnets" {}

variable "vpc_id" {}

variable "name" {}

variable "certificate_arn" {}

variable "public_key" {}

variable "key_name" {}

#Route 53 variables

variable "domain_name" {}

variable "record_name" {}
