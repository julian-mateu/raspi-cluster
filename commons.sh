#!/bin/bash

function reboot_and_wait() {
    exec_in_docker ansible raspi_cluster -b -a "reboot" || true
    wait_for_cluster
}

function wait_for_cluster() {
    tput smcup
    until clear && echo "Just rebooted the cluster, waiting until it comes up back again (press ^C to continue)" && exec_in_docker ansible raspi_cluster -m ping
    do
        sleep 5
    done
    tput rmcup
}

function docker_compose_up_with_file() {
    docker compose --env-file /dev/null --file "${1}" up -d --build
    sleep 5
}

function docker_compose_up() {
    docker compose --env-file /dev/null up -d --build
    sleep 5
}

function exec_in_docker_with_file() {
    docker compose --env-file /dev/null --file "${1}" exec "${@:2}"
}

function exec_in_docker() {
    docker compose --env-file /dev/null exec ansible "${@}"
}

function exec_in_docker_workdir() {
    docker compose --env-file /dev/null exec --workdir "${1}" ansible "${@:2}"
}
