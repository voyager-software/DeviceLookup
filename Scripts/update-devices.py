#!/usr/bin/env python3
"""Sync Sources/DeviceLookup/Resources/devices.json with Xcode's device database.

Xcode ships the identifier, marketing name and SoC code of every iPhone, iPad, iPod touch,
Apple TV, Apple Watch and Apple Vision Pro it can build for, in `Platforms/*/usr/standalone/device_traits.db`. New devices appear
there in the Xcode release that supports them, which is usually around the announcement.

Xcode's simulator device types, in /Library/Developer/CoreSimulator/Profiles/DeviceTypes, give each model's
screen. The script adds identifiers missing from devices.json, fills in screens from the simulators, and
reports what still needs a hand edit.
It never overwrites a field already in devices.json, so hand-curated names and values are kept.

    Scripts/update-devices.py                  # report only
    Scripts/update-devices.py --write          # add new identifiers to devices.json
    Scripts/update-devices.py --xcode /Applications/Xcode-beta.app

Fields:
    name      marketing name, from Xcode. Xcode names most watches without their case size, so
              by hand, append it as Xcode does for the older ones, e.g. "Apple Watch Series 9 (GPS) 45mm".
              The report says whether each one is the small or large case.
    year      the year it was released, e.g. 2025. New devices get the current year, since Xcode lists them
              around their announcement; correct it by hand if a device ships the next year.
    soc       Apple's SoC code (e.g. "t8150"), from Xcode
    chip      e.g. "A19 Pro"; by hand. The report suggests the chips of devices with the same SoC,
              but one SoC can ship under several names (A19 and A19 Pro are both t8150).
    cell      true for cellular iPad and Apple Watch models (iPhones are always cellular). Set
              automatically when Xcode's name says "Cellular" or the device Xcode falls back to is
              cellular, otherwise by hand.
    island    true when it has a Dynamic Island, from the simulator for the model
    screen    the main screen, from the simulator for the model; by hand for models too old to have one:
              diag      diagonal in inches, e.g. 6.3; always by hand
              w, h      portrait size in points, e.g. 402 x 874
              scale     e.g. 3
              corner    the display's corner radius in points, left out for square corners
              The main screen is the largest built-in display, so for a foldable it's the inner one.
              Apple TV and Apple Vision Pro have none.
"""

import argparse
import datetime
import json
import plistlib
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEVICES_JSON = ROOT / "Sources/DeviceLookup/Resources/devices.json"
PLATFORMS = ["iPhoneOS", "AppleTVOS", "WatchOS", "XROS"]
PREFIXES = ("iPhone", "iPad", "iPod", "AppleTV", "Watch", "RealityDevice")
FIELD_ORDER = ["name", "year", "chip", "cell", "island", "screen", "soc"]
SCREEN_ORDER = ["diag", "w", "h", "scale", "corner"]
SIMULATOR_PROFILES = Path("/Library/Developer/CoreSimulator/Profiles/DeviceTypes")
NO_SCREEN = ("AppleTV", "RealityDevice")


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
                "SELECT ProductType, ProductDescription, Platform, CompatibleDeviceFallback, Target FROM Devices"
            )
            for product_type, name, soc, fallback, target in rows:
                # Some iPads are listed once per thinning variant, as "iPad17,1-A" and "iPad17,1-B".
                identifier = re.sub(r"-[A-Z]$", "", product_type)
                if is_relevant(identifier) and identifier not in devices:
                    devices[identifier] = {"name": name, "soc": soc, "fallback": fallback, "target": target}
    return devices


def read_simulators(profiles):
    """Each identifier's main screen, and the identifiers with a Dynamic Island, from Xcode's simulator device types."""
    screens, islands = {}, set()
    for path in sorted(profiles.glob("*.simdevicetype")):
        resources = path / "Contents/Resources"
        try:
            profile = plistlib.loads((resources / "profile.plist").read_bytes())
            capabilities = plistlib.loads((resources / "capabilities.plist").read_bytes()).get("capabilities", {})
        except (OSError, plistlib.InvalidFileException):
            continue
        identifiers = {profile.get("modelIdentifier"), *profile.get("representedModelIdentifiers", [])} - {None}
        if capabilities.get("DeviceSupportsDynamicIsland"):
            islands |= identifiers
        # The device's own displays, not the external ones it can drive. A foldable has two; the inner one is larger.
        displays = [display for display in capabilities.get("displays") or [] if display.get("displayType") == "integrated"]
        if not displays:
            continue
        display = max(displays, key=lambda display: display["width"] * display["height"])
        scale = int(display["scale"])
        screen = {"w": round(display["width"] / scale), "h": round(display["height"] / scale), "scale": scale}
        corner = round(float(display.get("cornerRadiusUL") or 0), 2)
        if corner:
            screen["corner"] = int(corner) if corner.is_integer() else corner
        for identifier in identifiers:
            screens.setdefault(identifier, screen)
    return screens, islands


