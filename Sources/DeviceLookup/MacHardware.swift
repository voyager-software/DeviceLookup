//
//  MacHardware.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2022-01-02.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

#if os(macOS) || os(iOS)
import Foundation
#if os(macOS) || targetEnvironment(macCatalyst)
import IOKit
#endif

/// Reads the running Mac's hardware details, which Mac Catalyst hides behind the CPU architecture and an iPhone
/// or iPad app on a Mac behind a stand-in iPad.
enum MacHardware {
    #if os(macOS) || targetEnvironment(macCatalyst)
    /// The hardware model identifier from the I/O Registry, e.g. "MacBookPro18,3".
    static let modelIdentifier: String? = {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }

        guard let property = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0),
              let data = property.takeRetainedValue() as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
    }()

    /// The CPU brand string, e.g. "Apple M3 Pro". An iPhone or iPad app on a Mac can't read it.
    static let cpuBrand: String? = Self.sysctlString("machdep.cpu.brand_string")
    #else
    /// The hardware model identifier for an iPhone or iPad app on a Mac, which has no I/O Registry, e.g. "Mac16,5".
    static let modelIdentifier: String? = Self.sysctlString("hw.model")
    #endif

    private static func sysctlString(_ key: String) -> String? {
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer, encoding: .utf8)
    }
}
#endif
