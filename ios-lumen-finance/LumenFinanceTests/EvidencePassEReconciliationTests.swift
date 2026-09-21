import XCTest
import SwiftData
@testable import LumenFinance

final class EvidencePassEReconciliationTests: XCTestCase {
    @MainActor
    func testCanonicalFinalWithZeroOwnersIsCleaned() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x01, 0x02, 0x03]),
            at: paths.finalPayload
        )

        let candidates = harness.reconciler.discoverCandidates()
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].sourceID, sourceID)
        XCTAssertEqual(candidates[0].materials, [.finalPayload])

        let result = await harness.reconciler.reconcile(
            candidates[0],
            in: harness.context
        )

        XCTAssertEqual(result.disposition, .cleaned)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .missing
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.durableDirectory),
            .missing
        )
    }

    @MainActor
    func testCanonicalIncomingWithZeroOwnersIsCleaned() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x10, 0x20]),
            at: paths.incomingPayload
        )

        let results = await harness.reconciler.reconcile(
            in: harness.context
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].disposition, .cleaned)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.incomingPayload),
            .missing
        )
    }

    @MainActor
    func testCanonicalStagingWithZeroOwnersIsCleaned() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x21, 0x22]),
            at: paths.stagedPayload
        )

        let candidates = harness.reconciler.discoverCandidates()
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].sourceID, sourceID)
        XCTAssertEqual(candidates[0].materials, [.staging])

        let result = await harness.reconciler.reconcile(
            candidates[0],
            in: harness.context
        )

        XCTAssertEqual(result.disposition, .cleaned)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.stagedPayload),
            .missing
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.stagingDirectory),
            .missing
        )
    }

    @MainActor
    func testCommittedSourceWithZeroTransactionReferencesPreservesFinalPayload() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        _ = try persistSource(
            in: harness,
            sourceIDString: sourceID.uuidString,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )

        try createPayload(
            Data([0xAA, 0xBB]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedPersistedOwner
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testDuplicateSemanticOwnersPreservePhysicalMaterial() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        _ = try persistSource(
            in: harness,
            sourceIDString: sourceID.uuidString,
            storedFileURI: nil
        )
        _ = try persistSource(
            in: harness,
            sourceIDString: sourceID.uuidString.lowercased(),
            storedFileURI: nil
        )

        try createPayload(
            Data([0x31, 0x32]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedIdentityConflict
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testOwnerAppearingAfterDiscoveryIsPreservedByFreshOwnerRead() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x41, 0x42]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        _ = try persistSource(
            in: harness,
            sourceIDString: sourceID.uuidString,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedPersistedOwner
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
    }

    @MainActor
    func testReconciliationWaitsForSharedUUIDLease() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x51, 0x52]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        let lease = await harness.operationCoordinator.acquire(
            for: sourceID
        )

        let task = Task { @MainActor in
            await harness.reconciler.reconcile(
                candidate,
                in: harness.context
            )
        }

        for _ in 0..<12 {
            await Task.yield()
        }

        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)

        await harness.operationCoordinator.release(lease)

        let result = await task.value

        XCTAssertEqual(result.disposition, .cleaned)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .missing
        )
    }

    @MainActor
    func testUnavailableLedgerAuthorizesNoDeletion() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x61, 0x62]),
            at: paths.finalPayload
        )

        let results = await harness.reconciler.reconcile(
            in: nil
        )

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testNoncanonicalUUIDDirectoryIsNotDiscoveredOrCleaned() async throws {
        let harness = try makeHarness()
        let sourceID = try XCTUnwrap(
            UUID(
                uuidString: "ABCDEF12-3456-7890-ABCD-EF1234567890"
            )
        )
        let noncanonicalDirectory = harness.roots.durableV1Root
            .appendingPathComponent(
                sourceID.uuidString.lowercased(),
                isDirectory: true
            )
        let payload = noncanonicalDirectory
            .appendingPathComponent(
                "payload",
                isDirectory: false
            )

        try createPayload(
            Data([0x71, 0x72]),
            at: payload
        )

        let results = await harness.reconciler.reconcile(
            in: harness.context
        )

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: payload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testFutureVersionLayoutIsNotDiscoveredOrCleaned() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let payload = harness.applicationSupportDirectory
            .appendingPathComponent(
                "LumenEvidence",
                isDirectory: true
            )
            .appendingPathComponent(
                "v2",
                isDirectory: true
            )
            .appendingPathComponent(
                sourceID.uuidString,
                isDirectory: true
            )
            .appendingPathComponent(
                "payload",
                isDirectory: false
            )

        try createPayload(
            Data([0x81, 0x82]),
            at: payload
        )

        let results = await harness.reconciler.reconcile(
            in: harness.context
        )

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: payload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testStaleDiscoveryDoesNotAuthorizeSymlinkDeletion() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0x91, 0x92]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        try FileManager.default.removeItem(
            at: paths.finalPayload
        )

        let external = harness.root
            .appendingPathComponent(
                "external-payload",
                isDirectory: false
            )
        let externalData = Data([0xA1, 0xA2, 0xA3])
        try externalData.write(to: external)

        try FileManager.default.createSymbolicLink(
            at: paths.finalPayload,
            withDestinationURL: external
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedUnsafeFilesystem
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .symbolicLink
        )
        XCTAssertEqual(
            try Data(contentsOf: external),
            externalData
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testUnknownContentsPreserveKnownPayload() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0xB1, 0xB2]),
            at: paths.finalPayload
        )

        let unknown = paths.durableDirectory
            .appendingPathComponent(
                "unexpected",
                isDirectory: false
            )
        try Data([0xB3]).write(to: unknown)

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedUnsafeFilesystem
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: unknown),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testInspectionFailureAfterDiscoveryPreservesMaterial() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0xC1, 0xC2]),
            at: paths.finalPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )

        harness.fileSystem.nodeKindFailureURLs.insert(
            paths.durableDirectory
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedInspectionFailure
        )
        harness.fileSystem.nodeKindFailureURLs.remove(
            paths.durableDirectory
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .regularFile
        )
        XCTAssertTrue(harness.fileSystem.removedURLs.isEmpty)
    }

    @MainActor
    func testPartialDurableCleanupFailureDoesNotBroadenIntoStagingDeletion() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0xD1]),
            at: paths.finalPayload
        )
        try createPayload(
            Data([0xD2]),
            at: paths.incomingPayload
        )
        try createPayload(
            Data([0xD3]),
            at: paths.stagedPayload
        )

        let candidate = try XCTUnwrap(
            harness.reconciler.discoverCandidates().first
        )
        XCTAssertEqual(
            candidate.materials,
            [.finalPayload, .incomingPayload, .staging]
        )

        harness.fileSystem.removeFailureURLs.insert(
            paths.incomingPayload
        )

        let result = await harness.reconciler.reconcile(
            candidate,
            in: harness.context
        )

        XCTAssertEqual(
            result.disposition,
            .retainedCleanupFailure
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .missing
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.incomingPayload),
            .regularFile
        )
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.stagedPayload),
            .regularFile
        )
        XCTAssertFalse(
            harness.fileSystem.removedURLs.contains(
                paths.stagedPayload
            )
        )
    }

    @MainActor
    func testSecondReconciliationAfterSuccessfulCleanupIsConvergentNoOp() async throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.paths(for: sourceID)

        try createPayload(
            Data([0xE1, 0xE2]),
            at: paths.finalPayload
        )

        let first = await harness.reconciler.reconcile(
            in: harness.context
        )
        let second = await harness.reconciler.reconcile(
            in: harness.context
        )

        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(first[0].disposition, .cleaned)
        XCTAssertTrue(second.isEmpty)
        XCTAssertEqual(
            try harness.fileSystem.nodeKind(at: paths.finalPayload),
            .missing
        )
    }

    @MainActor
    func testPersistedOwnerLocatorQualityNeverGrantsCleanupAuthority() async throws {
        let mismatchID = UUID()

        let locatorCases: [(String, (UUID) -> String?)] = [
            ("nil", { _ in nil }),
            ("legacy", { _ in "file:///legacy/receipt.jpg" }),
            ("malformed", { _ in "lumen-evidence://v1/not-a-uuid/payload" }),
            ("unsupported", {
                "lumen-evidence://v2/\($0.uuidString)/payload"
            }),
            ("mismatched", {
                _ in RetainedEvidenceLocator(
                    sourceID: mismatchID
                ).serialized
            })
        ]

        for (name, makeLocator) in locatorCases {
            let harness = try makeHarness()
            let sourceID = UUID()
            let paths = harness.paths(for: sourceID)

            _ = try persistSource(
                in: harness,
                sourceIDString: sourceID.uuidString,
                storedFileURI: makeLocator(sourceID)
            )

            try createPayload(
                Data([0xF1, 0xF2]),
                at: paths.finalPayload
            )

            let candidate = try XCTUnwrap(
                harness.reconciler.discoverCandidates().first,
                name
            )

            let result = await harness.reconciler.reconcile(
                candidate,
                in: harness.context
            )

            XCTAssertEqual(
                result.disposition,
                .retainedPersistedOwner,
                name
            )
            XCTAssertEqual(
                try harness.fileSystem.nodeKind(
                    at: paths.finalPayload
                ),
                .regularFile,
                name
            )
            XCTAssertTrue(
                harness.fileSystem.removedURLs.isEmpty,
                name
            )

            let owners = try EvidenceIdentity.semanticOwners(
                of: sourceID,
                in: harness.context
            )
            XCTAssertEqual(owners.count, 1, name)
        }
    }

    @MainActor
    private struct Harness {
        let root: URL
        let temporaryDirectory: URL
        let applicationSupportDirectory: URL
        let roots: RetainedEvidenceStorageRoots
        let container: ModelContainer
        let context: ModelContext
        let fileSystem: PassEFileSystem
        let operationCoordinator: EvidenceOperationCoordinator
        let reconciler: EvidenceReconciler

        func paths(
            for sourceID: UUID
        ) -> RetainedEvidencePaths {
            roots.paths(for: sourceID)
        }
    }

    @MainActor
    private func makeHarness() throws -> Harness {
        let schema = LedgerStore.schema()
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        container.mainContext.autosaveEnabled = false

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Lumen-PassE-\(UUID().uuidString)",
                isDirectory: true
            )
        let temporaryDirectory = root
            .appendingPathComponent(
                "tmp",
                isDirectory: true
            )
        let applicationSupportDirectory = root
            .appendingPathComponent(
                "Application Support",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )

        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let roots = RetainedEvidenceStorageRoots.located(
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory
        )
        let fileSystem = PassEFileSystem(
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory
        )
        let operationCoordinator = EvidenceOperationCoordinator()
        let reconciler = EvidenceReconciler(
            operationCoordinator: operationCoordinator,
            fileSystem: fileSystem,
            roots: roots
        )

        return Harness(
            root: root,
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory,
            roots: roots,
            container: container,
            context: container.mainContext,
            fileSystem: fileSystem,
            operationCoordinator: operationCoordinator,
            reconciler: reconciler
        )
    }

    @MainActor
    private func persistSource(
        in harness: Harness,
        sourceIDString: String,
        storedFileURI: String?
    ) throws -> TransactionSource {
        let source = TransactionSource(
            id: sourceIDString,
            source_type: .receipt_photo,
            stored_file_uri: storedFileURI
        )
        harness.context.insert(source)
        try harness.context.save()
        return source
    }

    private func createPayload(
        _ data: Data,
        at url: URL
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }
}

