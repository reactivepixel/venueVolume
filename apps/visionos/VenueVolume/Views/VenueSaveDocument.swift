import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import VenueVolumeCore

extension UTType { static let venueVolumeSave = UTType(exportedAs: "com.venuevolume.save", conformingTo: .json) }

struct VenueSaveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.venueVolumeSave, .json] }
    var save: VenueSave

    init(save: VenueSave) { self.save = save }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= VenueSave.maximumFileBytes else {
            throw EnvironmentError.invalid("save file is missing or too large")
        }
        save = try JSONDecoder().decode(VenueSave.self, from: data)
        try save.validate(assetChecksum: RoomAssets.checksum(save.asset))
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try save.validate(assetChecksum: RoomAssets.checksum(save.asset))
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(save))
    }

    @MainActor static func read(_ url: URL) async throws -> VenueSave {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard url.isFileURL, let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= VenueSave.maximumFileBytes else { throw EnvironmentError.invalid("save file is empty or too large") }
        let save = try JSONDecoder().decode(VenueSave.self, from: Data(contentsOf: url))
        try save.validate(assetChecksum: RoomAssets.checksum(save.asset))
        // Reject an unreadable native asset before registering the imported save.
        if save.room.manifest.asset.file == "environment.usdz" {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: folder) }
            let assetURL = folder.appendingPathComponent("environment.usdz")
            try save.asset.write(to: assetURL)
            _ = try await Entity(contentsOf: assetURL)
        }
        return save
    }

    @MainActor static func make(model: VenueModel) async throws -> Self {
        guard let room = model.activeRoom else { throw EnvironmentError.invalid("open a venue before exporting") }
        let setup = try model.currentSetupSnapshot()
        let repository: any EnvironmentRepository
        if room.origin == .bundled {
            guard let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("room resources are missing") }
            repository = BundledEnvironmentRepository(directory: resources.appendingPathComponent("Environments"))
        } else { repository = DirectoryEnvironmentRepository(directory: try model.library.roomDirectory(room)) }
        let resolved = try await repository.resolve(id: room.manifest.id)
        guard resolved.manifest == room.manifest else { throw EnvironmentError.invalid("this room version is unavailable") }
        let save = VenueSave(room: room, setup: setup, asset: try Data(contentsOf: resolved.assetURL))
        try save.validate(assetChecksum: RoomAssets.checksum(save.asset))
        return .init(save: save)
    }
}

struct ExportVenueSaveButton: View {
    @Environment(VenueModel.self) private var model
    @State private var document: VenueSaveDocument?
    @State private var exporting = false
    @State private var preparing = false
    var body: some View {
        Button("Export save", systemImage: "square.and.arrow.up") {
            preparing = true
            Task { @MainActor in
                defer { preparing = false }
                do { document = try await .make(model: model); exporting = true }
                catch { model.libraryMessage = "Export failed: \(error.localizedDescription)" }
            }
        }
        .disabled(preparing || model.activeRoom == nil || model.libraryBusy)
        .fileExporter(isPresented: $exporting, document: document, contentType: .venueVolumeSave, defaultFilename: "Venue Volume Save") { result in
            switch result {
            case .success: model.libraryMessage = "Exported venue save with room, fixtures, presets, and material settings."; model.auditExternal("Export venue save")
            case .failure(let error): model.libraryMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
