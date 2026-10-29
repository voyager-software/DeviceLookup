//
//  MacHardware.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2022-01-02.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

#if os(macOS) || targetEnvironment(macCatalyst)
import Foundation
import IOKit

/// Reads the running Mac's hardware details, which Mac Catalyst hides behind the CPU architecture.
enum MacHardware {
    /// The hardware model identifier from the I/O Registry, e.g. "MacBookPro18,3".
    static let modelIdentifier: String? = {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }

        guard let property = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0),
              let data = property.takeRetainedValue() as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
    }()

    /// The CPU brand string, e.g. "Apple M3 Pro".
    static let cpuBrand: String? = {
        let key = "machdep.cpu.brand_string"
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer, encoding: .utf8)
    }()
}
#endif
