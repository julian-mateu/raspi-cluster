#!/bin/bash

SSH_KEY="${HOME}/.ssh/id_ed25519_rpi"

# shellcheck source=.env
source .env

if [[ ! -e "${SSH_KEY}" ]]; then
    ssh-keygen -t ed25519 -C "${EMAIL}" -f "${SSH_KEY}"
fi

docker compose up -d --build

sleep 5

docker compose exec ansible ansible-playbook copy_keys.yml
docker compose exec ansible ansible-playbook change_password.yml
docker compose exec ansible ansible-playbook change_hostnames.yml
