#if DEBUG
import Foundation
import VenueVolumeCore

/// Opt-in runtime integration check. Uses the real import, save and room-switch
/// paths in Simulator; its synthetic mesh is explicitly not a headset scan.
@MainActor enum RoomLibrarySmoke {
    static func run(model: VenueModel) async {
        let arguments = ProcessInfo.processInfo.arguments
        guard model.isDemoMode, arguments.contains("--library-smoke") || arguments.contains("--history-smoke") else { return }
        do {
            try await ready(model)
            guard let bundled = model.activeRoom, let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("default room missing") }
            model.setupName = "Classroom · blue wash"
            guard model.saveSetup(), let original = model.savedSetups.first(where: { $0.id == model.activeSetupID }) else { throw EnvironmentError.invalid("save failed") }
            let savedFixtures = model.fixtures
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("room-check-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: folder) }
            var manifest = bundled.manifest
            manifest.id = "import-runtime-check"; manifest.title = "Imported classroom"
            try JSONEncoder().encode(manifest).write(to: folder.appendingPathComponent("environment.json"))
            try FileManager.default.copyItem(at: resources.appendingPathComponent("Environments/Classroom/environment.usdz"), to: folder.appendingPathComponent("environment.usdz"))
            let imported = try await RoomAssets.importRoom(from: folder, store: model.library)
            model.registerRoom(imported); model.requestRoom(imported)
            try await ready(model, room: imported)
            guard model.fixtures.isEmpty else { throw EnvironmentError.invalid("new room was not blank") }
            guard model.dropFixture([FixtureKind.movingHead.dragToken], at: .init(x: 2.66,y: 0,z: -2), surfaceID: "floor"),
                  let fixture = model.fixtures.first, model.applyPreset(model.presets[0].id, to: fixture.id) else { throw EnvironmentError.invalid("fixture drop failed") }
            model.setupName = "Imported room · alternate rig"
            guard model.saveSetup() else { throw EnvironmentError.invalid("second setup save failed") }

            let mesh = ScannedMesh(chunks: [.init(vertices: [
                .init(x: -3,y: 0,z: -4), .init(x: 3,y: 0,z: -4), .init(x: 3,y: 0,z: 2), .init(x: -3,y: 0,z: 2),
                .init(x: -3,y: 3,z: -4), .init(x: 3,y: 3,z: -4), .init(x: 3,y: 3,z: 2), .init(x: -3,y: 3,z: 2)
            ], triangles: [0,2,1,0,3,2,0,1,5,0,5,4,0,4,7,0,7,3,1,2,6,1,6,5,3,7,6,3,6,2])])
            let data = try JSONEncoder().encode(mesh)
            let scanManifest = EnvironmentManifest.simple(id: "mesh-runtime-check", title: "Mesh replay check (synthetic)",
                min: [-3,0,-4], max: [3,3,2], spawn: [0,0,0], yaw: 0, file: "environment.mesh.json",
                checksum: RoomAssets.checksum(data), bytes: data.count, scanned: true)
            let replay = LibraryRoom(manifest: scanManifest, origin: .imported)
            try model.library.install(room: replay, asset: data)
            model.registerRoom(replay); model.requestRoom(replay)
            try await ready(model, room: replay)
            model.fixtureKind = .movingHead; model.beginPlacement(); model.placeOnMesh(at: .init(x: 0,y: 0,z: -2))
            guard model.scannedMesh != nil, model.fixtures.count == 1 else { throw EnvironmentError.invalid("mesh replay placement failed") }
            _ = model.applyPreset(model.presets[1].id, to: model.fixtures[0].id)
            model.setHeadAim(model.fixtures[0].id, panDegrees: 35, tiltDegrees: -20)
            guard model.fixtures[0].aimOverride != nil else { throw EnvironmentError.invalid("moving head pilot did not aim in the mesh room") }
            model.setupName = "Mesh replay · test light"
            guard model.saveSetup(), let meshSetup = model.savedSetups.first(where: { $0.id == model.activeSetupID }) else {
                throw EnvironmentError.invalid("mesh setup save failed")
            }
            let savedMeshFixture = model.fixtures[0]
            try await Task.sleep(for: .seconds(4))

            model.requestRoom(bundled, setup: original)
            try await ready(model, room: bundled)
            guard model.fixtures == savedFixtures, model.activeSetupID == original.id else { throw EnvironmentError.invalid("saved classroom restore failed") }
            model.requestRoom(replay, setup: meshSetup)
            try await ready(model, room: replay)
            guard model.scannedMesh != nil, model.fixtures == [savedMeshFixture], model.activeSetupID == meshSetup.id else {
                throw EnvironmentError.invalid("saved mesh setup or pilot pose did not reopen")
            }
            model.beginHistoryAction("Aim pilot in mesh replay")
            model.setHeadAim(savedMeshFixture.id, panDegrees: -25, tiltDegrees: 15)
            model.endHistoryAction()
            let changedMeshFixture = model.fixtures[0]
            guard changedMeshFixture != savedMeshFixture else { throw EnvironmentError.invalid("mesh pilot aim did not change") }
            model.undo()
            guard model.fixtures == [savedMeshFixture] else { throw EnvironmentError.invalid("mesh pilot aim undo failed") }
            model.redo()
            guard model.fixtures == [changedMeshFixture] else { throw EnvironmentError.invalid("mesh pilot aim redo failed") }
            model.requestRoom(bundled, setup: original)
            try await ready(model, room: bundled)
            guard model.fixtures == savedFixtures else { throw EnvironmentError.invalid("classroom did not reopen after mesh replay") }
            model.toolboxTab = 1
            model.libraryMessage = "Runtime check passed · mesh pilot pose, save/reopen, aim Undo/Redo and classroom restore."
            print("ROOM_LIBRARY_SMOKE_PASS")
            if arguments.contains("--history-smoke") {
                let before = model.auditState
                model.undo()
                try await ready(model, room: replay)
                model.redo()
                try await ready(model, room: bundled)
                guard model.auditState == before else { throw EnvironmentError.invalid("cross-room history replay differed") }
                model.remove(savedFixtures[0].id)
                guard model.fixtures.isEmpty else { throw EnvironmentError.invalid("delete failed") }
                model.undo()
                guard model.auditState == before, model.canRedo else { throw EnvironmentError.invalid("delete undo failed") }
                model.toolboxTab = 2
                model.historyMessage = "Runtime check passed · cross-room Undo/Redo and fixture restoration."
                print("AUDIT_HISTORY_SMOKE_PASS")
            }
        } catch {
            model.libraryMessage = "Runtime check failed: \(error.localizedDescription)"
            model.historyMessage = model.libraryMessage
            print("ROOM_LIBRARY_SMOKE_FAIL: \(error)")
        }
    }

    private static func ready(_ model: VenueModel, room: LibraryRoom? = nil) async throws {
        for _ in 0..<300 {
            try await Task.sleep(for: .milliseconds(100))
            if model.canPlace && !model.libraryBusy {
                if let room, model.activeRoom?.id != room.id { throw EnvironmentError.invalid("room switch failed: \(model.libraryMessage ?? "unknown")") }
                return
            }
        }
        throw EnvironmentError.invalid("room loading timed out")
    }
}
#endif
