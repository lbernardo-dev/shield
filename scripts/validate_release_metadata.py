#!/usr/bin/env python3
"""Print and enforce App Store Connect metadata character/UTF-8 byte limits."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


FIELDS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotionalText": 170,
    "description": 4000,
    "whatsNew": 4000,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metadata_dir", type=Path)
    parser.add_argument("--version", default="1.2.0")
    args = parser.parse_args()
    root = args.metadata_dir
    failed = False
    for locale in ("en-US", "es-ES"):
        info_path = root / "app-info" / f"{locale}.json"
        version_path = root / "version" / args.version / f"{locale}.json"
        if not info_path.is_file() or not version_path.is_file():
            print(f"{locale}: missing canonical JSON file", file=sys.stderr)
            failed = True
            continue
        info = json.loads(info_path.read_text(encoding="utf-8"))
        version = json.loads(version_path.read_text(encoding="utf-8"))
        print(locale)
        for field, limit in FIELDS.items():
            source = info if field in ("name", "subtitle") else version
            value = source.get(field)
            if not isinstance(value, str):
                print(f"  {field}: missing or not text")
                failed = True
                continue
            count = len(value)
            byte_count = len(value.encode("utf-8"))
            ok = byte_count <= limit if field == "keywords" else count <= limit
            print(f"  {field}: {count} chars, {byte_count} UTF-8 bytes / {limit} ({'PASS' if ok else 'FAIL'})")
            failed |= not ok
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
