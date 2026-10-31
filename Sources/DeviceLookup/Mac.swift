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

    public enum Kind: String, Decodable, Sendable {
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

        /// Decodes a kind newer than this enum as `.unknown`, so one new kind doesn't fail the whole Mac data.
        public init(from decoder: Decoder) throws {
            let rawValue = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: rawValue) ?? .unknown
        }

        // MARK: Public

        public var name: String {
            self.rawValue
        }
    }

    /// Every Mac in the bundled data.
    public static let all: [Mac] = {
        guard let url = Bundle.module.url(forResource: "all-macs", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([Mac].self, from: data)) ?? []
    }()

    public let kind: Kind
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
        case kind
        case name
        case modelIdentifiers = "ids"
    }

    private static let byModel: [String: Mac] = all.reduce(into: [:]) { result, mac in
        for model in mac.modelIdentifiers where result[model] == nil {
            result[model] = mac
        }
    }
}
