# Contributing

Device details are data, not code: `Sources/DeviceLookup/Resources/devices.json` for iPhone, iPad, iPod touch, Apple TV, Apple Watch and Apple Vision Pro, and `Sources/DeviceLookup/Resources/macs.json` for Macs. Adding or correcting a device is a JSON edit, and two scripts do most of it.

If a device is missing or wrong, an [issue](https://github.com/voyager-software/DeviceLookup/issues) with its model identifier is enough. Pull requests are welcome too.

## Updating the data

The [Update devices](.github/workflows/update-devices.yml) workflow runs both scripts every Monday and opens a pull request with whatever they add, plus a report of what to fill in. You can also run it from the Actions tab, or run the scripts locally when a new Xcode ships.

### iPhone, iPad, iPod touch, Apple TV, Apple Watch and Apple Vision Pro

```sh
Scripts/update-devices.py            # report what's new or different
Scripts/update-devices.py --write    # add new identifiers to devices.json
```

The script reads Xcode's `device_traits.db` and its simulator device types. For each new identifier it adds:

- the name and SoC code, from Xcode;
- the current year as its release year (correct it if a device ships the next year);
- the screen's size, scale and corner radius, and whether it has a Dynamic Island, from the simulator. For a foldable, the screen is the larger, inner display;
- `cell` (cellular) when Xcode's name says "Cellular" or the device it falls back to is cellular.

It then lists what still needs filling in by hand:

- `chip`, e.g. "A19 Pro". The report suggests the chips of devices with the same SoC.
- `diag` inside `screen`: the diagonal in inches, e.g. 6.3.
- `screen` for models too old to have a simulator.
- `cell` for iPads and watches whose name doesn't say.
- The case size for watches. Xcode names most watches without one, so append it to the name, e.g. "Apple Watch Series 11 (GPS) 46mm"; the report says whether it's the small or large case.

It never overwrites existing values. The tests fail until each device has a year, a chip and a screen with its diagonal (Apple TV and Apple Vision Pro need only the first two), and each watch name its case size.

### Macs

```sh
Scripts/update-macs.py               # report what's new or different
Scripts/update-macs.py --write       # rewrite macs.json from the pages
```

The script reads Apple's "Identify your Mac model" support pages, one per Mac family. It keeps each Mac's family, name, release year and model identifiers (`ids`), newest first as Apple lists them, so an identifier Apple reused across models resolves to the newest one. Nothing needs filling in by hand. If a page yields fewer Macs than `macs.json` has, Apple has probably redesigned it, and the script stops without writing.

## Tests

```sh
swift test
```

CI also runs the tests on iOS, tvOS and Mac Catalyst, builds them for watchOS, and builds the library with Xcode 16, the oldest supported.
