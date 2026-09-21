import XCTest
import SwiftData
@testable import LumenFinance

final class EvidencePassDAvailabilityTests: XCTestCase {
    @MainActor
    func testNoSourceMeansNoEvidenceExpectedWithoutTouchingEvidenceStorage() throws {
        let harness = try makeHarness()

        let resolution = try harness.resolver.resolve(
            source: nil,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .noEvidenceExpected,
                physicalObservation: .notApplicable
            )
        )
        XCTAssertEqual(
            harness.fileSystem.applicationSupportLookupCount,
            0
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: harness.evidenceRoot.path
            )
        )
    }

    @MainActor
    func testNilLocatorIsLegitimateNoRetainedLocatorAndDoesNotCreateStorage() throws {
        let harness = try makeHarness()
        let source = try persistSource(
            in: harness,
            sourceType: .receipt_photo,
            storedFileURI: nil,
            fileSizeBytes: 4_525_686,
            mimeType: "image/png"
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .noRetainedLocator,
                physicalObservation: .notApplicable
            )
        )
        XCTAssertEqual(
            harness.fileSystem.applicationSupportLookupCount,
            0
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: harness.evidenceRoot.path
            )
        )
    }

    @MainActor
    func testSourceTypeMimeAndSizeDoNotCreateAvailability() throws {
        let harness = try makeHarness()
        let source = try persistSource(
            in: harness,
            sourceType: .screenshot,
            storedFileURI: nil,
            fileSizeBytes: 999_999,
            mimeType: "image/jpeg"
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(resolution.state, .noRetainedLocator)
        XCTAssertEqual(
            resolution.physicalObservation,
            .notApplicable
        )
    }

    @MainActor
    func testUniqueSupportedLocatorAndReadableRegularPayloadIsAvailable() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)
        let payload = Data([0x10, 0x20, 0x30, 0x40])
        try createPayload(
            payload,
            at: paths.finalPayload
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .available,
                physicalObservation: .regularPayloadReadable
            )
        )
        XCTAssertEqual(
            harness.fileSystem.readURLs,
            [paths.finalPayload]
        )
    }

    @MainActor
    func testUniqueSupportedLocatorAndMissingPayloadIsExpectedButUnavailableWithoutCreatingRoots() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: harness.evidenceRoot.path
            )
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .missing
            )
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: harness.evidenceRoot.path
            )
        )
    }

    @MainActor
    func testRegularPayloadReadFailureIsUnavailableNotMissing() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)
        try createPayload(
            Data([0x01, 0x02, 0x03]),
            at: paths.finalPayload
        )
        harness.fileSystem.readFailureURLs.insert(
            paths.finalPayload
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .unreadable
            )
        )
    }

    @MainActor
    func testDirectoryAtFinalPayloadIsUnavailableWithUnexpectedNodeReason() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)

        try FileManager.default.createDirectory(
            at: paths.finalPayload,
            withIntermediateDirectories: true
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .unexpectedNodeKind(.directory)
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: paths.finalPayload.path
            )
        )
    }

    @MainActor
    func testSymlinkAtFinalPayloadIsUnavailableAndNeverRead() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)

        try FileManager.default.createDirectory(
            at: paths.durableDirectory,
            withIntermediateDirectories: true
        )
        let external = harness.root
            .appendingPathComponent("external-payload")
        let externalData = Data([0xAA, 0xBB, 0xCC])
        try externalData.write(to: external)
        try FileManager.default.createSymbolicLink(
            at: paths.finalPayload,
            withDestinationURL: external
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .unexpectedNodeKind(.symbolicLink)
            )
        )
        XCTAssertFalse(
            harness.fileSystem.readURLs.contains(
                paths.finalPayload
            )
        )
        XCTAssertEqual(
            try Data(contentsOf: external),
            externalData
        )
    }

    @MainActor
    func testSymlinkedControlledEvidenceRootFailsClosedBeforePayloadRead() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )

        try FileManager.default.createDirectory(
            at: harness.applicationSupportDirectory,
            withIntermediateDirectories: true
        )

        let externalEvidenceRoot = harness.root
            .appendingPathComponent(
                "ExternalLumenEvidence",
                isDirectory: true
            )
        let externalPaths = RetainedEvidenceStorageRoots.located(
            temporaryDirectory: harness.temporaryDirectory,
            applicationSupportDirectory: harness.root
        )
        .paths(for: sourceID)

        try FileManager.default.createDirectory(
            at: externalPaths.durableDirectory,
            withIntermediateDirectories: true
        )
        let externalData = Data([0x91, 0x92, 0x93])
        try externalData.write(
            to: externalPaths.finalPayload
        )

        let controlledEvidenceRoot = harness.evidenceRoot
        try FileManager.default.createSymbolicLink(
            at: controlledEvidenceRoot,
            withDestinationURL: externalEvidenceRoot
        )

        let externalV1 = externalEvidenceRoot
            .appendingPathComponent("v1", isDirectory: true)
        let externalUUID = externalV1
            .appendingPathComponent(
                sourceID.uuidString,
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: externalUUID,
            withIntermediateDirectories: true
        )
        let externalPayload = externalUUID
            .appendingPathComponent(
                "payload",
                isDirectory: false
            )
        try externalData.write(to: externalPayload)

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .unexpectedNodeKind(.symbolicLink)
            )
        )
        XCTAssertFalse(
            harness.fileSystem.readURLs.contains(
                externalPayload
            )
        )
        XCTAssertEqual(
            try Data(contentsOf: externalPayload),
            externalData
        )
    }

    @MainActor
    func testOtherNodeKindIsPreservedAsUnavailableDiagnostic() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)
        harness.fileSystem.forcedNodeKinds[
            paths.finalPayload
        ] = .other

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .unexpectedNodeKind(.other)
            )
        )
    }

    @MainActor
    func testFilesystemInspectionFailureIsUnavailableWithoutRepair() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: sourceID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        let paths = harness.paths(for: sourceID)
        harness.fileSystem.nodeKindFailureURLs.insert(
            paths.finalPayload
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .expectedButUnavailable,
                physicalObservation: .inspectionFailure
            )
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: harness.evidenceRoot.path
            )
        )
    }

    @MainActor
    func testDuplicateSemanticOwnerWinsBeforeMalformedLocatorOrPhysicalObservation() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let first = TransactionSource(
            id: sourceID.uuidString,
            source_type: .receipt_photo,
            stored_file_uri: "lumen-evidence://v1/not-a-uuid/payload"
        )
        let second = TransactionSource(
            id: sourceID.uuidString.lowercased(),
            source_type: .screenshot,
            stored_file_uri: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )
        harness.context.insert(first)
        harness.context.insert(second)
        try harness.context.save()

        let paths = harness.paths(for: sourceID)
        try createPayload(
            Data([0x55, 0x66]),
            at: paths.finalPayload
        )

        let resolution = try harness.resolver.resolve(
            source: first,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .identityConflict,
                physicalObservation: .notApplicable
            )
        )
        XCTAssertEqual(
            harness.fileSystem.applicationSupportLookupCount,
            0
        )
        XCTAssertTrue(harness.fileSystem.readURLs.isEmpty)
    }

    @MainActor
    func testSupportedLocatorForDifferentUUIDIsInvalidAssociationEvenWhenPhysicalPayloadExists() throws {
        let harness = try makeHarness()
        let ownerID = UUID()
        let locatorID = UUID()
        let source = try persistSource(
            in: harness,
            sourceID: ownerID,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: locatorID
            ).serialized
        )
        let locatorPaths = harness.paths(for: locatorID)
        try createPayload(
            Data([0xDE, 0xAD, 0xBE, 0xEF]),
            at: locatorPaths.finalPayload
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution,
            EvidenceAvailabilityResolution(
                state: .invalidAssociation,
                physicalObservation: .notApplicable
            )
        )
        XCTAssertEqual(
            harness.fileSystem.applicationSupportLookupCount,
            0
        )
        XCTAssertTrue(harness.fileSystem.readURLs.isEmpty)
    }

    @MainActor
    func testMalformedUnsupportedAndLegacyLocatorsRemainDistinct() throws {
        let malformedHarness = try makeHarness()
        let malformedID = UUID()
        let malformed = try persistSource(
            in: malformedHarness,
            sourceID: malformedID,
            storedFileURI: "lumen-evidence://v1/not-a-uuid/payload"
        )

        XCTAssertEqual(
            try malformedHarness.resolver.resolve(
                source: malformed,
                in: malformedHarness.context
            ).state,
            .invalidLocator
        )

        let unsupportedHarness = try makeHarness()
        let unsupportedID = UUID()
        let unsupported = try persistSource(
            in: unsupportedHarness,
            sourceID: unsupportedID,
            storedFileURI: "lumen-evidence://v2/\(unsupportedID.uuidString)/payload"
        )

        XCTAssertEqual(
            try unsupportedHarness.resolver.resolve(
                source: unsupported,
                in: unsupportedHarness.context
            ).state,
            .unsupportedVersion("v2")
        )

        let legacyHarness = try makeHarness()
        let legacy = try persistSource(
            in: legacyHarness,
            sourceIDString: "legacy-source-id",
            sourceType: .receipt_photo,
            storedFileURI: "file:///private/var/mobile/tmp/receipt.jpg"
        )

        XCTAssertEqual(
            try legacyHarness.resolver.resolve(
                source: legacy,
                in: legacyHarness.context
            ).state,
            .legacyOpaque
        )
    }

    @MainActor
    func testV1LocatorOnNonUUIDHistoricalSourceFailsAssociationWithoutFilesystemLookup() throws {
        let harness = try makeHarness()
        let locatorID = UUID()
        let source = try persistSource(
            in: harness,
            sourceIDString: "historical-source",
            sourceType: .receipt_photo,
            storedFileURI: RetainedEvidenceLocator(
                sourceID: locatorID
            ).serialized
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution.state,
            .invalidAssociation
        )
        XCTAssertEqual(
            harness.fileSystem.applicationSupportLookupCount,
            0
        )
    }

    @MainActor
    func testUnsavedUUIDSourceDoesNotMasqueradeAsAuthoritativeAvailability() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let source = TransactionSource(
            id: sourceID.uuidString,
            source_type: .receipt_photo,
            stored_file_uri: RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized
        )

        let resolution = try harness.resolver.resolve(
            source: source,
            in: harness.context
        )

        XCTAssertEqual(
            resolution.state,
            .identityConflict
        )
        XCTAssertEqual(
            resolution.physicalObservation,
            .notApplicable
        )
    }

    // MARK: - Helpers

    @MainActor
    private struct Harness {
        let root: URL
        let temporaryDirectory: URL
        let applicationSupportDirectory: URL
        let evidenceRoot: URL
        let context: ModelContext
        let fileSystem: PassDAvailabilityFileSystem
        let resolver: EvidenceAvailabilityResolver

        func paths(
            for sourceID: UUID
        ) -> RetainedEvidencePaths {
            RetainedEvidenceStorageRoots.located(
                temporaryDirectory: temporaryDirectory,
                applicationSupportDirectory: applicationSupportDirectory
            )
            .paths(for: sourceID)
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
                "Lumen-PassD-\(UUID().uuidString)",
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

        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let fileSystem = PassDAvailabilityFileSystem(
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory
        )

        return Harness(
            root: root,
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory,
            evidenceRoot: applicationSupportDirectory
                .appendingPathComponent(
                    "LumenEvidence",
                    isDirectory: true
                ),
            context: container.mainContext,
            fileSystem: fileSystem,
            resolver: EvidenceAvailabilityResolver(
                fileSystem: fileSystem
            )
        )
    }

    @MainActor
    private func persistSource(
        in harness: Harness,
        sourceID: UUID = UUID(),
        sourceType: SourceType = .receipt_photo,
        storedFileURI: String?,
        fileSizeBytes: Int? = nil,
        mimeType: String? = nil
    ) throws -> TransactionSource {
        try persistSource(
            in: harness,
            sourceIDString: sourceID.uuidString,
            sourceType: sourceType,
            storedFileURI: storedFileURI,
            fileSizeBytes: fileSizeBytes,
            mimeType: mimeType
        )
    }

    @MainActor
    private func persistSource(
        in harness: Harness,
        sourceIDString: String,
        sourceType: SourceType,
        storedFileURI: String?,
        fileSizeBytes: Int? = nil,
        mimeType: String? = nil
    ) throws -> TransactionSource {
        let source = TransactionSource(
            id: sourceIDString,
            source_type: sourceType,
            stored_file_uri: storedFileURI,
            file_size_bytes: fileSizeBytes,
            mime_type: mimeType
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

private final class PassDAvailabilityFileSystem:
    EvidenceAvailabilityFileSystem {
    private let base = LocalEvidenceFileSystem()

    let temporaryDirectory: URL
    private let applicationSupportURL: URL

    var applicationSupportLookupCount = 0
    var nodeKindFailureURLs: Set<URL> = []
    var readFailureURLs: Set<URL> = []
    var forcedNodeKinds: [URL: EvidenceFileNodeKind] = [:]
    var nodeKindURLs: [URL] = []
    var readURLs: [URL] = []

    init(
        temporaryDirectory: URL,
        applicationSupportDirectory: URL
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.applicationSupportURL = applicationSupportDirectory
    }

    func applicationSupportDirectoryURL() throws -> URL {
        applicationSupportLookupCount += 1
        return applicationSupportURL
    }

    func nodeKind(
        at url: URL
    ) throws -> EvidenceFileNodeKind {
        nodeKindURLs.append(url)

        if nodeKindFailureURLs.contains(url) {
            throw PassDInjectedFailure.nodeInspection
        }

        if let forced = forcedNodeKinds[url] {
            return forced
        }

        return try base.nodeKind(at: url)
    }

    func read(
        _ url: URL
    ) throws -> Data {
        readURLs.append(url)

        if readFailureURLs.contains(url) {
            throw PassDInjectedFailure.read
        }

        return try base.read(url)
    }
}

private enum PassDInjectedFailure: Error {
    case nodeInspection
    case read
}
