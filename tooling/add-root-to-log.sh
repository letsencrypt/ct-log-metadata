#!/bin/bash

source source_me.sh

function usage() {
    echo -e "EXAMPLE:
    ./$(basename "${0}") [ct-log-directory] [root-ca-cert] {root-ca-cert}

    ./$(basename "${0}") additional_roots/common example.pem /tmp/roots/*
    "
}

function add_root() {
    local LOG="${1}"
    local ROOT="${2}"

    O=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
    CN=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
    SKID=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.key_id' | tr -d '\n' | sed -e 's|:||g' | tr '[:upper:]' '[:lower:]')
    SERIAL=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].serial')
    PEM=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].pem')

    # The literal null comes from jq
    if [ -z "${PEM}" ]; then
        prettyRed "${ROOT} is borked"
    elif [ "${O}" == "null" ]; then
        echo "${PEM}" > "${LOG}/${CN} - ${SERIAL} - ${SKID}.crt"
    elif [ "${CN}" == "null" ]; then
        echo "${PEM}" > "${LOG}/${O} - ${SERIAL} - ${SKID}.crt"
    elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
        echo "${PEM}" > "${LOG}/${SERIAL} - ${SKID}.crt"
    else
        echo "${PEM}" > "${LOG}/${O} - ${CN} - ${SERIAL} - ${SKID}.crt"
    fi
}

if [ "${#}" -lt 2 ]; then
    usage
    exit 1
fi

LOG="${1}"
shift

if [ -z "${LOG}" ]; then
    prettyRed "Must specify log"
    exit 1
fi

if [ ! -d "${LOG}" ]; then
    prettyRed "${LOG} is not a directory"
    exit 1
fi

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

for ROOT in "${@}"; do
    if [ ! -r "${ROOT}" ]; then
        prettyRed "Coudldn't find root file at ${ROOT}"
        exit 1
    fi

    add_root "${LOG}" "${ROOT}"
done

pretty "You should run ./update_accepted_roots.py now"
