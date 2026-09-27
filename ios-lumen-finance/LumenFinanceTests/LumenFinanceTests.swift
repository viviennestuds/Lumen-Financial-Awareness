import XCTest
import SwiftData
@testable import LumenFinance

final class LumenFinanceTests: XCTestCase {
    @MainActor
    private func draft() -> TransactionDraft {
        let draft = TransactionDraft()
        draft.merchant_name = "  Cafe  "
        draft.amountText = "12.34"
        draft.category = LumenFinance.Category(name: "Dining", group: .guilt_free_spending, color: "#112233", icon: "fork.knife")
        return draft
    }

    @MainActor
    func testDraftConfirmationAndMachineBoundary() throws {
        let draft = draft()
        let tag = Tag(name: "essential")
        draft.tagIDs = [tag.id]
        draft.confidence_score = 0.8
        draft.notes = "Lunch"
        draft.status = .posted
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        draft.transaction_date = date
        let txn = try draft.makeTransaction(allTags: [tag])
        XCTAssertEqual(txn.merchant_name, "Cafe")
        XCTAssertEqual(txn.amount, 12.34)
        XCTAssertEqual(txn.transaction_date, date)
        XCTAssertNotNil(txn.posted_date)
        XCTAssertEqual(txn.tags.map(\.id), [tag.id])
        XCTAssertEqual(txn.notes, "Lunch")
        XCTAssertNil(txn.source)
        XCTAssertNil(txn.confidence_score)
        XCTAssertEqual(txn.status, .posted)
    }

    @MainActor
    func testInvalidDraftsCannotCreateOrEdit() throws {
        let draft = draft()
        let txn = try draft.makeTransaction(allTags: [])
        for amount in ["0", "-10", "NaN", "inf", "1e999", "", "1,234.56"] {
            draft.amountText = amount
            XCTAssertFalse(draft.isValid, amount)
            XCTAssertThrowsError(try draft.makeTransaction(allTags: []), amount)
            XCTAssertThrowsError(try draft.apply(to: txn, allTags: []), amount)
            XCTAssertEqual(txn.amount, 12.34)
        }
        draft.amountText = "12,34"
        XCTAssertTrue(draft.isValid)
        draft.merchant_name = " \n\t"
        XCTAssertFalse(draft.isValid)
        draft.merchant_name = "Cafe"
        draft.currency = "???"
        XCTAssertFalse(draft.isValid)
        draft.currency = "USD"
        draft.category = nil
        XCTAssertFalse(draft.isValid)
    }

    @MainActor
    func testNewInputOnlyConfirmsFinancialLifecycle() throws {
        let draft = draft()
        for status in TransactionStatus.allCases {
            draft.status = status
            if status == .pending || status == .posted {
                XCTAssertNoThrow(try draft.makeTransaction(allTags: []))
            } else {
                XCTAssertThrowsError(try draft.makeTransaction(allTags: []))
            }
        }
    }

    @MainActor
    func testUnrelatedEditPreservesLegacyPrecisionAndMetadata() throws {
        let txn = Transaction(amount: 12.345678901, currency: "KWD", merchant_name: "Legacy",
                              status: .posted, confidence_score: 0.71, duplicate_fingerprint: "soft-match",
                              category: draft().category)
        let created = txn.created_at
        let draft = TransactionDraft(from: txn)
        draft.notes = "Only notes changed"
        try draft.apply(to: txn, allTags: [])
        XCTAssertEqual(txn.amount, 12.345678901)
        XCTAssertEqual(txn.currency, "KWD")
        XCTAssertEqual(txn.created_at, created)
        XCTAssertNil(txn.posted_date, "Unrelated edits must not invent a missing legacy posted date")
        XCTAssertEqual(txn.confidence_score, 0.71)
        XCTAssertEqual(txn.duplicate_fingerprint, "soft-match")
        XCTAssertGreaterThanOrEqual(txn.updated_at, created)
    }

