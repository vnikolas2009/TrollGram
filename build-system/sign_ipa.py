#!/usr/bin/env python3
"""Re-sign an unsigned TrollGram .ipa with a personal Apple certificate.

Usage:

    python3 build-system/sign_ipa.py \
        --input Payload.ipa --output TrollGram-signed.ipa \
        --p12 cert.p12 --password secret --profile profile.mobileprovision

The script imports the .p12 into a throw-away keychain, rewrites the bundle
identifier when the provisioning profile does not cover the original one, drops
nested code that the profile cannot cover (watchOS app, app extensions) and
signs everything inside-out with the entitlements taken from the profile.

Exit code 0 means the produced IPA passed `codesign --verify --deep --strict`.
"""

import argparse
import datetime
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile


def log(message):
    print("[sign] %s" % message, flush=True)


def run(arguments, **kwargs):
    try:
        return subprocess.run(arguments, check=True, capture_output=True, text=True, **kwargs)
    except subprocess.CalledProcessError as error:
        sys.stderr.write("command failed: %s\n" % " ".join(arguments))
        if error.stdout:
            sys.stderr.write(error.stdout)
        if error.stderr:
            sys.stderr.write(error.stderr)
        raise


def try_run(arguments):
    try:
        subprocess.run(arguments, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError:
        return False


def read_profile(path):
    result = subprocess.run(
        ["security", "cms", "-D", "-i", path],
        check=True,
        capture_output=True,
    )
    return plistlib.loads(result.stdout)


def import_certificate(p12_path, password, keychain):
    keychain_password = "trollgram-sign"
    try_run(["security", "delete-keychain", keychain])
    run(["security", "create-keychain", "-p", keychain_password, keychain])
    run(["security", "set-keychain-settings", "-lut", "21600", keychain])
    run(["security", "unlock-keychain", "-p", keychain_password, keychain])
    run([
        "security", "import", p12_path,
        "-P", password,
        "-A", "-t", "cert", "-f", "pkcs12",
        "-k", keychain,
    ])
    run([
        "security", "set-key-partition-list",
        "-S", "apple-tool:,apple:,codesign:",
        "-k", keychain_password, keychain,
    ])
    # Prepend the throw-away keychain to the existing search list. The list
    # contains "login.keychain-db" on modern macOS, so it must be reused
    # instead of hardcoding "login.keychain".
    existing = run(["security", "list-keychains", "-d", "user"]).stdout
    existing_keychains = [line.strip().strip('"') for line in existing.splitlines() if line.strip()]
    run(["security", "list-keychains", "-d", "user", "-s", keychain] + existing_keychains)

    listing = run(["security", "find-identity", "-v", "-p", "codesigning", keychain]).stdout
    match = re.search(r'\)\s+"([^"]+)"', listing)
    if match is None:
        sys.stderr.write(listing)
        raise SystemExit("no code signing identity found in the .p12 (wrong password?)")
    return match.group(1)


def covers(profile_app_id, bundle_id):
    if profile_app_id.endswith("*"):
        return bundle_id.startswith(profile_app_id[:-1])
    return profile_app_id == bundle_id


def write_entitlements(profile_entitlements, team_id, bundle_id, path):
    entitlements = dict(profile_entitlements)
    entitlements["application-identifier"] = "%s.%s" % (team_id, bundle_id)
    entitlements["com.apple.developer.team-identifier"] = team_id
    # Only valid for App Store profiles, codesign rejects it from the outside.
    entitlements.pop("beta-reports-active", None)
    with open(path, "wb") as handle:
        plistlib.dump(entitlements, handle)


def strip_signature(path):
    for name in ("_CodeSignature", "SC_Info"):
        candidate = os.path.join(path, name)
        if os.path.isdir(candidate):
            shutil.rmtree(candidate)
    return path


def sign(path, identity, entitlements_path=None):
    arguments = ["codesign", "--force", "--sign", identity, "--timestamp=none"]
    if entitlements_path is not None:
        arguments += ["--entitlements", entitlements_path]
    arguments.append(path)
    run(arguments)


def bundle_identifier(app_path):
    with open(os.path.join(app_path, "Info.plist"), "rb") as handle:
        return plistlib.load(handle)["CFBundleIdentifier"]


def set_bundle_identifier(app_path, bundle_id):
    plist_path = os.path.join(app_path, "Info.plist")
    with open(plist_path, "rb") as handle:
        info = plistlib.load(handle)
    info["CFBundleIdentifier"] = bundle_id
    with open(plist_path, "wb") as handle:
        plistlib.dump(info, handle)


def nested_bundles(app_path):
    """Every nested code bundle, deepest paths first."""
    found = []
    for directory, dirnames, filenames in os.walk(app_path):
        for name in list(dirnames):
            if name.endswith((".framework", ".appex")):
                found.append(os.path.join(directory, name))
        for name in filenames:
            if name.endswith(".dylib"):
                found.append(os.path.join(directory, name))
    found.sort(key=lambda item: item.count(os.sep), reverse=True)
    return found


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--p12", required=True)
    parser.add_argument("--password", default="")
    parser.add_argument("--profile", required=True)
    arguments = parser.parse_args()

    profile = read_profile(arguments.profile)
    entitlements = profile.get("Entitlements", {})
    profile_app_id = entitlements.get("application-identifier")
    if not profile_app_id:
        raise SystemExit("the provisioning profile has no application-identifier")

    team_id = entitlements.get("com.apple.developer.team-identifier") or profile_app_id.split(".", 1)[0]

    expiration = profile.get("ExpirationDate")
    if expiration is not None and expiration < datetime.datetime.utcnow():
        raise SystemExit("the provisioning profile expired on %s" % expiration)

    devices = profile.get("ProvisionedDevices")
    if devices is not None and not profile.get("ProvisionsAllDevices"):
        log("development profile: the device UDID must be registered in it (%d device(s))" % len(devices))

    with tempfile.TemporaryDirectory() as temporary:
        keychain = os.path.join(temporary, "sign.keychain-db")
        identity = import_certificate(arguments.p12, arguments.password, keychain)
        log("identity: %s" % identity)

        work = os.path.join(temporary, "work")
        os.makedirs(work, exist_ok=True)
        # unzip/zip keep permissions and the framework symlinks intact.
        run(["unzip", "-q", os.path.abspath(arguments.input), "-d", work])

        payload = os.path.join(work, "Payload")
        apps = [name for name in os.listdir(payload) if name.endswith(".app")]
        if len(apps) != 1:
            raise SystemExit("expected exactly one .app in Payload, found %r" % apps)
        app_path = os.path.join(payload, apps[0])
        log("app: %s" % apps[0])

        original_bundle_id = bundle_identifier(app_path)
        bundle_id = original_bundle_id

        if not covers(profile_app_id, bundle_id):
            if profile_app_id.endswith("*"):
                raise SystemExit(
                    "the profile covers %r, which does not include %r" % (profile_app_id, bundle_id)
                )
            bundle_id = profile_app_id.split(".", 1)[1]
            log("profile bundle id %r != app %r, renaming the app" % (bundle_id, original_bundle_id))
            set_bundle_identifier(app_path, bundle_id)

        # The app derives its App Group from the bundle id ("group.<bundle id>"). A profile without that
        # group leaves the shared container unreachable at launch, so say it here instead of in the app.
        expected_group = "group.%s" % bundle_id
        profile_groups = entitlements.get("com.apple.security.application-groups") or []
        if expected_group not in profile_groups:
            log(
                "warning: the profile does not contain the app group %r (it has %r); the app will fall back "
                "to its own sandbox for data. Add the group to the App ID and regenerate the profile for "
                "a shared container." % (expected_group, profile_groups)
            )

        # watchOS code needs watchOS provisioning profiles - never available here.
        watch_path = os.path.join(app_path, "Watch")
        if os.path.isdir(watch_path):
            shutil.rmtree(watch_path)
            log("removed Watch/")

        plugins_path = os.path.join(app_path, "PlugIns")
        if os.path.isdir(plugins_path):
            plugin_ids = []
            for name in os.listdir(plugins_path):
                if name.endswith(".appex"):
                    try:
                        plugin_ids.append(bundle_identifier(os.path.join(plugins_path, name)))
                    except Exception:
                        plugin_ids.append("<unknown>")
            uncovered = [item for item in plugin_ids if not covers(profile_app_id, item)]
            if uncovered:
                shutil.rmtree(plugins_path)
                log("removed PlugIns/ (profile does not cover %s)" % ", ".join(uncovered))
            else:
                log("keeping extensions: %s" % ", ".join(plugin_ids))

        entitlements_dir = os.path.join(temporary, "entitlements")
        os.makedirs(entitlements_dir, exist_ok=True)

        def prepare(target_path, target_bundle_id, embedded_profile=None):
            """Strip, add the profile and write the entitlements for a bundle."""
            strip_signature(target_path)
            if embedded_profile is not None:
                shutil.copyfile(embedded_profile, os.path.join(target_path, "embedded.mobileprovision"))
            plist_path = os.path.join(
                entitlements_dir, target_bundle_id.replace("/", "_") + ".plist"
            )
            write_entitlements(entitlements, team_id, target_bundle_id, plist_path)
            return plist_path

        for nested in nested_bundles(app_path):
            if nested.endswith(".appex"):
                nested_id = bundle_identifier(nested)
                plist_path = prepare(nested, nested_id, arguments.profile)
                sign(nested, identity, plist_path)
                log("signed extension %s" % nested_id)
            elif nested.endswith(".framework"):
                strip_signature(nested)
                sign(nested, identity)
                log("signed framework %s" % os.path.basename(nested))
            else:
                sign(nested, identity)

        plist_path = prepare(app_path, bundle_id, arguments.profile)
        sign(app_path, identity, plist_path)

        run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", app_path])

        if os.path.exists(arguments.output):
            os.remove(arguments.output)
        run(["zip", "-qry", os.path.abspath(arguments.output), "Payload"], cwd=work)

    size = os.path.getsize(arguments.output) / (1024.0 * 1024.0)
    log("signed %s -> %s (%.1f MB)" % (bundle_id, arguments.output, size))


if __name__ == "__main__":
    main()
