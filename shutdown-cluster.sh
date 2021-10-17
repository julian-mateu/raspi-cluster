#!/bin/bash

# shellcheck source=.env
source .env

# shellcheck source=commons.sh
source commons.sh

exec_in_docker ansible all -b -a "shutdown now"
docker compose --env-file /dev/null down --volumes --remove-orphans
docker compose --env-file /dev/null --file docker-compose-monitor.yml down --volumes --remove-orphans