    @MainActor
    func testAnalyticsTypesStatusesAndCurrencyPolicy() {
        let now = Date(timeIntervalSince1970: 1_783_339_200)
        let txns = [
            Transaction(amount: 0.1, merchant_name: "A", transaction_date: now, status: .pending),
            Transaction(amount: 0.2, merchant_name: "B", transaction_date: now, status: .posted),
            Transaction(amount: 1, merchant_name: "Legacy review", transaction_date: now, status: .review_needed),
            Transaction(amount: 999, merchant_name: "Ignored", transaction_date: now, status: .ignored),
            Transaction(amount: 999, merchant_name: "Duplicate", transaction_date: now, status: .duplicate),
            Transaction(amount: 100, transaction_type: .income, merchant_name: "Income", transaction_date: now),
            Transaction(amount: 4, transaction_type: .refund, merchant_name: "Refund", transaction_date: now),
            Transaction(amount: 500, transaction_type: .transfer, merchant_name: "Transfer", transaction_date: now),
            Transaction(amount: 700, currency: "EUR", merchant_name: "Foreign", transaction_date: now)
        ]
        let summary = Analytics.summary(txns, currency: "USD", now: now)
        XCTAssertEqual(summary.totalSpending, 1.3)
        XCTAssertEqual(summary.totalIncome, 104)
        XCTAssertEqual(summary.netFlow, 102.7)
        XCTAssertEqual(summary.loggedThisWeek, 1.3)
        XCTAssertEqual(summary.countThisWeek, 6)
        XCTAssertEqual(summary.excludedCurrencyCount, 1)
        XCTAssertEqual(Analytics.summary(txns, currency: "EUR", now: now).totalSpending, 700)
        XCTAssertEqual(Analytics.categoryTotals(txns, currency: "USD").reduce(0) { $0 + $1.amount }, 1.3)
        XCTAssertEqual(Analytics.groupTotals(txns, currency: "USD").reduce(0) { $0 + $1.amount }, 1.3)
    }

