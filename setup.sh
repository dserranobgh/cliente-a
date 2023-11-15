#!/bin/sh

set -eux

ansible-galaxy collection install cloud.terraform
mv terraform.tfstate terraform.tfstate.bkp

terraform init
terraform apply -auto-approve
mv terraform.tfstate.bkp terraform.tfstate

ansible-playbook -i inventory.yml nginx.yml
ansible-playbook -i inventory.yml copyapp.yml

ip=$(ansible-inventory -i inventory.yml --list | jq -r '.nginx.hosts[0]')
curl "http://${ip}" --fail