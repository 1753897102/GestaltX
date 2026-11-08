import Foundation

struct TestFailure: Error { let message: String }
func expect(_ condition: Bool, _ message: String) throws {
    guard condition else { throw TestFailure(message: message) }
}
func expectThrows(_ message: String, _ work: () throws -> Void) throws {
    do { try work() } catch is TestFailure { throw TestFailure(message: message) } catch { return }
    throw TestFailure(message: message)
}
final class AccessTrace: @unchecked Sendable {
    var acquired = 0
    var released: [Int64] = []
    var writes = 0
}
@main struct DocumentTests {
    static func main() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("GestaltX-tests-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let device = root.appendingPathComponent("device.plist")
        let backups = root.appendingPathComponent("backups", isDirectory: true)
        let original: [String: Any] = [
            "CacheExtra": ["VasUgeSzVyHdB27g2XpN0g": "fixture-device", GestaltKeys.productType: "iPhone17,1",
                           "integer": NSNumber(value: 1), "boolean": NSNumber(value: true),
                           "payload": Data([0, 1, 255]), "nested": ["array": [1, true, "text"]]],
            "CacheData": Data([5, 10, 15]), "UnchangedTopLevel": "keep"
        ]
        let originalData = try PropertyListSerialization.data(fromPropertyList: original, format: .binary, options: 0)
        try originalData.write(to: device)
        let trace = AccessTrace()
        let store = GestaltFileStore(deviceURL: device, backupDirectory: backups, deviceID: "fixture-installation", acquire: {
            trace.acquired += 1; return 0
        }, release: { trace.released.append($0) }, writeData: { data, url in
            trace.writes += 1
            let files = try fm.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil)
            try expect(files.contains { $0.pathExtension == "plist" }, "A backup must exist before the system write")
            try data.write(to: url)
        })
        var document = try GestaltDocument(data: originalData)
        try expect(PlistValueKind.detect(document.extra["integer"]!) == .integer, "Integer type detection")
        try expect(PlistValueKind.detect(document.extra["boolean"]!) == .boolean, "Boolean type detection")
        try expect(!GestaltDocument.valuesEqual(NSNumber(value: true), NSNumber(value: 1)), "Do not conflate Boolean and integer")
        try expect(!GestaltDocument.valuesEqual(NSNumber(value: 1.0), NSNumber(value: 1)), "Do not conflate real and integer")
        try expectThrows("Reject an invalid integer") { _ = try PlistValueKind.integer.parse("bad") }
        try expectThrows("Reject non-finite real") { _ = try PlistValueKind.real.parse("NaN") }
        try expectThrows("Reject ambiguous Boolean") { _ = try PlistValueKind.boolean.parse("yes") }
        try expectThrows("Reject invalid Base64") { _ = try PlistValueKind.data.parse("***") }
        try expectThrows("Reject wrong collection type") { _ = try PlistValueKind.array.parse("<dict/>") }
        try expectThrows("Reject missing CacheExtra") { _ = try GestaltDocument(data: Data("<plist><dict/></plist>".utf8)) }
        let nested = try PlistValueKind.dictionary.parse("<dict><key>blob</key><data>AAH/</data><key>list</key><array><true/><integer>7</integer><date>2026-11-09T12:00:00Z</date></array></dict>")
        let roundtrip = try PlistValueKind.dictionary.parse(PlistValueKind.dictionary.text(for: nested))
        try expect(GestaltDocument.valuesEqual(nested, roundtrip), "Nested XML roundtrip preserves types")
        _ = try PlistValueKind.date.parse("2026-11-09T12:00:00.125Z")
        let initial = try await store.loadDevice()
        document.set("edited", for: "new")
        let committed = try await store.commit(document, expected: initial)
        try expect(committed.document.matches(document), "Successful transaction must match readback")
        try expect((committed.document.root["CacheData"] as? Data) == Data([5, 10, 15]), "Preserve CacheData")
        try expect((committed.document.root["UnchangedTopLevel"] as? String) == "keep", "Preserve unrelated root values")
        let records = try await store.backups()
        try expect(records.count == 1 && records[0].source == .device, "Persistent source-bound backup")
        try expect(try await store.backupData(records[0]) == originalData, "Backup stores the original bytes")
        try expect(trace.released == [0, 0], "Zero is a valid extension handle and must be released")
        do { _ = try await store.commit(document, expected: initial); throw TestFailure(message: "Reject stale snapshot") }
        catch is GestaltFailure {}
        try expect(trace.writes == 1, "Stale write must not reach writer")
        let restored = try await store.commit(GestaltDocument(data: originalData), expected: committed, restoring: records[0])
        try expect(restored.document.matches(try GestaltDocument(data: originalData)), "Restore original from owned backup")
        let foreign = BackupRecord(id: UUID(), date: .now, reason: "Manual backup", source: .local, deviceID: "other", byteCount: originalData.count)
        do { _ = try await store.commit(document, expected: restored, restoring: foreign); throw TestFailure(message: "Reject foreign backup") }
        catch is GestaltFailure {}

        for mode in ["partial-failure", "wrong-readback"] {
            try originalData.write(to: device)
            let broken = GestaltFileStore(deviceURL: device, backupDirectory: root.appendingPathComponent(mode), deviceID: "fixture-installation", acquire: { 1 }, release: { _ in }, writeData: { data, url in
                if mode == "partial-failure" { try Data("partial".utf8).write(to: url); throw GestaltFailure("injected failure") }
                var wrong = try GestaltDocument(data: data); wrong.set("unexpected", for: "tamper")
                try wrong.encoded().write(to: url)
            })
            let snapshot = try await broken.loadDevice()
            do { _ = try await broken.commit(document, expected: snapshot); throw TestFailure(message: "Must reject " + mode) }
            catch is GestaltFailure {}
            try expect(try Data(contentsOf: device) == originalData, "Recovery restores exact previous bytes: " + mode)
        }
        let occupied = root.appendingPathComponent("not-a-directory")
        try Data("occupied".utf8).write(to: occupied)
        let blockedTrace = AccessTrace()
        let blocked = GestaltFileStore(deviceURL: device, backupDirectory: occupied, deviceID: "fixture", acquire: { 1 }, release: { _ in }, writeData: { _, _ in blockedTrace.writes += 1 })
        let blockedSnapshot = try await blocked.loadDevice()
        do { _ = try await blocked.commit(document, expected: blockedSnapshot); throw TestFailure(message: "Backup failure must stop write") }
        catch is TestFailure { throw TestFailure(message: "Backup failure must stop write") } catch {}
        try expect(blockedTrace.writes == 0, "No system writer after backup failure")
        let local = GestaltFileStore(deviceURL: device, backupDirectory: root.appendingPathComponent("local"), deviceID: "local", acquire: { throw TestFailure(message: "Local mode must not acquire device access") }, release: { _ in })
        let localSnapshot = try await local.loadLocal(data: originalData, name: "test.plist")
        let savedLocal = try await local.commit(document, expected: localSnapshot)
        try expect(savedLocal.source == .local && savedLocal.document.matches(document), "Local document mode")
        try expect(try Data(contentsOf: device) == originalData, "Local mode leaves device bytes untouched")
        try expect(try await local.backups().first?.source == .local, "Local backups stay local")
        try await store.deleteBackup(records[0])
        let remaining = try await store.backups()
        try expect(!remaining.contains { $0.id == records[0].id }, "Backup deletion updates library")
        print("PASS: typed plist editing, nested roundtrip, durable backups, readback verification, stale-write rejection, owned restore, foreign-backup rejection, rollback, backup failure, local isolation, and extension release.")
    }
}
