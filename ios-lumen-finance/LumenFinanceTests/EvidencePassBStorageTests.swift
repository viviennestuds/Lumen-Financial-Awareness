import XCTest
import Foundation
@testable import LumenFinance

final class EvidencePassBStorageTests: XCTestCase {
    func testLiveRootsUseControlledTemporaryAndApplicationSupportNamespaces() throws {
        let harness = try makeHarness()
        let roots = try RetainedEvidenceStorageRoots.live(
            fileSystem: harness.fileSystem
        )

        XCTAssertEqual(
            roots.stagingRoot,
            harness.temporaryDirectory
                .appendingPathComponent("LumenEvidenceStaging", isDirectory: true)
        )
        XCTAssertEqual(
            roots.durableV1Root,
            harness.applicationSupportDirectory
                .appendingPathComponent("LumenEvidence", isDirectory: true)
                .appendingPathComponent("v1", isDirectory: true)
        )
    }

    func testPathsAreDeterministicCanonicalAndContainNoDomainMetadata() throws {
        let harness = try makeHarness()
        let sourceID = UUID(
            uuidString: "a0b1c2d3-e4f5-4678-9abc-def012345678"
        )!
        let paths = harness.store.paths(for: sourceID)

        XCTAssertEqual(
            paths.stagingDirectory.lastPathComponent,
            "A0B1C2D3-E4F5-4678-9ABC-DEF012345678"
        )
        XCTAssertEqual(paths.stagedPayload.lastPathComponent, "payload")
        XCTAssertEqual(
            paths.durableDirectory.lastPathComponent,
            "A0B1C2D3-E4F5-4678-9ABC-DEF012345678"
        )
        XCTAssertEqual(paths.incomingPayload.lastPathComponent, "payload.incoming")
        XCTAssertEqual(paths.finalPayload.lastPathComponent, "payload")

        let combined = [
            paths.stagingDirectory.path,
            paths.durableDirectory.path
        ].joined(separator: " ")

        XCTAssertFalse(combined.localizedCaseInsensitiveContains("merchant"))
        XCTAssertFalse(combined.localizedCaseInsensitiveContains("amount"))
        XCTAssertFalse(combined.localizedCaseInsensitiveContains("category"))
    }

