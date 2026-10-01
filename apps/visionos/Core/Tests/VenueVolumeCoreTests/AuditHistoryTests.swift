import Foundation
import Testing
@testable import VenueVolumeCore

struct AuditHistoryTests {
    @Test func undoRedoBranchesKeepAbandonedEvents() throws {
        var history = AuditHistory(state: 0)
        let initial = history.cursor
        let recorded = history.record("Add", state: 1)
        #expect(recorded)
        let added = history.cursor
        history.record("Move", state: 2)
        let moved = history.cursor
        try history.move(to: added, kind: .undo)
        #expect(history.current.state == 1 && history.redoTarget == moved)
        try history.move(to: initial, kind: .undo)
        try history.move(to: added, kind: .redo)
        history.record("Different move", state: 3)
        #expect(history.redoTarget == nil && history.node(moved)?.state == 2)
        #expect(history.nodes.count == 4)
        try history.move(to: moved, kind: .jump)
        #expect(history.current.state == 2 && history.undoTarget == added)
        try history.validate()
    }

    @Test func auditNavigationPersistsWithoutReplayingExternalEffects() throws {
        var history = AuditHistory(state: "initial")
        let first = history.cursor
        history.record("New scene", state: "scene")
        let scene = history.cursor
        history.append("Mock sync succeeded")
        #expect(history.nodes.count == 2 && history.entries.last?.kind == .external)
        let noOp = history.record("No change", state: "scene")
        #expect(!noOp)
        try history.move(to: first, kind: .undo)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("audit.json")
        try history.save(to: url)
        let loaded = try AuditHistory<String>.load(from: url)
        var restored = try #require(loaded)
        #expect(restored.cursor == first && restored.redoTarget == scene)
        try restored.move(to: scene, kind: .redo)
        #expect(restored.entries.filter { $0.kind == .external }.count == 1)
        #expect(restored.current.state == "scene")
    }

    @Test func corruptedAuditDoesNotOverwriteTheFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("audit.json")
        let history = AuditHistory(state: 0)
        try history.save(to: url)
        var json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        json["cursor"] = UUID().uuidString
        let damaged = try JSONSerialization.data(withJSONObject: json)
        try damaged.write(to: url)
        #expect(throws: (any Error).self) { try AuditHistory<Int>.load(from: url) }
        #expect(try Data(contentsOf: url) == damaged)
    }
}
