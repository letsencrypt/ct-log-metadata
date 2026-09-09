### Checklist

_NOTE: Let's Encrypt no longer accepts root inclusion requests for our
production CT logs. Instead, we keep our logs up-to-date with the CCADB. Please
only create pull requests for __testing__ roots._

- [ ] The roots added in this change are __testing-only__.
- [ ] I added my root certificate(s) to this PR using `./add-roots.sh roots/testing <pem-file>`

CI will automatically build and validate the accepted-roots bundles from your
change. A maintainer will review once checks pass.