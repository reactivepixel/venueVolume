import Foundation

/// Heavy portable-save work has an explicit executor, independent of the UI actor.
/// Actor hops retain the caller's cancellation; no detached worker outlives a request.
public actor VenueSaveWorker {
    public static let shared = VenueSaveWorker()
    public typealias Checksum = @Sendable (Data) throws -> String

    public struct ReadResult: Sendable {
        public let save: VenueSave
        public let checksum: String
    }

    public func read(_ url: URL, checksum: Checksum) throws -> ReadResult {
        try Task.checkCancellation()
        #if !os(Linux)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        #endif
        guard url.isFileURL, let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= VenueSave.maximumFileBytes else {
            throw EnvironmentError.invalid("save file is empty or too large")
        }
        let data = try Data(contentsOf: url)
        try Task.checkCancellation()
        guard !data.isEmpty, data.count <= VenueSave.maximumFileBytes else {
            throw EnvironmentError.invalid("save file is empty or too large")
        }
        let save = try JSONDecoder().decode(VenueSave.self, from: data)
        try Task.checkCancellation()
        let digest = try checksum(save.asset)
        try Task.checkCancellation()
        try save.validate(assetChecksum: digest)
        try Task.checkCancellation()
        return .init(save: save, checksum: digest)
    }

    public func encode(room: LibraryRoom, setup: VenueSetup, repository: any EnvironmentRepository,
                       checksum: Checksum) async throws -> Data {
        try Task.checkCancellation()
        let resolved = try await repository.resolve(id: room.manifest.id)
        try Task.checkCancellation()
        guard resolved.manifest == room.manifest else { throw EnvironmentError.invalid("this room version is unavailable") }
        let save = VenueSave(room: room, setup: setup, asset: try Data(contentsOf: resolved.assetURL))
        try Task.checkCancellation()
        let digest = try checksum(save.asset)
        try Task.checkCancellation()
        try save.validate(assetChecksum: digest)
        try Task.checkCancellation()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(save)
        try Task.checkCancellation()
        guard data.count <= VenueSave.maximumFileBytes else { throw EnvironmentError.invalid("save file exceeds its size limit") }
        return data
    }

    public func stageNativeAsset(_ data: Data) throws -> URL {
        try Task.checkCancellation()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("environment.usdz")
            try data.write(to: url)
            try Task.checkCancellation()
            return url
        } catch { try? FileManager.default.removeItem(at: folder); throw error }
    }

    public func removeStagedNativeAsset(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// Fully write a new room/setup off the UI actor. The final publication is a
    /// short synchronous rename, after the UI checks that its intent is current.
    public func prepareImport(_ document: VenueSave, assetChecksum: String,
                              store: RoomLibraryStore) throws -> PreparedVenueSaveImport {
        try Task.checkCancellation()
        try document.validate(assetChecksum: assetChecksum)
        try Task.checkCancellation()
        var room = document.room
        room.origin = document.room.manifest.asset.file == "environment.mesh.json" ? .scanned : .imported
        var setup = document.setup; setup.id = UUID(); setup.modified = Date()
        let destination = try store.roomDirectory(room)
        let assetURL = destination.appendingPathComponent(room.manifest.asset.file)
        let recordURL = destination.appendingPathComponent("room.json")
        let existing: PreparedVenueSaveImport.ExistingRoom?
        if FileManager.default.fileExists(atPath: destination.path) {
            let before = try PreparedVenueSaveImport.ExistingRoom(asset: assetURL, record: recordURL)
            let asset = try Data(contentsOf: assetURL)
            try Task.checkCancellation()
            let prior = try JSONDecoder().decode(LibraryRoom.self, from: Data(contentsOf: recordURL))
            guard asset == document.asset, prior.manifest == room.manifest,
                  before == (try PreparedVenueSaveImport.ExistingRoom(asset: assetURL, record: recordURL)) else {
                throw EnvironmentError.invalid("different room data already uses this room version")
            }
            existing = before
        } else { existing = nil }
        try Task.checkCancellation()
        let staging = store.directory.appendingPathComponent(".save-" + UUID().uuidString)
        do {
            let stagedStore = RoomLibraryStore(directory: staging)
            if existing == nil { try stagedStore.install(room: room, asset: document.asset) }
            try Task.checkCancellation()
            try stagedStore.save(setup, room: room)
            try Task.checkCancellation()
            return .init(room: room, setup: setup, store: store, staging: staging, existing: existing)
        } catch { try? FileManager.default.removeItem(at: staging); throw error }
    }
}

public struct PreparedVenueSaveImport: Sendable {
    public let room: LibraryRoom
    public let setup: VenueSetup
    private let store: RoomLibraryStore
    private let staging: URL
    private let existing: ExistingRoom?

    fileprivate struct Fingerprint: Equatable, Sendable {
        let size: UInt64
        let inode: UInt64
        let modified: Date
        init(_ url: URL) throws {
            let info = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let size = info[.size] as? UInt64, let inode = info[.systemFileNumber] as? UInt64,
                  let modified = info[.modificationDate] as? Date else {
                throw EnvironmentError.invalid("room file attributes are unavailable")
            }
            self.size = size; self.inode = inode; self.modified = modified
        }
    }
    fileprivate struct ExistingRoom: Equatable, Sendable {
        let asset: Fingerprint
        let record: Fingerprint
        init(asset: URL, record: URL) throws { self.asset = try Fingerprint(asset); self.record = try Fingerprint(record) }
    }
    fileprivate init(room: LibraryRoom, setup: VenueSetup, store: RoomLibraryStore, staging: URL, existing: ExistingRoom?) {
        self.room = room; self.setup = setup; self.store = store; self.staging = staging; self.existing = existing
    }

    public func discard() { try? FileManager.default.removeItem(at: staging) }

    /// Call only after checking the UI's navigation intent, without an intervening
    /// suspension. Existing immutable geometry must still match its checked files.
    public func commit() throws {
        defer { discard() }
        try Task.checkCancellation()
        let files = FileManager.default
        let destination = try store.roomDirectory(room)
        let stagedStore = RoomLibraryStore(directory: staging)
        let setupFolder = store.directory.appendingPathComponent("Setups")
        let setupName = setup.id.uuidString + ".json"
        let sourceSetup = staging.appendingPathComponent("Setups").appendingPathComponent(setupName)
        var installedRoom = false
        if let existing {
            guard existing == (try ExistingRoom(asset: destination.appendingPathComponent(room.manifest.asset.file),
                                               record: destination.appendingPathComponent("room.json"))) else {
                throw EnvironmentError.invalid("room changed during import; select the save again")
            }
        } else {
            guard !files.fileExists(atPath: destination.path) else {
                throw EnvironmentError.invalid("room changed during import; select the save again")
            }
        }
        try files.createDirectory(at: setupFolder, withIntermediateDirectories: true)
        do {
            if existing == nil {
                try files.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try files.moveItem(at: stagedStore.roomDirectory(room), to: destination)
                installedRoom = true
            }
            try files.moveItem(at: sourceSetup, to: setupFolder.appendingPathComponent(setupName))
        } catch {
            if installedRoom { try? files.removeItem(at: destination) }
            throw error
        }
    }
}
