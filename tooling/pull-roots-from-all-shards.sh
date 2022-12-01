#!/bin/bash

source source_me.sh

function get_roots() {
    local LOG="${1}"
    local SHARD="${2}"
    local TEMPDIR="${3}"
    local counter=1
    for root in $(curl -sL https://${LOG}.ct.letsencrypt.org/${SHARD}/ct/v1/get-roots | jq -r '.certificates[]'); do
        echo -n "${root}" | base64 -d | openssl x509 -inform der -outform pem > ${TEMPDIR}/${counter}.crt
        counter=$((counter+1))
    done
}

function copy() {
    SRC="${1}"
    DST="${2}"

    if [ -r "${DST}" ] ; then
        echo "Duplicate! ${SRC} cannot copy to ${DST} as it already exists."
    else
        cp "${SRC}" "${DST}"
    fi
}

function rename_roots() {
    local LOG="${1}"
    local SHARD="${2}"
    local TEMPDIR="${3}"

    mkdir -p "${LOG}-${SHARD}"

    for CRT in $(ls "${TEMPDIR}" | grep -E '^[0-9]*.crt'); do
        ROOT="${TEMPDIR}/${CRT}"

        O=$(certigo dump -f PEM --json "${ROOT}" | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
        CN=$(certigo dump -f PEM --json "${ROOT}" | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
        SKID=$(certigo dump -f PEM --json "${ROOT}" | jq -r '.certificates[].subject.key_id' | tr -d '\n' | sed -e 's|:||g' | tr '[:upper:]' '[:lower:]')

        # We specifically chose not to use the SHA256 of the fingerprint, or a serial, or any other numeric identifier
        # because we want to keep these human readable.
        # The literal null comes from jq

        if [ "${SKID}" == "null" ]; then
            SKID="0"
        fi

        if [ "${O}" == "null" ]; then
            copy "${ROOT}" "${LOG}-${SHARD}/${CN} - ${SKID}.crt"
        elif [ "${CN}" == "null" ]; then
            copy "${ROOT}" "${LOG}-${SHARD}/${O} - ${SKID}.crt"
        elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
            copy "${ROOT}" "${LOG}-${SHARD}/${SKID}.crt"
        else
            copy "${ROOT}" "${LOG}-${SHARD}/${O} - ${CN} - ${SKID}.crt"
        fi
    done
}

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    prettyRed  "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

for SHARD in 2022h2 2023h1; do
    TEMPDIR="$(mktemp -d -p sapling --suffix=-${SHARD})"
    pretty "Backgrounding data gather from sapling ${SHARD}"
    { get_roots "sapling" "${SHARD}" "${TEMPDIR}" && rename_roots "sapling" "${SHARD}" "${TEMPDIR}"; } &
done

for SHARD in 2022 2023 2024h1 2024h2; do
    TEMPDIR="$(mktemp -d -p oak --suffix=-${SHARD})"
    pretty "Backgrounding data gather from oak ${SHARD}"
    { get_roots "oak" "${SHARD}" "${TEMPDIR}" && rename_roots "oak" "${SHARD}" "${TEMPDIR}"; } &
done

pretty "Waiting for all processing to finish"
wait
