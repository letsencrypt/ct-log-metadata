#!/bin/bash

function prep() {
    for FOLDER in common oak sapling; do
        if [ -d "${FOLDER}" ]; then
            if [ -d "${FOLDER}.old" ]; then
                rm -rf "${FOLDER}.old"
            fi
            mv "${FOLDER}" "${FOLDER}.old"
        fi
        mkdir -p "${FOLDER}"
        touch "${FOLDER}/.gitkeep"
    done
}

function get_roots() {
    local LOG="${1}"
    local SHARD="${2}"
    local counter=1
    for root in $(curl -sL https://${LOG}.ct.letsencrypt.org/${SHARD}/ct/v1/get-roots | jq -r '.certificates[]'); do
        echo -n "${root}" | base64 -d | openssl x509 -inform der -outform pem > ${LOG}/${counter}.crt
        counter=$((counter+1))
    done
}


function rename_roots() {
    local LOG="${1}"
    for CRT in $(ls ${LOG} | grep -E '^[0-9]*.crt'); do
        O=$(certigo dump -f PEM --json ${LOG}/${CRT} | jq -r '.certificates[].subject.organization[0]' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')
        CN=$(certigo dump -f PEM --json ${LOG}/${CRT} | jq -r '.certificates[].subject.common_name' | tr -d '\n' | sed -e 's|/| |g' -e 's|\\||g')

        # We specifically chose not to use the SHA256 of the fingerprint, or a serial, or any other numeric identifier
        # because we want to keep these human readable.
        # The literal null comes from jq
        if [ "${O}" == "null" ]; then
            mv "${LOG}/${CRT}" "${LOG}/${CN}.crt"
        elif [ "${CN}" == "null" ]; then
            mv "${LOG}/${CRT}" "${LOG}/${O}.crt"
        elif [ "${CN}" == "null" ] && [ "${O}" == "null" ]; then
            echo "!!!!!!!!!!!!"
            echo "${CRT} is borked"
            echo "!!!!!!!!!!!!"
        else
            mv "${LOG}/${CRT}" "${LOG}/${O} - ${CN}.crt"
        fi
    done
}

# Split out common roots into and all that jazz
function musical_roots() {
    while read root; do
        mv oak/"${root}" common/
        rm -f sapling/"${root}"
    done < <(comm -12 <(ls oak) <(ls sapling))
}

function accepted_roots() {
    local LOG="${1}"

    if [ -z "${LOG}" ]; then
        echo "Provide a log"
        exit 1
    fi

    if [ "${LOG}" == "common" ]; then
        echo "I don't think you're doing what you think you should be doing"
        exit 1
    fi

    if [ ! -d common ]; then
        echo "Folder common does not exist, even if it's supposed to be empty"
        exit 1
    fi

    if [ ! -d "${LOG}" ]; then
        echo "Folder ${LOG} does not exist"
        exit 1
    fi

    find common "${LOG}" -type f ! -name ".gitkeep" -exec openssl x509 -inform pem -in {} \; > "${LOG}-accepted-roots.txt"
}

command -v certigo > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    echo "Missing certigo binary. Is it in your PATH?"
    exit 1
fi

prep

# TODO: Get the accepted roots from every shard to ensure that the CTFE config map contains the same values
get_roots "sapling" "2023h1"
get_roots "oak" "2023"

rename_roots "sapling"
rename_roots "oak"

# TODO: This thing, jeez.
musical_roots

accepted_roots "oak"
RETVAL="${?}"
if [ "${RETVAL}" -ne 0 ]; then
    exit "${RETVAL}"
fi

accepted_roots "sapling"
RETVAL="${?}"
if [ "${RETVAL}" -ne 0 ]; then
    exit "${RETVAL}"
fi
