#!/bin/bash

set -euo pipefail

function usage() {
    echo -e "USAGE:
    ./$(basename "${0}") <production-bundle> <testing-bundle>

Validates that both bundles are non-empty and contain only well-formed
certificates, and that every certificate in <production-bundle> is also
present in <testing-bundle>.
    "
}

function validate_bundle() {
    local bundle="${1}"
    local prefix="${2}"

    if [ ! -s "${bundle}" ]; then
        echo "::error::${bundle} is empty or missing" >&2
        exit 1
    fi

    csplit -s -z -f "${prefix}" -b '%03d.pem' "${bundle}" '/-----BEGIN CERTIFICATE-----/' '{*}'

    for cert in "${prefix}"*.pem; do
        if ! openssl x509 -in "${cert}" -noout > /dev/null 2>&1; then
            echo "::error::${bundle} contains a block that doesn't parse as a certificate (${cert})" >&2
            exit 1
        fi
    done
}

# Canonical per-cert fingerprints (DER hash), so we compare cert content
# rather than raw PEM text/line-wrapping.
function cert_fingerprints() {
    local prefix="${1}"
    for cert in "${prefix}"*.pem; do
        openssl x509 -in "${cert}" -outform DER | sha256sum | cut -d' ' -f1
    done | sort -u
}

if [ "${#}" -ne 2 ]; then
    usage
    exit 1
fi

PRODUCTION_BUNDLE="${1}"
TESTING_BUNDLE="${2}"

for bundle in "${PRODUCTION_BUNDLE}" "${TESTING_BUNDLE}"; do
    if [ ! -r "${bundle}" ]; then
        echo "::error::Couldn't find bundle at '${bundle}'" >&2
        exit 1
    fi
done

command -v openssl > /dev/null 2>&1
if [ "${?}" -ne 0 ]; then
    echo "::error::Missing openssl binary. Is it in your PATH?" >&2
    exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

validate_bundle "${PRODUCTION_BUNDLE}" "${WORKDIR}/prod-"
validate_bundle "${TESTING_BUNDLE}" "${WORKDIR}/test-"

MISSING="$(comm -23 <(cert_fingerprints "${WORKDIR}/prod-") <(cert_fingerprints "${WORKDIR}/test-"))"
if [ -n "${MISSING}" ]; then
    echo "::error::Certificate(s) in ${PRODUCTION_BUNDLE} are missing from ${TESTING_BUNDLE}" >&2
    exit 1
fi

echo "OK: '${PRODUCTION_BUNDLE}' and '${TESTING_BUNDLE}' are both valid, and every certificate in '${PRODUCTION_BUNDLE}' is present in '${TESTING_BUNDLE}'."
