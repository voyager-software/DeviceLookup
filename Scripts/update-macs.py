#!/usr/bin/env python3
"""Sync Sources/DeviceLookup/Resources/macs.json with Apple's "Identify your Mac model" pages.

Apple keeps one support page per Mac family, listing every model newest first with its name and
model identifiers. The script reads all of them and rebuilds macs.json in the same order, so an
identifier Apple reused across models resolves to the newest one.

    Scripts/update-macs.py                     # report what's new or different
    Scripts/update-macs.py --write             # rewrite macs.json from the pages
    Scripts/update-macs.py --pages DIR         # read saved pages (imac.html, ...) instead of fetching

Fields:
    family    the product line, e.g. "MacBook Pro", from the start of the name
    name      e.g. "MacBook Pro (14-inch, M5, 2025)". Newer pages give the year on its own line, so
              it's added to the name as the older entries have it.
    ids       the model identifiers, e.g. ["Mac17,2"]

Pages get redesigned now and then. If one yields fewer Macs than macs.json has for that family,
the script stops without writing, so a parsing failure never empties the data.
"""

import argparse
import html
import json
import re
import sys
import urllib.request
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MACS_JSON = ROOT / "Sources/DeviceLookup/Resources/macs.json"
# Page name -> Apple support article, in the order macs.json lists the families.
PAGES = {
    "imac": "108054",
    "macstudio": "102231",
    "macbook": "103257",
    "macbookair": "102869",
    "macbookpro": "108052",
    "macmini": "102852",
    "macpro": "102887",
}
# Longest first, so "MacBook Pro" wins over "MacBook" and "Mac Pro Server" over "Mac Pro".
FAMILIES = sorted(
    ["iMac", "iMac Pro", "MacBook", "MacBook Air", "MacBook Pro", "Mac mini", "Mac Pro", "Mac Pro Server", "Mac Studio"],
    key=len,
    reverse=True,
)
IDENTIFIER = re.compile(r"\b(?:Mac|iMac|iMacPro|MacBook|MacBookAir|MacBookPro|Macmini|MacPro)\d+,\d+\b")


class Blocks(HTMLParser):
    """Collects the page's headings and paragraphs as (is_name_candidate, text)."""

    def __init__(self):
        super().__init__()
        self.blocks = []
        self.tag = None
        self.text = ""
        self.bold = ""

    def handle_starttag(self, tag, attrs):
        if tag in ("h2", "h3", "p"):
            self.tag, self.text, self.bold = tag, "", ""
        elif tag == "b" and self.tag:
            self.in_bold = True

    def handle_endtag(self, tag):
        if tag == "b":
            self.in_bold = False
        elif tag == self.tag:
            text = clean(self.text)
            # A model's name is a heading, or a paragraph that's all bold.
            is_name = self.tag in ("h2", "h3") or (text and clean(self.bold) == text)
            self.blocks.append((is_name, text))
            self.tag = None

    def handle_data(self, data):
        if self.tag:
            self.text += data
            if getattr(self, "in_bold", False):
                self.bold += data


def clean(text):
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


def family_of(name):
    return next((family for family in FAMILIES if name.startswith(family + " ") or name == family), None)


def with_year(name, year):
    """Adds the year to a name that doesn't have one: "Mac mini (M6)" -> "Mac mini (M6, 2026)"."""
    if not year or re.search(r"\b(19|20)\d\d\b", name):
        return name
    return f"{name[:-1]}, {year})" if name.endswith(")") else f"{name} ({year})"


def parse(page_html):
    blocks = Blocks()
    blocks.feed(page_html)
    macs, name, year = [], None, None
    for is_name, text in blocks.blocks:
        if is_name and family_of(text):
            name, year = text, None
        elif text.startswith("Year introduced:"):
            year = text.split(":", 1)[1].strip()
        elif text.startswith("Model Identifier") and name:
            ids = IDENTIFIER.findall(text)
            if ids:
                macs.append({"family": family_of(name), "name": with_year(name, year), "ids": sorted(set(ids))})
    return macs


def distinct_families(macs):
    """Distinct models per family, so an entry listed twice doesn't count twice."""
    return Counter(family for family, _, _ in {(mac["family"], mac["name"], tuple(mac["ids"])) for mac in macs})


def fetch(article):
    request = urllib.request.Request(f"https://support.apple.com/en-us/{article}", headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--write", action="store_true", help="rewrite macs.json from the pages")
    parser.add_argument("--pages", help="directory of saved pages (imac.html, ...) to read instead of fetching")
    args = parser.parse_args()

    current = json.loads(MACS_JSON.read_text())
    current_families = distinct_families(current)

    macs = []
    for page, article in PAGES.items():
        page_html = (Path(args.pages) / f"{page}.html").read_text() if args.pages else fetch(article)
        macs += parse(page_html)

    found_families = distinct_families(macs)
    short = [
        f"{family}: {found_families[family]} on Apple's pages, {count} in macs.json"
        for family, count in current_families.items()
        if found_families[family] < count
    ]

    old = {(mac["name"], tuple(mac["ids"])) for mac in current}
    new = {(mac["name"], tuple(mac["ids"])) for mac in macs}
    for name, ids in sorted(new - old):
        print(f"NEW      {name}: {', '.join(ids)}")
    for name, ids in sorted(old - new):
        print(f"MISSING  {name}: {', '.join(ids)}")
    print(f"{len(macs)} Macs on Apple's pages, {len(current)} in macs.json")

    if short:
        print("\nFewer Macs than macs.json has, so a page may have changed format:")
        print("\n".join(f"  {line}" for line in short))
        if args.write:
            print("Not writing.")
        return 1

    if args.write and macs != current:
        MACS_JSON.write_text(json.dumps(macs, indent=2, ensure_ascii=False) + "\n")
        print(f"Wrote {MACS_JSON.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
