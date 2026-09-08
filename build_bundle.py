#!/usr/bin/python3

import argparse
import logging

from ct_meta_py import CA

from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
ROOTS_DIR = SCRIPT_DIR / "roots"
COMMON_ROOTS_DIR = ROOTS_DIR / "common"
TESTING_ROOTS_DIR = ROOTS_DIR / "testing"

PARSER = argparse.ArgumentParser(description="Build a bundle of accepted roots")
PARSER.add_argument(
    "--log-level",
    default=logging.INFO,
    type=lambda x: getattr(logging, x.upper()),
    help="Configure the logging level, defaults to INFO.",
)
PARSER.add_argument(
    "--testing",
    "-t",
    action="store_true",
    help="Include the testing roots in addition to the common roots.",
)
PARSER.add_argument(
    "--output",
    "-o",
    default="bundle.pem",
    type=Path,
    help="Where to write the resulting PEM bundle. Defaults to ./bundle.pem",
)


class RootsBundler:
    def __init__(self):
        self._logger = logging.getLogger("build_bundle")
        self._rootPEMsToCAs = {}

    def loadRootsFrom(self, path):
        for pemFile in path.glob("*.crt"):
            self._logger.debug("Loading root %s/%s", path, pemFile)
            ca = CA(pemFile.read_text(), pemFile)

            if ca.pem in self._rootPEMsToCAs:
                self._logger.warning(
                    "Duplicate found, so either [%s] or [%s] should go away.",
                    self._rootPEMsToCAs[ca.pem].origin,
                    pemFile,
                )
            self._rootPEMsToCAs[ca.pem] = ca

    def write(self, outPath):
        self._logger.debug(
            "Writing out %d PEMs to [%s]", len(self._rootPEMsToCAs), outPath
        )
        with outPath.open("w") as outFp:
            for ca in sorted(self._rootPEMsToCAs.values(), key=lambda x: x.pem):
                outFp.write(ca.pem)


def main():
    args = PARSER.parse_args()
    logging.basicConfig(level=args.log_level)

    if not COMMON_ROOTS_DIR.is_dir():
        logging.error(
            "The common roots dir does not appear to exist: %s", COMMON_ROOTS_DIR
        )
        return

    bundler = RootsBundler()
    bundler.loadRootsFrom(COMMON_ROOTS_DIR)

    if args.testing:
        if not TESTING_ROOTS_DIR.is_dir():
            logging.error(
                "The testing roots dir does not appear to exist: %s",
                TESTING_ROOTS_DIR,
            )
            return
        bundler.loadRootsFrom(TESTING_ROOTS_DIR)

    bundler.write(args.output)


if __name__ == "__main__":
    main()
