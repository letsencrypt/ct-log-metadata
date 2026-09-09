#!/bin/bash

source source_me.sh

function usage() {
    echo -e "USAGE:
    ./$(basename "${0}") <log-url> <destination>

EXAMPLE:
    ./$(basename "${0}") https://log.twig.ct.letsencrypt.org/2026h2/ /tmp/downloaded-roots/
    "
}

function get_roots() {
    local LOG_BASEURL="${1}"
    local DEST_DIR="${2}"
    local counter=1
    for root in $(curl -sL "${LOG_BASEURL}/ct/v1/get-roots" | jq -r '.certificates[]'); do
        echo -n "${root}" | base64 -d | openssl x509 -inform der -outform pem > ${DEST_DIR}/${counter}.crt
        counter=$((counter+1))
    done
}

function rename_roots() {
    local DEST_DIR="${1}"
    for CRT in $(ls "${DEST_DIR}" | grep -E '^[0-9]*.crt'); do
        O=$(certigo dump -f PEM --json "${DEST_DIR}/${CRT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
        CN=$(certigo dump -f PEM --json "${DEST_DIR}/${CRT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')

        # We specifically chose not to use the SHA256 of the fingerprint, or a
        # serial, or any other numeric identifier because we want to keep these
        # human readable. The literal null comes from jq.
        if [ "${O}" == "null" ]; then
            mv "${DEST_DIR}/${CRT}" "${DEST_DIR}/${CN}.crt"
        elif [ "${CN}" == "null" ]; then
            mv "${DEST_DIR}/${CRT}" "${DEST_DIR}/${O}.crt"
        elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
            prettyRed "'${DEST_DIR}/${CRT}' is borked"
        else
            mv "${DEST_DIR}/${CRT}" "${DEST_DIR}/${O} - ${CN}.crt"
        fi
    done
}

if [ "${#}" -lt 2 ]; then
    usage
    exit 1
fi

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

LOG_URL="${1}"
DEST="${2}"
shift

if [ -z "${LOG_URL}" ]; then
    prettyRed "Must specify a log URL to pull roots from"
    exit 1
fi

if [ -z "${DEST}" ]; then
    prettyRed "Must specify a destination for the root(s)"
    exit 1
fi

if [ ! -d "${DEST}" ]; then
    prettyRed "'${DEST}' is not a directory"
    exit 1
fi

get_roots "${LOG_URL}" "${DEST}"
rename_roots "${DEST}"
