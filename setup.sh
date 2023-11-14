#!/bin/sh

set -eux

ansible-galaxy collection install cloud.terraform
snap install jq  # version 1.5+dfsg-1

terraform init
terraform apply -auto-approve

ansible-playbook -i inventory.yml nginx.yml
ansible-playbook -i inventory.yml copyapp.yml

ip=$(ansible-inventory -i inventory.yml --list | jq -r '.nginx.hosts[0]')
curl "http://${ip}" --fail