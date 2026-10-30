# ``DeviceLookup``

Names, chips, screen sizes and families for Apple device model identifiers.

## Overview

DeviceLookup turns a hardware model identifier such as `iPhone18,1` into what people call the device, "iPhone 17 Pro", along with its chip, screen size and kind. It covers iPhone, iPad, iPod touch, Apple TV, Apple Watch and Mac.

```swift
import DeviceLookup

let device = Device.current
device.modelName          // "iPhone 17 Pro"
device.deviceDescription  // "iPhone 17 Pro, A19 Pro"
device.family             // .phone
device.diagonal           // 6.3

Device(modelIdentifier: "Watch7,18").modelName  // "Apple Watch Series 11 (GPS) 46mm"
Mac.find(model: "Mac14,7")?.name                // "MacBook Pro (13-inch, M2, 2022)"
```

The details are bundled data taken from Xcode's own device list, not code, so supporting a new device is a data update rather than new enum cases. A device that's newer than the data still resolves: its ``Device/family`` comes from the identifier prefix and its ``Device/modelName`` falls back to the identifier, so ``Device/isKnown`` tells you which you have.

``Device`` is `Sendable` and never reads `UIDevice`, so you can use it from any thread or actor. On a simulator, ``Device/current`` describes the simulated device, and under Mac Catalyst it describes the Mac rather than an iPad.

## Topics

### Looking Up a Device

- ``Device``
- ``Device/current``
- ``Device/init(modelIdentifier:)``
- ``Device/all``
- <doc:MigratingFromDeviceKit>

### Device Details

- ``Device/modelIdentifier``
- ``Device/modelName``
- ``Device/chip``
- ``Device/diagonal``
- ``Device/hasCellular``
- ``Device/description``
- ``Device/deviceDescription``
- ``Device/isKnown``
- ``Device/isSimulator``
- ``Device/machineIdentifier``

### Kinds of Device

- ``Device/Family``
- ``Device/family``
- ``Device/isPhone``
- ``Device/isPad``
- ``Device/isPod``
- ``Device/isTV``
- ``Device/isWatch``
- ``Device/isMac``

### Macs

- ``Mac``
- ``Device/mac``

### The Running System

- ``Device/operatingSystemName``
- ``Device/operatingSystemVersion``
- ``Device/operatingSystemVersionString``
- ``Device/physicalMemory``
- ``Device/processorCount``
- ``Device/systemUptime``
- ``Device/volumeTotalCapacity``
- ``Device/volumeAvailableCapacity``
- ``Device/volumeAvailableCapacityForImportantUsage``
- ``Device/volumeAvailableCapacityForOpportunisticUsage``
