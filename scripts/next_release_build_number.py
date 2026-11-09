#!/usr/bin/env python3
"""Choose a MaskID build number without reusing ASC or local archive numbers.

Requires the current `asc` CLI, an authenticated read-only ASC profile, Python
3.9+, and the project checkout. It never writes to Xcode or App Store Connect.
"""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import subprocess
import sys
import zipfile
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parents[1]
APP_ID = "6790398619"
PROFILE = "RomeroDev"
PROJECT = ROOT / "Shield.xcodeproj"
ARTIFACTS = ROOT / ".asc" / "artifacts"


def run_json(args: list[str]) -> object:
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError("ASC read-only lookup failed; no build number was selected")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("ASC returned invalid JSON; no build number was selected") from error


def version_prefix(version: str) -> str:
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Version must contain three numeric components: X.Y.Z")
    return "".join(version.split("."))


def versions_from_asc(payload: object, prefix: str) -> set[str]:
    found: set[str] = set()
    if not isinstance(payload, dict):
        return found
    data = payload.get("data", [])
    if not isinstance(data, list):
        return found
    for item in data:
        if not isinstance(item, dict) or item.get("type") != "builds":
            continue
        attributes = item.get("attributes", {})
        if isinstance(attributes, dict):
            candidate = attributes.get("version")
            if isinstance(candidate, str) and candidate.startswith(prefix):
                found.add(candidate)
    return found


def archived_builds(version: str, prefix: str) -> set[str]:
    found: set[str] = set()
    if not ARTIFACTS.exists():
        return found
    for archive in ARTIFACTS.rglob("*.xcarchive"):
        info = archive / "Products" / "Applications" / "MaskID.app" / "Info.plist"
        if not info.is_file():
            continue
        try:
            with info.open("rb") as handle:
                plist = plistlib.load(handle)
        except (OSError, plistlib.InvalidFileException):
            continue
        if plist.get("CFBundleShortVersionString") == version:
            candidate = str(plist.get("CFBundleVersion", ""))
            if candidate.startswith(prefix):
                found.add(candidate)
    for ipa in ARTIFACTS.rglob("*.ipa"):
        try:
            with zipfile.ZipFile(ipa) as package:
                info_path = next(
                    (name for name in package.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)),
                    None,
                )
                if info_path is None:
                    continue
                plist = plistlib.loads(package.read(info_path))
        except (OSError, zipfile.BadZipFile, KeyError, plistlib.InvalidFileException):
            continue
        if plist.get("CFBundleShortVersionString") == version:
            candidate = str(plist.get("CFBundleVersion", ""))
            if candidate.startswith(prefix):
                found.add(candidate)
    return found


def tagged_builds(version: str, prefix: str) -> set[str]:
    result = subprocess.run(
        ["git", "tag", "--list"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        raise RuntimeError("Could not inspect local Git tags; no build number was selected")
    tag_pattern = re.compile(rf"{re.escape(prefix)}\d{{8}}\d{{2}}")
    return {
        match.group(0)
        for tag in result.stdout.splitlines()
        if version in tag
        for match in tag_pattern.finditer(tag)
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Public X.Y.Z version")
    parser.add_argument("--app-id", default=APP_ID, help="Exact App Store Connect app ID")
    parser.add_argument("--profile", default=PROFILE, help="ASC profile used for read-only collision checks")
    args = parser.parse_args()

    try:
        prefix = version_prefix(args.version)
        day = datetime.now(ZoneInfo("Europe/Madrid")).strftime("%Y%m%d")
        remote = run_json([
            "asc", "--profile", args.profile, "--read-only", "builds", "list",
            "--app", args.app_id, "--version", args.version, "--platform", "IOS",
            "--paginate", "--output", "json",
        ])
        used = versions_from_asc(remote, prefix)
        used |= archived_builds(args.version, prefix)
        used |= tagged_builds(args.version, prefix)

        daily_prefix = f"{prefix}{day}"
        daily_numbers = {
            int(value[-2:])
            for value in used
            if re.fullmatch(r"\d+", value)
            and value.startswith(daily_prefix)
            and len(value) == len(daily_prefix) + 2
        }
        next_number = max(daily_numbers, default=0) + 1
        if next_number > 99:
            raise RuntimeError("Daily NN is exhausted at 99; owner decision is required")
        result = f"{daily_prefix}{next_number:02d}"
        print(json.dumps({
            "version": args.version,
            "buildDate": day,
            "timezone": "Europe/Madrid",
            "nextDailySequence": f"{next_number:02d}",
            "buildNumber": result,
            "checkedASC": True,
            "matchedExistingNumbers": sorted(used),
            "writesPerformed": False,
        }, ensure_ascii=False, indent=2))
        return 0
    except (ValueError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
