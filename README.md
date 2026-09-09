# Let's Encrypt Certificate Transparency Logs

This repository contains all root CAs from whom [Let's Encrypt's Certificate Transparency Logs](https://letsencrypt.org/docs/ct-logs/) accept leaf certificates.

Certificates are stored in the `roots/` directory:

1. The `roots/common/` directory, which is included in bundles for testing and production logs.

2. The `roots/testing/` directory, which is only included in the bundle for testing logs.

# Submitting a CA root for inclusion

First, you'll need to install [certigo](https://github.com/square/certigo).

Next, fork this GitHub repository and add your root certificate(s) to the store:

```
./add-roots.sh roots/testing example_new_ca.pem
```

Create a [new pull
request](https://github.com/letsencrypt/ct-log-metadata/compare?template=root_inclusion.md)
and fill out the provided template. All communication will be performed via
responses to your PR.

Upon approval, Let's Encrypt staff will merge your change, which publishes new
accepted-roots bundles (see below). Rolling a new bundle out to our running CT
logs is a separate, SRE-gated process and isn't automatic.

# Other tooling

To dump all root certificates a log currently accepts:

```
mkdir /tmp/downloaded-roots/
./pull-roots.sh https://log.twig.ct.letsencrypt.org/2026h2/ /tmp/downloaded-roots/
```

The `build_bundle.py` script is used in CI by the release build process. You
shouldn't need to use it directly for submitting a new root.

# Accepted-roots bundles

Every merge to `main` that touches `roots/` or `build_bundle.py` triggers a CI
job that builds two bundles and publishes them as
[GitHub Release](https://github.com/letsencrypt/ct-log-metadata/releases)
assets, alongside a `SHA256SUMS` file:

* `bundle-production.pem` — roots trusted by our production logs (`roots/common/` only).
* `bundle-testing.pem` — roots trusted by our testing logs (`roots/common/` + `roots/testing/`).

The current bundles are always available at stable URLs, with no
authentication required:

```
https://github.com/letsencrypt/ct-log-metadata/releases/latest/download/bundle-production.pem
https://github.com/letsencrypt/ct-log-metadata/releases/latest/download/bundle-testing.pem
https://github.com/letsencrypt/ct-log-metadata/releases/latest/download/SHA256SUMS
```

Every release is also kept permanently under its own tag
(`bundles-YYYY.MM.DD-<commit>`), so a specific historical bundle can be
retrieved by substituting that tag for `latest` in the URLs above.

**Fetching a bundle and verifying it against `SHA256SUMS`?** Resolve
`/releases/latest` to a concrete tag once, then download both files from that
same tag — don't fetch them as two separate `latest` requests, since a new
release could land in between and produce a spurious checksum mismatch.
