#!/bin/bash
set -e -o pipefail -u

if [[ ! -e k3s-ansible ]]; then
    git clone https://github.com/k3s-io/k3s-ansible.git k3s-ansible
fi

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

if ! docker ps -a | grep -q 'raspi-cluster_ansible_1'; then
    docker_compose_up
fi

exec_in_docker \
    python termplates/render_template.py \
    termplates/k3s_hosts_template.ini.j2 "${RASPI_MASTER_IP}" "${RASPI_WORKER_IPS[@]}" \
    >k3s-ansible/inventory/sample/hosts.ini

sed -e 's/ansible_user: debian/ansible_user: pi/g' \
    k3s-ansible/inventory/sample/group_vars/all.yml \
    >k3s-ansible/inventory/sample/group_vars/all.yml.tmp &&
    mv k3s-ansible/inventory/sample/group_vars/all.yml.tmp \
        k3s-ansible/inventory/sample/group_vars/all.yml

grep -qxF \
    'ansible_ssh_private_key_file: ~/.ssh/id_ed25519_rpi' \
    k3s-ansible/inventory/sample/group_vars/all.yml ||
    echo 'ansible_ssh_private_key_file: ~/.ssh/id_ed25519_rpi' \
        >>k3s-ansible/inventory/sample/group_vars/all.yml

exec_in_docker_workdir \
    /app/k3s-ansible \
    ansible-playbook site.yml \
    -i inventory/sample/hosts.ini

exec_in_docker ansible-playbook a04_copy_kubeconfig.yml
exec_in_docker cat /tmp/kube_config >"${KUBECONFIG}"
