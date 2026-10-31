//
//  Mac.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2022-01-02.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

/// A Mac model and every model identifier it shipped with.
public struct Mac: Decodable, Sendable {
    // MARK: Public

    /// The product line, e.g. MacBook Pro. The raw value is Apple's name for it, e.g. "MacBook Pro".
    public enum Family: String, Decodable, Sendable {
        case
            unknown = "",
            iMac = "iMac",
            iMacPro = "iMac Pro",
            macBook = "MacBook",
            macBookAir = "MacBook Air",
            macBookPro = "MacBook Pro",
            macMini = "Mac mini",
            macPro = "Mac Pro",
            macProServer = "Mac Pro Server",
            macStudio = "Mac Studio"

        // MARK: Lifecycle

        /// Decodes a family newer than this enum as `.unknown`, so one new family doesn't fail the whole Mac data.
        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Family(rawValue: rawValue) ?? .unknown
        }

        // MARK: Public

        /// Apple's name for the product line, e.g. "MacBook Pro".
        public var name: String {
            self.rawValue
        }
    }

    /// Every Mac in the bundled data, newest first within each family.
    public static let all: [Mac] = {
        guard let url = Bundle.module.url(forResource: "macs", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([Mac].self, from: data)) ?? []
    }()

    /// The product line, e.g. `.macBookPro`.
    public let family: Family

    /// The model name as Apple gives it, e.g. "MacBook Pro (14-inch, M5, 2025)".
    public let name: String

    /// The model identifiers this Mac shipped with, e.g. ["Mac14,7"].
    public let modelIdentifiers: [String]

    // MARK: Internal

    /// Finds the Mac with the given model identifier, e.g. "Mac14,7". Public lookups go through `Device.mac`.
    static func find(model: String) -> Mac? {
        self.byModel[model]
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case family
        case name
        case modelIdentifiers = "ids"
    }

    private static let byModel: [String: Mac] = all.reduce(into: [:]) { result, mac in
        for model in mac.modelIdentifiers where result[model] == nil {
            result[model] = mac
        }
    }
}
