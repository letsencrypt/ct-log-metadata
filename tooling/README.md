# Overview

We decided to store the issuer files with human readable names, rather than the serial or fingerprint. This decision is completely arbitrary.

Certificates for the logs come from three places:

1. The "[PEM of Root Certificates in Mozilla’s Root Store with the Websites (TLS/SSL) Trust Bit Enabled (CSV)](https://ccadb-public.secure.force.com/mozilla/IncludedRootsDistrustTLSSSLPEMCSV?TrustBitsInclude=Websites)" export from ccadb.org
	Note: The version used is also stored in `accepted_roots` for ease of evaluation.

2. The `additional_roots/common/` directory

3. The `additional_roots/${log_name}/` directory (currently only `sapling`)

To use the tooling in this folder, you will need [certigo](https://github.com/square/certigo).

# Usage

Create a new accepted roots file from the root certificates in each respective logs folder. This will not apply the change to a running shard. That work is done in another repository and requires SRE change control.
```
./update_accepted_roots.py --log oak --shard 2022
```

Add a root certificate to an `additional_roots` subdirectory.
```
./add-root-to-log.sh additional_roots/common example_new_ca.pem
```

To get all root certificates currently applied to a log shard:

```
./pull-roots-from-all-shards.sh
```

To perform analysis on roots pulled from each shard:
```
./diff_accepted_roots.py oak/tmp.FOO-2023 oak/tmp.BAR-2024h1
```

## Notes

When adding a new shard, the scripts will need to be updated to account for the new shard.
