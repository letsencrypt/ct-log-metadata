# Overview

We decided to store the issuer files with human readable names, rather than the serial or fingerprint. This decision is completely arbitrary.

Issuer file names are broken down as follows:

* Default to `organization - common name.crt`
* If the `organization` field is unset, the filename will be `common name.crt`
* If the `common name` field is unset, the filename will be `organization.crt`

To use the tooling in this folder, you will need [certigo](https://github.com/square/certigo).

# Usage

```
./build-accepted-roots.sh
```
