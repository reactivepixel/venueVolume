#if DEBUG
import Foundation
import RealityKit
import VenueVolumeCore

/// Opt-in runtime integration check. Uses the real import, save and room-switch
/// paths in Simulator; its synthetic mesh is explicitly not a headset scan.
@MainActor enum RoomLibrarySmoke {
    static func catalog(model: VenueModel) async {
        guard model.isDemoMode, ProcessInfo.processInfo.arguments.contains("--catalog-smoke") else { return }
        do {
            guard let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("Missing resources") }
            for asset in FixtureCatalog.all {
                try Task.checkCancellation()
                let template = try await Entity(contentsOf: resources.appendingPathComponent(asset.resource))
                let fixture = Fixture(name: asset.name, assetID: asset.id, channels: asset.neutralChannels, position: .init(x: 0,y: 0,z: 0))
                let rig = try FixtureRig(template: template, id: fixture.id, descriptor: asset)
                for byte in [128, 0, 255, 128] {
                    var channels = asset.neutralChannels
                    for joint in asset.joints { channels[joint.channel] = byte }
                    rig.update(fixture: fixture, channels: channels, selected: false, blackout: false, placing: false)
                    rig.tick(deltaTime: 1)
                    try rig.checkEmitterPose(channels: channels)
                }
                print("CATALOG_RIG_PASS \(asset.id)")
            }
            print("CATALOG_SMOKE_PASS assets=\(FixtureCatalog.all.count)")
        } catch {
            model.message = "Catalog smoke failed: \(error.localizedDescription)"
            print("CATALOG_SMOKE_FAIL \(error)")
        }
    }
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
            model.beginRetarget(model.fixtures[0].id)
            guard model.acceptTarget(.init(x: 1,y: 1.5,z: -4)), model.fixtures[0].aimOverride == nil,
                  model.saveTarget() else { throw EnvironmentError.invalid("mesh target preview/save failed") }
            guard model.fixtures[0].aimOverride == nil,
                  model.presets.first(where: { $0.id == model.fixtures[0].presetID })?.channels == model.fixtures[0].channels else { throw EnvironmentError.invalid("moving head pilot did not aim in the mesh room") }
            model.setupName = "Mesh replay · test light"
            guard model.saveSetup(), let meshSetup = model.savedSetups.first(where: { $0.id == model.activeSetupID }) else {
                throw EnvironmentError.invalid("mesh setup save failed")
            }
            let savedMeshFixture = model.fixtures[0]
            try await Task.sleep(for: .seconds(4))

            model.requestRoom(bundled, setup: original)
            try await ready(model, room: bundled)
            guard restoresSavedLook(model, fixtures: savedFixtures), model.activeSetupID == original.id else { throw EnvironmentError.invalid("saved classroom restore failed") }
            model.requestRoom(replay, setup: meshSetup)
            try await ready(model, room: replay)
            guard model.scannedMesh != nil, model.fixtures == [savedMeshFixture], model.activeSetupID == meshSetup.id else {
                throw EnvironmentError.invalid("saved mesh setup or pilot pose did not reopen")
            }
            model.beginTransform(savedMeshFixture.id)
            let center = FixtureAiming.vector(savedMeshFixture.position) + [0,LightingPreview.height/2,0]
            model.beginTransformDrag(axis: .y, mode: .rotate, at: center+[0,0,0.42])
            model.updateTransformDrag(to: center+[0.42,0,0]); model.endTransformDrag()
            let changedMeshFixture = model.fixtures[0]
            guard changedMeshFixture.orientation != savedMeshFixture.orientation, changedMeshFixture.channels == savedMeshFixture.channels else {
                throw EnvironmentError.invalid("mesh axis rotation did not preserve DMX")
            }
            model.undo()
            guard model.fixtures == [savedMeshFixture] else { throw EnvironmentError.invalid("mesh pilot aim undo failed") }
            model.redo()
            guard model.fixtures == [changedMeshFixture] else { throw EnvironmentError.invalid("mesh pilot aim redo failed") }
            model.requestRoom(bundled, setup: original)
            try await ready(model, room: bundled)
            guard restoresSavedLook(model, fixtures: savedFixtures) else { throw EnvironmentError.invalid("classroom did not reopen after mesh replay") }
            model.toolboxTab = 1
            model.libraryMessage = "Runtime check passed · mesh target preview/save, pose reopen, axis Undo/Redo and classroom restore."
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

    // A saved setup receives an independent preset when its shared definition
    // changed in another room. Preserve all fixture data while checking the
    // remapped assignment resolves to the original saved DMX look.
    private static func restoresSavedLook(_ model: VenueModel, fixtures: [Fixture]) -> Bool {
        guard model.fixtures.count == fixtures.count else { return false }
        return zip(model.fixtures, fixtures).allSatisfy { current, saved in
            var normalized = current
            if saved.presetID != nil {
                guard model.presets.first(where: { $0.id == current.presetID })?.channels == saved.channels else { return false }
            } else if current.presetID != nil { return false }
            normalized.presetID = saved.presetID
            return normalized == saved
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
