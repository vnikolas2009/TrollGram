#!/usr/bin/env python3
"""Fetches the Python 3.11 iOS runtime for TrollGram plugins.

Produces:
  third-party/python/Python.xcframework   (static framework, device + simulator)
  build/python-ios/python/                (stdlib, copied into the app bundle)

Usage:
  python3 build-system/setup_python.py [--python-revision 3.11-b13]
"""

import argparse
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request

REVISION = "3.11-b13"
VERSION = "3.11"
URL_TEMPLATE = "https://github.com/beeware/Python-Apple-support/releases/download/{rev}/Python-{ver}-iOS-support.{rev_short}.tar.gz"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THIRD_PARTY = os.path.join(ROOT, "third-party", "python")
BUNDLE_OUT = os.path.join(ROOT, "build", "python-ios")


def download(url, destination):
    print("Downloading", url)
    with urllib.request.urlopen(url) as response, open(destination, "wb") as handle:
        shutil.copyfileobj(response, handle)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--python-revision", default=REVISION)
    args = parser.parse_args()

    revision = args.python_revision
    revision_short = revision.split("-")[-1]
    url = URL_TEMPLATE.format(rev=revision, ver=VERSION, rev_short=revision_short)

    os.makedirs(THIRD_PARTY, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        archive = os.path.join(tmp, "python.tar.gz")
        download(url, archive)

        extract_dir = os.path.join(tmp, "extract")
        with tarfile.open(archive, "r:gz") as tar:
            tar.extractall(extract_dir)

        framework = os.path.join(extract_dir, "Python.xcframework")
        if not os.path.isdir(framework):
            print("Python.xcframework not found in archive", file=sys.stderr)
            sys.exit(1)

        target = os.path.join(THIRD_PARTY, "Python.xcframework")
        if os.path.isdir(target):
            shutil.rmtree(target)
        # Only static archives + headers are needed; dynamic libs are skipped
        # (they also cannot be extracted on Windows hosts).
        skipped = shutil.ignore_patterns("*.dylib", "*.so", "__pycache__", "*.pyc")
        shutil.copytree(framework, target, ignore=skipped)
        print("Installed", target)

        # Bundle resources: the shared stdlib is referenced by every slice.
        stdlib_source = os.path.join(framework, "lib", "python3.11")
        if os.path.isdir(BUNDLE_OUT):
            shutil.rmtree(BUNDLE_OUT)
        os.makedirs(BUNDLE_OUT, exist_ok=True)
        shutil.copytree(stdlib_source, os.path.join(BUNDLE_OUT, "python3.11"), ignore=skipped)
        print("Prepared bundle resources in", BUNDLE_OUT)


if __name__ == "__main__":
    main()
