#!/bin/bash
set -e -o pipefail -u

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

if ! docker ps -a | grep -q 'raspi-cluster-ansible-1'; then
    docker_compose_up
fi

perl -i -p0e \
    "s/pihole.*\.nip\.io/pihole\.${INGRESS_IP}\.nip\.io/g" \
    ./pihole/pihole.values.yml

perl -i -p0e \
    "s/loadBalancerIP: .*/..*/..*/..*/loadBalancerIP: ${INGRESS_IP}/g" \
    ./pihole/pihole.values.yml

exec_in_docker ansible-playbook a09_setup_pihole.yml

sleep 60

helm install pihole mojo2600/pihole \
  --namespace pihole \
  --values ./pihole/pihole.values.yml

kubectl get pods -n pihole -o wide -w
