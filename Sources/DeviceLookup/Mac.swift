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
    public let models: [String]

    // MARK: Internal

    /// Finds the Mac with the given model identifier, e.g. "Mac14,7". Public lookups go through `Device.mac`.
    static func find(model: String) -> Mac? {
        self.byModel[model]
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case kind
        case name
        case models = "ids"
    }

    private static let byModel: [String: Mac] = all.reduce(into: [:]) { result, mac in
        for model in mac.models where result[model] == nil {
            result[model] = mac
        }
    }
}
