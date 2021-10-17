#!/bin/bash
set -e -o pipefail -u

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

if [[ ! -e cluster-monitoring ]]; then
    git clone https://github.com/carlosedp/cluster-monitoring.git cluster-monitoring
fi

perl -i -p0e \
    "s/k3s: {\n    enabled: false,\n    master_ip:.*\n  },/k3s: {\n    enabled: true,\n    master_ip: \['${RASPI_MASTER_IP}'\]\n  },/g" \
    cluster-monitoring/vars.jsonnet
perl -i -p0e \
    "s/suffixDomain: '.*',/suffixDomain: '${RASPI_WORKER_IPS[0]}.np.io',/g" \
    cluster-monitoring/vars.jsonnet
perl -i -p0e \
    "s/'armExporter',\n      enabled: false,/'armExporter',\n      enabled: true,/g" \
    cluster-monitoring/vars.jsonnet
perl -i -p0e \
    "s/'traefikExporter',\n      enabled: false,/'traefikExporter',\n      enabled: true,/g" \
    cluster-monitoring/vars.jsonnet

INGRESS_IP=${RASPI_WORKER_IPS[0]}
INGRESS_IP=$INGRESS_IP docker_compose_up_with_file docker-compose-monitor.yml

# TODO: Yaml files built from the image seem to have problems with the ingress version
# INGRESS_IP=$INGRESS_IP exec_in_docker_with_file docker-compose-monitor.yml monitoring bash -c "cp -r /build/* ./"

# TODO: use a different location for the generated manifests, to avoid docker re-builds if the source files change
INGRESS_IP=$INGRESS_IP exec_in_docker_with_file docker-compose-monitor.yml monitoring make change_suffix suffix="$INGRESS_IP.nip.io"

if ! docker ps -a | grep -q 'raspi-cluster_ansible_1'; then
    docker_compose_up
fi

# using kubectl from the cluster to use k3s config
exec_in_docker ansible-playbook a05_install_monitoring.yml

# kubectl apply -f cluster-monitoring/manifests/setup/
# kubectl apply -f cluster-monitoring/manifests/