#!/bin/sh

set -eux

ansible-galaxy collection install cloud.terraform


terraform init
terraform apply -auto-approve

chmod 400 cliente_a

ansible-playbook -i inventory.yml nginx.yml
ansible-playbook -i inventory.yml copyapp.yml

ip=$(ansible-inventory -i inventory.yml --list | jq -r '.nginx.hosts[0]')
curl "http://${ip}" --fail