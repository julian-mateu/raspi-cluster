#!/bin/bash

function docker_compose_up() {
    docker compose --env-file /dev/null up -d --build
    sleep 5
}

function exec_in_docker() {
    docker compose --env-file /dev/null exec ansible "${@}"
}

function exec_in_docker_workdir() {
    docker compose --env-file /dev/null exec --workdir "${1}" ansible "${@:2}"
}
