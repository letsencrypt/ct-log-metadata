#!/bin/bash

source source_me.sh

function accepted_roots() {
    local LOG="${1}"
    local SHARD="${2}"

    if [ -z "${LOG}" ]; then
        prettyRed "Provide a log"
        exit 1
    fi

    if [ ! -d "${LOG}" ]; then
        prettyRed "Folder ${LOG} does not exist"
        exit 1
    fi

    pretty "Processing ${LOG}-${SHARD} in the background..."

    rm "accepted_roots/${LOG}-${SHARD}-ctfe-accepted-roots.pem"
    find "${LOG}/" -maxdepth 1 -type f -name '*.crt' | sort | while read file; do
      openssl x509 -inform pem -in "${file}" >> "accepted_roots/${LOG}-${SHARD}-ctfe-accepted-roots.pem"
    done
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

wait

pretty "Done"
