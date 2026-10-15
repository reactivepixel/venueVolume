import SwiftUI
import VenueVolumeCore

extension VenueModel {
    func selectTransformMode(_ mode: FixtureTransformMode) {
        endTransformDrag()
        transformMode = mode
        message = nil
    }

    func beginTransform(_ id: UUID) {
        guard canPlace, fixture(id) != nil else { return }
        focusSelection(id); gizmoVisible = true; transformMode = .move; previewDraft = false
    }

    func tapFixture(_ id: UUID) {
        if selectedID == id && !multiSelection && !multiSelectionMode {
            if !gizmoVisible { beginTransform(id) }
        }
        else { select(id) }
    }

    @discardableResult func updateFixtureDetails(_ id: UUID, name: String, universe: Int, address: Int) -> Bool {
        guard !libraryBusy, let i = fixtures.firstIndex(where: { $0.id == id }) else { return false }
        var candidate = fixtures[i]
        candidate.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.universe = universe; candidate.startAddress = address
        if let issue = candidate.validationIssue(among: fixtures) { message = issue; return false }
        if var session = tour {
            let shared = session.show.units.contains { $0.id == id }
            if let i = session.show.units.firstIndex(where: { $0.id == id }), session.show.units[i].fixture.name != candidate.name {
                session.show.units[i].fixture.name = candidate.name; session.show.revision += 1
            }
            if let i = session.localUnits.firstIndex(where: { $0.id == id }) { session.localUnits[i].fixture.name = candidate.name }
            var updated = fixtures; updated[i] = candidate
            return commitTour(session, fixtures: updated, title: "Edit inventory name and venue patch", publish: shared && session.show != tour?.show)
        }
        var updated = fixtures
        let ids = actionIDs(for: id)
        var nextAddress = address
        for index in updated.indices where ids.contains(updated[index].id) {
            updated[index].universe = universe; updated[index].startAddress = nextAddress
            if updated[index].id == id { updated[index].name = candidate.name }
            nextAddress += updated[index].channels.count
        }
        for member in updated { if let issue = member.validationIssue(among: updated) { message = issue; return false } }
        endTransformDrag()
        beginHistoryAction("Edit fixture details"); defer { endHistoryAction() }
        cancelPicking(); fixtures = updated; revision += 1; persist()
        message = "Saved item details."
        return true
    }

    var transformFixtureContext: Fixture? {
        guard var selected = selectedID.flatMap({ fixture($0) }) else { return nil }
        let members = fixtures.filter { tourSelection.contains($0.id) }
        if tour != nil, members.count > 1 {
            let center = members.reduce(SIMD3<Float>.zero) { $0 + FixtureAiming.vector($1.position) } / Float(members.count)
            selected.position = .init(x: center.x, y: center.y, z: center.z)
        }
        return selected
    }
    func beginSelectionTransform() {
        guard canPlace, selectedID != nil, tourSelection.isSubset(of: Set(fixtures.map(\.id))) else { message = "Place every selected unit before transforming."; return }
        cancelTourPreview(); cancelPicking(); gizmoVisible = true; previewDraft = false
    }
    func returnSelection() {
        let ids = tourSelection
        endTransformDrag(); beginHistoryAction("Return \(ids.count) units to inventory"); defer { endHistoryAction() }
        for id in ids { remove(id) }
        selectedUnitIDs = []; selectedGroupID = nil
    }
    func programmingSummary(_ unit: InventoryUnit) -> String {
        guard let tour else { return "" }
        let individual = tour.programming.units[unit.id]?.isEmpty == false || (tour.show.programming.units[unit.id]?.keys.contains { tour.programming.releasedUnits[unit.id]?.contains($0) != true } == true)
        let ids = Set(unit.fixture.channels.indices.compactMap { tour.binding(for: unit, channel: $0) })
        let names = tour.presets.filter { ids.contains($0.id) }.map(\.name).joined(separator: ", ")
        return (individual ? "Individual assignment · " : "Group / baseline · ") + (names.isEmpty ? "Inventory defaults" : names)
    }

    func beginTransformDrag(axis: FixtureAxis, mode: FixtureTransformMode, at point: SIMD3<Float>) {
        guard canPlace, gizmoVisible, !isTransformDragging, let id = selectedID, let fixture = fixture(id) else { return }
        let pivot = transformFixtureContext?.position ?? fixture.position
        var context = fixture; context.position = pivot
        let center = FixtureAiming.vector(context.visualCenter)
        let angle = axis.angle(at: point, about: center)
        guard mode == .move || angle != nil else { return }
        cancelPicking(); previewDraft = false
        beginHistoryAction("\(mode.rawValue) fixture · \(axis.rawValue.uppercased()) axis")
        transformDrag = .init(fixture: fixture, members: fixtures.filter { actionIDs(for: id).contains($0.id) }, axis: axis, mode: mode, start: point, lastAngle: angle, pivot: pivot)
    }

