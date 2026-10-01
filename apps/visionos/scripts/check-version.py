#!/usr/bin/env python3
"""Verify that the visionOS bundle version and npm app versions match Git SemVer."""

import argparse
import json
import plistlib
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SEMVER = re.compile(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\Z")


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def fail(reason: str) -> None:
    raise SystemExit(f"Version check failed: {reason}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true", help="also require this tag to point to HEAD")
    args = parser.parse_args()

    try:
        tag = git("describe", "--tags", "--abbrev=0", "--match", "v[0-9]*")
    except subprocess.CalledProcessError:
        fail("no reachable version tag")
    version = tag.removeprefix("v")
    if tag != "v" + version or not SEMVER.fullmatch(version):
        fail(f"latest reachable tag {tag!r} is not vMAJOR.MINOR.PATCH SemVer")
    if args.release and tag not in git("tag", "--points-at", "HEAD").splitlines():
        fail(f"{tag} does not point to HEAD")
    if args.release and git("cat-file", "-t", f"refs/tags/{tag}") != "tag":
        fail(f"{tag} must be an annotated tag")

    project = (ROOT / "apps/visionos/project.yml").read_text()
    found = re.findall(r"(?m)^\s*MARKETING_VERSION:\s*['\"]?([^'\"\s#]+)", project)
    if found != [version]:
        fail(f"project.yml MARKETING_VERSION {found!r} differs from {tag}")
    plist = plistlib.loads((ROOT / "apps/visionos/VenueVolume/Info.plist").read_bytes())
    if plist.get("CFBundleShortVersionString") != "$(MARKETING_VERSION)":
        fail("Info.plist must use $(MARKETING_VERSION)")
    generated = (ROOT / "apps/visionos/VenueVolume.xcodeproj/project.pbxproj").read_text()
    if f"MARKETING_VERSION = {version};" not in generated:
        fail("generated Xcode project does not contain the marketing version")

    for app in ("design-studio", "marketing"):
        folder = ROOT / "apps" / app
        package = json.loads((folder / "package.json").read_text())
        lock = json.loads((folder / "package-lock.json").read_text())
        if package["version"] != version or lock["version"] != version or lock["packages"][""]["version"] != version:
            fail(f"{app} package.json/package-lock.json differs from {tag}")
    print(f"Version check passed: {tag} = visionOS MARKETING_VERSION/Info.plist = both npm apps.")


if __name__ == "__main__":
    main()