private final class PassEFileSystem: EvidenceFileSystem {
    private let base = LocalEvidenceFileSystem()
    private let applicationSupportURL: URL

    let temporaryDirectory: URL
    var nodeKindFailureURLs: Set<URL> = []
    var removeFailureURLs: Set<URL> = []
    var removedURLs: [URL] = []

    init(
        temporaryDirectory: URL,
        applicationSupportDirectory: URL
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.applicationSupportURL = applicationSupportDirectory
    }

    func applicationSupportDirectory() throws -> URL {
        try FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
        return applicationSupportURL
    }

    func nodeKind(
        at url: URL
    ) throws -> EvidenceFileNodeKind {
        if nodeKindFailureURLs.contains(url) {
            throw PassEInjectedFailure.nodeInspection
        }

        return try base.nodeKind(at: url)
    }

    func createDirectory(
        at url: URL
    ) throws {
        try base.createDirectory(at: url)
    }

    func write(
        _ data: Data,
        to url: URL,
        atomically: Bool
    ) throws {
        try base.write(
            data,
            to: url,
            atomically: atomically
        )
    }

    func read(
        _ url: URL
    ) throws -> Data {
        try base.read(url)
    }

    func contentsOfDirectory(
        at url: URL
    ) throws -> [URL] {
        try base.contentsOfDirectory(at: url)
    }

    func removeRegularFile(
        at url: URL
    ) throws {
        if removeFailureURLs.contains(url) {
            throw PassEInjectedFailure.remove
        }

        try base.removeRegularFile(at: url)
        removedURLs.append(url)
    }

    func removeDirectoryIfEmpty(
        at url: URL
    ) throws {
        try base.removeDirectoryIfEmpty(at: url)
    }

    func replaceItemAtomically(
        at destinationURL: URL,
        withItemAt sourceURL: URL
    ) throws {
        try base.replaceItemAtomically(
            at: destinationURL,
            withItemAt: sourceURL
        )
    }

    func applyCompleteFileProtection(
        at url: URL
    ) throws {
        try base.applyCompleteFileProtection(at: url)
    }

    func fileProtection(
        at url: URL
    ) throws -> URLFileProtection? {
        try base.fileProtection(at: url)
    }

    func clearBackupExclusion(
        at url: URL
    ) throws {
        try base.clearBackupExclusion(at: url)
    }

    func isExcludedFromBackup(
        at url: URL
    ) throws -> Bool {
        try base.isExcludedFromBackup(at: url)
    }
}

private enum PassEInjectedFailure: Error {
    case nodeInspection
    case remove
}
