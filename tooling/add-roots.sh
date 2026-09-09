#!/bin/bash

source source_me.sh

function usage() {
    echo -e "USAGE:
    ./$(basename "${0}") <destination> [root-ca-cert] [root-ca-cert] ...

EXAMPLE:
    ./$(basename "${0}") roots/common example.pem /tmp/roots/*
    "
}

function add_root() {
    local DEST="${1}"
    local ROOT="${2}"

    O=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
    CN=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
    SKID=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].subject.key_id' | tr -d '\n' | sed -e 's|:||g' | tr '[:upper:]' '[:lower:]')
    SERIAL=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].serial')
    PEM=$(certigo dump --json "${ROOT}" | jq -r '.certificates[].pem')

    # The literal null comes from jq
    if [ -z "${PEM}" ]; then
        prettyRed "'${ROOT}' is borked"
    elif [ "${O}" == "null" ]; then
        echo "${PEM}" > "${DEST}/${CN} - ${SERIAL} - ${SKID}.crt"
    elif [ "${CN}" == "null" ]; then
        echo "${PEM}" > "${DEST}/${O} - ${SERIAL} - ${SKID}.crt"
    elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
        echo "${PEM}" > "${DEST}/${SERIAL} - ${SKID}.crt"
    else
        echo "${PEM}" > "${DEST}/${O} - ${CN} - ${SERIAL} - ${SKID}.crt"
    fi
}

if [ "${#}" -lt 2 ]; then
    usage
    exit 1
fi

DEST="${1}"
shift

if [ -z "${DEST}" ]; then
    prettyRed "Must specify a destination for the root(s)"
    exit 1
fi

if [ ! -d "${DEST}" ]; then
    prettyRed "'${DEST}' is not a directory"
    exit 1
fi

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

for ROOT in "${@}"; do
    if [ ! -r "${ROOT}" ]; then
        prettyRed "Couldn't find root file at '${ROOT}'"
        exit 1
    fi

    add_root "${DEST}" "${ROOT}"
done
