# Overview

We decided to store the issuer files with human readable names, rather than the serial or fingerprint. This decision is completely arbitrary.

Certificates for the logs come from the `roots/` directory at the root of this repo:

1. The `roots/common/` directory, which is always included in a bundle.

2. The `roots/testing/` directory, which is only included when building a testing bundle.

To use this tooling, you will need [certigo](https://github.com/square/certigo).

# Usage

Build a production bundle (common roots only) from the root certificates checked into this repo. This will not apply the change to a running shard. That work is done in another repository and requires SRE change control.
```
./build_bundle.py
```

Build a testing bundle (common + testing roots) instead:
```
./build_bundle.py --testing
```

Both write to `./bundle.pem` by default; use `--output`/`-o` to write elsewhere.

Add a root certificate to a `roots` subdirectory.
```
./add-root-to-log.sh roots/common example_new_ca.pem
```

To get all root certificates currently applied to a log shard:

```
./pull-roots-from-all-shards.sh
```

## Notes

After adding a root, run `./build_bundle.py` to rebuild the bundle.
