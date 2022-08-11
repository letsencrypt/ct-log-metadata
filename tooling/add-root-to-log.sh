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

    O=$(certigo dump -f PEM --json "${ROOT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
    CN=$(certigo dump -f PEM --json "${ROOT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')

    # We specifically chose not to use the SHA256 of the fingerprint, or a serial, or any other numeric identifier
    # because we want to keep these human readable.
    # The literal null comes from jq
    if [ "${O}" == "null" ]; then
        cp "${ROOT}" "${LOG}/${CN}.crt"
    elif [ "${CN}" == "null" ]; then
        cp "${ROOT}" "${LOG}/${O}.crt"
    elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
        prettyRed "${ROOT} is borked"
    else
        cp "${ROOT}" "${LOG}/${O} - ${CN}.crt"
    fi
}

if [ "${#}" -ne 2 ]; then
    usage
    exit 1
fi

LOG="${1}"
ROOT="${2}"

if [ -z "${LOG}" ]; then
    prettyRed "Must specify log"
    exit 1
fi

if [ -z "${ROOT}" ]; then
    prettyRed "Must specify root cert file"
    exit 1
fi

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

add_root "${LOG}" "${ROOT}"

pretty "You should run ./assemble-accepted-roots.sh now"
