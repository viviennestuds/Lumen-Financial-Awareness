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

    // Each layer gets its own store and test outcome; an early failed assertion cannot hide disk evidence.
    private enum RecoveryLayer { case held, sameContext, freshContext, reopened }

    @MainActor
    private func transactionState(_ txn: Transaction) -> [String: String] {
        [
            "id": txn.id, "amount": String(txn.amount), "currency": txn.currency,
            "type": txn.transaction_type.rawValue, "merchant": txn.merchant_name,
            "status": txn.status.rawValue,
            "transactionDate": String(txn.transaction_date.timeIntervalSince1970),
            "postedDate": txn.posted_date.map { String($0.timeIntervalSince1970) } ?? "nil",
            "created": String(txn.created_at.timeIntervalSince1970),
            "updated": String(txn.updated_at.timeIntervalSince1970),
            "category": txn.category?.id ?? "nil", "payment": txn.payment_method?.id ?? "nil",
            "tags": txn.tags.map(\.id).sorted().joined(separator: ","),
            "source": txn.source?.id ?? "nil", "notes": txn.notes ?? "nil",
            "confidence": txn.confidence_score.map { String($0) } ?? "nil",
            "fingerprint": txn.duplicate_fingerprint ?? "nil",
            "user": txn.user_id ?? "nil", "budget": txn.budget_id ?? "nil",
            "phase": txn.cashflow_phase_id ?? "nil"
        ]
    }

    @MainActor
    private func graphState(in context: ModelContext, heldTags: [Tag]? = nil) throws -> [String: String] {
        let tags = try heldTags ?? context.fetch(FetchDescriptor<Tag>())
        let rows = try context.fetch(FetchDescriptor<Transaction>())
        let sources = try context.fetch(FetchDescriptor<TransactionSource>())
        return [
            "hasChanges": String(context.hasChanges),
            "transactions": String(try context.fetchCount(FetchDescriptor<Transaction>())),
            "fetchedTransactions": String(rows.count),
            "sources": String(try context.fetchCount(FetchDescriptor<TransactionSource>())),
            "sourceIDs": sources.map(\.id).sorted().joined(separator: ","),
            "transactionSources": rows.map { "\($0.id):\($0.source?.id ?? "nil")" }.sorted().joined(separator: ","),
            "tagInverses": tags.map { "\($0.id):\($0.transactions.count)" }.sorted().joined(separator: ",")
        ]
    }

    @MainActor
    private func fetchTransaction(_ id: String, in context: ModelContext) throws -> Transaction {
        let request = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
        return try XCTUnwrap(context.fetch(request).first)
    }

    @MainActor
    private func failedCreateState(_ layer: RecoveryLayer) throws {
        try withStore { url in
            var expected: [String: String] = [:]
            var observed: [String: String] = [:]
            var identityEvidence = ""
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                try Seed.bootstrapIfNeeded(context)
                let draft = try draft(in: context)
                draft.source = TransactionSource(source_type: .receipt_photo, parse_status: .manual_review)
                let tags = try context.fetch(FetchDescriptor<Tag>())
                expected = try graphState(in: context, heldTags: tags)
                XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    context.insert(try draft.makeTransaction(allTags: tags))
                })
                switch layer {
                case .held:
                    observed = try graphState(in: context, heldTags: tags)
                    let refetched = try context.fetch(FetchDescriptor<Tag>())
                    identityEvidence = tags.map { tag in
                        let current = refetched.first { $0.id == tag.id }
                        return "heldContext=\(tag.modelContext === context),sameInstance=\(current === tag),heldInverse=\(tag.transactions.count),fetchedInverse=\(current?.transactions.count ?? -1)"
                    }.joined(separator: ";")
                case .sameContext: observed = try graphState(in: context)
                case .freshContext:
                    let fresh = ModelContext(store)
                    fresh.autosaveEnabled = false
                    observed = try graphState(in: fresh)
                case .reopened: break
                }
            }
            if layer == .reopened {
                try autoreleasepool {
                    let reopened = try container(at: url)
                    defer { withExtendedLifetime(reopened) {} }
                    observed = try graphState(in: reopened.mainContext)
                }
            }
            XCTAssertEqual(observed, expected, "Failed create layer: \(layer); \(identityEvidence)")
        }
    }

    @MainActor
    private func editFixture(in context: ModelContext) throws -> (Transaction, TransactionDraft, [Tag]) {
        try Seed.bootstrapIfNeeded(context)
        let tags = try context.fetch(FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.id)]))
        let categories = try context.fetch(FetchDescriptor<LumenFinance.Category>(sortBy: [SortDescriptor(\.id)]))
        let payments = try context.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.id)]))
        let initial = try draft(in: context)
        initial.category = try XCTUnwrap(categories.first)
        initial.payment_method = try XCTUnwrap(payments.first)
        initial.tagIDs = [try XCTUnwrap(tags.first).id]
        initial.transaction_date = Date(timeIntervalSince1970: 1_700_000_000)
        initial.source = TransactionSource(id: "recovery-source", source_type: .receipt_photo)
        let txn = try LedgerWrite.perform(in: context) {
            let txn = try initial.makeTransaction(allTags: tags)
            txn.id = "recovery-B"
            txn.created_at = Date(timeIntervalSince1970: 1_700_000_000)
            txn.updated_at = txn.created_at
            txn.confidence_score = 0.71
            txn.duplicate_fingerprint = "soft-match"
            context.insert(txn)
            return txn
        }
        let edit = TransactionDraft(from: txn)
        edit.amountText = "88.50"
        edit.status = .posted
        edit.posted_date = Date(timeIntervalSince1970: 1_700_100_000)
        edit.transaction_date = Date(timeIntervalSince1970: 1_700_050_000)
        edit.merchant_name = "Attempted edit"
        edit.currency = "EUR"
        edit.notes = "Retain this draft"
        edit.category = try XCTUnwrap(categories.last)
        edit.payment_method = try XCTUnwrap(payments.last)
        edit.tagIDs = [try XCTUnwrap(tags.last).id]
        return (txn, edit, tags)
    }

    @MainActor
    private func failedEditState(_ layer: RecoveryLayer) throws {
        try withStore { url in
            var expected: [String: String] = [:]
            var observed: [String: String] = [:]
            var expectedGraph: [String: String] = [:]
            var observedGraph: [String: String] = [:]
            var id = ""
            var identityEvidence = ""
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let (txn, edit, tags) = try editFixture(in: context)
                id = txn.id
                expected = transactionState(txn)
                expectedGraph = try graphState(in: context, heldTags: tags)
                XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    try edit.apply(to: txn, allTags: tags)
                })
                switch layer {
                case .held:
                    observed = transactionState(txn)
                    observedGraph = try graphState(in: context, heldTags: tags)
                    let refetched = try fetchTransaction(id, in: context)
                    identityEvidence = "heldContext=\(txn.modelContext === context),heldContextNil=\(txn.modelContext == nil),sameInstance=\(txn === refetched),samePersistentID=\(txn.persistentModelID == refetched.persistentModelID),heldAmountAfterFetch=\(txn.amount),fetchedAmount=\(refetched.amount)"
                case .sameContext:
                    observed = transactionState(try fetchTransaction(id, in: context))
                    observedGraph = try graphState(in: context)
                case .freshContext:
                    let fresh = ModelContext(store)
                    fresh.autosaveEnabled = false
                    observed = transactionState(try fetchTransaction(id, in: fresh))
                    observedGraph = try graphState(in: fresh)
                case .reopened: break
                }
                XCTAssertEqual(edit.amountText, "88.50")
                XCTAssertEqual(edit.status, .posted)
                XCTAssertEqual(edit.notes, "Retain this draft")
            }
            if layer == .reopened {
                try autoreleasepool {
                    let reopened = try container(at: url)
                    defer { withExtendedLifetime(reopened) {} }
                    observed = transactionState(try fetchTransaction(id, in: reopened.mainContext))
                    observedGraph = try graphState(in: reopened.mainContext)
                }
            }
            XCTAssertEqual(observed, expected, "Failed edit layer: \(layer); \(identityEvidence)")
            XCTAssertEqual(observedGraph, expectedGraph, "Failed edit graph layer: \(layer)")
        }
    }

    @MainActor func testFailedCreateHeldReferences() throws { try failedCreateState(.held) }
    @MainActor func testFailedCreateSameContext() throws { try failedCreateState(.sameContext) }
    @MainActor func testFailedCreateFreshContext() throws { try failedCreateState(.freshContext) }
    @MainActor func testFailedCreateReopenedStore() throws { try failedCreateState(.reopened) }
    @MainActor func testFailedEditHeldReference() throws { try failedEditState(.held) }
    @MainActor func testFailedEditSameContext() throws { try failedEditState(.sameContext) }
    @MainActor func testFailedEditFreshContext() throws { try failedEditState(.freshContext) }
    @MainActor func testFailedEditReopenedStore() throws { try failedEditState(.reopened) }

    @MainActor
    func testFailedCreateRetryHasExactlyOneDurableGraph() throws {
        try withStore { url in
            var id = ""
            var sourceID = ""
            var tagID = ""
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                try Seed.bootstrapIfNeeded(context)
                let draft = try draft(in: context)
                draft.source = TransactionSource(source_type: .receipt_photo, original_filename: "retry.jpg", parse_status: .manual_review)
                sourceID = try XCTUnwrap(draft.source?.id)
                tagID = try XCTUnwrap(draft.tagIDs.first)
                let tags = try context.fetch(FetchDescriptor<Tag>())
                XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    context.insert(try draft.makeTransaction(allTags: tags))
                })
                XCTAssertEqual(draft.amountText, "42.19")
                XCTAssertEqual(draft.source?.id, sourceID)
                XCTAssertEqual(draft.source?.original_filename, "retry.jpg")
                XCTAssertTrue(draft.canConfirm)
                let txn = try LedgerWrite.perform(in: context) {
                    let txn = try draft.makeTransaction(allTags: tags)
                    context.insert(txn)
                    return txn
                }
                id = txn.id
                XCTAssertFalse(context.hasChanges)
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 1)
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransactionSource>()), 1)
                XCTAssertEqual(txn.tags.map(\.id), [tagID])
                XCTAssertEqual(tags.first { $0.id == tagID }?.transactions.map(\.id), [id])
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let txn = try fetchTransaction(id, in: context)
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<Transaction>()), 1)
                XCTAssertEqual(try context.fetchCount(FetchDescriptor<TransactionSource>()), 1)
                XCTAssertEqual(txn.source?.id, sourceID)
                XCTAssertEqual(txn.tags.map(\.id), [tagID])
                XCTAssertEqual(txn.tags.first?.transactions.map(\.id), [id])
            }
        }
    }

    @MainActor
    func testFailedEditRetainsDraftAndRetryPersistsAfterReopen() throws {
        try withStore { url in
            var expected: [String: String] = [:]
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let (txn, edit, tags) = try editFixture(in: context)
                let proposedCategory = edit.category?.id
                let proposedPayment = edit.payment_method?.id
                let proposedTags = edit.tagIDs
                XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    try edit.apply(to: txn, allTags: tags)
                })
                XCTAssertEqual(edit.amountText, "88.50")
                XCTAssertEqual(edit.status, .posted)
                XCTAssertEqual(edit.posted_date, Date(timeIntervalSince1970: 1_700_100_000))
                XCTAssertEqual(edit.category?.id, proposedCategory)
                XCTAssertEqual(edit.payment_method?.id, proposedPayment)
                XCTAssertEqual(edit.tagIDs, proposedTags)
                XCTAssertEqual(edit.notes, "Retain this draft")
                XCTAssertTrue(edit.isValid)
                try LedgerWrite.perform(in: context) { try edit.apply(to: txn, allTags: tags) }
                XCTAssertFalse(context.hasChanges)
                XCTAssertEqual(txn.amount, 88.5)
                XCTAssertEqual(txn.status, .posted)
                XCTAssertEqual(txn.category?.id, proposedCategory)
                XCTAssertEqual(txn.payment_method?.id, proposedPayment)
                XCTAssertEqual(Set(txn.tags.map(\.id)), proposedTags)
                XCTAssertEqual(txn.tags.count, proposedTags.count)
                expected = transactionState(txn)
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let txn = try fetchTransaction("recovery-B", in: store.mainContext)
                XCTAssertEqual(transactionState(txn), expected)
                XCTAssertEqual(try store.mainContext.fetchCount(FetchDescriptor<Transaction>()), 1)
                XCTAssertEqual(txn.tags.first?.transactions.map(\.id), [txn.id])
            }
        }
    }

    private enum FailedOperation { case status, delete, unrelatedEdit }

    @MainActor
    private func independentFailure(_ operation: FailedOperation) throws {
        try withStore { url in
            var expected: [String: String] = [:]
            var expectedA: [String: String] = [:]
            var expectedGraph: [String: String] = [:]
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                let (txn, edit, tags) = try editFixture(in: context)
                // A is committed, not an unrelated unsaved mutation that violates the boundary.
                let a = try LedgerWrite.perform(in: context) {
                    let a = Transaction(id: "recovery-A", amount: 17.125, currency: "KWD", merchant_name: "Unrelated committed A",
                                        status: .posted, notes: "Preserve A", source: txn.source,
                                        category: txn.category, payment_method: txn.payment_method, tags: txn.tags)
                    context.insert(a)
                    return a
                }
                expected = transactionState(txn)
                expectedA = transactionState(a)
                expectedGraph = try graphState(in: context, heldTags: tags)
                XCTAssertFalse(context.hasChanges)
                XCTAssertThrowsError(try LedgerWrite.perform(in: context, commit: { _ in throw InjectedFailure.diskWrite }) {
                    switch operation {
                    case .status:
                        txn.status = .posted
                        txn.posted_date = Date(timeIntervalSince1970: 1_700_100_000)
                        txn.updated_at = .now
                    case .delete: context.delete(txn)
                    case .unrelatedEdit: try edit.apply(to: txn, allTags: tags)
                    }
                })
                // Capture all observations before assertions, without a refetch healing the held-value observation.
                let held = transactionState(txn)
                let heldA = transactionState(a)
                let heldGraph = try graphState(in: context, heldTags: tags)
                let same = transactionState(try fetchTransaction(txn.id, in: context))
                let fresh = ModelContext(store)
                fresh.autosaveEnabled = false
                let freshB = transactionState(try fetchTransaction(txn.id, in: fresh))
                let freshA = transactionState(try fetchTransaction(a.id, in: fresh))
                XCTAssertEqual(held, expected, "Held B after \(operation)")
                XCTAssertEqual(heldA, expectedA, "Held unrelated A after \(operation)")
                XCTAssertEqual(heldGraph, expectedGraph, "Held graph after \(operation)")
                XCTAssertEqual(same, expected)
                XCTAssertEqual(freshB, expected)
                XCTAssertEqual(freshA, expectedA)
                XCTAssertFalse(context.hasChanges)
            }
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext
                XCTAssertEqual(transactionState(try fetchTransaction("recovery-B", in: context)), expected)
                XCTAssertEqual(transactionState(try fetchTransaction("recovery-A", in: context)), expectedA)
                XCTAssertEqual(try graphState(in: context), expectedGraph)
            }
        }
    }

    @MainActor func testFailedStatusIndependentlyRestoresCommittedState() throws { try independentFailure(.status) }
    @MainActor func testFailedDeleteIndependentlyPreservesCommittedState() throws { try independentFailure(.delete) }
    @MainActor func testFailedWritePreservesUnrelatedCommittedTransaction() throws { try independentFailure(.unrelatedEdit) }

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
