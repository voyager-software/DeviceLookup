//
//  DeviceTests.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

@testable import DeviceLookup
import Foundation
import Testing

struct DeviceTests {
    /// Devices in the data whose chip or diagonal has not been filled in yet. Fill them in and remove them here.
    static let awaitingData: Set<String> = []

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

    /// Xcode names most watches without a case size, so it's added by hand; see the README.
    /// Apple Watch Ultra comes in one size, so its name has none.
    @Test func `watch names have a case size`() {
        for device in Device.all where device.isWatch && !device.modelName.contains("Ultra") {
            #expect(device.modelName.hasSuffix("mm"), "\(device.modelIdentifier): \(device.modelName)")
        }
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
        ("VirtualMac2,1", .mac),
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
        #expect(Device(modelIdentifier: "iPhone18,1").mac == nil)
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

    @Test func `all is in identifier order`() throws {
        let identifiers = Device.all.map(\.modelIdentifier)
        let iPhone9 = try #require(identifiers.firstIndex(of: "iPhone9,1"))
        let iPhone10 = try #require(identifiers.firstIndex(of: "iPhone10,1"))
        #expect(iPhone9 < iPhone10)
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
        // A virtual machine isn't a Mac model, so it isn't in the data.
        if !device.modelIdentifier.hasPrefix("VirtualMac") {
            #expect(device.isKnown, "\(device.modelIdentifier) is missing from macs.json")
        }
        #expect(device.chip?.hasPrefix("Apple") == true)
        #expect(Device.operatingSystemName == "macOS")
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
        #expect(Device.physicalMemory > 0)
        #expect(Device.processorCount > 0)
        #expect((Device.volumeTotalCapacity ?? 0) > 0)
        #expect(!Device.operatingSystemVersionString.contains("Version"))
    }
}

struct MacTests {
    @Test func `find missing`() {
        #expect(Mac.find(model: "INVALID_MODEL") == nil)
    }

    @Test func `find name`() {
        #expect(Mac.find(model: "iMac21,2")?.name == "iMac (24-inch, M1, 2021)")
    }

    /// Apple reused some identifiers across models. The data lists the newest model first, and it wins.
    @Test(arguments: [
        ("MacBookPro15,1", "MacBook Pro (15-inch, 2019)"),
        ("MacBookAir7,2", "MacBook Air (13-inch, 2017)"),
        ("Mac14,8", "Mac Pro (2023)"),
    ])
    func `shared identifier names the newest model`(model: String, name: String) {
        #expect(Device(modelIdentifier: model).modelName == name)
    }

    @Test func `unrecognized kind decodes as unknown`() throws {
        let json = #"[{"kind": "Mac Something", "name": "Mac Something (M9, 2030)", "ids": ["Mac99,1"]}]"#
        let macs = try JSONDecoder().decode([Mac].self, from: Data(json.utf8))
        #expect(macs.first?.kind == .unknown)
    }

    /// `Device` looks a `.mac` identifier up only in the Mac data, and anything else only in the device data.
    @Test func `families match the data they are looked up in`() {
        for model in Mac.all.flatMap(\.modelIdentifiers) {
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

    /// Each entry is one identifier, e.g. "Macmini6,1", never several run together.
    @Test func `identifiers are well formed`() {
        for model in Mac.all.flatMap(\.modelIdentifiers) {
            #expect(model.wholeMatch(of: /[A-Za-z]+\d+,\d+/) != nil, "\(model)")
        }
        #expect(Device(modelIdentifier: "Macmini6,2").modelName == "Mac mini (Late 2012)")
    }
}