    func testStagePreservesExactBytesAtControlledPayloadPath() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 7)

        let staged = try harness.store.stage(data, for: sourceID)
        let paths = harness.store.paths(for: sourceID)

        XCTAssertEqual(staged.sourceID, sourceID)
        XCTAssertEqual(staged.url, paths.stagedPayload)
        XCTAssertEqual(staged.byteCount, data.count)
        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testHappyPathProducesOneExactDurablyPreparedPayloadAndKeepsStaging() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 11)

        _ = try harness.store.stage(data, for: sourceID)
        let preparation = try harness.store.prepareDurablePayload(for: sourceID)
        let prepared = try harness.store.finalizeDurablePayload(for: sourceID)
        let paths = harness.store.paths(for: sourceID)

        XCTAssertEqual(preparation.sourceID, sourceID)
        XCTAssertEqual(preparation.incomingURL, paths.incomingPayload)
        XCTAssertEqual(preparation.finalURL, paths.finalPayload)
        XCTAssertEqual(preparation.byteCount, data.count)

        XCTAssertEqual(prepared.sourceID, sourceID)
        XCTAssertEqual(prepared.url, paths.finalPayload)
        XCTAssertEqual(prepared.byteCount, data.count)

        XCTAssertEqual(try Data(contentsOf: paths.finalPayload), data)
        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.incomingPayload.path))

        let durableNames = try FileManager.default
            .contentsOfDirectory(atPath: paths.durableDirectory.path)
            .sorted()
        XCTAssertEqual(durableNames, ["payload"])

        XCTAssertEqual(
            try harness.fileSystem.fileProtection(at: paths.finalPayload),
            .complete
        )
        XCTAssertFalse(
            try harness.fileSystem.isExcludedFromBackup(at: paths.finalPayload)
        )
        XCTAssertEqual(
            harness.fileSystem.appliedProtectionURLs,
            [paths.finalPayload]
        )
        XCTAssertEqual(
            harness.fileSystem.clearedBackupExclusionURLs,
            [paths.finalPayload]
        )
    }

    func testRetryConvergesOnSameDestinationWithoutNumberedPayloads() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 19)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        let first = try harness.store.finalizeDurablePayload(for: sourceID)

        _ = try harness.store.prepareDurablePayload(for: sourceID)
        let second = try harness.store.finalizeDurablePayload(for: sourceID)

        XCTAssertEqual(first.url, second.url)
        XCTAssertEqual(first.byteCount, second.byteCount)

        let paths = harness.store.paths(for: sourceID)
        let names = try FileManager.default
            .contentsOfDirectory(atPath: paths.durableDirectory.path)
            .sorted()

        XCTAssertEqual(names, ["payload"])
        XCTAssertFalse(names.contains("payload-2"))
        XCTAssertFalse(names.contains("payload-3"))
        XCTAssertEqual(try Data(contentsOf: paths.finalPayload), data)
    }

    func testStageWriteFailureNeverCreatesDurableMaterial() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.store.paths(for: sourceID)
        harness.fileSystem.writeFailureURL = paths.stagedPayload

        XCTAssertThrowsError(
            try harness.store.stage(testPayload(seed: 23), for: sourceID)
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.incomingPayload.path))
    }

    func testDurableDirectoryCreationFailureRetainsStaging() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 29)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        harness.fileSystem.createDirectoryFailureURL = paths.durableDirectory

        XCTAssertThrowsError(
            try harness.store.prepareDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testPartialIncomingWriteFailureRetainsStagingAndCannotMasqueradeAsFinal() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 31)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        harness.fileSystem.partialWriteFailureURL = paths.incomingPayload

        XCTAssertThrowsError(
            try harness.store.prepareDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.incomingPayload.path))
    }

    func testPartialIncomingWriteAndCleanupFailureRetainsOnlyIncomingAsNonfinalMaterial() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 33)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        harness.fileSystem.partialWriteFailureURL = paths.incomingPayload
        harness.fileSystem.removeFailureURL = paths.incomingPayload

        XCTAssertThrowsError(
            try harness.store.prepareDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.incomingPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))

        let partial = try Data(contentsOf: paths.incomingPayload)
        XCTAssertNotEqual(partial, data)
        XCTAssertLessThan(partial.count, data.count)
    }

    func testIncomingByteMismatchIsRejectedAndCleanedWithoutTouchingStaging() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 37)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        harness.fileSystem.corruptWriteURL = paths.incomingPayload

        XCTAssertThrowsError(
            try harness.store.prepareDurablePayload(for: sourceID)
        ) { error in
            XCTAssertEqual(
                error as? RetainedEvidenceStoreError,
                .byteVerificationFailed(sourceID)
            )
        }

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.incomingPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testFinalizationFailureRetainsStagingAndIncomingWithoutFalseFinalState() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 41)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.replaceFailure = true

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertEqual(try Data(contentsOf: paths.incomingPayload), data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testProtectionFailureNeverReportsDurablyPreparedSuccessAndKeepsStaging() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 43)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.applyProtectionFailure = true

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testProtectionVerificationMismatchNeverReportsDurablyPreparedSuccess() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 45)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.forcedFileProtection = .none

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        ) { error in
            XCTAssertEqual(
                error as? RetainedEvidenceStoreError,
                .completeProtectionNotVerified(sourceID)
            )
        }

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testLocalFileSystemCompleteProtectionCharacterization() throws {
        let harness = try makeHarness()
        let fileURL = harness.root.appendingPathComponent("protection-probe")
        try Data([0x01, 0x02, 0x03]).write(to: fileURL)

        let local = LocalEvidenceFileSystem()
        try local.applyCompleteFileProtection(at: fileURL)

        guard let reported = try local.fileProtection(at: fileURL) else {
            throw XCTSkip("This environment does not report file-protection resource values")
        }

#if targetEnvironment(simulator)
        guard reported == .complete else {
            throw XCTSkip(
                "The simulator reports \(reported.rawValue) after a successful Complete-protection set"
            )
        }
#endif

        XCTAssertEqual(reported, .complete)
    }

    func testBackupEligibilityApplicationFailureNeverReportsDurablyPreparedSuccess() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 46)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.clearBackupExclusionFailure = true

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        )

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
        XCTAssertEqual(
            harness.fileSystem.clearedBackupExclusionURLs,
            [paths.finalPayload]
        )
    }

    func testBackupExclusionVerificationFailureNeverReportsDurablyPreparedSuccess() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 47)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.forcedBackupExclusion = true

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        ) { error in
            XCTAssertEqual(
                error as? RetainedEvidenceStoreError,
                .backupExclusionDetected(sourceID)
            )
        }

        XCTAssertEqual(try Data(contentsOf: paths.stagedPayload), data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    func testRetryDoesNotPreserveStaleFinalBackupExclusionMetadata() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 51)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        _ = try harness.store.finalizeDurablePayload(for: sourceID)

        try (paths.finalPayload as NSURL).setResourceValue(
            true,
            forKey: .isExcludedFromBackupKey
        )
        XCTAssertTrue(
            try LocalEvidenceFileSystem().isExcludedFromBackup(at: paths.finalPayload)
        )

        _ = try harness.store.prepareDurablePayload(for: sourceID)
        _ = try harness.store.finalizeDurablePayload(for: sourceID)

        XCTAssertFalse(
            try LocalEvidenceFileSystem().isExcludedFromBackup(at: paths.finalPayload)
        )
        XCTAssertEqual(try Data(contentsOf: paths.finalPayload), data)
    }

    func testRetryAfterPostFinalizationVerificationFailureRepreparesFromStaging() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 53)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        harness.fileSystem.forcedBackupExclusion = true

        XCTAssertThrowsError(
            try harness.store.finalizeDurablePayload(for: sourceID)
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))

        harness.fileSystem.forcedBackupExclusion = nil
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        let retry = try harness.store.finalizeDurablePayload(for: sourceID)

        XCTAssertEqual(retry.url, paths.finalPayload)
        XCTAssertEqual(try Data(contentsOf: paths.finalPayload), data)

        let names = try FileManager.default
            .contentsOfDirectory(atPath: paths.durableDirectory.path)
            .sorted()
        XCTAssertEqual(names, ["payload"])
    }

    func testCleanupRetainsEntireControlledDirectoryWhenUnexpectedMaterialExists() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 59)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        _ = try harness.store.finalizeDurablePayload(for: sourceID)

        let unknown = paths.durableDirectory
            .appendingPathComponent("unknown-material")
        try Data([0x01]).write(to: unknown)

        let outcome = try harness.store.cleanupPreparedDurableMaterial(for: sourceID)

        XCTAssertEqual(
            outcome,
            .retainedUnexpectedContents(["unknown-material"])
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unknown.path))
    }

    func testCleanupRemovesOnlyKnownMaterialAndControlledSourceDirectory() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(testPayload(seed: 61), for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)

        XCTAssertEqual(
            try harness.store.cleanupStaging(for: sourceID),
            .removedKnownMaterial
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.stagedPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.stagingDirectory.path))

        XCTAssertEqual(
            try harness.store.cleanupPreparedDurableMaterial(for: sourceID),
            .removedKnownMaterial
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.incomingPayload.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.durableDirectory.path))
    }

    func testCleanupFailurePropagatesAndDoesNotClaimSuccess() throws {
        let harness = try makeHarness()
        let sourceID = UUID()
        let data = testPayload(seed: 67)
        let paths = harness.store.paths(for: sourceID)

        _ = try harness.store.stage(data, for: sourceID)
        _ = try harness.store.prepareDurablePayload(for: sourceID)
        _ = try harness.store.finalizeDurablePayload(for: sourceID)

        harness.fileSystem.removeFailureURL = paths.finalPayload

        XCTAssertThrowsError(
            try harness.store.cleanupPreparedDurableMaterial(for: sourceID)
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.finalPayload.path))
    }

    private struct Harness {
        let root: URL
        let temporaryDirectory: URL
        let applicationSupportDirectory: URL
        let fileSystem: FaultInjectingEvidenceFileSystem
        let store: RetainedEvidenceStore
    }

    private func makeHarness() throws -> Harness {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Lumen-PassB-\(UUID().uuidString)",
                isDirectory: true
            )

        let temporaryDirectory = root
            .appendingPathComponent("tmp", isDirectory: true)
        let applicationSupportDirectory = root
            .appendingPathComponent("Application Support", isDirectory: true)

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

        let fileSystem = FaultInjectingEvidenceFileSystem(
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory
        )

        let roots = RetainedEvidenceStorageRoots(
            stagingRoot: temporaryDirectory
                .appendingPathComponent("LumenEvidenceStaging", isDirectory: true),
            durableV1Root: applicationSupportDirectory
                .appendingPathComponent("LumenEvidence", isDirectory: true)
                .appendingPathComponent("v1", isDirectory: true)
        )

        let store = RetainedEvidenceStore(
            fileSystem: fileSystem,
            roots: roots
        )

        return Harness(
            root: root,
            temporaryDirectory: temporaryDirectory,
            applicationSupportDirectory: applicationSupportDirectory,
            fileSystem: fileSystem,
            store: store
        )
    }

    private func testPayload(seed: UInt8) -> Data {
        Data((0..<4096).map { index in
            UInt8((Int(seed) + index * 37) % 256)
        })
    }
}

