//
//  Device.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

/// An Apple device, identified by its hardware model identifier (e.g. "iPhone18,1", "Mac15,6").
///
/// Model details come from bundled data rather than code, so a device missing from the data still
/// resolves: its ``family`` is derived from the identifier and ``modelName`` falls back to the identifier.
public struct Device: Hashable, Sendable, CustomStringConvertible {
    // MARK: Lifecycle

    /// Looks up a device by its hardware model identifier.
    public init(modelIdentifier: String) {
        self.init(modelIdentifier: modelIdentifier, isSimulator: false, chip: nil)
    }

    private init(modelIdentifier: String, isSimulator: Bool, chip: String?) {
        self.modelIdentifier = modelIdentifier
        self.family = Family(modelIdentifier: modelIdentifier)
        self.isSimulator = isSimulator

        // Only look in the data that can hold this family, so each platform decodes one file.
        let lookInDevices = self.family != .mac
        let lookInMacs = self.family == .mac || self.family == .unknown

        if lookInDevices, let entry = DeviceTable.entries[modelIdentifier] {
            self.isKnown = true
            self.modelName = entry.name
            self.chip = chip ?? entry.chip
            self.diagonal = entry.diagonal
            self.hasCellular = self.family == .phone || entry.cellular == true
        }
        else if lookInMacs, let mac = Mac.find(model: modelIdentifier) {
            self.isKnown = true
            self.modelName = mac.name
            self.chip = chip
            self.diagonal = nil
            self.hasCellular = false
        }
        else {
            self.isKnown = false
            self.modelName = modelIdentifier
            self.chip = chip
            self.diagonal = nil
            self.hasCellular = self.family == .phone
        }
    }

    // MARK: Public

    /// The device this process is running on. On a simulator, this is the simulated device.
    public static let current: Device = {
        #if os(macOS) || targetEnvironment(macCatalyst)
        Device(
            modelIdentifier: MacHardware.modelIdentifier ?? Self.machineIdentifier,
            isSimulator: false,
            chip: MacHardware.cpuBrand
        )
        #elseif targetEnvironment(simulator)
        Device(
            modelIdentifier: ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? Self.machineIdentifier,
            isSimulator: true,
            chip: nil
        )
        #else
        Device(modelIdentifier: Self.machineIdentifier, isSimulator: false, chip: nil)
        #endif
    }()

    /// The raw machine name reported by the kernel, e.g. "iPhone18,1", or "arm64" on a simulator and under Mac Catalyst.
    public static let machineIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }()

    /// Every iPhone, iPad, iPod touch, Apple TV and Apple Watch in the bundled data, in identifier order.
    /// For Macs, see ``Mac/all``.
    public static var all: [Device] {
        DeviceTable.sortedIdentifiers.map(Device.init(modelIdentifier:))
    }

    /// The hardware model identifier, e.g. "iPhone18,1". On a simulator, the identifier of the simulated device.
    public let modelIdentifier: String

    /// The kind of device, derived from the model identifier.
    public let family: Family

    /// The marketing name, e.g. "iPhone 17 Pro" or "Apple Watch Series 11 (GPS) 46mm", or the model identifier
    /// when the device is not in the bundled data.
    public let modelName: String

    /// The chip, e.g. "A19 Pro". On a Mac, the CPU brand string of the running Mac, e.g. "Apple M3 Pro".
    public let chip: String?

    /// The screen diagonal in inches, when known. For a foldable such as iPhone Duo, the inner display's.
    public let diagonal: Double?

    /// Whether the device has a cellular radio. Every iPhone does; only cellular iPad and Apple Watch models do.
    public let hasCellular: Bool

    /// Whether this is a simulator, in which case the other properties describe the simulated device.
    public let isSimulator: Bool

    /// Whether the device was found in the bundled data. An unknown device has a ``family`` but no details.
    public let isKnown: Bool

    public var isPhone: Bool {
        self.family == .phone
    }

    public var isPad: Bool {
        self.family == .pad
    }

    public var isPod: Bool {
        self.family == .pod
    }

    public var isTV: Bool {
        self.family == .tv
    }

    public var isWatch: Bool {
        self.family == .watch
    }

    public var isMac: Bool {
        self.family == .mac
    }

    /// The Mac details, when this device is a known Mac. An identifier Apple reused across models, such as
    /// "MacBookPro15,1" for the 2018 and 2019 15-inch MacBook Pro, gives the newest of them.
    public var mac: Mac? {
        // Checking the family first keeps other platforms from decoding the Mac data.
        self.isMac ? Mac.find(model: self.modelIdentifier) : nil
    }

    /// The marketing name, e.g. "iPhone 17 Pro", or "Simulator (iPhone 17 Pro)" on a simulator.
    public var description: String {
        self.isSimulator ? "Simulator (\(self.modelName))" : self.modelName
    }

    /// The description followed by the chip when known, e.g. "iPhone 17 Pro, A19 Pro".
    public var deviceDescription: String {
        guard let chip else { return self.description }
        return "\(self.description), \(chip)"
    }
}