    @MainActor
    func testDuplicateMatcherSeparatesFinancialEvents() throws {
        let draft = draft()
        let original = try draft.makeTransaction(allTags: [])
        XCTAssertEqual(Analytics.similarTransaction(to: draft, in: [original])?.id, original.id)
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original], excludingID: original.id))
        draft.currency = "EUR"
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original]))
        draft.currency = "USD"
        draft.transaction_type = .refund
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original]))
        draft.transaction_type = .expense
        draft.amountText = "12.35"
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original]))
        draft.amountText = "12.34"
        original.status = .ignored
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original]))
        original.status = .posted
        original.transaction_date = draft.transaction_date.addingTimeInterval(-3 * 24 * 60 * 60)
        XCTAssertNil(Analytics.similarTransaction(to: draft, in: [original]))
    }

    @MainActor
    func testDateWindowsUseExplicitClockAndTimezone() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var pacific = utc
        pacific.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let parser = ISO8601DateFormatter()
        let boundary = try XCTUnwrap(parser.date(from: "2026-03-01T00:30:00Z"))
        let now = try XCTUnwrap(parser.date(from: "2026-03-02T12:00:00Z"))
        XCTAssertTrue(Analytics.isInCurrentMonth(boundary, now: now, calendar: utc))
        XCTAssertFalse(Analytics.isInCurrentMonth(boundary, now: now, calendar: pacific))
        let txn = Transaction(amount: 42, merchant_name: "Boundary", transaction_date: boundary)
        XCTAssertEqual(Analytics.summary([txn], currency: "USD", now: now, calendar: utc).totalSpending, 42)
        XCTAssertEqual(Analytics.summary([txn], currency: "USD", now: now, calendar: pacific).totalSpending, 0)
        XCTAssertEqual(txn.transaction_date, boundary, "Display/aggregation must not rewrite persisted instants")
    }

    @MainActor
    func testSearchFiltersComposeAndManualOriginCanBeSourceFree() throws {
        let txn = try draft().makeTransaction(allTags: [])
        XCTAssertTrue(TransactionSearch.matches(txn, text: "cafe", filter: .expenses, category: "Dining", source: .manual_entry))
        XCTAssertFalse(TransactionSearch.matches(txn, text: "cafe", filter: .income, category: nil, source: nil))
        XCTAssertFalse(TransactionSearch.matches(txn, text: "cafe", filter: .all, category: nil, source: .screenshot))
        XCTAssertFalse(TransactionSearch.matches(txn, text: "other", filter: .all, category: nil, source: nil))
        XCTAssertTrue(TransactionSearch.matches(txn, text: "  ", filter: .pending, category: nil, source: nil))
    }

    @MainActor
    func testFormattingAndStubDoNotInventFinancialAuthority() {
        XCTAssertTrue(Money.format(12.34, currency: "USD").contains("USD"))
        XCTAssertTrue(Money.format(12.34, currency: "EUR").contains("EUR"))
        XCTAssertFalse(Money.format(500, currency: "USD", signed: false).hasPrefix("+"))
        let sourceID = UUID()
        let stub = UploadView.makeStubbedDraft(
            sourceID: sourceID,
            sizeBytes: nil,
            mimeType: nil
        )
        XCTAssertEqual(stub.source?.id, sourceID.uuidString)
        XCTAssertNil(stub.source?.stored_file_uri)
        XCTAssertEqual(stub.source?.parse_status, .manual_review)
        XCTAssertNil(stub.source?.source_hash)
        XCTAssertNil(stub.source?.captured_at)
        XCTAssertNil(stub.confidence_score)
        XCTAssertFalse(stub.canConfirm, "A category must be deliberately chosen")
    }

    // MARK: - Phase 1C financial-date characterization probes
    //
    // Evidence only. These tests characterize Foundation Date/calendar behavior and
    // current model permissiveness. They are not Portable v1 acceptance tests and
    // do not define production conversion or restoration policy.

    func testFinancialDateProbeSameInstantProjectsToDifferentGregorianDaysAcrossTimeZones() throws {
        let parser = ISO8601DateFormatter()
        let instant = try XCTUnwrap(parser.date(from: "2026-03-01T00:30:00Z"))

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        let utcParts = utc.dateComponents([.year, .month, .day], from: instant)
        let pacificParts = pacific.dateComponents([.year, .month, .day], from: instant)

        XCTAssertEqual([utcParts.year, utcParts.month, utcParts.day], [2026, 3, 1])
        XCTAssertEqual([pacificParts.year, pacificParts.month, pacificParts.day], [2026, 2, 28])
        XCTAssertNotEqual(utcParts.day, pacificParts.day)
    }

    func testFinancialDateProbeCalendarSystemChangesYearMonthDayInterpretation() throws {
        let parser = ISO8601DateFormatter()
        let instant = try XCTUnwrap(parser.date(from: "2026-03-01T12:00:00Z"))
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = utc

        let gregorianParts = gregorian.dateComponents([.year, .month, .day], from: instant)
        let buddhistParts = buddhist.dateComponents([.year, .month, .day], from: instant)

        XCTAssertEqual([gregorianParts.year, gregorianParts.month, gregorianParts.day], [2026, 3, 1])
        XCTAssertNotEqual(gregorianParts.year, buddhistParts.year)
    }

    func testFinancialDateProbeDSTCivilDaysAreNotUniformTwentyFourHourIntervals() throws {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        let springStart = try XCTUnwrap(newYork.date(from: DateComponents(year: 2026, month: 3, day: 8)))
        let springNext = try XCTUnwrap(newYork.date(byAdding: .day, value: 1, to: springStart))
        let fallStart = try XCTUnwrap(newYork.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let fallNext = try XCTUnwrap(newYork.date(byAdding: .day, value: 1, to: fallStart))

        XCTAssertEqual(springNext.timeIntervalSince(springStart), 23 * 60 * 60, accuracy: 1)
        XCTAssertEqual(fallNext.timeIntervalSince(fallStart), 25 * 60 * 60, accuracy: 1)
    }

    func testFinancialDateProbeFixedZoneRestorationAnchorCanRenderAsAdjacentDayElsewhere() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let restoredAnchor = try XCTUnwrap(
            utc.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 0, minute: 0))
        )

        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let parts = pacific.dateComponents([.year, .month, .day], from: restoredAnchor)

        XCTAssertEqual([parts.year, parts.month, parts.day], [2026, 2, 28])
    }

    @MainActor
    func testFinancialDateProbePostedDatePresenceIsStructurallyIndependentOfStatus() throws {
        let parser = ISO8601DateFormatter()
        let posted = try XCTUnwrap(parser.date(from: "2026-03-01T12:00:00Z"))

        let pendingWithDate = Transaction(
            amount: 1,
            merchant_name: "Pending with date",
            posted_date: posted,
            status: .pending
        )
        let postedWithoutDate = Transaction(
            amount: 1,
            merchant_name: "Posted without date",
            posted_date: nil,
            status: .posted
        )
        let ignoredWithDate = Transaction(
            amount: 1,
            merchant_name: "Ignored with date",
            posted_date: posted,
            status: .ignored
        )
        let duplicateWithoutDate = Transaction(
            amount: 1,
            merchant_name: "Duplicate without date",
            posted_date: nil,
            status: .duplicate
        )
        let reviewNeededWithDate = Transaction(
            amount: 1,
            merchant_name: "Review needed with date",
            posted_date: posted,
            status: .review_needed
        )

        XCTAssertEqual(pendingWithDate.posted_date, posted)
        XCTAssertNil(postedWithoutDate.posted_date)
        XCTAssertEqual(ignoredWithDate.posted_date, posted)
        XCTAssertNil(duplicateWithoutDate.posted_date)
        XCTAssertEqual(reviewNeededWithDate.posted_date, posted)
    }

}
