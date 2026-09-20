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

enum EvidenceCleanupOutcome {
    case nothingToRemove
    case removedKnownMaterial
    case retainedUnexpectedContents([String])
    case retainedUnexpectedNodeKinds([String])
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
        try requireControlledPayloadDirectory(
            at: paths.stagingDirectory,
            sourceID: sourceID,
            allowedNames: ["payload"]
        )

        try fileSystem.write(
            data,
            to: paths.stagedPayload,
            atomically: true
        )

        try requireRegularPayload(
            at: paths.stagedPayload,
            sourceID: sourceID,
            missingError: .stagedPayloadMissing(sourceID)
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

        try requireControlledPayloadDirectory(
            at: paths.stagingDirectory,
            sourceID: sourceID,
            allowedNames: ["payload"]
        )
        try requireRegularPayload(
            at: paths.stagedPayload,
            sourceID: sourceID,
            missingError: .stagedPayloadMissing(sourceID)
        )

        let stagedData = try fileSystem.read(paths.stagedPayload)

        try fileSystem.createDirectory(
            at: roots.durableV1Root.deletingLastPathComponent()
        )
        try fileSystem.createDirectory(at: roots.durableV1Root)
        try fileSystem.createDirectory(at: paths.durableDirectory)
        try requireControlledPayloadDirectory(
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

            try requireRegularPayload(
                at: paths.incomingPayload,
                sourceID: sourceID,
                missingError: .incomingPayloadMissing(sourceID)
            )

            let incomingData = try fileSystem.read(paths.incomingPayload)
            guard incomingData == stagedData else {
                throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
            }
        } catch {
            try? fileSystem.removeRegularFile(at: paths.incomingPayload)
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

        try requireControlledPayloadDirectory(
            at: paths.stagingDirectory,
            sourceID: sourceID,
            allowedNames: ["payload"]
        )
        try requireControlledPayloadDirectory(
            at: paths.durableDirectory,
            sourceID: sourceID,
            allowedNames: ["payload.incoming", "payload"]
        )

        try requireRegularPayload(
            at: paths.stagedPayload,
            sourceID: sourceID,
            missingError: .stagedPayloadMissing(sourceID)
        )
        try requireRegularPayload(
            at: paths.incomingPayload,
            sourceID: sourceID,
            missingError: .incomingPayloadMissing(sourceID)
        )

        let stagedData = try fileSystem.read(paths.stagedPayload)
        let incomingData = try fileSystem.read(paths.incomingPayload)

        guard incomingData == stagedData else {
            throw RetainedEvidenceStoreError.byteVerificationFailed(sourceID)
        }

        try fileSystem.replaceItemAtomically(
            at: paths.finalPayload,
            withItemAt: paths.incomingPayload
        )

        try requireRegularPayload(
            at: paths.finalPayload,
            sourceID: sourceID,
            missingError: .finalPayloadMissing(sourceID)
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

    private func requireControlledPayloadDirectory(
        at directory: URL,
        sourceID: UUID,
        allowedNames: Set<String>
    ) throws {
        let directoryKind = try fileSystem.nodeKind(at: directory)
        guard directoryKind == .directory else {
            throw RetainedEvidenceStoreError.unexpectedControlledNodeKind(
                sourceID,
                directory.lastPathComponent,
                directoryKind
            )
        }

        let items = try fileSystem.contentsOfDirectory(at: directory)

        let unexpectedNames = items
            .map(\.lastPathComponent)
            .filter { !allowedNames.contains($0) }
            .sorted()

        guard unexpectedNames.isEmpty else {
            throw RetainedEvidenceStoreError.unexpectedControlledContents(
                sourceID,
                unexpectedNames
            )
        }

        for item in items {
            let name = item.lastPathComponent
            guard allowedNames.contains(name) else {
                continue
            }

            let kind = try fileSystem.nodeKind(at: item)
            guard kind == .regularFile else {
                throw RetainedEvidenceStoreError.unexpectedControlledNodeKind(
                    sourceID,
                    name,
                    kind
                )
            }
        }
    }

    private func requireRegularPayload(
        at url: URL,
        sourceID: UUID,
        missingError: RetainedEvidenceStoreError
    ) throws {
        let kind = try fileSystem.nodeKind(at: url)

        if kind == .missing {
            throw missingError
        }

        guard kind == .regularFile else {
            throw RetainedEvidenceStoreError.unexpectedControlledNodeKind(
                sourceID,
                url.lastPathComponent,
                kind
            )
        }
    }

    private func cleanupControlledDirectory(
        _ directory: URL,
        sourceID: UUID,
        knownItems: [URL]
    ) throws -> EvidenceCleanupOutcome {
        let directoryKind = try fileSystem.nodeKind(at: directory)

        if directoryKind == .missing {
            return .nothingToRemove
        }

        guard directoryKind == .directory else {
            return .retainedUnexpectedNodeKinds([
                describeNode(
                    name: directory.lastPathComponent,
                    kind: directoryKind
                )
            ])
        }

        let knownNames = Set(knownItems.map(\.lastPathComponent))
        let initialItems = try fileSystem.contentsOfDirectory(at: directory)

        let unexpectedNames = initialItems
            .map(\.lastPathComponent)
            .filter { !knownNames.contains($0) }
            .sorted()

        guard unexpectedNames.isEmpty else {
            return .retainedUnexpectedContents(unexpectedNames)
        }

        var unsafeKinds: [String] = []

        for item in knownItems {
            let kind = try fileSystem.nodeKind(at: item)

            switch kind {
            case .missing, .regularFile:
                continue
            case .directory, .symbolicLink, .other:
                unsafeKinds.append(
                    describeNode(
                        name: item.lastPathComponent,
                        kind: kind
                    )
                )
            }
        }

        guard unsafeKinds.isEmpty else {
            return .retainedUnexpectedNodeKinds(unsafeKinds.sorted())
        }

        for item in knownItems {
            if try fileSystem.nodeKind(at: item) == .regularFile {
                try fileSystem.removeRegularFile(at: item)
            }
        }

        do {
            try fileSystem.removeDirectoryIfEmpty(at: directory)
        } catch {
            let remainingItems = try fileSystem.contentsOfDirectory(at: directory)

            if !remainingItems.isEmpty {
                let retainedKinds = try remainingItems.compactMap { item -> String? in
                    let name = item.lastPathComponent
                    guard knownNames.contains(name) else {
                        return nil
                    }

                    let kind = try fileSystem.nodeKind(at: item)
                    guard kind != .regularFile else {
                        return nil
                    }

                    return describeNode(name: name, kind: kind)
                }
                .sorted()

                if !retainedKinds.isEmpty {
                    return .retainedUnexpectedNodeKinds(retainedKinds)
                }

                return .retainedUnexpectedContents(
                    remainingItems
                        .map(\.lastPathComponent)
                        .sorted()
                )
            }

            throw error
        }

        return .removedKnownMaterial
    }

    private func describeNode(
        name: String,
        kind: EvidenceFileNodeKind
    ) -> String {
        "\(name):\(nodeKindName(kind))"
    }

    private func nodeKindName(
        _ kind: EvidenceFileNodeKind
    ) -> String {
        switch kind {
        case .missing:
            return "missing"
        case .regularFile:
            return "regularFile"
        case .directory:
            return "directory"
        case .symbolicLink:
            return "symbolicLink"
        case .other:
            return "other"
        }
    }
}

enum RetainedEvidenceStoreError: Error, Equatable {
    case stagedPayloadMissing(UUID)
    case incomingPayloadMissing(UUID)
    case finalPayloadMissing(UUID)
    case byteVerificationFailed(UUID)
    case completeProtectionNotVerified(UUID)
    case backupExclusionDetected(UUID)
    case unexpectedControlledContents(UUID, [String])
    case unexpectedControlledNodeKind(
        UUID,
        String,
        EvidenceFileNodeKind
    )
}
