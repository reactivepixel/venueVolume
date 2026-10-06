import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import VenueVolumeCore

extension UTType { static let venueVolumeSave = UTType(exportedAs: "com.venuevolume.save", conformingTo: .json) }

struct VenueSaveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.venueVolumeSave, .json] }
    // Encoding finishes on VenueSaveWorker before presentation. SwiftUI may call
    // fileWrapper on any executor; it never needs to decode/hash a large room.
    private let encodedData: Data

    init(encodedData: Data) { self.encodedData = encodedData }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, !data.isEmpty,
              data.count <= VenueSave.maximumFileBytes else {
            throw EnvironmentError.invalid("save file is missing or too large")
        }
        encodedData = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: encodedData)
    }

    @MainActor static func read(_ url: URL) async throws -> VenueSaveWorker.ReadResult {
        let worker = VenueSaveWorker.shared
        let result = try await worker.read(url, checksum: RoomAssets.checksum)
        try Task.checkCancellation()
        // Security scope is needed only while reading the source bytes. Native
        // preflight reads a private staged copy and remains on RealityKit's actor.
        if result.save.room.manifest.asset.file == "environment.usdz" {
            let assetURL = try await worker.stageNativeAsset(result.save.asset)
            do {
                try Task.checkCancellation()
                _ = try await Entity(contentsOf: assetURL)
                try Task.checkCancellation()
            } catch {
                await worker.removeStagedNativeAsset(assetURL)
                throw error
            }
            await worker.removeStagedNativeAsset(assetURL)
        }
        try Task.checkCancellation()
        return result
    }

    @MainActor static func make(model: VenueModel) async throws -> Self {
        guard let room = model.activeRoom else { throw EnvironmentError.invalid("open a venue before exporting") }
        let setup = try model.currentSetupSnapshot()
        let repository: any EnvironmentRepository
        if room.origin == .bundled {
            guard let resources = Bundle.main.resourceURL else { throw EnvironmentError.invalid("room resources are missing") }
            repository = BundledEnvironmentRepository(directory: resources.appendingPathComponent("Environments"))
        } else { repository = DirectoryEnvironmentRepository(directory: try model.library.roomDirectory(room)) }
        let data = try await VenueSaveWorker.shared.encode(room: room, setup: setup, repository: repository,
                                                          checksum: RoomAssets.checksum)
        try Task.checkCancellation()
        return .init(encodedData: data)
    }
}

struct ExportVenueSaveButton: View {
    @Environment(VenueModel.self) private var model
    @State private var document: VenueSaveDocument?
    @State private var exporting = false
    @State private var preparing = false
    var body: some View {
        Button(preparing ? "Preparing save…" : "Export save", systemImage: "square.and.arrow.up") {
            preparing = true
        }
        .disabled(preparing || model.activeRoom == nil || model.libraryBusy)
        .task(id: preparing) {
            guard preparing else { return }
            defer { preparing = false }
            do {
                let prepared = try await VenueSaveDocument.make(model: model)
                try Task.checkCancellation()
                document = prepared; exporting = true
            } catch is CancellationError {
                // A dismissed source view must not reopen a late export sheet.
            } catch {
                if !Task.isCancelled { model.libraryMessage = "Export failed: \(error.localizedDescription)" }
            }
        }
        .onDisappear { preparing = false }
        .fileExporter(isPresented: $exporting, document: document, contentType: .venueVolumeSave, defaultFilename: "Venue Volume Save") { result in
            switch result {
            case .success: model.libraryMessage = "Exported venue save with room, fixtures, palettes/phasers, and material settings."; model.auditExternal("Export venue save")
            case .failure(let error): model.libraryMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
