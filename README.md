<p align="center"><img src="Assets/logo.png" width="128" height="128" alt="DeviceLookup logo"></p>

<h1 align="center">DeviceLookup</h1>

<p align="center">
  <a href="https://github.com/voyager-software/DeviceLookup/actions/workflows/ci.yml"><img src="https://github.com/voyager-software/DeviceLookup/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://swiftpackageindex.com/voyager-software/DeviceLookup"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvoyager-software%2FDeviceLookup%2Fbadge%3Ftype%3Dswift-versions" alt="Swift versions"></a>
  <a href="https://swiftpackageindex.com/voyager-software/DeviceLookup"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvoyager-software%2FDeviceLookup%2Fbadge%3Ftype%3Dplatforms" alt="Platforms"></a>
</p>

Names, release years, chips, screens and families for iPhone, iPad, iPod touch, Apple TV, Apple Watch, Apple Vision Pro and Mac model identifiers, plus the running device's OS, memory and storage details. Replaces DeviceKit and MacLookup.

- **Sendable.** `Device` never touches `UIDevice`, so you can use it from any thread or actor without hopping to the main actor.
- **Right where the kernel isn't.** On a simulator, under Mac Catalyst and in an iPhone or iPad app on a Mac, `Device.current` describes the actual model rather than "arm64" or a stand-in iPad.
- **Data, not code.** Details come from Xcode's device list and simulators and Apple's Mac pages, updated weekly. A device newer than the data still gets the right family.
- **Offline.** The data ships inside the package, and DeviceLookup never goes online.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/voyager-software/DeviceLookup.git", from: "2026.11.1"),
]
```

Requires Swift 6 (Xcode 16 or later) and iOS 15, tvOS 15, watchOS 9, visionOS 1, macOS 12 or Mac Catalyst 15.

## Usage

### The current device

```swift
import DeviceLookup

let device = Device.current
device.modelName          // "iPhone 17 Pro"
device.deviceDescription  // "iPhone 17 Pro, A19 Pro"
device.isSimulator        // false
device.screen?.width      // 402 (see Screens)
device.mac?.family        // nil on an iPhone; .macBookPro on a MacBook Pro (see Macs)
```

`Device.current` is an ordinary `Device`, so everything in the sections below works on it as well as on a looked-up identifier. On a simulator, it's the simulated device. Under Mac Catalyst and in an iPhone or iPad app on a Mac, it's the Mac, e.g. "MacBook Pro (14-inch, Nov 2023), Apple M3 Pro".

### Any model identifier

Lookups work for every family on every platform, so an iPhone app can name a paired watch or an identifier from your server.

```swift
let device = Device(modelIdentifier: "iPhone18,1")
device.modelName    // "iPhone 17 Pro"
device.family       // .phone (raw value "phone", for analytics)
device.year         // 2025
device.chip         // "A19 Pro"
device.hasCellular  // true

Device(modelIdentifier: "Watch7,18").modelName  // "Apple Watch Series 11 (GPS) 46mm"
Device(modelIdentifier: "iPhone99,1").family    // .phone, named "iPhone99,1", with isKnown false
```

### Screens

```swift
let device = Device(modelIdentifier: "iPhone18,1")
device.screen?.diagonal      // 6.3 (inches)
device.screen?.width         // 402 (points, portrait)
device.screen?.height        // 874
device.screen?.scale         // 3
device.screen?.cornerRadius  // 62 (points)
device.hasDynamicIsland      // true
```

A foldable's screen is its larger, inner display. Apple TV, Apple Vision Pro, Macs and unknown identifiers have no `screen`.

### Macs

```swift
let mac = Device(modelIdentifier: "Mac14,7").mac
mac?.name    // "MacBook Pro (13-inch, M2, 2022)"
mac?.family  // .macBookPro
mac?.year    // 2022
```

`Mac.all` lists every Mac, newest first within each family. An identifier Apple reused across models gives the newest of them.

### The running system

These are static, since they describe the device the code runs on rather than a looked-up one.

```swift
Device.operatingSystemName           // "iOS"
Device.operatingSystemVersionString  // "26.1 (23B85)"
Device.physicalMemory                // 8589934592 (bytes)
Device.volumeAvailableCapacity       // free space in bytes
```

## Coming from DeviceKit

| DeviceKit | DeviceLookup |
| --- | --- |
| `Device.identifier` | `Device.machineIdentifier` |
| `device.description` | `device.description` |
| `device.cpu.description` | `device.chip` |
| `device.diagonal` (-1 when unknown) | `device.screen?.diagonal` (`nil` when unknown) |
| `device.hasDynamicIsland` | `device.hasDynamicIsland` |
| `device.isOneOf([.appleTVHD, ...])` | compare `device.modelIdentifier` |
| `device.name`, `.systemName`, `.model` (`UIDevice`) | not provided; use `UIDevice` on the main actor |

The [migration guide](Sources/DeviceLookup/DeviceLookup.docc/MigratingFromDeviceKit.md) covers the rest: checking for specific models without enum cases, and the runtime APIs to use for features DeviceLookup leaves out, such as Face ID and cameras.

## Keeping the data current

DeviceLookup is maintained by [Voyager Software](https://github.com/voyager-software) and used in its own shipping apps, including PocketLion, so new devices matter to us as much as to you.

New devices are added once the Xcode release that supports them is out, which is usually around the announcement. A weekly workflow checks the newest Xcode on GitHub's runners, betas included, its simulators, and Apple's Mac identification pages, and opens a pull request when they list devices that aren't in the data yet. The aim is a release within a week. If a device is missing, [open an issue](https://github.com/voyager-software/DeviceLookup/issues) with its model identifier. Until it's added, the device still gets the right `family`, and its `modelName` is the identifier.

Because the data ships inside the package, lookups are synchronous and give the same answer offline and on first launch, nothing about your users is sent anywhere, and a shipped build behaves the same for as long as it's in use. If you need names for hardware newer than an app build, in analytics for example, record the `modelIdentifier` and map it to a name on your server.

[CONTRIBUTING.md](CONTRIBUTING.md) explains how the data is updated.

## License

MIT. See [LICENSE](LICENSE). The chip and screen-diagonal values were first imported from [DeviceKit](https://github.com/devicekit/DeviceKit), whose license is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
