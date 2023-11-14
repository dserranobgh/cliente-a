#EC2 variables

variable "ami" {}

variable "instance_type" {}

variable "key_name" {}

variable "vpc_security_group_ids" {}

variable "subnet_id" {}

variable "security_groups" {}

variable "subnets" {}

variable "vpc_id" {}

variable "name" {}

variable "certificate_arn" {}

variable "private_key_path" {}

#Route 53 variables

variable "domain_name" {}

variable "record_name" {}
