import Foundation

struct RetainedEvidenceStorageRoots: Equatable {
    let stagingRoot: URL
    let durableV1Root: URL

    static func live(
        fileSystem: any EvidenceFileSystem
    ) throws -> RetainedEvidenceStorageRoots {
        let stagingRoot = fileSystem.temporaryDirectory
            .appendingPathComponent("LumenEvidenceStaging", isDirectory: true)

        let durableV1Root = try fileSystem.applicationSupportDirectory()
            .appendingPathComponent("LumenEvidence", isDirectory: true)
            .appendingPathComponent("v1", isDirectory: true)

        return RetainedEvidenceStorageRoots(
            stagingRoot: stagingRoot,
            durableV1Root: durableV1Root
        )
    }
}

struct RetainedEvidencePaths: Equatable {
    let stagingDirectory: URL
    let stagedPayload: URL
    let durableDirectory: URL
    let incomingPayload: URL
    let finalPayload: URL
}

struct StagedEvidencePayload: Equatable {
    let sourceID: UUID
    let url: URL
    let byteCount: Int
}

struct DurableEvidencePreparation: Equatable {
    let sourceID: UUID
    let incomingURL: URL
    let finalURL: URL
    let byteCount: Int
}

struct DurablyPreparedEvidencePayload: Equatable {
    let sourceID: UUID
    let url: URL
    let byteCount: Int
}

enum EvidenceCleanupOutcome: Equatable {
    case nothingToRemove
    case removedKnownMaterial
    case retainedUnexpectedContents([String])
}

struct RetainedEvidenceStore {
    private let fileSystem: any EvidenceFileSystem
    let roots: RetainedEvidenceStorageRoots

    init(
        fileSystem: any EvidenceFileSystem,
        roots: RetainedEvidenceStorageRoots
    ) {
        self.fileSystem = fileSystem
        self.roots = roots
    }

    static func live(
        fileSystem: any EvidenceFileSystem = LocalEvidenceFileSystem()
    ) throws -> RetainedEvidenceStore {
        try RetainedEvidenceStore(
            fileSystem: fileSystem,
            roots: .live(fileSystem: fileSystem)
        )
    }

    func paths(for sourceID: UUID) -> RetainedEvidencePaths {
        let identity = EvidenceIdentity.canonicalString(for: sourceID)

        let stagingDirectory = roots.stagingRoot
            .appendingPathComponent(identity, isDirectory: true)

        let durableDirectory = roots.durableV1Root
            .appendingPathComponent(identity, isDirectory: true)

        return RetainedEvidencePaths(
            stagingDirectory: stagingDirectory,
            stagedPayload: stagingDirectory
                .appendingPathComponent("payload", isDirectory: false),
            durableDirectory: durableDirectory,
            incomingPayload: durableDirectory
                .appendingPathComponent("payload.incoming", isDirectory: false),
            finalPayload: durableDirectory
                .appendingPathComponent("payload", isDirectory: false)
        )
    }

    func stage(
        _ data: Data,
        for sourceID: UUID
    ) throws -> StagedEvidencePayload {
        let paths = paths(for: sourceID)

        try fileSystem.createDirectory(at: roots.stagingRoot)
        try fileSystem.createDirectory(at: paths.stagingDirectory)
        try requireOnlyExpectedContents(
            at: paths.stagingDirectory,
            sourceID: sourceID,
            allowedNames: ["payload"]
        )

        try fileSystem.write(
            data,
            to: paths.stagedPayload,
            atomically: true
        )

        let stagedData = try fileSystem.read(paths.stagedPayload)
        guard stagedData == data else {
            throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
        }

        return StagedEvidencePayload(
            sourceID: sourceID,
            url: paths.stagedPayload,
            byteCount: data.count
        )
    }

    func prepareDurablePayload(
        for sourceID: UUID
    ) throws -> DurableEvidencePreparation {
        let paths = paths(for: sourceID)

        guard fileSystem.fileExists(at: paths.stagedPayload) else {
            throw RetainedEvidenceStoreError.stagedPayloadMissing(sourceID)
        }

        let stagedData = try fileSystem.read(paths.stagedPayload)

        try fileSystem.createDirectory(at: roots.durableV1Root)
        try fileSystem.createDirectory(at: paths.durableDirectory)
        try requireOnlyExpectedContents(
            at: paths.durableDirectory,
            sourceID: sourceID,
            allowedNames: ["payload.incoming", "payload"]
        )

        do {
            try fileSystem.write(
                stagedData,
                to: paths.incomingPayload,
                atomically: false
            )

            let incomingData = try fileSystem.read(paths.incomingPayload)
            guard incomingData == stagedData else {
                throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
            }
        } catch {
            try? fileSystem.removeItem(at: paths.incomingPayload)
            throw error
        }

        return DurableEvidencePreparation(
            sourceID: sourceID,
            incomingURL: paths.incomingPayload,
            finalURL: paths.finalPayload,
            byteCount: stagedData.count
        )
    }

