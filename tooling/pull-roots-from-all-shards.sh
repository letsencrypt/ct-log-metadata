#!/bin/bash

source source_me.sh

function get_roots() {
    local LOG="${1}"
    local SHARD="${2}"
    local counter=1
    mkdir -p "${LOG}/${SHARD}"
    for root in $(curl -sL https://${LOG}.ct.letsencrypt.org/${SHARD}/ct/v1/get-roots | jq -r '.certificates[]'); do
        echo -n "${root}" | base64 -d | openssl x509 -inform der -outform pem > ${LOG}/${SHARD}/${counter}.crt
        counter=$((counter+1))
    done
}

function rename_roots() {
    local LOG="${1}"
    local SHARD="${2}"
    for CRT in $(ls "${LOG}/${SHARD}" | grep -E '^[0-9]*.crt'); do
        O=$(certigo dump -f PEM --json "${LOG}/${SHARD}/${CRT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
        CN=$(certigo dump -f PEM --json "${LOG}/${SHARD}/${CRT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')

        # We specifically chose not to use the SHA256 of the fingerprint, or a serial, or any other numeric identifier
        # because we want to keep these human readable.
        # The literal null comes from jq
        if [ "${O}" == "null" ]; then
            mv "${LOG}/${SHARD}/${CRT}" "${LOG}/${SHARD}/${CN}.crt"
        elif [ "${CN}" == "null" ]; then
            mv "${LOG}/${SHARD}/${CRT}" "${LOG}/${SHARD}/${O}.crt"
        elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
            prettyRed "${LOG}/${SHARD}/${CRT} is borked"
        else
            mv "${LOG}/${SHARD}/${CRT}" "${LOG}/${SHARD}/${O} - ${CN}.crt"
        fi
    done
}

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

for SHARD in 2022h2 2023h1; do
    pretty "Backgrounding data gather from sapling ${SHARD}"
    { get_roots "sapling" "${SHARD}" && rename_roots "sapling" "${SHARD}"; } &
done

for SHARD in 2022 2023 2024h1 2024h2; do
    pretty "Backgrounding data gather from oak ${SHARD}"
    { get_roots "oak" "${SHARD}" && rename_roots "oak" "${SHARD}"; } &
done

pretty "Waiting for all processing to finish"
wait
