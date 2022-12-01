#!/usr/bin/python3

import argparse
import base64
import binascii
import json
import logging
import pem
import subprocess
import tempfile

from pathlib import Path

PARSER = argparse.ArgumentParser(description="Update the accepted roots")
PARSER.add_argument(
    "--log-level",
    default=logging.INFO,
    type=lambda x: getattr(logging, x.upper()),
    help="Configure the logging level, defaults to INFO.",
)
PARSER.add_argument(
    "old",
    type=Path,
    help="Old root list",
)
PARSER.add_argument(
    "new",
    type=Path,
    help="New root list",
)

PARSER.add_argument(
    "--old-out",
    type=Path,
    help="Write PEMs missing from old here",
)
PARSER.add_argument(
    "--new-out",
    type=Path,
    help="Write PEMs missing from new here",
)

class RootList:
    def __init__(self):
        self._rootPEMs = set()

    def load(self, file):
        file_contents = file.read_bytes()

        try:
            for pemData in json.loads(file_contents)["certificates"]:
                self.addRoot(pemData)

        except:
            for pemData in pem.parse(file_contents):
                data = str(pemData).replace("\n", "").replace("-----BEGIN CERTIFICATE-----","").replace("-----END CERTIFICATE-----","")
                self.addRoot(data)

    def addRoot(self, pem):
        assert pem not in self._rootPEMs
        self._rootPEMs.add(pem)

    def difference(self, other):
        return self._rootPEMs.difference(other._rootPEMs)


def certPretty(log, pem):
    try:
        der = base64.b64decode(pem + "==")
        result = subprocess.run(["certigo", "dump", "-f", "DER", "--json"], capture_output=True, input=der)
        if result.stderr:
            raise Exception(result.stderr.rstrip())


        certData = json.loads(result.stdout.decode("UTF-8"))["certificates"][0]

        try:
            cn = certData["subject"]["common_name"]
        except:
            cn = ""

        try:
            o = certData["subject"]["organization"][0]
        except:
            o = ""

        try:
            skid = certData["subject"]["key_id"]
        except:
            skid = ""

        print("- CN=%s, O=%s, SKID=%s" % (cn, o, skid))
    except binascii.Error as e:
        log.warning("Couldn't pretty print %s because %s", pem, e)
    except Exception:
        log.exception("Couldn't pretty print %s", pem)

def differences(left, leftName, right, rightName, outdir=None):
    diff = left.difference(right)
    if diff:
        print("%d PEMs in %s but not in %s" % (len(diff), leftName, rightName))
        log = logging.getLogger(leftName)
        for pem in diff:
            certPretty(log, pem)

    if outdir and diff:
        for pem in diff:
            with tempfile.NamedTemporaryFile(mode="wb", dir=outdir, suffix=".der", delete=False) as of:
                of.write(base64.b64decode(pem + "=="))
                log.debug("Wrote to %s", of.name)


def main():
    args = PARSER.parse_args()
    logging.basicConfig(level=args.log_level)

    oldRl = RootList()
    oldRl.load(args.old)

    newRl = RootList()
    newRl.load(args.new)

    if args.old_out:
        args.old_out.mkdir()

    if args.new_out:
        args.new_out.mkdir()

    differences(oldRl, str(args.old), newRl, str(args.new), args.old_out)
    print()
    differences(newRl, str(args.new), oldRl, str(args.old), args.new_out)


if __name__ == "__main__":
    main()
