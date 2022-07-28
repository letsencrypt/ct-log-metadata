# Overview

We decided to store the issuer files with human readable names, rather than the serial or fingerprint. This decision is completely arbitrary.

Issuer file names are broken down as follows:

* Default to `organization - common name.crt`
* If the `organization` field is unset, the filename will be `common name.crt`
* If the `common name` field is unset, the filename will be `organization.crt`

To use the tooling in this folder, you will need [certigo](https://github.com/square/certigo).

# Usage

To get all root certificates currently applied to a log shard:

```
./pull-roots-from-all-shards.sh

```

Create a new accepted roots file, this will not apply the change to a running shard. That work is done in another repository and requires SRE change control.
```
./assemble-accepted-roots.sh
```

Add a root certificate to all accepted roots files for all shards in a log. This will not apply the change to the running shards.
```
./add-root-to-log.sh
```

Show any different roots between folders
```
./diff_accepted_roots.sh oak/2023 oak/2024h1
./diff_accepted_roots.sh sapling/2024h1 oak/2022
```

## Notes

When adding a new shard, the scripts will need to be updated to account for the new shard.
