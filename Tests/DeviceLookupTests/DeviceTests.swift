//
//  DeviceTests.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

@testable import DeviceLookup
import Testing

struct DeviceTests {
    /// Devices in the data whose chip or diagonal has not been filled in yet. Fill them in and remove them here.
    static let awaitingData: Set<String> = ["iPhone19,4"]

    @Test func `known phone`() {
        let device = Device(modelIdentifier: "iPhone18,1")
        #expect(device.isKnown)
        #expect(device.isPhone)
        #expect(device.modelName == "iPhone 17 Pro")
        #expect(device.chip == "A19 Pro")
        #expect(device.diagonal == 6.3)
        #expect(device.hasCellular)
        #expect(device.deviceDescription == "iPhone 17 Pro, A19 Pro")
    }

    @Test func `unknown device still has family`() {
        let device = Device(modelIdentifier: "iPhone99,1")
        #expect(!device.isKnown)
        #expect(device.family == .phone)
        #expect(device.modelName == "iPhone99,1")
        #expect(device.chip == nil)
        #expect(device.diagonal == nil)
        #expect(device.hasCellular)
        #expect(device.deviceDescription == "iPhone99,1")
    }

    @Test func `pad cellular`() {
        #expect(!Device(modelIdentifier: "iPad16,3").hasCellular)
        #expect(Device(modelIdentifier: "iPad16,4").hasCellular)
    }

    @Test func `apple TV`() {
        let device = Device(modelIdentifier: "AppleTV5,3")
        #expect(device.isTV)
        #expect(device.modelName == "Apple TV HD")
        #expect(!device.hasCellular)
    }

    @Test func watch() {
        let device = Device(modelIdentifier: "Watch7,20")
        #expect(device.isWatch)
        #expect(device.modelName == "Apple Watch Series 11 (GPS + Cellular) 46mm")
        #expect(device.chip == "S10")
        #expect(device.hasCellular)
        #expect(!Device(modelIdentifier: "Watch7,18").hasCellular)
    }

    /// Xcode's board names, not DeviceKit, decide the case size: DeviceKit has the SE 3 sizes swapped.
    @Test func `watch case sizes`() {
        #expect(Device(modelIdentifier: "Watch7,13").modelName == "Apple Watch SE 3 (GPS) 40mm")
        #expect(Device(modelIdentifier: "Watch7,14").modelName == "Apple Watch SE 3 (GPS) 44mm")
        #expect(Device(modelIdentifier: "Watch7,15").modelName == "Apple Watch SE 3 (GPS + Cellular) 40mm")
    }

    @Test(arguments: [
        ("iPhone1,1", Device.Family.phone),
        ("iPad17,3", .pad),
        ("iPod9,1", .pod),
        ("AppleTV14,1", .tv),
        ("Watch8,1", .watch),
        ("Mac15,6", .mac),
        ("MacBookPro18,3", .mac),
        ("iMac21,2", .mac),
        ("Macmini9,1", .mac),
        ("RealityDevice14,1", .vision),
        ("arm64", .unknown),
    ])
    func family(identifier: String, family: Device.Family) {
        #expect(Device.Family(modelIdentifier: identifier) == family)
    }

    @Test func mac() {
        let device = Device(modelIdentifier: "Mac14,7")
        #expect(device.isKnown)
        #expect(device.isMac)
        #expect(device.modelName == "MacBook Pro (13-inch, M2, 2022)")
        #expect(device.mac?.kind == .macBookPro)
    }

    @Test func `all devices have data`() {
        let all = Device.all
        #expect(all.count > 150)

        for device in all {
            #expect(device.family != .unknown, "\(device.modelIdentifier)")
            #expect(!device.modelName.isEmpty, "\(device.modelIdentifier)")
            guard !Self.awaitingData.contains(device.modelIdentifier) else { continue }
            #expect(device.chip != nil, "\(device.modelIdentifier) has no chip")
            if !device.isTV {
                #expect(device.diagonal != nil, "\(device.modelIdentifier) has no diagonal")
            }
        }
    }

    @Test func `awaiting data is still missing`() {
        for identifier in Self.awaitingData {
            let device = Device(modelIdentifier: identifier)
            #expect(device.chip == nil || device.diagonal == nil, "\(identifier) is complete; remove it from awaitingData")
        }
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    @Test func `current mac`() {
        let device = Device.current
        #expect(device.isMac)
        #expect(device.isKnown, "\(device.modelIdentifier) is missing from all-macs.json")
        #expect(device.chip?.hasPrefix("Apple") == true)
        #expect(device.operatingSystemName == "macOS")
    }
    #endif

    #if targetEnvironment(simulator)
    @Test func `current simulator`() {
        let device = Device.current
        #expect(device.isSimulator)
        #expect(device.isKnown, "\(device.modelIdentifier) is missing from devices.json")
        #expect(device.description == "Simulator (\(device.modelName))")
        #expect(Device.machineIdentifier == "arm64")
    }
    #endif

    @Test func system() {
        let device = Device.current
        #expect(device.physicalMemory > 0)
        #expect(device.processorCount > 0)
        #expect((device.volumeTotalCapacity ?? 0) > 0)
        #expect(!device.operatingSystemVersionString.contains("Version"))
    }
}

struct MacTests {
    @Test func `find missing`() {
        #expect(Mac.find(model: "INVALID_MODEL") == nil)
    }

    @Test func `find name`() {
        #expect(Mac.find(model: "iMac21,2")?.name == "iMac (24-inch, M1, 2021)")
    }

    /// `Device` looks a `.mac` identifier up only in the Mac data, and anything else only in the device data.
    @Test func `families match the data they are looked up in`() {
        for model in Mac.all.flatMap(\.models) {
            #expect(Device.Family(modelIdentifier: model) == .mac, "\(model)")
        }
        for identifier in DeviceTable.entries.keys {
            #expect(Device.Family(modelIdentifier: identifier) != .mac, "\(identifier)")
        }
    }

    @Test func `no unknown kinds`() {
        #expect(!Mac.all.isEmpty)
        #expect(Mac.all.allSatisfy { $0.kind != .unknown })
    }
}
