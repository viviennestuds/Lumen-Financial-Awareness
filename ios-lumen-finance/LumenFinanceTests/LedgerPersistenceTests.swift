import XCTest
import SwiftData
@testable import LumenFinance

private enum InjectedFailure: Error { case diskWrite }

final class LedgerPersistenceTests: XCTestCase {
    @MainActor
    private func container(at url: URL) throws -> ModelContainer {
        let schema = LedgerStore.schema()
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: [config])
        container.mainContext.autosaveEnabled = false
        return container
    }

    private func withStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory.appendingPathComponent("ledger.store"))
    }

    @MainActor
    private func draft(in context: ModelContext) throws -> TransactionDraft {
        let draft = TransactionDraft()
        draft.merchant_name = "Persistence test"
        draft.amountText = "42.19"
        draft.category = try XCTUnwrap(context.fetch(FetchDescriptor<LumenFinance.Category>()).first)
        draft.tagIDs = Set(try context.fetch(FetchDescriptor<Tag>()).prefix(1).map(\.id))
        return draft
    }

    @MainActor
    func testDiskCreateReopenEditStatusDeleteReopen() throws {
        try withStore { url in
            var id = ""
            try autoreleasepool {
                let store = try container(at: url)
                let context = store.mainContext
                try Seed.bootstrapIfNeeded(context)
                let draft = try draft(in: context)
                let tags = try context.fetch(FetchDescriptor<Tag>())
                let txn = try LedgerWrite.perform(in: context) {
                    let txn = try draft.makeTransaction(allTags: tags)
                    context.insert(txn)
                    return txn
                }
                id = txn.id
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let txn = try XCTUnwrap(context.fetch(FetchDescriptor<Transaction>()).first)
                XCTAssertEqual(txn.id, id)
                XCTAssertEqual(txn.amount, 42.19)
                XCTAssertEqual(txn.tags.count, 1)
                XCTAssertNil(txn.source)
                let draft = TransactionDraft(from: txn)
                draft.merchant_name = "Edited"
                draft.amountText = "51.09"
                draft.status = .posted
                draft.notes = "Persisted edit"
                let tags = try context.fetch(FetchDescriptor<Tag>())
                try LedgerWrite.perform(in: context) { try draft.apply(to: txn, allTags: tags) }
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let txn = try XCTUnwrap(context.fetch(FetchDescriptor<Transaction>()).first)
                XCTAssertEqual(txn.id, id)
                XCTAssertEqual(txn.merchant_name, "Edited")
                XCTAssertEqual(txn.amount, 51.09)
                XCTAssertEqual(txn.status, .posted)
                XCTAssertNotNil(txn.posted_date)
                XCTAssertEqual(txn.notes, "Persisted edit")
                try LedgerWrite.perform(in: context) { context.delete(txn) }
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 0)
                XCTAssertGreaterThan(try context.fetchCount(FetchDescriptor<Tag>()), 0)
            }
        }
    }

    @MainActor
    func testFailedCreateRollsBackSourceAndTagsThenCanRetry() throws {
        try withStore { url in
            let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
            try Seed.bootstrapIfNeeded(context)
            let draft = try draft(in: context)
            draft.source = TransactionSource(source_type: .receipt_photo, parse_status: .manual_review)
            let sourceID = draft.source?.id
            let tags = try context.fetch(FetchDescriptor<Tag>())
            var reportedSuccess = false
            do {
                try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    context.insert(try draft.makeTransaction(allTags: tags))
                }
                reportedSuccess = true
            } catch { }
            XCTAssertFalse(reportedSuccess)
            XCTAssertFalse(context.hasChanges)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 0)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransactionSource>()), 0)
            XCTAssertTrue(tags.allSatisfy { $0.transactions.isEmpty })
            XCTAssertEqual(draft.source?.id, sourceID)
            try LedgerWrite.perform(in: context) { context.insert(try draft.makeTransaction(allTags: tags)) }
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 1)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransactionSource>()), 1)
        }
    }

    @MainActor
    func testFailedEditStatusAndDeleteRestoreCommittedState() throws {
        try withStore { url in
            let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
            try Seed.bootstrapIfNeeded(context)
            let draft = try draft(in: context)
            let txn = try LedgerWrite.perform(in: context) {
                let txn = try draft.makeTransaction(allTags: [])
                context.insert(txn)
                return txn
            }
            let updated = txn.updated_at
            draft.amountText = "88.50"
            draft.status = .posted
            XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                try draft.apply(to: txn, allTags: [])
            })
            XCTAssertEqual(txn.amount, 42.19)
            XCTAssertEqual(txn.status, .pending)
            XCTAssertEqual(txn.updated_at, updated)
            XCTAssertNil(txn.posted_date)
            XCTAssertEqual(draft.amountText, "88.50", "Retry must retain the edit buffer")
            XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                context.delete(txn)
            })
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 1)
            XCTAssertFalse(context.hasChanges)
        }
    }

    @MainActor
    func testSeedIdempotencyAndFailureRetryWithoutSamples() throws {
        try withStore { url in
            let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
            XCTAssertThrowsError(try Seed.bootstrapIfNeeded(context, commit: { _ in throw InjectedFailure.diskWrite }))
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<LumenFinance.Category>()), 0)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<PaymentMethod>()), 0)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Tag>()), 0)
            try Seed.bootstrapIfNeeded(context)
            let categoryIDs = Set(try context.fetch(FetchDescriptor<LumenFinance.Category>()).map(\.id))
            try Seed.bootstrapIfNeeded(context)
            XCTAssertEqual(Set(try context.fetch(FetchDescriptor<LumenFinance.Category>()).map(\.id)), categoryIDs)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<PaymentMethod>()), 7)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Tag>()), 4)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 0)
        }
    }

    @MainActor
    func testRepeatedDuplicateReadAndDiscardLeaveNoDurableGraph() throws {
        try withStore { url in
            let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
            try Seed.bootstrapIfNeeded(context)
            let draft = try draft(in: context)
            let tags = try context.fetch(FetchDescriptor<Tag>())
            for _ in 0..<50 { XCTAssertNil(Analytics.similarTransaction(to: draft, in: [])) }
            XCTAssertFalse(context.hasChanges)
            XCTAssertTrue(tags.allSatisfy { $0.transactions.isEmpty })
            try context.save()
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 0)
        }
    }

    @MainActor
    func testAllLegacyValuesRoundTripUnchangedSchemaAndSharedSourceSurvivesDelete() throws {
        // Same-schema round-trip only. NOT an authentic baseline migration fixture.
        try withStore { url in
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                try LedgerWrite.perform(in: context) {
                    let source = TransactionSource(source_type: .screenshot, source_hash: "legacy-not-a-content-hash")
                    context.insert(source)
                    for status in TransactionStatus.allCases {
                        context.insert(Transaction(id: status.rawValue, amount: 12.345, currency: "KWD",
                                                   merchant_name: status.rawValue, status: status,
                                                   confidence_score: 0.71, duplicate_fingerprint: "soft-match", source: source))
                    }
                }
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let rows = try context.fetch(FetchDescriptor<Transaction>())
                XCTAssertEqual(Set(rows.map { $0.status.rawValue }), Set(TransactionStatus.allCases.map(\.rawValue)))
                XCTAssertTrue(rows.allSatisfy { $0.amount == 12.345 && $0.currency == "KWD" && $0.confidence_score == 0.71 && $0.duplicate_fingerprint == "soft-match" })
                let row = try XCTUnwrap(rows.first)
                try LedgerWrite.perform(in: context) { context.delete(row) }
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransactionSource>()), 1)
                XCTAssertTrue(try context.fetch(FetchDescriptor<Transaction>()).allSatisfy { $0.source != nil })
            }
        }
    }

    @MainActor
    func testContainerFailureNeverFallsBackAndDirtyContextIsNotDiscarded() throws {
        var attempts = 0
        XCTAssertThrowsError(try LedgerStore.open { _, _ in
            attempts += 1
            throw InjectedFailure.diskWrite
        })
        XCTAssertEqual(attempts, 1)
        try withStore { url in
            let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
            context.insert(Transaction(amount: 1, merchant_name: "Uncommitted"))
            var mutationRan = false
            XCTAssertThrowsError(try LedgerWrite.perform(in: context) { mutationRan = true })
            XCTAssertFalse(mutationRan)
            XCTAssertTrue(context.hasChanges, "Unexpected unrelated work must not be silently rolled back")
            context.rollback()
        }
    }
}
