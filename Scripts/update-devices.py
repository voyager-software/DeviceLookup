#!/usr/bin/env python3
"""Sync Sources/DeviceLookup/Resources/devices.json with Xcode's device database.

Xcode ships the identifier, marketing name and SoC code of every iPhone, iPad, iPod touch and
Apple TV it can build for, in `Platforms/*/usr/standalone/device_traits.db`. New devices appear
there in the Xcode release that supports them, which is usually around the announcement.

The script adds identifiers missing from devices.json and reports what still needs a hand edit.
It never overwrites a field already in devices.json, so hand-curated names and values are kept.

    Scripts/update-devices.py                  # report only
    Scripts/update-devices.py --write          # add new identifiers to devices.json
    Scripts/update-devices.py --xcode /Applications/Xcode-beta.app

Fields:
    name      marketing name, from Xcode
    soc       Apple's SoC code (e.g. "t8150"), from Xcode
    chip      e.g. "A19 Pro"; by hand. The report suggests the chips of devices with the same SoC,
              but one SoC can ship under several names (A19 and A19 Pro are both t8150).
    diagonal  screen size in inches; by hand (not needed for Apple TV)
    cellular  true for cellular iPad models; by hand (iPhones are always cellular)
"""

import argparse
import json
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEVICES_JSON = ROOT / "Sources/DeviceLookup/Resources/devices.json"
PLATFORMS = ["iPhoneOS", "AppleTVOS"]
PREFIXES = ("iPhone", "iPad", "iPod", "AppleTV")
FIELD_ORDER = ["name", "chip", "diagonal", "cellular", "soc"]


def natural_key(identifier):
    return [int(part) if part.isdigit() else part for part in re.split(r"(\d+)", identifier)]


def developer_dir(xcode):
    if xcode:
        path = Path(xcode)
        return path / "Contents/Developer" if path.suffix == ".app" else path
    return Path(subprocess.check_output(["xcode-select", "-p"], text=True).strip())


def is_relevant(identifier):
    if not identifier.startswith(PREFIXES):
        return False
    # Apple TV 2nd/3rd generation predate tvOS.
    match = re.match(r"AppleTV(\d+),", identifier)
    return not (match and int(match.group(1)) < 5)


def read_xcode(dev_dir):
    devices = {}
    for platform in PLATFORMS:
        db = dev_dir / f"Platforms/{platform}.platform/usr/standalone/device_traits.db"
        if not db.exists():
            sys.exit(f"Missing {db}")
        with sqlite3.connect(f"file:{db}?mode=ro", uri=True) as conn:
            rows = conn.execute(
                "SELECT ProductType, ProductDescription, Platform, CompatibleDeviceFallback FROM Devices"
            )
            for product_type, name, soc, fallback in rows:
                # Some iPads are listed once per thinning variant, as "iPad17,1-A" and "iPad17,1-B".
                identifier = re.sub(r"-[A-Z]$", "", product_type)
                if is_relevant(identifier) and identifier not in devices:
                    devices[identifier] = {"name": name, "soc": soc, "fallback": fallback}
    return devices


def chips_by_soc(entries):
    chips = {}
    for entry in entries.values():
        if entry.get("soc") and entry.get("chip"):
            chips.setdefault(entry["soc"], set()).add(entry["chip"])
    return chips


def ordered(entry):
    return {key: entry[key] for key in FIELD_ORDER if entry.get(key) is not None}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--xcode", help="Xcode.app or its Developer directory (default: xcode-select -p)")
    parser.add_argument("--write", action="store_true", help="write new identifiers to devices.json")
    args = parser.parse_args()

    dev_dir = developer_dir(args.xcode)
    xcode = read_xcode(dev_dir)
    entries = json.loads(DEVICES_JSON.read_text()) if DEVICES_JSON.exists() else {}

    print(f"Xcode: {dev_dir}")
    print(f"{len(xcode)} identifiers in Xcode, {len(entries)} in devices.json\n")

    added = []
    for identifier in sorted(xcode, key=natural_key):
        info = xcode[identifier]
        entry = entries.get(identifier)
        if entry is None:
            entry = {"name": info["name"], "soc": info["soc"]}
            entries[identifier] = entry
            added.append(identifier)
            closest = xcode.get(info["fallback"], {}).get("name", info["fallback"])
            print(f"NEW      {identifier:<14} {info['name']}  (closest: {info['fallback']} {closest})")
            continue
        if entry.get("soc") is None:
            entry["soc"] = info["soc"]
        if not entry.get("name"):
            entry["name"] = info["name"]
        elif entry["name"] != info["name"]:
            print(f"NAME     {identifier:<14} ours: {entry['name']!r}  Xcode: {info['name']!r}")

    for identifier in sorted(set(entries) - set(xcode), key=natural_key):
        print(f"NOT IN XCODE {identifier:<10} {entries[identifier]['name']}")

    print()
    soc_chips = chips_by_soc(entries)
    for identifier in sorted(entries, key=natural_key):
        entry = entries[identifier]
        missing = []
        if not entry.get("chip"):
            same_soc = sorted(soc_chips.get(entry.get("soc"), []))
            missing.append(f"chip (same SoC: {', '.join(same_soc)})" if same_soc else "chip")
        if not identifier.startswith("AppleTV") and not entry.get("diagonal"):
            missing.append("diagonal")
        if identifier in added and identifier.startswith("iPad"):
            missing.append("cellular?")
        if missing:
            print(f"TO FILL  {identifier:<14} {entry['name']}: {', '.join(missing)}")

    if args.write:
        output = {identifier: ordered(entries[identifier]) for identifier in sorted(entries, key=natural_key)}
        DEVICES_JSON.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n")
        print(f"\nWrote {len(output)} identifiers to {DEVICES_JSON.relative_to(ROOT)}")
    elif added:
        print(f"\n{len(added)} new identifiers. Run with --write to add them.")


if __name__ == "__main__":
    main()
