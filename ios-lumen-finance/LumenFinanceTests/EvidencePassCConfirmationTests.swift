import XCTest
import Foundation
import SwiftData
@testable import LumenFinance

final class EvidencePassCConfirmationTests: XCTestCase {
    @MainActor
    func testRetainedConfirmationPersistsLocatorThenCleansStaging() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 11)
        let paths = harness.store.paths(for: fixture.sourceID)

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .terminal(.saved) = result else {
            return XCTFail("Expected retained confirmation to save")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            1
        )

        let source = try XCTUnwrap(
            try harness.context.fetch(FetchDescriptor<Transaction>())
                .first?.source
        )

        XCTAssertEqual(
            source.stored_file_uri,
            RetainedEvidenceLocator(sourceID: fixture.sourceID).serialized
        )
        XCTAssertNil(
            fixture.draft.source?.stored_file_uri,
            "The locator must become durable on the confirmation-time source copy, not the transient draft source"
        )
        XCTAssertEqual(source.file_size_bytes, fixture.data.count)
        XCTAssertEqual(source.mime_type, "image/jpeg")

        try assertRegularFile(
            paths.finalPayload,
            fileSystem: harness.fileSystem
        )
        try assertMissing(
            paths.stagedPayload,
            fileSystem: harness.fileSystem
        )

        guard case .none = fixture.draft.evidenceRetentionState else {
            return XCTFail("Successful retained save must clear transient evidence state")
        }
    }

    @MainActor
    func testRetentionFailureKeepsDraftAndStagingAndDoesNotWriteLedger() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 13)
        let paths = harness.store.paths(for: fixture.sourceID)
        harness.fileSystem.writeFailureURL = paths.incomingPayload

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let failure) = result,
              case .retentionFailedRetryable = failure.state else {
            return XCTFail("Expected retryable retention failure")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            0
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
        guard case .staged = fixture.draft.evidenceRetentionState else {
            return XCTFail("Retention failure must preserve staged draft state")
        }
    }

    @MainActor
    func testRetainedLedgerFailureLeavesNoCanonicalAssociationAndPreservesStaging() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 17)
        let paths = harness.store.paths(for: fixture.sourceID)

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence,
            ledgerCommit: { _ in
                throw PassCInjectedFailure.ledgerWrite
            }
        )

        guard case .nonterminal(let failure) = result,
              case .ledgerFailedRetryable(.retainedEvidence) = failure.state else {
            return XCTFail("Expected retained ledger failure to remain retryable")
        }

        let fresh = ModelContext(harness.container)
        fresh.autosaveEnabled = false
        XCTAssertEqual(
            try fresh.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try fresh.fetchCount(FetchDescriptor<TransactionSource>()),
            0
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
        try assertMissing(
            paths.finalPayload,
            fileSystem: harness.fileSystem
        )
    }

    @MainActor
    func testExplicitSaveWithoutEvidenceAfterRetentionFailurePersistsNilLocator() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 19)
        let paths = harness.store.paths(for: fixture.sourceID)
        harness.fileSystem.writeFailureURL = paths.incomingPayload

        let retainedResult = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let failure) = retainedResult,
              case .retentionFailedRetryable = failure.state else {
            return XCTFail("Expected retention failure before explicit downgrade")
        }

        harness.fileSystem.writeFailureURL = nil

        let withoutResult = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .saveWithoutRetainedEvidence
        )

        guard case .terminal(.savedWithoutEvidence) = withoutResult else {
            return XCTFail("Expected explicit save without retained evidence")
        }

        let transaction = try XCTUnwrap(
            try harness.context.fetch(FetchDescriptor<Transaction>()).first
        )
        let source = try XCTUnwrap(transaction.source)

        XCTAssertNil(source.stored_file_uri)
        XCTAssertEqual(source.id, fixture.sourceID.uuidString)
        XCTAssertEqual(source.file_size_bytes, fixture.data.count)
        XCTAssertEqual(source.mime_type, "image/jpeg")
        try assertMissing(
            paths.stagedPayload,
            fileSystem: harness.fileSystem
        )
        try assertMissing(
            paths.finalPayload,
            fileSystem: harness.fileSystem
        )
    }

    @MainActor
    func testSaveWithoutEvidenceLedgerFailureCannotReturnToRetainedConfirmation() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 23)
        let paths = harness.store.paths(for: fixture.sourceID)

        let failed = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .saveWithoutRetainedEvidence,
            ledgerCommit: { _ in
                throw PassCInjectedFailure.ledgerWrite
            }
        )

        guard case .nonterminal(let failure) = failed,
              case .ledgerFailedRetryable(.saveWithoutEvidence) = failure.state else {
            return XCTFail("Expected financially retryable save-without failure")
        }

        guard case .saveWithoutEvidenceOnly(let sourceID) =
                fixture.draft.evidenceRetentionState else {
            return XCTFail("Retained confirmation must become unavailable after authorized cleanup")
        }
        XCTAssertEqual(sourceID, fixture.sourceID)
        try assertMissing(
            paths.stagedPayload,
            fileSystem: harness.fileSystem
        )

        let retainedRetry = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let retainedFailure) = retainedRetry,
              case .retentionFailedRetryable = retainedFailure.state else {
            return XCTFail("Retained retry must be unavailable after save-without cleanup")
        }

        let financialRetryCoordinator = EvidenceConfirmationCoordinator(
            operationCoordinator: EvidenceOperationCoordinator(),
            storeProvider: {
                throw PassCInjectedFailure.storageInitialization
            }
        )

        let retry = await financialRetryCoordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .saveWithoutRetainedEvidence
        )

        guard case .terminal(.savedWithoutEvidence) = retry else {
            return XCTFail("Financial retry must not depend on evidence storage after cleanup")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
    }

    @MainActor
    func testPreCommitIdentityConflictBlocksLedgerAndLeavesStaging() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 29)
        let paths = harness.store.paths(for: fixture.sourceID)

        try LedgerWrite.perform(in: harness.context) {
            harness.context.insert(
                TransactionSource(
                    id: fixture.sourceID.uuidString.lowercased(),
                    source_type: .screenshot
                )
            )
        }

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let failure) = result,
              case .preCommitIdentityConflict = failure.state else {
            return XCTFail("Expected pre-commit identity conflict")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
        try assertMissing(
            paths.finalPayload,
            fileSystem: harness.fileSystem
        )
    }

    @MainActor
    func testFreshOwnerRecheckBlocksCommitWhenOwnerAppearsAfterFinalization() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 30)
        let paths = harness.store.paths(for: fixture.sourceID)

        harness.fileSystem.afterAtomicReplacement = {
            try LedgerWrite.perform(in: harness.context) {
                harness.context.insert(
                    TransactionSource(
                        id: fixture.sourceID.uuidString.lowercased(),
                        source_type: .screenshot
                    )
                )
            }
        }

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let failure) = result,
              case .preCommitIdentityConflict = failure.state else {
            return XCTFail("Fresh post-finalization owner recheck must block ledger commit")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            1
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
        XCTAssertNil(fixture.draft.source?.stored_file_uri)
    }

    @MainActor
    func testPostCommitIdentityConflictIsTerminalAndPreservesLedgerAndBytes() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 31)
        let paths = harness.store.paths(for: fixture.sourceID)

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence,
            ledgerCommit: { context in
                try context.save()
                context.insert(
                    TransactionSource(
                        id: fixture.sourceID.uuidString.lowercased(),
                        source_type: .screenshot
                    )
                )
                try context.save()
            }
        )

        guard case .terminal(.savedWithEvidenceConflict) = result else {
            return XCTFail("Post-commit identity conflict must be terminal")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            2
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
    }

    @MainActor
    func testDirtyCallerContextIsNeverSavedOrRolledBackByConfirmation() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 37)
        let paths = harness.store.paths(for: fixture.sourceID)

        let unrelated = Transaction(
            id: "pending-unrelated",
            amount: 5,
            merchant_name: "Pending unrelated"
        )
        harness.context.insert(unrelated)
        XCTAssertTrue(harness.context.hasChanges)

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .nonterminal(let failure) = result,
              case .ledgerFailedRetryable(.retainedEvidence) = failure.state else {
            return XCTFail("Dirty caller state should block ledger write without being discarded")
        }

        XCTAssertTrue(harness.context.hasChanges)
        XCTAssertEqual(unrelated.id, "pending-unrelated")
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )

        let fresh = ModelContext(harness.container)
        fresh.autosaveEnabled = false
        XCTAssertEqual(
            try fresh.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try fresh.fetchCount(FetchDescriptor<TransactionSource>()),
            0
        )
    }

    @MainActor
    func testPlainConfirmationDoesNotResolveEvidenceStore() async throws {
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
        let context = container.mainContext
        try Seed.bootstrapIfNeeded(context)

        let category = try XCTUnwrap(
            try context.fetch(FetchDescriptor<LumenFinance.Category>()).first
        )
        let draft = TransactionDraft()
        draft.amountText = "9.25"
        draft.merchant_name = "Manual only"
        draft.category = category
        draft.status = .pending

        let coordinator = EvidenceConfirmationCoordinator(
            operationCoordinator: EvidenceOperationCoordinator(),
            storeProvider: {
                throw PassCInjectedFailure.storageInitialization
            }
        )

        let result = await coordinator.confirm(
            draft: draft,
            allTags: try context.fetch(FetchDescriptor<Tag>()),
            in: context,
            intent: .plain
        )

        guard case .terminal(.saved) = result else {
            return XCTFail("Manual confirmation must not depend on evidence storage")
        }

        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
    }

    @MainActor
    func testRetainedRetryReplacesStaleZeroOwnerFinalFromStaging() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 41)
        let paths = harness.store.paths(for: fixture.sourceID)

        try createDurableDirectory(paths, in: harness)
        let stale = Data(repeating: 0xEE, count: fixture.data.count)
        try harness.fileSystem.write(
            stale,
            to: paths.finalPayload,
            atomically: false
        )

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .terminal(.saved) = result else {
            return XCTFail("Expected retained retry to reprepare from staging")
        }

        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
        XCTAssertNotEqual(stale, fixture.data)
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            1
        )
    }

    @MainActor
    func testRetainedLedgerFailureRetryConvergesOnOneIdentityAndPayload() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 43)
        let paths = harness.store.paths(for: fixture.sourceID)

        let failed = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence,
            ledgerCommit: { _ in
                throw PassCInjectedFailure.ledgerWrite
            }
        )

        guard case .nonterminal(let failure) = failed,
              case .ledgerFailedRetryable(.retainedEvidence) = failure.state else {
            return XCTFail("Expected first retained ledger attempt to fail retryably")
        }

        let retry = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .terminal(.saved) = retry else {
            return XCTFail("Expected retained retry to succeed")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            1
        )

        let source = try XCTUnwrap(
            try harness.context.fetch(FetchDescriptor<Transaction>()).first?.source
        )
        XCTAssertEqual(source.id, fixture.sourceID.uuidString)
        XCTAssertEqual(
            source.stored_file_uri,
            RetainedEvidenceLocator(sourceID: fixture.sourceID).serialized
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
    }

    @MainActor
    func testPostCommitStagingCleanupFailureDoesNotTurnLedgerSuccessIntoRetryableFailure() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 47)
        let paths = harness.store.paths(for: fixture.sourceID)
        harness.fileSystem.removeFailureURL = paths.stagedPayload

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .retainEvidence
        )

        guard case .terminal(.saved) = result else {
            return XCTFail("Ledger success must remain terminal after staging cleanup failure")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
    }

    @MainActor
    func testSaveWithoutEvidenceDeletesFinalThenIncomingThenStaging() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 51)
        let paths = harness.store.paths(for: fixture.sourceID)

        try createDurableDirectory(paths, in: harness)
        try harness.fileSystem.write(
            fixture.data,
            to: paths.finalPayload,
            atomically: false
        )
        try harness.fileSystem.write(
            fixture.data,
            to: paths.incomingPayload,
            atomically: false
        )

        harness.fileSystem.removedURLs.removeAll()

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .saveWithoutRetainedEvidence
        )

        guard case .terminal(.savedWithoutEvidence) = result else {
            return XCTFail("Expected explicit save without retained evidence")
        }

        XCTAssertEqual(
            harness.fileSystem.removedURLs,
            [
                paths.finalPayload,
                paths.incomingPayload,
                paths.stagedPayload
            ]
        )
    }

    @MainActor
    func testAbandonmentCleansStagingEvenWhenPersistedOwnerMakesDurableDeletionAmbiguous() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 53)
        let paths = harness.store.paths(for: fixture.sourceID)

        try LedgerWrite.perform(in: harness.context) {
            harness.context.insert(
                TransactionSource(
                    id: fixture.sourceID.uuidString,
                    source_type: .screenshot
                )
            )
        }

        let result = await harness.coordinator.abandonEvidence(
            for: fixture.draft,
            in: harness.context
        )

        guard case .completedWithDurableMaterialRetained = result else {
            return XCTFail("Committed/ambiguous ownership must retain durable material authority")
        }

        try assertMissing(
            paths.stagedPayload,
            fileSystem: harness.fileSystem
        )
    }

    @MainActor
    func testSaveWithoutEvidenceCleanupFailurePreservesStagingAndBlocksLedger() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 57)
        let paths = harness.store.paths(for: fixture.sourceID)

        try createDurableDirectory(paths, in: harness)
        try harness.fileSystem.write(
            fixture.data,
            to: paths.finalPayload,
            atomically: false
        )
        harness.fileSystem.removeFailureURL = paths.finalPayload

        let result = await harness.coordinator.confirm(
            draft: fixture.draft,
            allTags: harness.tags,
            in: harness.context,
            intent: .saveWithoutRetainedEvidence
        )

        guard case .nonterminal(let failure) = result,
              case .retentionFailedRetryable = failure.state else {
            return XCTFail("Required cleanup failure must block save without evidence")
        }

        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            0
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.stagedPayload),
            fixture.data
        )
        XCTAssertEqual(
            try Data(contentsOf: paths.finalPayload),
            fixture.data
        )
        guard case .staged = fixture.draft.evidenceRetentionState else {
            return XCTFail("Staging must remain available when durable cleanup fails")
        }
    }

    @MainActor
    func testConcurrentDoubleSubmitCreatesAtMostOneFirstCommitment() async throws {
        let harness = try makeHarness()
        let fixture = try makeEvidenceDraft(in: harness, seed: 59)

        let firstTask = Task { @MainActor in
            await harness.coordinator.confirm(
                draft: fixture.draft,
                allTags: harness.tags,
                in: harness.context,
                intent: .retainEvidence
            )
        }

        await Task.yield()

        let secondTask = Task { @MainActor in
            await harness.coordinator.confirm(
                draft: fixture.draft,
                allTags: harness.tags,
                in: harness.context,
                intent: .retainEvidence
            )
        }

        let results = await (
            firstTask.value,
            secondTask.value
        )

        let savedCount = [results.0, results.1].reduce(into: 0) { count, result in
            if case .terminal(.saved) = result {
                count += 1
            }
        }

        XCTAssertEqual(savedCount, 1)
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<Transaction>()),
            1
        )
        XCTAssertEqual(
            try harness.context.fetchCount(FetchDescriptor<TransactionSource>()),
            1
        )
    }

    func testSameUUIDLeaseRemainsExclusiveAcrossSuspension() async {
        let coordinator = EvidenceOperationCoordinator()
        let sourceID = UUID()
        let first = await coordinator.acquire(for: sourceID)
        let probe = PassCLeaseProbe()

        let secondTask = Task {
            let second = await coordinator.acquire(for: sourceID)
            await probe.markAcquired()
            await Task.yield()
            await coordinator.release(second)
        }

        for _ in 0..<50 {
            await Task.yield()
        }

        let beforeRelease = await probe.isAcquired()
        XCTAssertFalse(
            beforeRelease,
            "A second same-UUID operation entered while the first lease was suspended"
        )

        await coordinator.release(first)
        _ = await secondTask.value

        let afterRelease = await probe.isAcquired()
        XCTAssertTrue(afterRelease)
    }

    func testDifferentUUIDDoesNotNeedToWaitForHeldLease() async {
        let coordinator = EvidenceOperationCoordinator()
        let first = await coordinator.acquire(for: UUID())
        let second = await coordinator.acquire(for: UUID())

        await coordinator.release(second)
        await coordinator.release(first)
    }

    func testCaseVariedUUIDSpellingMapsToSameLeaseAuthority() async throws {
        let canonical = UUID()
        let varied = try XCTUnwrap(
            UUID(uuidString: canonical.uuidString.lowercased())
        )
        XCTAssertEqual(canonical, varied)

        let coordinator = EvidenceOperationCoordinator()
        let first = await coordinator.acquire(for: canonical)
        let probe = PassCLeaseProbe()

        let secondTask = Task {
            let second = await coordinator.acquire(for: varied)
            await probe.markAcquired()
            await coordinator.release(second)
        }

        for _ in 0..<50 {
            await Task.yield()
        }

        let beforeRelease = await probe.isAcquired()
        XCTAssertFalse(beforeRelease)

        await coordinator.release(first)
        _ = await secondTask.value

        let afterRelease = await probe.isAcquired()
        XCTAssertTrue(afterRelease)
    }

    @MainActor
    private struct Harness {
        let root: URL
        let container: ModelContainer
        let context: ModelContext
        let tags: [Tag]
        let fileSystem: PassCFileSystem
        let store: RetainedEvidenceStore
        let coordinator: EvidenceConfirmationCoordinator
    }

    private struct EvidenceFixture {
        let sourceID: UUID
        let data: Data
        let draft: TransactionDraft
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
        let context = container.mainContext
        try Seed.bootstrapIfNeeded(context)

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Lumen-PassC-\(UUID().uuidString)",
                isDirectory: true
            )
        let temporary = root
            .appendingPathComponent("tmp", isDirectory: true)
        let support = root
            .appendingPathComponent("Application Support", isDirectory: true)

        try FileManager.default.createDirectory(
            at: temporary,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: support,
            withIntermediateDirectories: true
        )

        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let fileSystem = PassCFileSystem(
            temporaryDirectory: temporary,
            applicationSupportDirectory: support
        )
        let roots = RetainedEvidenceStorageRoots(
            stagingRoot: temporary
                .appendingPathComponent(
                    "LumenEvidenceStaging",
                    isDirectory: true
                ),
            durableV1Root: support
                .appendingPathComponent("LumenEvidence", isDirectory: true)
                .appendingPathComponent("v1", isDirectory: true)
        )
        let store = RetainedEvidenceStore(
            fileSystem: fileSystem,
            roots: roots
        )

        return Harness(
            root: root,
            container: container,
            context: context,
            tags: try context.fetch(FetchDescriptor<Tag>()),
            fileSystem: fileSystem,
            store: store,
            coordinator: EvidenceConfirmationCoordinator(
                operationCoordinator: EvidenceOperationCoordinator(),
                store: store
            )
        )
    }

    private func assertRegularFile(
        _ url: URL,
        fileSystem: PassCFileSystem,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let kind = try fileSystem.nodeKind(at: url)
        guard case .regularFile = kind else {
            return XCTFail(
                "Expected regular file at \(url.path)",
                file: file,
                line: line
            )
        }
    }

    private func assertMissing(
        _ url: URL,
        fileSystem: PassCFileSystem,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let kind = try fileSystem.nodeKind(at: url)
        guard case .missing = kind else {
            return XCTFail(
                "Expected no filesystem node at \(url.path)",
                file: file,
                line: line
            )
        }
    }

    @MainActor
    private func createDurableDirectory(
        _ paths: RetainedEvidencePaths,
        in harness: Harness
    ) throws {
        try harness.fileSystem.createDirectory(
            at: harness.store.roots.durableV1Root.deletingLastPathComponent()
        )
        try harness.fileSystem.createDirectory(
            at: harness.store.roots.durableV1Root
        )
        try harness.fileSystem.createDirectory(
            at: paths.durableDirectory
        )
    }

    @MainActor
    private func makeEvidenceDraft(
        in harness: Harness,
        seed: UInt8
    ) throws -> EvidenceFixture {
        let sourceID = UUID()
        let data = Data((0..<2048).map { index in
            UInt8((Int(seed) + index * 29) % 256)
        })
        let staged = try harness.store.stage(
            data,
            for: sourceID
        )

        let category = try XCTUnwrap(
            try harness.context.fetch(FetchDescriptor<LumenFinance.Category>()).first
        )

        let draft = TransactionDraft()
        draft.amountText = "42.19"
        draft.currency = "USD"
        draft.merchant_name = "Pass C Merchant"
        draft.status = .pending
        draft.category = category
        draft.source = TransactionSource(
            id: sourceID.uuidString,
            source_type: .receipt_photo,
            stored_file_uri: nil,
            file_size_bytes: data.count,
            mime_type: "image/jpeg",
            uploaded_at: .now,
            parse_status: .manual_review
        )
        draft.evidenceRetentionState = .staged(
            StagedEvidenceContext(
                sourceID: sourceID,
                stagedURL: staged.url,
                byteCount: staged.byteCount
            )
        )

        return EvidenceFixture(
            sourceID: sourceID,
            data: data,
            draft: draft
        )
    }
}

