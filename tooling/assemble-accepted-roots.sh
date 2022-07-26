#!/bin/bash

source source_me.sh

function accepted_roots() {
    local LOG="${1}"
    local SHARD="${2}"

    if [ -z "${LOG}" ]; then
        prettyRed "Provide a log"
        exit 1
    fi

    if [ -z "${SHARD}" ]; then
        prettyRed "Provide a shard"
        exit 1
    fi

    if [ ! -d "${LOG}" ]; then
        prettyRed "Folder ${LOG} does not exist"
        exit 1
    fi

    if [ ! -d "${LOG}/${SHARD}" ]; then
        prettyRed "Folder ${LOG}/${SHARD} does not exist"
        exit 1
    fi

    find "${LOG}/${SHARD}" -type f -exec openssl x509 -inform pem -in {} \; > "accepted_roots/${LOG}-${SHARD}-ctfe-accepted-roots.pem"
}

for SHARD in 2022h2 2023h1; do
    {
    accepted_roots "sapling" "${SHARD}"
    RETVAL="${?}"
    if [ "${RETVAL}" -ne 0 ]; then
        prettyRed "Failed generating accepted_roots/${LOG}-${SHARD}-ctfe-accepted-roots.pem"
        exit "${RETVAL}"
    fi
    } &
done

for SHARD in 2022 2023 2024h1 2024h2; do
    {
    accepted_roots "oak" "${SHARD}"
    RETVAL="${?}"
    if [ "${RETVAL}" -ne 0 ]; then
        prettyRed "Failed generating accepted_roots/${LOG}-${SHARD}-ctfe-accepted-roots.pem"
        exit "${RETVAL}"
    fi
    } &
done

pretty "Done"
