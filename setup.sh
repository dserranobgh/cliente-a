#!/bin/sh

set -eux

ansible-galaxy collection install cloud.terraform
ansible-galaxy collection install community.general
ansible-galaxy collection install datadog.dd

terraform apply -auto-approve

chmod 400 cliente_a

export dns_public=$(terraform output | awk '{print $3}' | sed -e 's|["'\'']||g')

ssh -o "StrictHostKeyChecking no" -i cliente_a ubuntu@${dns_public} exit

ansible-playbook -i inventory.yml nginx.yml
ansible-playbook -i inventory.yml copyapp.yml
ansible-playbook -i inventory.yml datadog.yml

ip=$(ansible-inventory -i inventory.yml --list | jq -r '.nginx.hosts[0]')
curl "http://${ip}" --fail