    func updateTransformDrag(to point: SIMD3<Float>) {
        guard var drag = transformDrag, point.x.isFinite, point.y.isFinite, point.z.isFinite,
              selectedID == drag.fixture.id, let i = fixtures.firstIndex(where: { $0.id == drag.fixture.id }), let environment else { return }
        var candidate = drag.fixture
        if drag.mode == .move {
            var position = FixtureAiming.vector(candidate.position)
            position[drag.axis.index] += point[drag.axis.index]-drag.start[drag.axis.index]
            candidate.position = .init(x: position.x, y: position.y, z: position.z)
            if let issue = candidate.placementIssue(in: environment) { message = issue; return }
        } else {
            var context = drag.fixture; context.position = drag.pivot ?? candidate.position
            let center = FixtureAiming.vector(context.visualCenter)
            guard let next = drag.axis.angle(at: point, about: center), let previous = drag.lastAngle else { return }
            drag.totalAngle += FixtureAiming.angleDelta(from: previous, to: next); drag.lastAngle = next
            candidate.orientation = FixtureAiming.rotatedMount(candidate.orientation, around: drag.axis, radians: drag.totalAngle)
        }
        transformDrag = drag; candidate.surfaceID = nil
        if drag.mode == .move { candidate.mountPlane = nil }
        else { candidate.mountPlane = candidate.mountPlane ?? supportingPlane(for: drag.fixture) }
        guard candidate != fixtures[i], candidate.validationIssue(among: fixtures) == nil else { return }
        if drag.members.count > 1 {
            let pivot = FixtureAiming.vector(drag.pivot ?? drag.fixture.position)
            let q = FixtureAiming.rotatedMount(.init(), around: drag.axis, radians: drag.totalAngle)
            let delta = FixtureAiming.vector(candidate.position) - FixtureAiming.vector(drag.fixture.position)
            var updates = fixtures
            for original in drag.members {
                guard let index = updates.firstIndex(where: { $0.id == original.id }) else { return }
                var member = original
                if drag.mode == .move {
                    let point = FixtureAiming.vector(original.position) + delta
                    member.position = .init(x: point.x, y: point.y, z: point.z)
                } else {
                    let point = pivot + FixtureAiming.rotate(q, FixtureAiming.vector(original.position)-pivot)
                    member.position = .init(x: point.x, y: point.y, z: point.z)
                    member.orientation = FixtureAiming.rotatedMount(original.orientation, around: drag.axis, radians: drag.totalAngle)
                }
                member.surfaceID = nil
                if drag.mode == .move { member.mountPlane = nil }
                else { member.mountPlane = member.mountPlane ?? supportingPlane(for: original) }
                if let issue = member.placementIssue(in: environment) { message = issue; return }
                updates[index] = member
            }
            if let tour { do { try tour.validate(fixtures: updates) } catch { message = error.localizedDescription; return } }
            fixtures = updates
        } else { fixtures[i] = candidate }
        lastTarget = nil; revision += 1; persist(); message = nil
    }

    func endTransformDrag() {
        guard isTransformDragging else { return }
        transformDrag = nil; surfaceDrag = nil; endHistoryAction()
    }

    func supportingPlane(for fixture: Fixture) -> FixtureMountPlane {
        if let plane = fixture.mountPlane { return plane }
        let offset: Float = fixture.assetID == nil ? fixture.footprintRadius : 0
        return .init(origin: .init(x: fixture.position.x, y: fixture.position.y-offset, z: fixture.position.z), normal: .init(x: 0,y: 1,z: 0))
    }

    func beginSurfaceDrag(_ id: UUID, at point: SIMD3<Float>) {
        guard canPlace, !libraryBusy, gizmoVisible, transformMode == .move, selectedID == id, !isTransformDragging,
              !isRetargeting, !isPlacing, let fixture = fixture(id) else { return }
        cancelPicking(); previewDraft = false; transformMode = .move
        beginHistoryAction("Slide fixture on its surface")
        surfaceDrag = .init(fixture: fixture, plane: supportingPlane(for: fixture), members: fixtures.filter { actionIDs(for: id).contains($0.id) }, start: point)
    }

