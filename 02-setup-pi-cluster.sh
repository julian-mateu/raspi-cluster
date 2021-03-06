#!/bin/bash

SSH_KEY="${HOME}/.ssh/id_ed25519_rpi"

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

if [[ ! -e "${SSH_KEY}" ]]; then
    echo "${SSH_KEY} does not exist, creating. Note that a password will cause problems with Ansible!"
    echo
    ssh-keygen -t ed25519 -C "${EMAIL}" -f "${SSH_KEY}"
fi

docker_compose_up

wait_for_cluster

exec_in_docker \
    python templates/render_template.py \
    templates/inventory_template.yml.j2 "${RASPI_MASTER_IP}" "${RASPI_WORKER_IPS[@]}" \
    >inventory.yml

exec_in_docker ansible-playbook a01_copy_keys.yml
exec_in_docker ansible-playbook a02_change_password.yml
exec_in_docker ansible-playbook a03_change_hostnames.yml

reboot_and_wait
