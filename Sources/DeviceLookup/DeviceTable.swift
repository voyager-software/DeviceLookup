//
//  DeviceTable.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

/// The bundled iPhone, iPad, iPod touch, Apple TV, Apple Watch and Apple Vision Pro data, keyed by model identifier.
/// Maintained with `Scripts/update-devices.py`.
enum DeviceTable {
    struct Entry: Decodable, Sendable {
        enum CodingKeys: String, CodingKey {
            case name
            case year
            case chip
            case cellular = "cell"
            case dynamicIsland = "island"
            case screen
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.year = try container.decodeIfPresent(Int.self, forKey: .year)
            self.chip = try container.decodeIfPresent(String.self, forKey: .chip)
            self.cellular = try container.decodeIfPresent(Bool.self, forKey: .cellular)
            self.dynamicIsland = try container.decodeIfPresent(Bool.self, forKey: .dynamicIsland)
            // A new device's screen comes from the simulator before its diagonal is filled in by hand. Until then it
            // has no screen, rather than failing the whole table.
            self.screen = try? container.decodeIfPresent(Device.Screen.self, forKey: .screen)
        }

        let name: String
        let year: Int?
        let chip: String?
        let cellular: Bool?
        let dynamicIsland: Bool?
        let screen: Device.Screen?
    }

    static let entries: [String: Entry] = {
        guard let url = Bundle.module.url(forResource: "devices", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [:] }
        return (try? JSONDecoder().decode([String: Entry].self, from: data)) ?? [:]
    }()

    static let sortedIdentifiers: [String] = entries.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
}
