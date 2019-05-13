#!/bin/bash

set -euo pipefail

aws s3 cp s3://domainmarket-files/ansible/deploy.key /root/.ssh/deploy.key
chmod 400 /root/.ssh/deploy.key

aws s3 cp s3://domainmarket-files/ansible/ssh_config /root/.ssh/config
chmod 600 /root/.ssh/config

aws s3 cp s3://domainmarket-files/ansible/ansible-vault-key.txt /root/ansible-vault-key.txt

ansible-pull -d /root/playbooks -i 'localhost,' -U git@gitlab.domainmarket.com:devops/ansible.git --accept-host-key --vault-password-file=/root/ansible-vault-key.txt ${playbook}
