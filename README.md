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
request](https://github.com/letsencrypt/ct-log-metadata/compare) and fill out
the provided template. All communication will be performed via responses to your
PR.

Upon approval, Let's Encrypt staff will merge your change and our tooling will
automatically update the accepted roots bundle across our CT logs within the
next 24 hours.

# Other tooling

To dump all root certificates a log currently accepts:

```
mkdir /tmp/downloaded-roots/
./pull-roots.sh https://log.twig.ct.letsencrypt.org/2026h2/ /tmp/downloaded-roots/
```

The `build_bundle.py` script is used in CI by the release build process. You
shouldn't need to use it directly for submitting a new root.
