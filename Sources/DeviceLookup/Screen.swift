//
//  Screen.swift
//  DeviceLookup
//
//  Created by Gabor Shaio on 2026-10-31.
//  Copyright © 2026 Voyager Software Inc. All rights reserved.
//

import Foundation

public extension Device {
    /// A device's main screen, as apps see it: its largest built-in display, so for a foldable such as iPhone Duo,
    /// the inner one.
    struct Screen: Hashable, Sendable, Decodable {
        // MARK: Lifecycle

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.diagonal = try container.decode(Double.self, forKey: .diagonal)
            self.width = try container.decode(Int.self, forKey: .width)
            self.height = try container.decode(Int.self, forKey: .height)
            self.scale = try container.decode(Int.self, forKey: .scale)
            self.cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 0
        }

        init(diagonal: Double, width: Int, height: Int, scale: Int, cornerRadius: Double = 0) {
            self.diagonal = diagonal
            self.width = width
            self.height = height
            self.scale = scale
            self.cornerRadius = cornerRadius
        }

        // MARK: Public

        /// The diagonal in inches, e.g. 6.3.
        public let diagonal: Double

        /// The width in points, in portrait, e.g. 402.
        public let width: Int

        /// The height in points, in portrait, e.g. 874.
        public let height: Int

        /// The points-to-pixels scale, e.g. 3. Width and height times the scale give the size apps render at,
        /// which on iPhone 6 Plus through 8 Plus is downsampled to fit the panel.
        public let scale: Int

        /// The radius of the display's rounded corners in points, e.g. 62, or 0 for square corners.
        public let cornerRadius: Double

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case diagonal = "diag"
            case width = "w"
            case height = "h"
            case scale
            case cornerRadius = "corner"
        }
    }
}