    func surfaceDragDestination(to point: SIMD3<Float>) -> (point: Position3D, normal: Position3D, radius: Float)? {
        guard let drag = surfaceDrag else { return nil }
        var fixture = drag.fixture
        let moved = FixtureAiming.vector(fixture.position) + drag.plane.projected(point-drag.start)
        fixture.position = .init(x: moved.x,y: moved.y,z: moved.z)
        return (mountingPoint(for: fixture), drag.plane.normal, fixture.footprintRadius)
    }

    @discardableResult func updateSurfaceDrag(to point: SIMD3<Float>) -> Bool {
        guard let drag = surfaceDrag, selectedID == drag.fixture.id, let environment,
              let i = fixtures.firstIndex(where: { $0.id == drag.fixture.id }),
              [point.x,point.y,point.z].allSatisfy(\.isFinite) else { return false }
        let delta = drag.plane.projected(point-drag.start)
        if FixtureAiming.length(delta) < 0.0001 { return true }
        var candidate = drag.fixture
        let moved = FixtureAiming.vector(candidate.position) + delta
        candidate.position = .init(x: moved.x,y: moved.y,z: moved.z); candidate.mountPlane = drag.plane
        let base = mountingPoint(for: candidate)
        if let surfaceID = candidate.surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }),
           surface.fixturePosition(hit: base, halfSize: candidate.footprintRadius) == nil {
            message = "Keep the fixture on its current surface, or click a different surface."; return false
        }
        if let scannedMesh, !scannedMesh.supports(base, normal: drag.plane.normal, radius: candidate.footprintRadius) {
            message = "The scan has no support here. Choose a captured surface."; return false
        }
        if let issue = candidate.placementIssue(in: environment) ?? candidate.validationIssue(among: fixtures) { message = issue; return false }
        guard candidate != fixtures[i] else { return true }
        guard let updates = surfaceGroupPlacement(anchor: drag.fixture, candidate: candidate, members: drag.members) else { return false }
        fixtures = updates; revision += 1; persist(); message = nil
        return true
    }

    func mountingPoint(for fixture: Fixture) -> Position3D {
        let p = FixtureAiming.vector(fixture.position)
            - (fixture.assetID == nil ? FixtureAiming.rotate(fixture.orientation, [0,fixture.footprintRadius,0]) : .zero)
        return .init(x: p.x,y: p.y,z: p.z)
    }

    @discardableResult func moveToSurface(at point: Position3D, normal: Position3D, surfaceID: String? = nil) -> Bool {
        guard canPlace, !libraryBusy, isSurfaceMoveActive, let id = selectedID,
              let i = fixtures.firstIndex(where: { $0.id == id }), let environment else { return false }
        let plane = FixtureMountPlane(origin: point, normal: normal)
        guard plane.isValid else { message = "Choose a valid surface."; return false }
        var candidate = fixtures[i]
        if let surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }),
           surface.fixturePosition(hit: point, halfSize: candidate.footprintRadius) == nil {
            message = "Choose a surface with enough space for the fixture."; return false
        }
        if let scannedMesh, !scannedMesh.supports(point, normal: normal, radius: candidate.footprintRadius) {
            message = "Choose a captured surface with enough space."; return false
        }
        candidate.orientation = FixtureAiming.alignedMount(candidate.orientation, normal: FixtureAiming.vector(normal))
        let position = FixtureAiming.vector(point) + (candidate.assetID == nil ? FixtureAiming.vector(normal)*candidate.footprintRadius : .zero)
        candidate.position = .init(x: position.x,y: position.y,z: position.z)
        candidate.surfaceID = surfaceID; candidate.mountPlane = plane
        if let issue = candidate.placementIssue(in: environment) ?? candidate.validationIssue(among: fixtures) { message = issue; return false }
        guard let updates = surfaceGroupPlacement(anchor: fixtures[i], candidate: candidate, members: fixtures.filter { actionIDs(for: id).contains($0.id) }) else { return false }
        endTransformDrag(); beginHistoryAction("Move fixture to surface"); defer { endHistoryAction() }
        fixtures = updates; scenePick = nil; gizmoVisible = true; transformMode = .move; lastTarget = nil
        revision += 1; persist(); message = "Fixture moved and aligned to the surface."
        return true
    }

    private func surfaceGroupPlacement(anchor: Fixture, candidate: Fixture, members: [Fixture]) -> [Fixture]? {
        guard let environment, let plane = candidate.mountPlane else { return nil }
        let rotation = ViewerNavigationPose.compose(candidate.orientation, FixtureAiming.inverse(anchor.orientation))
        var updates = fixtures
        for original in members {
            guard let index = updates.firstIndex(where: { $0.id == original.id }) else { return nil }
            var member = original
            let relative = FixtureAiming.vector(original.position)-FixtureAiming.vector(anchor.position)
            let position = FixtureAiming.vector(candidate.position)+FixtureAiming.rotate(rotation, relative)
            member.position = .init(x: position.x,y: position.y,z: position.z)
            member.orientation = ViewerNavigationPose.compose(rotation, original.orientation)
            member.surfaceID = candidate.surfaceID; member.mountPlane = plane
            let point = mountingPoint(for: member)
            if let surfaceID = member.surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }),
               surface.fixturePosition(hit: point, halfSize: member.footprintRadius) == nil {
                message = "Choose a surface with enough room for the entire selection."; return nil
            }
            if let scannedMesh, !scannedMesh.supports(point, normal: plane.normal, radius: member.footprintRadius) {
                message = "Capture enough support for the entire selection."; return nil
            }
            if let issue = member.placementIssue(in: environment) { message = issue; return nil }
            updates[index] = original.id == anchor.id ? candidate : member
        }
        for member in updates { if let issue = member.validationIssue(among: updates) { message = issue; return nil } }
        return updates
    }

    func reposition(at hit: Position3D, surfaceID: String) {
        guard let surface = environment?.surfaces.first(where: { $0.id == surfaceID }) else { return }
        _ = moveToSurface(at: hit, normal: .init(x: surface.normal[0],y: surface.normal[1],z: surface.normal[2]), surfaceID: surfaceID)
    }

    func repositionOnMesh(at point: Position3D) {
        _ = moveToSurface(at: point, normal: .init(x: 0,y: 1,z: 0))
    }

    private func relocateGroup(_ id: UUID, to destination: Position3D, surfaceID: String?) -> Bool {
        guard let anchor = fixture(id), let environment else { return false }
        let delta = FixtureAiming.vector(destination) - FixtureAiming.vector(anchor.position)
        let ids = actionIDs(for: id)
        var updated = fixtures
        for index in updated.indices where ids.contains(updated[index].id) {
            let p = FixtureAiming.vector(updated[index].position) + delta
            updated[index].position = updated[index].id == id ? destination : .init(x: p.x, y: p.y, z: p.z)
            updated[index].surfaceID = surfaceID
            if let surfaceID, let surface = environment.surfaces.first(where: { $0.id == surfaceID }) {
                let radius = updated[index].footprintRadius
                let base = updated[index].position
                guard surface.fixturePosition(hit: .init(x: base.x, y: base.y, z: base.z), halfSize: radius) != nil else {
                    message = "Choose a surface with enough space for the entire group."; return false
                }
            } else if let scannedMesh, !scannedMesh.supports(updated[index].position, radius: updated[index].footprintRadius) {
                message = "Scan enough support for the entire group."; return false
            }
        }
        fixtures = updated
        return true
    }

    func resetAim(_ id: UUID) {
        if !groupActionActive, actionIDs(for: id).count > 1 {
            beginHistoryAction("Reset group aim"); groupActionActive = true
            defer { groupActionActive = false; endHistoryAction() }
            for member in actionIDs(for: id) { resetAim(member) }
            return
        }
        guard !libraryBusy else { return }
        beginHistoryAction("Reset fixture aim"); defer { endHistoryAction() }
        guard let index = fixtures.firstIndex(where: { $0.id == id }),
              fixtures[index].aimOverride != nil || fixtures[index].jointOverrides != nil else { return }
        cancelPicking()
        let saved = presets.first(where: { $0.id == fixtures[index].presetID })
        fixtures[index].aimOverride = nil
        fixtures[index].jointOverrides = nil
        for joint in fixtures[index].asset?.joints ?? [] where fixtures[index].channels.indices.contains(joint.channel) {
            fixtures[index].channels[joint.channel] = saved.flatMap { $0.channels.indices.contains(joint.channel) ? $0.channels[joint.channel] : nil } ?? (joint.continuous ? 0 : 128)
        }
        let channels = (fixtures[index].asset?.joints ?? []).map(\.channel)
        if !channels.isEmpty { _ = recordCuePalette(DMXPreset(name: "Reset motion", channels: fixtures[index].channels, attributeIndices: channels), targets: [id]) }
        previewDraft = false; lastTarget = nil
        revision += 1; persist(); message = saved == nil ? "Returned moving parts to rest." : "Restored the palette's motion values."
    }


}
