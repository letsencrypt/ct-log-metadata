#!/usr/bin/python3

import argparse
import csv
import logging
import requests

from ct_meta_py import CA

from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
ADDITIONAL_ROOTS_DIR = SCRIPT_DIR / "additional_roots"
ACCEPTED_ROOTS_DIR = SCRIPT_DIR / "accepted_roots"
MOZ_CSV = (
    "https://ccadb-public.secure.force.com/mozilla/"
    + "IncludedRootsDistrustTLSSSLPEMCSV?TrustBitsInclude=Websites"
)

PARSER = argparse.ArgumentParser(description="Update the accepted roots")
PARSER.add_argument(
    "--log-level",
    default=logging.INFO,
    type=lambda x: getattr(logging, x.upper()),
    help="Configure the logging level, defaults to INFO.",
)
PARSER.add_argument(
    "--log",
    required=True,
    help="Log name",
)
PARSER.add_argument(
    "--shard",
    required=True,
    help="Shard name",
)


class RootsExporter:
    def __init__(self, log, shard):
        self._logger = logging.getLogger(f"{log}-{shard}")
        self._rootPEMsToCAs = {}
        self._outPath = None

    def setOutput(self, path):
        self._outPath = path

    def loadAdditionalRootsFrom(self, path):
        for pemFile in path.glob("*.crt"):
            self._logger.debug("Loading root %s/%s", path, pemFile)
            ca = CA(pemFile.read_text(), pemFile)

            if ca.pem in self._rootPEMsToCAs:
                self._logger.warning(
                    "Duplicate found in additional roots, so either [%s] or [%s] should go away.",
                    self._rootPEMsToCAs[ca.pem].origin,
                    pemFile,
                )
            self._rootPEMsToCAs[ca.pem] = ca

    def loadRootsFromCCADB(self, ccadb):
        rootsReader = csv.DictReader(ccadb)
        for row in rootsReader:
            ca = CA(row["PEM"].strip("'"), "CCADB")

            if ca.pem in self._rootPEMsToCAs:
                self._logger.warning(
                    "Duplicate found from CCADB, so [%s] should go away. Unlinking it."
                    + "If you disagree, this is a git repo, fix it.",
                    self._rootPEMsToCAs[ca.pem].origin,
                )
                print(self._rootPEMsToCAs[ca.pem].pem)
                print()
                print(ca.pem)
                # self._rootPEMsToCAs[ca.pem].origin.unlink()
            self._rootPEMsToCAs[ca.pem] = ca

    def write(self):
        self._logger.debug(
            "Writing out %d PEMs to [%s]", len(self._rootPEMsToCAs), self._outPath
        )
        with self._outPath.open("w") as outFp:
            for ca in sorted(self._rootPEMsToCAs.values(), key=lambda x: x.pem):
                outFp.write(ca.pem)


def main():
    args = PARSER.parse_args()
    logging.basicConfig(level=args.log_level)

    if not ADDITIONAL_ROOTS_DIR.is_dir():
        logging.error(
            "The additional roots dir does not appear to exist: %s",
            ADDITIONAL_ROOTS_DIR,
        )
        return

    if not ACCEPTED_ROOTS_DIR.is_dir():
        logging.error(
            "The accepted roots dir does not appear to exist: %s", ACCEPTED_ROOTS_DIR
        )
        return

    ccadb_file = ACCEPTED_ROOTS_DIR / "ccadb.csv"

    with requests.get(MOZ_CSV, stream=True) as r:
        with open(ccadb_file, "wb") as fd:
            for chunk in r.iter_content(chunk_size=128):
                fd.write(chunk)

    rExporter = RootsExporter(args.log, args.shard)
    rExporter.setOutput(
        ACCEPTED_ROOTS_DIR / f"{args.log}-{args.shard}-ctfe-accepted-roots.pem"
    )
    rExporter.loadAdditionalRootsFrom(ADDITIONAL_ROOTS_DIR / "common")
    rExporter.loadAdditionalRootsFrom(ADDITIONAL_ROOTS_DIR / args.log)

    with ccadb_file.open() as csv_fp:
        rExporter.loadRootsFromCCADB(csv_fp)

    rExporter.write()


if __name__ == "__main__":
    main()