private final class PassCFileSystem: EvidenceFileSystem {
    private let base = LocalEvidenceFileSystem()

    let temporaryDirectory: URL
    private let applicationSupportURL: URL

    var writeFailureURL: URL?
    var removeFailureURL: URL?
    var removedURLs: [URL] = []
    var afterAtomicReplacement: (() throws -> Void)?

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

    func nodeKind(at url: URL) throws -> EvidenceFileNodeKind {
        try base.nodeKind(at: url)
    }

    func createDirectory(at url: URL) throws {
        try base.createDirectory(at: url)
    }

    func write(
        _ data: Data,
        to url: URL,
        atomically: Bool
    ) throws {
        if url == writeFailureURL {
            throw PassCInjectedFailure.storageWrite
        }
        try base.write(data, to: url, atomically: atomically)
    }

    func read(_ url: URL) throws -> Data {
        try base.read(url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try base.contentsOfDirectory(at: url)
    }

    func removeRegularFile(at url: URL) throws {
        if url == removeFailureURL {
            throw PassCInjectedFailure.storageRemoval
        }
        try base.removeRegularFile(at: url)
        removedURLs.append(url)
    }

    func removeDirectoryIfEmpty(at url: URL) throws {
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
        try afterAtomicReplacement?()
        afterAtomicReplacement = nil
    }

    func applyCompleteFileProtection(at url: URL) throws {}

    func fileProtection(at url: URL) throws -> URLFileProtection? {
        .complete
    }

    func clearBackupExclusion(at url: URL) throws {}

    func isExcludedFromBackup(at url: URL) throws -> Bool {
        false
    }
}

private actor PassCLeaseProbe {
    private var acquired = false

    func markAcquired() {
        acquired = true
    }

    func isAcquired() -> Bool {
        acquired
    }
}

private enum PassCInjectedFailure: Error {
    case storageInitialization
    case storageWrite
    case storageRemoval
    case ledgerWrite
}
