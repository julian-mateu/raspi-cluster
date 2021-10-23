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
    "s/suffixDomain: '.*',/suffixDomain: '${INGRESS_IP}.np.io',/g" \
    cluster-monitoring/vars.jsonnet
perl -i -p0e \
    "s/'armExporter',\n      enabled: false,/'armExporter',\n      enabled: true,/g" \
    cluster-monitoring/vars.jsonnet
perl -i -p0e \
    "s/'traefikExporter',\n      enabled: false,/'traefikExporter',\n      enabled: true,/g" \
    cluster-monitoring/vars.jsonnet


INGRESS_IP=${INGRESS_IP} docker_compose_up_with_file docker-compose-monitor.yml

# TODO: Yaml files built from the image seem to have problems with the ingress version, so for now it's using
#  the files cloned from the repo, the actual result of the build in docker is being ignored!
# INGRESS_IP=$INGRESS_IP exec_in_docker_with_file docker-compose-monitor.yml monitoring bash -c "cp -r /build/* ./"

# TODO: The previous step copies the build files to the workdir of the container, which currently is inside the 
#  cluster monitoring folder. This causes the docker image to be rebuilt and not re-use the cache. One option is
#  using a different location for the generated manifests.

# shellcheck disable=SC2097,SC2098
INGRESS_IP=${INGRESS_IP} exec_in_docker_with_file docker-compose-monitor.yml monitoring make change_suffix suffix="${INGRESS_IP}.nip.io"

if ! docker ps -a | grep -q 'raspi-cluster-ansible-1'; then
    docker_compose_up
fi

# Applying the manifests using the local `kubectl` on my laptop does not work, so I used ansible to apply these from
#  the master node. It's likely to be a missing configuration from k3s.
exec_in_docker ansible-playbook a05_install_monitoring.yml
