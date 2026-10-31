//
//  Device+System.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

// Details of the running system. These are static because they read the process's own
// environment, so they describe the device this code runs on, not a looked-up `Device`.

public extension Device {
    /// "iOS", "iPadOS", "tvOS", "watchOS", "visionOS" or "macOS" (also under Mac Catalyst).
    static var operatingSystemName: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        "macOS"
        #elseif os(tvOS)
        "tvOS"
        #elseif os(watchOS)
        "watchOS"
        #elseif os(visionOS)
        "visionOS"
        #else
        Self.current.isPad ? "iPadOS" : "iOS"
        #endif
    }

    static var operatingSystemVersion: OperatingSystemVersion {
        ProcessInfo.processInfo.operatingSystemVersion
    }

    /// The version and build, e.g. "26.1 (23B85)".
    static var operatingSystemVersionString: String {
        ProcessInfo.processInfo.operatingSystemVersionString
            .replacingOccurrences(of: "Version ", with: "")
            .replacingOccurrences(of: "Build ", with: "")
    }
}

public extension Device {
    static var physicalMemory: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    static var processorCount: Int {
        ProcessInfo.processInfo.processorCount
    }

    static var systemUptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

public extension Device {
    /// The volume’s total capacity in bytes.
    static var volumeTotalCapacity: Int64? {
        Self.homeVolumeValues(.volumeTotalCapacityKey)?.volumeTotalCapacity.map(Int64.init)
    }

    /// The volume’s available capacity in bytes.
    static var volumeAvailableCapacity: Int64? {
        Self.homeVolumeValues(.volumeAvailableCapacityKey)?.volumeAvailableCapacity.map(Int64.init)
    }

    #if !os(tvOS) && !os(watchOS)
    /// The volume’s available capacity in bytes for storing important resources.
    static var volumeAvailableCapacityForImportantUsage: Int64? {
        Self.homeVolumeValues(.volumeAvailableCapacityForImportantUsageKey)?.volumeAvailableCapacityForImportantUsage
    }

    /// The volume’s available capacity in bytes for storing nonessential resources.
    static var volumeAvailableCapacityForOpportunisticUsage: Int64? {
        Self.homeVolumeValues(.volumeAvailableCapacityForOpportunisticUsageKey)?.volumeAvailableCapacityForOpportunisticUsage
    }
    #endif

    private static func homeVolumeValues(_ key: URLResourceKey) -> URLResourceValues? {
        try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [key])
    }
}