    func finalizeDurablePayload(
        for sourceID: UUID
    ) throws -> DurablyPreparedEvidencePayload {
        let paths = paths(for: sourceID)

        guard fileSystem.fileExists(at: paths.stagedPayload) else {
            throw RetainedEvidenceStoreError.stagedPayloadMissing(sourceID)
        }

        guard fileSystem.fileExists(at: paths.incomingPayload) else {
            throw RetainedEvidenceStoreError.incomingPayloadMissing(sourceID)
        }

        let stagedData = try fileSystem.read(paths.stagedPayload)
        let incomingData = try fileSystem.read(paths.incomingPayload)

        guard incomingData == stagedData else {
            throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
        }

        try fileSystem.replaceItemAtomically(
            at: paths.finalPayload,
            withItemAt: paths.incomingPayload
        )

        try fileSystem.applyCompleteFileProtection(at: paths.finalPayload)
        try fileSystem.clearBackupExclusion(at: paths.finalPayload)

        let finalData = try fileSystem.read(paths.finalPayload)
        guard finalData == stagedData else {
            throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
        }

        guard try fileSystem.fileProtection(at: paths.finalPayload) == .complete else {
            throw RetainedEvidenceStoreError.completeProtectionNotVerified(sourceID)
        }

        guard try !fileSystem.isExcludedFromBackup(at: paths.finalPayload) else {
            throw RetainedEvidenceStoreError.backupExclusionDetected(sourceID)
        }

        return DurablyPreparedEvidencePayload(
            sourceID: sourceID,
            url: paths.finalPayload,
            byteCount: finalData.count
        )
    }

    func cleanupStaging(
        for sourceID: UUID
    ) throws -> EvidenceCleanupOutcome {
        let paths = paths(for: sourceID)
        return try cleanupControlledDirectory(
            paths.stagingDirectory,
            sourceID: sourceID,
            knownItems: [paths.stagedPayload]
        )
    }

    /// Removes only deterministic prepared-storage artifacts.
    ///
    /// This method does not infer ledger commitment. A caller must establish
    /// deletion authority before invoking it for a source UUID.
    func cleanupPreparedDurableMaterial(
        for sourceID: UUID
    ) throws -> EvidenceCleanupOutcome {
        let paths = paths(for: sourceID)
        return try cleanupControlledDirectory(
            paths.durableDirectory,
            sourceID: sourceID,
            knownItems: [
                paths.incomingPayload,
                paths.finalPayload
            ]
        )
    }

    private func requireOnlyExpectedContents(
        at directory: URL,
        sourceID: UUID,
        allowedNames: Set<String>
    ) throws {
        let names = try fileSystem.contentsOfDirectory(at: directory)
            .map(\.lastPathComponent)

        let unexpected = names
            .filter { !allowedNames.contains($0) }
            .sorted()

        guard unexpected.isEmpty else {
            throw RetainedEvidenceStoreError.unexpectedControlledContents(
                sourceID,
                unexpected
            )
        }
    }

    private func cleanupControlledDirectory(
        _ directory: URL,
        sourceID: UUID,
        knownItems: [URL]
    ) throws -> EvidenceCleanupOutcome {
        guard fileSystem.fileExists(at: directory) else {
            return .nothingToRemove
        }

        let knownNames = Set(knownItems.map(\.lastPathComponent))
        let initialNames = try fileSystem.contentsOfDirectory(at: directory)
            .map(\.lastPathComponent)

        let unexpected = initialNames
            .filter { !knownNames.contains($0) }
            .sorted()

        guard unexpected.isEmpty else {
            return .retainedUnexpectedContents(unexpected)
        }

        var removedAny = false

        for item in knownItems where fileSystem.fileExists(at: item) {
            try fileSystem.removeItem(at: item)
            removedAny = true
        }

        do {
            try fileSystem.removeDirectoryIfEmpty(at: directory)
            removedAny = true
        } catch {
            let remaining = try fileSystem.contentsOfDirectory(at: directory)
                .map(\.lastPathComponent)
                .sorted()

            if !remaining.isEmpty {
                return .retainedUnexpectedContents(remaining)
            }

            throw error
        }

        return removedAny
            ? .removedKnownMaterial
            : .nothingToRemove
    }
}

enum RetainedEvidenceStoreError: Error, Equatable {
    case stagedPayloadMissing(UUID)
    case incomingPayloadMissing(UUID)
    case byteVerificationFailed(UUID)
    case completeProtectionNotVerified(UUID)
    case backupExclusionDetected(UUID)
    case unexpectedControlledContents(UUID, [String])
}
