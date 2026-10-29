//
//  Family.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-28.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

public extension Device {
    /// The kind of device. The raw value is a short lowercase name suitable for analytics, e.g. "phone".
    enum Family: String, Sendable, CaseIterable {
        case phone
        case pad
        case pod
        case tv
        case watch
        case mac
        case vision
        case unknown

        // MARK: Lifecycle

        /// Derives the family from the identifier prefix, so devices newer than the bundled data still resolve.
        public init(modelIdentifier: String) {
            self = switch modelIdentifier {
            case let id where id.hasPrefix("iPhone"):
                .phone
            case let id where id.hasPrefix("iPad"):
                .pad
            case let id where id.hasPrefix("iPod"):
                .pod
            case let id where id.hasPrefix("AppleTV"):
                .tv
            case let id where id.hasPrefix("Watch"):
                .watch
            case let id where id.hasPrefix("Mac") || id.hasPrefix("iMac"):
                .mac
            case let id where id.hasPrefix("RealityDevice"):
                .vision
            default:
                .unknown
            }
        }
    }
}
