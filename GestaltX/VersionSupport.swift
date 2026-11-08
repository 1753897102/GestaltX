// SPDX-License-Identifier: GPL-3.0-only
import Foundation

enum VersionSupport {
    // The upstream worse_query range describes the escape, not every capability.
    static func contains(_ version: OperatingSystemVersion) -> Bool {
        let value = (version.majorVersion, version.minorVersion, version.patchVersion)
        return (value >= (26, 0, 0) && value <= (26, 7, 2))
            || (value >= (27, 0, 0) && value <= (27, 2, 0))
    }
    static var current: Bool { contains(ProcessInfo.processInfo.operatingSystemVersion) }
    static var label: String { L(current ? "Supported" : "Unsupported") }
}
