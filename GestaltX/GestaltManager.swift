// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 huamidev
import Foundation
import SwiftUI
import Combine

@MainActor
final class GestaltManager: ObservableObject {
    @Published private(set) var snapshot: DocumentSnapshot?
    @Published private(set) var working: GestaltDocument?
    @Published private(set) var isBusy = false
    @Published private(set) var status = "Connect to your device or open a plist."
    @Published private(set) var deviceAccessible = false
    @Published private(set) var backups: [BackupRecord] = []
    @Published private(set) var logs: [String] = []
    @Published var message: String?
    @Published var isRespringing = false
    @Published var needsRespring = false
    @Published var choices: [String: PresetChoice] = [:]
    @Published var regionID = "keep"
    @Published var changesName = false
    @Published var modelName = ""
    @Published var subtype = 0
    private let files: GestaltFileStore
    private var exploitLogObserver: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        let deviceID = defaults.string(forKey: "GestaltX.installationID") ?? UUID().uuidString
        defaults.set(deviceID, forKey: "GestaltX.installationID")
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GestaltX/Backups", isDirectory: true)
        files = GestaltFileStore(deviceURL: URL(fileURLWithPath: GestaltKeys.devicePath), backupDirectory: directory,
                                deviceID: deviceID, acquire: {
            #if targetEnvironment(simulator)
            throw GestaltFailure("Device access is unavailable in the Simulator. Open a plist to explore GestaltX.")
            #else
            guard let signedGroup = GXEntitlementsReader.usableAppGroup() else {
                throw GestaltFailure("The signed app has no usable App Group. Enable its App Group capability and sign it again.")
            }
            let handle = worse_query((GestaltKeys.devicePath as NSString).deletingLastPathComponent,
                                     signedGroup, false, false)
            guard handle >= 0 else {
                if handle == -1 { throw GestaltFailure("The signed app has no usable App Group. Enable its App Group capability and sign it again.") }
                throw GestaltFailure("MobileGestalt access was denied. Check the OS version and App Group signing.")
            }
            return handle
            #endif
        }, release: { worse_query_release($0) }, eventSink: { text in
            NotificationCenter.default.post(name: Notification.Name("GestaltX.worse_query.log"), object: nil,
                                            userInfo: ["message": text])
        })
        exploitLogObserver = NotificationCenter.default.addObserver(forName: Notification.Name("GestaltX.worse_query.log"), object: nil, queue: nil) { [weak self] notification in
            guard let text = notification.userInfo?["message"] as? String else { return }
            DispatchQueue.main.async { [weak self] in self?.log("[worse_query] " + text) }
        }
    }

    deinit { if let exploitLogObserver { NotificationCenter.default.removeObserver(exploitLogObserver) } }

    var changeKeys: [String] {
        guard let before = snapshot?.document.extra, let after = preview?.extra else { return [] }
        return Set(before.keys).union(after.keys).filter { key in
            switch (before[key], after[key]) {
            case (nil, nil): return false
            case (nil, _), (_, nil): return true
            case (let a?, let b?): return !GestaltDocument.valuesEqual(a, b)
            }
        }.sorted()
    }
    var changeCount: Int { changeKeys.count }
    var hasDocument: Bool { snapshot != nil }
    var sourceIsDevice: Bool { snapshot?.source == .device }
    var displayedName: String {
        working?.artwork["ArtworkDeviceProductDescription"] as? String ?? working?.extra["Z/dqyWS6OZTRy10UcmUAhw"] as? String ?? UIDevice.current.model
    }
    var preview: GestaltDocument? {
        guard var doc = working else { return nil }
        for capability in Capability.all {
            let choice = choices[capability.id] ?? .keep
            guard choice != .keep else { continue }
            for key in capability.keys { doc.set(choice == .enable ? capability.enabled : capability.disabled, for: key) }
        }
        if subtype != 0 {
            doc.setArtwork(NSNumber(value: subtype), for: "ArtworkDeviceSubType")
            doc.set(NSNumber(value: true), for: "YlEtTtHlNesRBMal1CqRaA")
        }
        if changesName {
            doc.setArtwork(modelName.trimmingCharacters(in: .whitespacesAndNewlines), for: "ArtworkDeviceProductDescription")
            doc.set(modelName.trimmingCharacters(in: .whitespacesAndNewlines), for: "Z/dqyWS6OZTRy10UcmUAhw")
            doc.set(modelName.trimmingCharacters(in: .whitespacesAndNewlines), for: "bbtR9jQx50Fv5Af/affNtA")
        }
        if let region = RegionPreset.all.first(where: { $0.id == regionID }), region.id != "keep" {
            doc.set(region.code, for: GestaltKeys.regionCode)
            // Choose the key that the loaded OS actually uses; update both only if both exist.
            let present = [GestaltKeys.regionInfo, GestaltKeys.legacyRegionInfo].filter { doc.extra[$0] != nil }
            for key in present.isEmpty ? [GestaltKeys.regionInfo] : present { doc.set(region.info, for: key) }
        }
        return doc
    }

    private func log(_ text: String) {
        let time = Date.now.formatted(date: .omitted, time: .standard)
        logs.append("[\(time)] \(text)")
        if logs.count > 1000 { logs.removeFirst(logs.count - 1000) }
    }
    private func failed(_ error: Error) { message = error.localizedDescription; log(error.localizedDescription) }
    private func accept(_ loaded: DocumentSnapshot) {
        snapshot = loaded; working = loaded.document
        choices = [:]; regionID = "keep"; changesName = false; subtype = 0
        modelName = loaded.document.artwork["ArtworkDeviceProductDescription"] as? String ?? ""
    }
    func clearStaged() {
        if let snapshot { accept(snapshot) }
    }
    func clearLog() { logs = [] }

    // MARK: - Exploit-process logging

    private func describe(_ value: Any?) -> String {
        guard let value else { return "∅" }
        if let data = value as? Data { return "\(data.count) bytes" }
        let text = PlistValueKind.detect(value).text(for: value)
        return text.count > 80 ? String(text.prefix(80)) + "…" : text
    }

    private func diffLines(_ before: [String: Any], _ after: [String: Any], prefix: String = "") -> [String] {
        var lines: [String] = []
        for key in Set(before.keys).union(after.keys).sorted() {
            let path = prefix.isEmpty ? key : prefix + "." + key
            switch (before[key], after[key]) {
            case (nil, let value?): lines.append("+ \(path) = \(describe(value))")
            case (let value?, nil): lines.append("- \(path)  (was \(describe(value)))")
            case (let oldValue?, let newValue?):
                guard !GestaltDocument.valuesEqual(oldValue, newValue) else { continue }
                if let oldDict = oldValue as? [String: Any], let newDict = newValue as? [String: Any] {
                    lines.append(contentsOf: diffLines(oldDict, newDict, prefix: path))
                } else {
                    lines.append("~ \(path): \(describe(oldValue)) → \(describe(newValue))")
                }
            default: break
            }
        }
        return lines
    }

    private func summarize(_ document: GestaltDocument) -> [String] {
        var lines = ["CacheExtra: \(document.extra.count) keys"]
        if let cacheData = document.root["CacheData"] as? Data { lines.append("CacheData: \(cacheData.count) bytes") }
        if let model = document.artwork["ArtworkDeviceProductDescription"] as? String { lines.append("model name: \(model)") }
        if let subtype = document.artwork["ArtworkDeviceSubType"] { lines.append("subtype: \(describe(subtype))") }
        if let region = document.extra[GestaltKeys.regionCode] as? String { lines.append("region code: \(region)") }
        for key in [GestaltKeys.regionInfo, GestaltKeys.legacyRegionInfo] {
            if let info = document.extra[key] as? String { lines.append("region info: \(info)") }
        }
        if let product = document.extra[GestaltKeys.productType] as? String { lines.append("product type: \(product)") }
        return lines
    }

    func connect(showErrorAlert: Bool = true) async {
        guard !isBusy else { return }
        isBusy = true; status = "Checking device access…"
        log("[read] Starting MobileGestalt access")
        defer { isBusy = false }
        do {
            let result = try await files.loadDevice()
            accept(result); deviceAccessible = true; status = "Device connected"
            log("[read] plist: \(result.data.count) bytes")
            for line in summarize(result.document) { log("[read] " + line) }
            log(L("Device connected"))
        } catch {
            deviceAccessible = false; status = "Device access unavailable"
            if showErrorAlert { failed(error) } else { log(error.localizedDescription) }
        }
        await reloadBackups()
    }

    func open(_ url: URL) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            guard (values.fileSize ?? 0) <= 16 * 1024 * 1024 else { throw GestaltFailure("Choose a plist smaller than 16 MB.") }
            let result = try await files.loadLocal(data: Data(contentsOf: url), name: url.lastPathComponent)
            accept(result); status = "Local file opened"; needsRespring = false
            log("[open] \(url.lastPathComponent): \(result.data.count) bytes")
            for line in summarize(result.document) { log("[open] " + line) }
            log(L("Local file opened") + ": " + url.lastPathComponent)
        } catch { failed(error) }
    }

    func stage(_ draft: FieldDraft) throws {
        let key = draft.key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw GestaltFailure("Enter a field key.") }
        guard var doc = working else { throw GestaltFailure("Load a document first.") }
        if draft.originalKey != key && doc.extra[key] != nil { throw GestaltFailure("That key already exists. Edit the existing field instead.") }
        let value = try draft.kind.parse(draft.text)
        if let originalKey = draft.originalKey, originalKey != key { doc.set(nil, for: originalKey) }
        doc.set(value, for: key); working = doc
        // Explicit field edits take precedence: discard presets that would overwrite the key.
        for capability in Capability.all where capability.keys.contains(key) { choices[capability.id] = .keep }
        if [GestaltKeys.regionCode, GestaltKeys.regionInfo, GestaltKeys.legacyRegionInfo].contains(key) { regionID = "keep" }
        if key == GestaltKeys.artwork { subtype = 0 }
        if [GestaltKeys.artwork, "Z/dqyWS6OZTRy10UcmUAhw", "bbtR9jQx50Fv5Af/affNtA"].contains(key) { changesName = false }
    }
    func removeField(_ key: String) {
        working?.set(nil, for: key)
        for capability in Capability.all where capability.keys.contains(key) { choices[capability.id] = .keep }
        if [GestaltKeys.regionCode, GestaltKeys.regionInfo, GestaltKeys.legacyRegionInfo].contains(key) { regionID = "keep" }
        if key == GestaltKeys.artwork { subtype = 0 }
        if [GestaltKeys.artwork, "Z/dqyWS6OZTRy10UcmUAhw", "bbtR9jQx50Fv5Af/affNtA"].contains(key) { changesName = false }
    }

    func apply() async {
        guard !isBusy, let snapshot, let edited = preview, changeCount > 0 else { return }
        if changesName && modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { failed(GestaltFailure("Enter a model name before applying.")); return }
        isBusy = true
        defer { isBusy = false }
        do {
            log("[apply] source=\(snapshot.source.rawValue) fields=\(changeCount)")
            for line in diffLines(snapshot.document.extra, edited.extra) { log("[diff] " + line) }
            let result = try await files.commit(edited, expected: snapshot)
            accept(result); needsRespring = result.source == .device
            status = result.source == .device ? "Changes verified on device" : "Local changes saved"
            message = L(result.source == .device ? "Write verified. Some features require a device restart." : "Local changes saved. Export the plist to keep a copy.")
            log(L(status)); await reloadBackups()
        } catch { failed(error); await reloadBackups() }
    }

    func backup() async {
        guard !isBusy, let snapshot else { return }
        isBusy = true; defer { isBusy = false }
        do { try await files.backup(snapshot); log(L("Backup saved")); message = L("Backup saved"); await reloadBackups() }
        catch { failed(error) }
    }
    func reloadBackups() async {
        do { backups = try await files.backups() } catch { failed(error) }
    }
    func restore(_ record: BackupRecord) async {
        guard !isBusy, let snapshot else { return }
        isBusy = true; defer { isBusy = false }
        do {
            let data = try await files.backupData(record)
            let restored = try GestaltDocument(data: data)
            log("[restore] \(record.filename) · \(record.byteCount) bytes · reason=\(record.reason)")
            for line in diffLines(snapshot.document.extra, restored.extra) { log("[restore-diff] " + line) }
            let result = try await files.commit(restored, expected: snapshot, restoring: record)
            accept(result); needsRespring = result.source == .device
            message = L(result.source == .device ? "Backup restored and verified." : "Backup opened as a local document.")
            log(message ?? ""); await reloadBackups()
        } catch { failed(error); await reloadBackups() }
    }
    func openBackup(_ record: BackupRecord) async {
        guard !isBusy else { return }
        isBusy = true; defer { isBusy = false }
        do {
            let data = try await files.backupData(record)
            accept(try await files.loadLocal(data: data, name: record.filename)); status = "Local file opened"
        } catch { failed(error) }
    }
    func deleteBackup(_ record: BackupRecord) async {
        guard !isBusy else { return }
        isBusy = true; defer { isBusy = false }
        do { try await files.deleteBackup(record); await reloadBackups() } catch { failed(error) }
    }
    func exportBackup(_ record: BackupRecord) async -> URL? {
        do { return try exportData(await files.backupData(record), name: record.filename) }
        catch { failed(error); return nil }
    }
    func exportDocument() -> URL? {
        guard let doc = preview else { return nil }
        do { return try exportData(doc.encoded(), name: "MobileGestalt-GestaltX.plist") }
        catch { failed(error); return nil }
    }
    private func exportData(_ data: Data, name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(name); try data.write(to: url, options: .atomic)
        return url
    }
}
