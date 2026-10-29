# DeviceLookup

Names, chips, screen sizes and families for iPhone, iPad, iPod touch, Apple TV and Mac model identifiers, plus the running device's OS, memory and storage details. Replaces DeviceKit and MacLookup.

Device details are data (`Resources/devices.json`, `Resources/all-macs.json`), not code, so adding a device is a JSON edit. A device missing from the data still resolves: its family comes from the identifier prefix and its name falls back to the identifier.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/voyager-software/DeviceLookup.git", from: "2026.10.0"),
]
```

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
Mac.find(model: "Mac14,7")?.name                // "MacBook Pro (13-inch, M2, 2022)"
```

## Updating the data

When a new Xcode ships, run:

```sh
Scripts/update-devices.py            # report what's new or different
Scripts/update-devices.py --write    # add new identifiers to devices.json
```

It reads Xcode's `device_traits.db`, adds missing identifiers with their name and SoC code, and lists what still needs filling in by hand: `chip`, `diagonal`, and `cellular` for iPads. It never overwrites existing values. `DeviceTests.allDevicesHaveData` fails until each device has a chip and a diagonal.

Mac data comes from the MacModelParser project.

## Coming from DeviceKit

| DeviceKit | DeviceLookup |
| --- | --- |
| `Device.identifier` | `Device.machineIdentifier` |
| `device.description` | `device.description` |
| `device.cpu.description` | `device.chip` |
| `device.diagonal` (-1 when unknown) | `device.diagonal` (`nil` when unknown) |
| `device.isOneOf([.appleTVHD, ...])` | compare `device.modelIdentifier` |
| `device.name`, `.systemName`, `.model` (`UIDevice`) | not provided; use `UIDevice` on the main actor |

Chip and screen-size values were first imported from [DeviceKit](https://github.com/devicekit/DeviceKit) (MIT).