private final class FaultInjectingEvidenceFileSystem: EvidenceFileSystem {
    private let base = LocalEvidenceFileSystem()

    let temporaryDirectory: URL
    private let applicationSupportURL: URL

    var createDirectoryFailureURL: URL?
    var writeFailureURL: URL?
    var partialWriteFailureURL: URL?
    var corruptWriteURL: URL?
    var removeFailureURL: URL?
    var replaceFailure = false
    var applyProtectionFailure = false
    var forcedFileProtection: URLFileProtection? = .complete
    private(set) var appliedProtectionURLs: [URL] = []
    var clearBackupExclusionFailure = false
    private(set) var clearedBackupExclusionURLs: [URL] = []
    var forcedBackupExclusion: Bool?

    init(
        temporaryDirectory: URL,
        applicationSupportDirectory: URL
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.applicationSupportURL = applicationSupportDirectory
    }

    func applicationSupportDirectory() throws -> URL {
        applicationSupportURL
    }

    func createDirectory(at url: URL) throws {
        if url == createDirectoryFailureURL {
            throw EvidencePassBInjectedFailure.injected
        }
        try base.createDirectory(at: url)
    }

    func write(
        _ data: Data,
        to url: URL,
        atomically: Bool
    ) throws {
        if url == writeFailureURL {
            throw EvidencePassBInjectedFailure.injected
        }

        if url == partialWriteFailureURL {
            let prefixCount = max(1, data.count / 3)
            try base.write(
                Data(data.prefix(prefixCount)),
                to: url,
                atomically: false
            )
            throw EvidencePassBInjectedFailure.injected
        }

        if url == corruptWriteURL {
            var corrupted = data
            if corrupted.isEmpty {
                corrupted.append(0xFF)
            } else {
                corrupted[corrupted.startIndex] ^= 0xFF
            }
            try base.write(
                corrupted,
                to: url,
                atomically: atomically
            )
            return
        }

        try base.write(data, to: url, atomically: atomically)
    }

