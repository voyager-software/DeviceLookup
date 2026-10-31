# Migrating from DeviceKit

Replace DeviceKit's enum cases with model identifiers and bundled data.

## Overview

DeviceLookup's ``Device`` has the same name as DeviceKit's and covers what most apps use it for: the device's name, chip and screen size, and whether it's a phone, pad or TV. Instead of an enum case per model, a device is its model identifier, so new devices need no new API.

| DeviceKit | DeviceLookup |
| --- | --- |
| `Device.identifier` | ``Device/machineIdentifier`` |
| `device.description` | ``Device/description`` |
| `device.cpu.description` | ``Device/chip`` |
| `device.diagonal` (-1 when unknown) | ``Device/diagonal`` (`nil` when unknown) |
| `device.isPhone`, `.isPad`, `.isPod` | ``Device/isPhone``, ``Device/isPad``, ``Device/isPod`` |
| `device.isSimulator` | ``Device/isSimulator`` |
| `device.realDevice` | not needed; ``Device/current`` already describes the simulated device |
| `device == .iPhone15Pro`, `device.isOneOf([...])` | compare ``Device/modelIdentifier`` |
| `device.name`, `.systemName`, `.model` | not provided; use `UIDevice` on the main actor |

### Checking for specific models

Where DeviceKit compares enum cases, keep a set of model identifiers, with a comment naming each one:

```swift
// DeviceKit
Device.current.isOneOf([.appleTVHD, .appleTV4K])

// DeviceLookup
let modelsWithoutLiquidGlass: Set<String> = [
    "AppleTV5,3", // Apple TV HD
    "AppleTV6,2", // Apple TV 4K (1st generation)
]
modelsWithoutLiquidGlass.contains(Device.current.modelIdentifier)
```

New devices never change the set's meaning, so no code needs updating when they ship. Compare identifiers rather than ``Device`` values: two devices are equal only when every property matches, so ``Device/current`` on a simulator never equals a device you looked up. To check for a family of devices rather than particular models, use ``Device/family``.

### Features without an equivalent

DeviceLookup leaves out per-model hardware facts that an Apple framework reports more accurately at runtime:

- Face ID or Touch ID: `LAContext().biometryType`.
- Dynamic Island, sensor housing and rounded corners: the safe area insets.
- Cameras and LiDAR: `AVCaptureDevice.DiscoverySession`.
- Screen ratio and pixel density: `UIScreen`.

It also leaves out state that `UIDevice`, `UIScreen` and `ProcessInfo` already provide, such as battery level, screen brightness, Low Power Mode, orientation and thermal state. Those change while the app runs, and the `UIDevice` and `UIScreen` ones need the main actor, so ``Device`` leaves them to those APIs and stays `Sendable`.
