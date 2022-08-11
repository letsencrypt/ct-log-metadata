#!/bin/bash

source source_me.sh

function usage() {
    echo -e "EXAMPLE:
    ./$(basename "${0}") [ct-log] [root-ca-cert]

    ./$(basename "${0}") sapling example.pem
    "
}

function add_root() {
    local LOG="${1}"
    local ROOT="${2}"

    openssl x509 -in "${ROOT}" -inform PEM -noout
    if [ "${?}" -ne 0 ]; then
        prettyRed "${ROOT} is not a PEM file, make this function better"
        exit 1
    fi

    cp "${ROOT}" "${LOG}/"
}

if [ "${#}" -ne 2 ]; then
    usage
    exit 1
fi

LOG="${1}"
ROOT="${2}"

if [ -n "${LOG}" ]; then
    prettyRed "Must specify log"
    exit 1
fi

if [ -n "${ROOT}" ]; then
    prettyRed "Must specify root cert file"
    exit 1
fi

add_root "${LOG}" "${ROOT}"

pretty "You should run ./assemble-accepted-roots.sh now"
