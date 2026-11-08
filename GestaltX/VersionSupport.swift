// SPDX-License-Identifier: GPL-3.0-only
import Foundation

enum VersionSupport {
    // Supported OS versions; individual capabilities still depend on device access.
    static let range = "iOS 26.0–26.7.2 / 27.x"

    static func contains(_ version: OperatingSystemVersion) -> Bool {
        let value = (version.majorVersion, version.minorVersion, version.patchVersion)
        return (value >= (26, 0, 0) && value <= (26, 7, 2))
            || version.majorVersion == 27
    }
    static var current: Bool { contains(ProcessInfo.processInfo.operatingSystemVersion) }
    static var label: String { L(current ? "Supported" : "Unsupported") }
}
