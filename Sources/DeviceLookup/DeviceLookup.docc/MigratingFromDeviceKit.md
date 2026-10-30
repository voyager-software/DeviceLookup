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

### Features without an equivalent

DeviceLookup leaves out per-model hardware facts that an Apple framework reports more accurately at runtime:

- Face ID or Touch ID: `LAContext().biometryType`.
- Dynamic Island, sensor housing and rounded corners: the safe area insets.
- Cameras and LiDAR: `AVCaptureDevice.DiscoverySession`.
- Screen ratio and pixel density: `UIScreen`.

It also leaves out state that `UIDevice`, `UIScreen` and `ProcessInfo` already provide, such as battery level, screen brightness, Low Power Mode, orientation and thermal state. Those need the main actor, and ``Device`` stays `Sendable` by not reading them.
