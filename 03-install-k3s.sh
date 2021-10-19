#!/bin/bash
set -e -o pipefail -u

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

function setup() {
    exec_in_docker \
        python templates/render_template.py \
        templates/k3s_hosts_template.ini.j2 "${RASPI_MASTER_IP}" "${RASPI_WORKER_IPS[@]}" \
        >k3s-ansible/inventory/sample/hosts.ini

    sed -e 's/ansible_user: debian/ansible_user: pi/g' \
        k3s-ansible/inventory/sample/group_vars/all.yml \
        >k3s-ansible/inventory/sample/group_vars/all.yml.tmp &&
        mv k3s-ansible/inventory/sample/group_vars/all.yml.tmp \
            k3s-ansible/inventory/sample/group_vars/all.yml

    sed -e 's/k3s_version: v1\.17\.5\+k3s1/k3s_version: v1\.22\.2\+k3s2/g' \
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
}

function remove() {
    exec_in_docker_workdir \
        /app/k3s-ansible \
        ansible-playbook reset.yml \
        -i inventory/sample/hosts.ini
}

if [[ ! -e k3s-ansible ]]; then
    git clone https://github.com/k3s-io/k3s-ansible.git k3s-ansible
fi

if ! docker ps -a | grep -q 'raspi-cluster_ansible_1'; then
    docker_compose_up
fi

# Uncomment this line and comment the `setup` to uninstall k3s
# remove
setup

# sleep 10
reboot_and_wait

watch --difference=permanent 'echo "Waiting until kubectl nodes are up (press ^C to continue)" && kubectl get nodes'
