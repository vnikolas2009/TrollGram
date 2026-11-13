"""Bumps ExpirationDate of the bundled fake provisioning profiles in place.

The checked-in profiles under build-system/fake-codesigning/profiles expired on
2026-10-30, and both rules_apple's plisttool and Make.py's
DirectoryCodesigningSource reject expired profiles, which broke every CI build.

The replacement is length-preserving (only the year digits change), so the CMS
envelope stays structurally valid and `openssl smime -verify -noverify` keeps
parsing it.

Usage:
    python3 build-system/fix_fake_profiles.py [--year 2036]
"""

import argparse
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROFILES = os.path.join(ROOT, "build-system", "fake-codesigning", "profiles")


def patch(path, year):
    with open(path, "rb") as handle:
        data = handle.read()
    key = b"<key>ExpirationDate</key>"
    index = data.find(key)
    if index == -1:
        return None
    start = data.find(b"<date>", index)
    end = data.find(b"</date>", start)
    if start == -1 or end == -1:
        return None
    value = data[start + len(b"<date>"):end]
    if len(value) < 4:
        return None
    new_value = str(year).encode("ascii") + value[4:]
    if new_value == value:
        return None
    assert len(new_value) == len(value), "replacement must keep the same size"
    data = data[:start + len(b"<date>")] + new_value + data[end:]
    with open(path, "wb") as handle:
        handle.write(data)
    return value.decode("ascii", "replace"), new_value.decode("ascii", "replace")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", type=int, default=2036)
    args = parser.parse_args()

    changed = 0
    for path in sorted(glob.glob(os.path.join(PROFILES, "*.mobileprovision"))):
        result = patch(path, args.year)
        name = os.path.basename(path)
        if result is None:
            print("%-40s unchanged" % name)
        else:
            print("%-40s %s -> %s" % (name, result[0], result[1]))
            changed += 1
    print("Patched %d profile(s) in %s" % (changed, PROFILES))
    if changed == 0:
        print("Nothing to do", file=sys.stderr)


if __name__ == "__main__":
    main()
