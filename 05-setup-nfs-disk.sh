#!/bin/bash
set -e -o pipefail -u

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

if ! docker ps -a | grep -q 'raspi-cluster-ansible-1'; then
    docker_compose_up
fi

exec_in_docker ansible-playbook a06_setup_disk.yml
exec_in_docker ansible-playbook a07_setup_nfs.yml
exec_in_docker ansible-playbook a08_setup_nfs_client.yml
