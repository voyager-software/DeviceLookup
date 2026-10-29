#!/usr/bin/env python3
"""Import Mac data from MacModelParser into Sources/DeviceLookup/Resources/all-macs.json.

MacModelParser's output also lists colors, part numbers and notes; only the fields
DeviceLookup decodes are kept, to keep the bundled file small.

    Scripts/import-macs.py                                     # from ../MacModelParser
    Scripts/import-macs.py path/to/all-macs.json
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MACS_JSON = ROOT / "Sources/DeviceLookup/Resources/all-macs.json"
DEFAULT_SOURCE = ROOT.parent / "MacModelParser/All Mac Models/all-macs.json"
# MacModelParser field -> DeviceLookup key.
FIELDS = {"kind": "kind", "name": "name", "models": "ids"}


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE
    macs = json.loads(source.read_text())
    slim = [{key: mac[field] for field, key in FIELDS.items()} for mac in macs]
    MACS_JSON.write_text(json.dumps(slim, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {len(slim)} Macs from {source} to {MACS_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