def watch_case(target):
    """"small" or "large" for a watch that comes in two case sizes, from its board name, e.g. "n207sap"."""
    match = re.search(r"([sb])ap$", target or "")
    return {"s": "small", "b": "large"}[match.group(1)] if match else None


def same_name(ours, xcode_name):
    """Whether our name is Xcode's, allowing a case size we appended, e.g. "... (GPS) 45mm"."""
    return ours == xcode_name or re.fullmatch(re.escape(xcode_name) + r" \d+mm", ours) is not None


def chips_by_soc(entries):
    chips = {}
    for entry in entries.values():
        if entry.get("soc") and entry.get("chip"):
            chips.setdefault(entry["soc"], set()).add(entry["chip"])
    return chips


def ordered(entry):
    result = {key: entry[key] for key in FIELD_ORDER if entry.get(key) is not None}
    if "screen" in result:
        result["screen"] = {key: result["screen"][key] for key in SCREEN_ORDER if key in result["screen"]}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--xcode", help="Xcode.app or its Developer directory (default: xcode-select -p)")
    parser.add_argument("--write", action="store_true", help="write new identifiers to devices.json")
    args = parser.parse_args()

    dev_dir = developer_dir(args.xcode)
    xcode = read_xcode(dev_dir)
    entries = json.loads(DEVICES_JSON.read_text()) if DEVICES_JSON.exists() else {}
    screens, islands = read_simulators(SIMULATOR_PROFILES)

    print(f"Xcode: {dev_dir}")
    print(f"{len(xcode)} identifiers in Xcode, {len(entries)} in devices.json, {len(screens)} with simulator screens\n")

    added = []
    for identifier in sorted(xcode, key=natural_key):
        info = xcode[identifier]
        entry = entries.get(identifier)
        if entry is None:
            entry = {"name": info["name"], "year": datetime.date.today().year, "soc": info["soc"]}
            # A device falls back to its predecessor of the same kind, so a cellular predecessor means cellular.
            if "Cellular" in info["name"] or entries.get(info["fallback"], {}).get("cell"):
                entry["cell"] = True
            entries[identifier] = entry
            added.append(identifier)
            closest = xcode.get(info["fallback"], {}).get("name", info["fallback"])
            print(f"NEW      {identifier:<14} {info['name']}  (closest: {info['fallback']} {closest})")
            continue
        if entry.get("soc") is None:
            entry["soc"] = info["soc"]
        if not entry.get("name"):
            entry["name"] = info["name"]
        elif not same_name(entry["name"], info["name"]):
            print(f"NAME     {identifier:<14} ours: {entry['name']!r}  Xcode: {info['name']!r}")

    for identifier, entry in entries.items():
        if "screen" not in entry and identifier in screens and not identifier.startswith(NO_SCREEN):
            entry["screen"] = dict(screens[identifier])
            print(f"SCREEN   {identifier:<14} {entry['name']}: {screens[identifier]}")
        if identifier in islands and not entry.get("island"):
            entry["island"] = True
            print(f"ISLAND   {identifier:<14} {entry['name']}")

    for identifier in sorted(set(entries) - set(xcode), key=natural_key):
        print(f"NOT IN XCODE {identifier:<10} {entries[identifier]['name']}")

    print()
    soc_chips = chips_by_soc(entries)
    for identifier in sorted(entries, key=natural_key):
        entry = entries[identifier]
        missing = []
        if not entry.get("year"):
            missing.append("year")
        if not entry.get("chip"):
            same_soc = sorted(soc_chips.get(entry.get("soc"), []))
            missing.append(f"chip (same SoC: {', '.join(same_soc)})" if same_soc else "chip")
        if not identifier.startswith(NO_SCREEN):
            if not entry.get("screen"):
                missing.append("screen")
            elif not entry["screen"].get("diag"):
                missing.append("screen diag")
        if identifier in added and identifier.startswith(("iPad", "Watch")) and not entry.get("cell") and not re.search(r"GPS|Cellular", entry["name"]):
            missing.append("cell?")
        size = watch_case(xcode.get(identifier, {}).get("target")) if identifier.startswith("Watch") else None
        if size and not re.search(r" \d+mm$", entry["name"]):
            missing.append(f"case size in name ({size} case)")
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
