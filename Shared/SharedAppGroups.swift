// SPDX-License-Identifier: GPL-3.0-only
import Foundation

// Uses LCSign's runtime entitlement reader in both processes. Re-signing must
// preserve at least one group shared by the app and its embedded extension.
enum SharedAppGroups {
    static var hostBundleIdentifier: String {
        let bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            let parent = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let identifier = Bundle(url: parent)?.bundleIdentifier { return identifier }
        }
        return bundle.bundleIdentifier ?? "com.huami.gestultx"
    }

    static var inboxes: [SharedPlistInbox] {
        GXEntitlementsReader.usableAppGroups().compactMap { group in
            guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }
            return try? SharedPlistInbox(container: container, namespace: hostBundleIdentifier)
        }
    }

    static func oldestEntry() throws -> (SharedPlistInbox, SharedPlistEntry)? {
        var pending: [(SharedPlistInbox, SharedPlistEntry)] = []
        for inbox in inboxes { pending.append(contentsOf: try inbox.entries().map { (inbox, $0) }) }
        return pending.min { $0.1.created < $1.1.created }
    }
}
