#!/usr/bin/python3

import argparse
import logging
import requests
import csv

from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
ADDITIONAL_ROOTS_DIR = SCRIPT_DIR / "additional_roots"
ACCEPTED_ROOTS_DIR = SCRIPT_DIR / "accepted_roots"
MOZ_CSV = "https://ccadb-public.secure.force.com/mozilla/IncludedRootsDistrustTLSSSLPEMCSV?TrustBitsInclude=Websites"

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
        self._log = log
        self._shard = shard
        self._rootPEMs = set()
        self._outPath = None

    def setOutput(self, path):
        self._outPath = path

    def loadAdditionalRootsFrom(self, path):
        for pemFile in path.glob("*.pem"):
            data = pemFile.read_text()
            if data in self._rootPEMs:
                logging.warning("Duplicate found within %s: %s", ADDITIONAL_ROOTS_DIR, pemFile)
            self._rootPEMs.add(data)

    def loadRootsFromCCADB(self, ccadb):
        rootsReader = csv.DictReader(ccadb)
        for row in rootsReader:
            data = row["PEM"].strip('\'')
            if data in self._rootPEMs:
                logging.warning("Duplicate found from CCADB, so something in %s should go away: %s", ADDITIONAL_ROOTS_DIR, data)
            self._rootPEMs.add(data)

    def write(self):
        with self._outPath.open("w") as outFp:
            for pem in sorted(list(self._rootPEMs)):
                outFp.write(pem)
                outFp.write('\n')

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
        with open(ccadb_file, 'wb') as fd:
            for chunk in r.iter_content(chunk_size=128):
                fd.write(chunk)

    rExporter = RootsExporter(args.log, args.shard)
    rExporter.setOutput(ACCEPTED_ROOTS_DIR / f"{args.log}-{args.shard}-ctfe-accepted-roots.pem")
    rExporter.loadAdditionalRootsFrom(ADDITIONAL_ROOTS_DIR / "common")
    rExporter.loadAdditionalRootsFrom(ADDITIONAL_ROOTS_DIR / args.log)

    with ccadb_file.open() as csv_fp:
        rExporter.loadRootsFromCCADB(csv_fp)

    rExporter.write()


if __name__ == "__main__":
    main()
