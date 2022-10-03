# Let's Encrypt Certificate Transparency Logs

This repository contains all Root Certificate Authorities from whom [Let's Encrypt's Certificate Transparency Logs](https://letsencrypt.org/docs/ct-logs/) accept leaf certificates.

Let's Encrypt operates two publicly-accessible [Certificate Transparency](https://www.certificate-transparency.org/what-is-ct) logs:
* **Oak**
* **Sapling**

## Oak

Oak is a production log, containing only certificates which are trusted by the [Mozilla Root Program](https://www.mozilla.org/en-US/about/governance/policies/security-group/certs/policy/).

## Sapling

Sapling is a preproduction log, intended for certificates which are not publicly trusted, but which are issued by Certificate Authorities who either issue or are expected to issue publicly trusted certificates. In other words, Sapling is used by trusted Certificate Authorities in their testing infrastructures.

## Testflume

[Testflume no longer exists](https://groups.google.com/a/chromium.org/g/ct-policy/c/CLBlt5rSsAk) and has been replaced by the Sapling test log.

## ct-test-srv

The [Boulder](https://github.com/letsencrypt/boulder/tree/main/test/ct-test-srv) codebase contains a piece of software named `ct-test-srv` which  implements RFC6962 `add-chain` and `add-pre-chain` endpoints. This software is sufficient for development and other testing environments. It does not persist data.

# Submitting a CA root for inclusion

Create a [New Issue](https://github.com/letsencrypt/ct-log-metadata/issues/new/choose) and fill out the provided template. All communication will be performed via responses to your Github Issue. Upon approval, Let's Encrypt staff will create a Pull Request to include your certificates and update our Certificate Transparency logs.

# What roots does a log contain?

Calling the `get-roots` endpoint for a [Trillian](https://github.com/google/trillian) backed log will return a JSON structure containing each root as base64 encoded DER.

Example retrieving all the roots from a CT log and viewing certificate content:
```
counter=1
for root in $(curl -sL https://oak.ct.letsencrypt.org/2023/ct/v1/get-roots | jq -r '.certificates[]'); do
    echo -n "${root}" | base64 -d > /tmp/${counter}.crt
    counter=$((counter+1))
done

openssl x509 -inform DER -in /tmp/${counter}.crt -noout -issuer -serial
```
