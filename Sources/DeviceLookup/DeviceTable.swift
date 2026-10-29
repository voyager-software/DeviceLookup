//
//  DeviceTable.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

/// The bundled iPhone, iPad, iPod touch and Apple TV data, keyed by model identifier.
/// Maintained with `Scripts/update-devices.py`.
enum DeviceTable {
    struct Entry: Decodable, Sendable {
        enum CodingKeys: String, CodingKey {
            case name
            case chip
            case diagonal = "diag"
            case cellular = "cell"
        }

        let name: String
        let chip: String?
        let diagonal: Double?
        let cellular: Bool?
    }

    static let entries: [String: Entry] = {
        guard let url = Bundle.module.url(forResource: "devices", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [:] }
        return (try? JSONDecoder().decode([String: Entry].self, from: data)) ?? [:]
    }()

    static let sortedIdentifiers: [String] = entries.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
}