    func read(_ url: URL) throws -> Data {
        try base.read(url)
    }

    func fileExists(at url: URL) -> Bool {
        base.fileExists(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try base.contentsOfDirectory(at: url)
    }

    func removeItem(at url: URL) throws {
        if url == removeFailureURL {
            throw EvidencePassBInjectedFailure.injected
        }
        try base.removeItem(at: url)
    }

    func removeDirectoryIfEmpty(at url: URL) throws {
        try base.removeDirectoryIfEmpty(at: url)
    }

    func replaceItemAtomically(
        at destinationURL: URL,
        withItemAt sourceURL: URL
    ) throws {
        if replaceFailure {
            throw EvidencePassBInjectedFailure.injected
        }
        try base.replaceItemAtomically(
            at: destinationURL,
            withItemAt: sourceURL
        )
    }

    func applyCompleteFileProtection(at url: URL) throws {
        appliedProtectionURLs.append(url)
        if applyProtectionFailure {
            throw EvidencePassBInjectedFailure.injected
        }
        try base.applyCompleteFileProtection(at: url)
    }

    func fileProtection(at url: URL) throws -> URLFileProtection? {
        if let forcedFileProtection {
            return forcedFileProtection
        }
        return try base.fileProtection(at: url)
    }

    func clearBackupExclusion(at url: URL) throws {
        clearedBackupExclusionURLs.append(url)
        if clearBackupExclusionFailure {
            throw EvidencePassBInjectedFailure.injected
        }
        try base.clearBackupExclusion(at: url)
    }

    func isExcludedFromBackup(at url: URL) throws -> Bool {
        if let forcedBackupExclusion {
            return forcedBackupExclusion
        }
        return try base.isExcludedFromBackup(at: url)
    }
}

private enum EvidencePassBInjectedFailure: Error {
    case injected
}
