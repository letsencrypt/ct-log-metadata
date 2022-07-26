#!/bin/bash

source source_me.sh

function usage() {
    echo -e "EXAMPLE:
    ./$(basename "${0}") [path-to-shard-folder-1] [path-to-shard-folder-2]

    ./$(basename "${0}") oak/2024h1 oak/2024h2
    ./$(basename "${0}") oak/2023 sapling/202431
    "
}

function diff_roots_folders() {
    local SHARD_1="${1}"
    local SHARD_2="${2}"

    comm --check-order -3 <(ls "${SHARD_1}") <(ls "${SHARD_2}") |
    sed "{
    /^\t\t/ {s||BOTH>&|; b}
    /^\t/ {s|| ${SHARD_2}>&|; b}
    s|^| ${SHARD_1}>|
    }"
}

if [ "${#}" -ne 2 ]; then
    usage
    exit 1
fi

if [ ! -d "${1}" ] ; then
    prettyRed "Path ${1} does not exist"
    exit 1
fi

if [ ! -d "${2}" ] ; then
    prettyRed "Path ${2} does not exist"
    exit 1
fi

pretty "Showing differences between ${1} and ${2}"
diff_roots_folders "${1}" "${2}"
