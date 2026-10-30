# DeviceLookup

[![CI](https://github.com/voyager-software/DeviceLookup/actions/workflows/ci.yml/badge.svg)](https://github.com/voyager-software/DeviceLookup/actions/workflows/ci.yml)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvoyager-software%2FDeviceLookup%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/voyager-software/DeviceLookup)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvoyager-software%2FDeviceLookup%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/voyager-software/DeviceLookup)

Names, chips, screen sizes and families for iPhone, iPad, iPod touch, Apple TV, Apple Watch and Mac model identifiers, plus the running device's OS, memory and storage details. Replaces DeviceKit and MacLookup.

Device details are data (`Resources/devices.json`, `Resources/all-macs.json`), not code, so adding a device is a JSON edit. A device missing from the data still resolves: its family comes from the identifier prefix and its name falls back to the identifier.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/voyager-software/DeviceLookup.git", from: "2026.10.4"),
]
```

Requires Swift 6 (Xcode 16 or later) and iOS 15, tvOS 15, watchOS 9, macOS 12 or Mac Catalyst 15.

## Usage

```swift
import DeviceLookup

let device = Device.current
device.modelIdentifier      // "iPhone18,1" (the simulated device on a simulator, the Mac model under Catalyst)
device.modelName            // "iPhone 17 Pro"
device.deviceDescription    // "iPhone 17 Pro, A19 Pro"  /  "MacBook Pro (14-inch, M3 Pro, 2023), Apple M3 Pro"
device.family               // .phone (raw value "phone")
device.diagonal             // 6.3
device.hasCellular          // true
device.isSimulator          // false

Device(modelIdentifier: "iPad16,4").modelName   // "iPad Pro 11-inch (M4)"
Device(modelIdentifier: "Watch7,18").modelName  // "Apple Watch Series 11 (GPS) 46mm"
Mac.find(model: "Mac14,7")?.name                // "MacBook Pro (13-inch, M2, 2022)"
```

## Updating the data

When a new Xcode ships, run:

```sh
Scripts/update-devices.py            # report what's new or different
Scripts/update-devices.py --write    # add new identifiers to devices.json
```

It reads Xcode's `device_traits.db`, adds missing identifiers with their name and SoC code, and lists what still needs filling in by hand: `chip`, `diag` (screen diagonal in inches), `cell` (cellular) for iPads and watches whose name doesn't say, and the case size for watches. Xcode names most watches without one, so append it to the name, e.g. "Apple Watch Series 11 (GPS) 46mm"; the report says whether it's the small or large case. It never overwrites existing values. `DeviceTests.allDevicesHaveData` fails until each device has a chip and a diagonal.

Mac data comes from the MacModelParser project. After regenerating it there, run `Scripts/import-macs.py`, which keeps only the kind, name and model identifiers (`ids`).

## Coming from DeviceKit

| DeviceKit | DeviceLookup |
| --- | --- |
| `Device.identifier` | `Device.machineIdentifier` |
| `device.description` | `device.description` |
| `device.cpu.description` | `device.chip` |
| `device.diagonal` (-1 when unknown) | `device.diagonal` (`nil` when unknown) |
| `device.isOneOf([.appleTVHD, ...])` | compare `device.modelIdentifier` |
| `device.name`, `.systemName`, `.model` (`UIDevice`) | not provided; use `UIDevice` on the main actor |

## License

MIT. See [LICENSE](LICENSE), which also carries the license of [DeviceKit](https://github.com/devicekit/DeviceKit), where the chip and screen-size values were first imported from.
