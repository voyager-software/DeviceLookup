# ``DeviceLookup``

Names, chips, screen sizes and families for Apple device model identifiers.

## Overview

DeviceLookup turns a hardware model identifier such as `iPhone18,1` into what people call the device, "iPhone 17 Pro", along with its release year, chip, screen size and family. It covers iPhone, iPad, iPod touch, Apple TV, Apple Watch, Apple Vision Pro and Mac.

``Device`` is `Sendable` and never touches `UIDevice`, so you can use it from any thread or actor without hopping to the main actor.

```swift
import DeviceLookup

let device = Device.current
device.modelName          // "iPhone 17 Pro"
device.deviceDescription  // "iPhone 17 Pro, A19 Pro"
device.year               // 2025
device.family             // .phone
device.diagonal           // 6.3

Device(modelIdentifier: "Watch7,18").modelName  // "Apple Watch Series 11 (GPS) 46mm"
Device(modelIdentifier: "Mac14,7").modelName    // "MacBook Pro (13-inch, M2, 2022)"
Device(modelIdentifier: "Mac14,7").mac?.family  // .macBookPro
```

The details are bundled data taken from Xcode's own device list and Apple's Mac identification pages, not code, so supporting a new device is a data update rather than new enum cases. A device that's newer than the data still resolves: its ``Device/family`` comes from the identifier prefix and its ``Device/modelName`` falls back to the identifier, so ``Device/isKnown`` tells you which you have.

The data ships inside the package, and DeviceLookup never goes online. Lookups are synchronous and give the same answer offline and on first launch, nothing about your users is sent anywhere, and a shipped build behaves the same for as long as it's in use. New devices arrive with a package release. If you need names for hardware newer than an app build, in analytics for example, record ``Device/modelIdentifier`` and map it to a name on your server.

On a simulator, ``Device/current`` describes the simulated device. Under Mac Catalyst, and in an iPhone or iPad app running on a Mac, it describes the Mac rather than an iPad.

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
- ``Device/year``
- ``Device/diagonal``
- ``Device/screen``
- ``Device/Screen``
- ``Device/hasCellular``
- ``Device/description``
- ``Device/deviceDescription``
- ``Device/isKnown``
- ``Device/isSimulator``
- ``Device/machineIdentifier``

### Device Families

- ``Device/Family``
- ``Device/family``
- ``Device/isPhone``
- ``Device/isPad``
- ``Device/isPod``
- ``Device/isTV``
- ``Device/isWatch``
- ``Device/isMac``
- ``Device/isVision``

### Macs

- ``Mac``
- ``Device/mac``
- ``Mac/all``
- ``Mac/Family``

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
