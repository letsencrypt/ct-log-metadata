#!/usr/bin/python3

import argparse
import binascii
import json
import logging
import pem
import subprocess
import tempfile

from ct_meta_py import CA

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
        self._rootPEMsToCAs = dict()

    def load(self, file):
        file_contents = file.read_bytes()

        try:
            for pemData in json.loads(file_contents)["certificates"]:
                ca = CA(pemData, file)
                self._rootPEMsToCAs[ca.pem] = ca

        except json.decoder.JSONDecodeError:
            for pemData in pem.parse(file_contents):
                ca = CA(str(pemData), file)
                self._rootPEMsToCAs[ca.pem] = ca

    def difference(self, them):
        our_keys = set(self._rootPEMsToCAs.keys())
        their_keys = set(them._rootPEMsToCAs.keys())

        diffs = []
        for key in our_keys.difference(their_keys):
            diffs.append(self._rootPEMsToCAs[key])
        return diffs


def certPretty(log, ca):
    try:
        result = subprocess.run(
            ["certigo", "dump", "-f", "DER", "--json"],
            capture_output=True,
            input=ca.der,
        )
        if result.stderr:
            raise Exception(result.stderr.rstrip())

        certData = json.loads(result.stdout.decode("UTF-8"))["certificates"][0]

        try:
            cn = certData["subject"]["common_name"]
        except Exception:
            cn = ""

        try:
            o = certData["subject"]["organization"][0]
        except Exception:
            o = ""

        try:
            skid = certData["subject"]["key_id"]
        except Exception:
            skid = ""

        try:
            serial = certData["serial"]
        except Exception:
            serial = ""

        print("- CN=%s, O=%s, SKID=%s, Serial=%s" % (cn, o, skid, serial))
    except binascii.Error as e:
        log.warning("Couldn't pretty print %s because %s", ca.pem, e)


def differences(left, leftName, right, rightName, outdir=None):
    diff = left.difference(right)
    if diff:
        print("%d PEMs in %s but not in %s" % (len(diff), leftName, rightName))
        log = logging.getLogger(leftName)
        for ca in diff:
            certPretty(log, ca)

            if outdir:
                with tempfile.NamedTemporaryFile(
                    mode="wb", dir=outdir, suffix=".der", delete=False
                ) as of:
                    of.write(ca.der)
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
