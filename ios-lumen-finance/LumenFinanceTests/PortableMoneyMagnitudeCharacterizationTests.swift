import XCTest
import SwiftData
@testable import LumenFinance

/// Phase 1C decimal-exponent / magnitude characterization only.
///
/// This diagnostic is non-production evidence. It does not define the final PortableMoneyV1
/// product envelope, serializer, scale rules, or currency rules.
///
/// The exact comparison oracle uses normalized decimal coefficient/exponent pairs rather than
/// Foundation Decimal so that probes near binary64 exponent boundaries are not constrained by
/// Foundation Decimal's own range.
final class PortableMoneyMagnitudeCharacterizationTests: XCTestCase {
    private let lexicalPattern = #"^[0-9]+(?:\.[0-9]+)?$"#

    private struct NormalizedDecimal: Equatable, Hashable {
        let coefficient: String
        let exponent: Int

        var precision: Int { coefficient.count }
        var adjustedExponent: Int { exponent + precision - 1 }
    }

    private struct Probe: Hashable {
        let id: String
        let input: String
        let expected: NormalizedDecimal
        let group: String
        let variant: String
    }

    private struct Observation {
        let probe: Probe
        var parsedDouble: Double?
        var serializedBeforePersistence: String?
        var parsedEquivalent: Bool?
        var moneyMagnitudePresent: Bool?
        var moneyMagnitudeFinite: Bool?
        var currentCreateValid: Bool
        var insertedBitPattern: UInt64?
        var reopenedBitPattern: UInt64?
        var serializedAfterPersistence: String?
        var durableEquivalent: Bool?
        var classification: String
    }

    @MainActor
    private func container(at url: URL) throws -> ModelContainer {
        let schema = LedgerStore.schema()
        let configuration = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        return container
    }

    private func withStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PortableMoneyMagnitudeCharacterization-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory.appendingPathComponent("ledger.store"))
    }

    private func isCandidateLexical(_ text: String) -> Bool {
        text.range(of: lexicalPattern, options: .regularExpression) != nil
    }

    private func normalizePlainDecimal(_ text: String) -> NormalizedDecimal? {
        guard isCandidateLexical(text) else { return nil }

        let parts = text.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }

        let integer = String(parts[0])
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        var digits = integer + fraction

        while digits.first == "0" {
            digits.removeFirst()
        }
        guard !digits.isEmpty else { return nil }

        var exponent = -fraction.count
        while digits.last == "0" {
            digits.removeLast()
            exponent += 1
        }

        guard !digits.isEmpty else { return nil }
        return NormalizedDecimal(coefficient: digits, exponent: exponent)
    }

    private func plainDecimal(coefficient: String, exponent: Int) -> String {
        precondition(!coefficient.isEmpty)
        precondition(coefficient.first != "0")
        precondition(coefficient.last != "0")

        if exponent >= 0 {
            return coefficient + String(repeating: "0", count: exponent)
        }

        let fractionalDigits = -exponent
        if fractionalDigits < coefficient.count {
            let splitOffset = coefficient.count - fractionalDigits
            let split = coefficient.index(coefficient.startIndex, offsetBy: splitOffset)
            return String(coefficient[..<split]) + "." + String(coefficient[split...])
        }

        return "0."
            + String(repeating: "0", count: fractionalDigits - coefficient.count)
            + coefficient
    }

    private func coefficient(precision: Int, variant: Int) -> String {
        precondition((1...15).contains(precision))

        if precision == 1 {
            return ["1", "5", "9"][variant % 3]
        }

        switch variant % 3 {
        case 0:
            return "1" + String(repeating: "0", count: precision - 2) + "1"
        case 1:
            let pattern = Array("314159265358979".utf8)
            let bytes = (0..<precision).map { pattern[$0 % pattern.count] }
            var value = String(bytes: bytes, encoding: .ascii)!
            if value.last == "0" {
                value.removeLast()
                value.append("1")
            }
            return value
        default:
            return String(repeating: "9", count: precision)
        }
    }

    private func candidateSerialize(_ value: Double) -> String? {
        guard value.isFinite, value > 0 else { return nil }
        return canonicalPlainDecimal(fromShortestRoundTrip: String(value))
    }

    private func canonicalPlainDecimal(fromShortestRoundTrip text: String) -> String? {
        let lower = text.lowercased()
        let parts = lower.split(separator: "e", maxSplits: 1, omittingEmptySubsequences: false)

        let plain: String
        if parts.count == 1 {
            plain = String(parts[0])
        } else {
            guard parts.count == 2, let exponent = Int(parts[1]) else { return nil }
            let mantissa = String(parts[0])
            guard !mantissa.hasPrefix("-"), !mantissa.hasPrefix("+") else { return nil }

            let mantissaParts = mantissa.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            guard mantissaParts.count <= 2 else { return nil }

            let integer = String(mantissaParts[0])
            let fraction = mantissaParts.count == 2 ? String(mantissaParts[1]) : ""
            guard !integer.isEmpty else { return nil }

            let digits = integer + fraction
            guard !digits.isEmpty, digits.allSatisfy({ $0.isNumber }) else { return nil }

            let shiftedPoint = integer.count + exponent

            if shiftedPoint <= 0 {
                plain = "0." + String(repeating: "0", count: -shiftedPoint) + digits
            } else if shiftedPoint >= digits.count {
                plain = digits + String(repeating: "0", count: shiftedPoint - digits.count)
            } else {
                let split = digits.index(digits.startIndex, offsetBy: shiftedPoint)
                plain = String(digits[..<split]) + "." + String(digits[split...])
            }
        }

        guard let normalized = normalizePlainDecimal(plain) else { return nil }
        return plainDecimal(coefficient: normalized.coefficient, exponent: normalized.exponent)
    }

    private func generatedProbes() -> [Probe] {
        var adjustedExponents = Set<Int>()

        // Broad technical scan.
        for exponent in stride(from: -330, through: 310, by: 10) {
            adjustedExponents.insert(exponent)
        }

        // Dense scan around the Foundation Decimal / current validation envelope.
        for exponent in -140...175 {
            adjustedExponents.insert(exponent)
        }

        // Dense scan around binary64 normal/subnormal and upper-range boundaries.
        for exponent in -325 ... -300 {
            adjustedExponents.insert(exponent)
        }
        for exponent in 300...310 {
            adjustedExponents.insert(exponent)
        }

        let precisions = [1, 2, 5, 10, 15]
        var probes: [Probe] = []
        var serial = 0

        for adjustedExponent in adjustedExponents.sorted() {
            for precision in precisions {
                for variant in 0..<3 {
                    let coefficient = coefficient(precision: precision, variant: variant)
                    let normalizedExponent = adjustedExponent - (precision - 1)
                    let expected = NormalizedDecimal(
                        coefficient: coefficient,
                        exponent: normalizedExponent
                    )
                    let input = plainDecimal(
                        coefficient: coefficient,
                        exponent: normalizedExponent
                    )
                    probes.append(
                        Probe(
                            id: String(format: "pmm-%05d", serial),
                            input: input,
                            expected: expected,
                            group: "adjusted_exponent_matrix",
                            variant: "p\(precision)-v\(variant)"
                        )
                    )
                    serial += 1
                }
            }
        }

        return probes
    }

    private func emit(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            XCTFail("Could not encode magnitude characterization evidence")
            return
        }
        print("PMMAG|\(text)")
    }

    @MainActor
    func testCurrentPortableMoneyDecimalExponentMagnitudeEnvelope() throws {
        let probes = generatedProbes()
        XCTAssertGreaterThan(probes.count, 4_000, "Magnitude characterization envelope unexpectedly shrank")

        var observations = probes.map {
            Observation(
                probe: $0,
                parsedDouble: nil,
                serializedBeforePersistence: nil,
                parsedEquivalent: nil,
                moneyMagnitudePresent: nil,
                moneyMagnitudeFinite: nil,
                currentCreateValid: false,
                insertedBitPattern: nil,
                reopenedBitPattern: nil,
                serializedAfterPersistence: nil,
                durableEquivalent: nil,
                classification: "not_evaluated"
            )
        }

        try withStore { url in
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext

                let category = Category(
                    id: "portable-money-magnitude-characterization-category",
                    name: "Portable Money Magnitude Characterization",
                    group: .custom,
                    color: "#000000",
                    icon: "number",
                    is_default: false,
                    created_at: Date(timeIntervalSince1970: 1_700_000_000)
                )
                try LedgerWrite.perform(in: context) {
                    context.insert(category)
                }

                try LedgerWrite.perform(in: context) {
                    for index in observations.indices {
                        let probe = observations[index].probe

                        let draft = TransactionDraft()
                        draft.amountText = probe.input
                        draft.currency = "USD"
                        draft.transaction_type = .expense
                        draft.merchant_name = "Portable Money Magnitude Characterization"
                        draft.category = category
                        draft.transaction_date = Date(timeIntervalSince1970: 1_700_000_000)
                        draft.status = .pending

                        let parsed = draft.amount
                        observations[index].parsedDouble = parsed

                        if parsed == 0 {
                            observations[index].classification = "double_underflow_zero"
                            continue
                        }
                        if !parsed.isFinite {
                            observations[index].classification = "double_overflow_nonfinite"
                            continue
                        }

                        guard let serialized = candidateSerialize(parsed),
                              let normalizedSerialized = normalizePlainDecimal(serialized) else {
                            observations[index].classification = "candidate_serializer_failed"
                            continue
                        }

                        observations[index].serializedBeforePersistence = serialized
                        let equivalent = normalizedSerialized == probe.expected
                        observations[index].parsedEquivalent = equivalent

                        if !equivalent {
                            observations[index].classification = "double_monetary_value_changed"
                            continue
                        }

                        let magnitude = Money.magnitude(parsed)
                        observations[index].moneyMagnitudePresent = magnitude != nil
                        observations[index].moneyMagnitudeFinite = magnitude?.isFinite

                        observations[index].currentCreateValid = draft.canConfirm
                        guard draft.canConfirm else {
                            observations[index].classification =
                                magnitude == nil
                                ? "current_money_magnitude_rejected"
                                : "current_create_rejected_other"
                            continue
                        }

                        let transaction = try draft.makeTransaction(allTags: [])
                        transaction.id = probe.id
                        transaction.created_at = Date(timeIntervalSince1970: 1_700_000_000)
                        transaction.updated_at = transaction.created_at

                        observations[index].insertedBitPattern = transaction.amount.bitPattern
                        context.insert(transaction)
                    }
                }
            }

            try autoreleasepool {
                let reopened = try container(at: url)
                defer { withExtendedLifetime(reopened) {} }
                let context = reopened.mainContext
                let transactions = try context.fetch(FetchDescriptor<Transaction>())
                let byID = Dictionary(uniqueKeysWithValues: transactions.map { ($0.id, $0) })

                for index in observations.indices {
                    guard observations[index].currentCreateValid else { continue }
                    let probe = observations[index].probe

                    guard let transaction = byID[probe.id] else {
                        observations[index].classification = "missing_after_reopen"
                        continue
                    }

                    observations[index].reopenedBitPattern = transaction.amount.bitPattern
                    guard observations[index].insertedBitPattern == transaction.amount.bitPattern else {
                        observations[index].classification = "double_bit_pattern_changed_after_reopen"
                        continue
                    }

                    guard let serialized = candidateSerialize(transaction.amount),
                          let normalizedSerialized = normalizePlainDecimal(serialized) else {
                        observations[index].classification = "candidate_serializer_failed_after_reopen"
                        continue
                    }

                    observations[index].serializedAfterPersistence = serialized
                    let equivalent = normalizedSerialized == probe.expected
                    observations[index].durableEquivalent = equivalent
                    observations[index].classification = equivalent ? "pass" : "durable_monetary_value_changed"
                }
            }
        }

        let classifications = Dictionary(grouping: observations, by: \.classification).mapValues(\.count)

        emit([
            "record_type": "meta",
            "test_role": "decimal_exponent_magnitude_characterization",
            "comparison": "exact normalized coefficient/exponent equality",
            "precision_policy_under_test": "<=15 normalized significant decimal digits",
            "total_probe_count": observations.count,
            "double_greatest_finite": String(Double.greatestFiniteMagnitude),
            "double_least_normal": String(Double.leastNormalMagnitude),
            "double_least_nonzero": String(Double.leastNonzeroMagnitude),
            "double_significand_bit_count": Double.significandBitCount,
            "foundation_decimal_note": "Current TransactionDraft validity also requires Money.magnitude(Double) != nil"
        ])

        emit([
            "record_type": "summary",
            "total_probe_count": observations.count,
            "classifications": classifications
        ])

        let byAdjustedExponent = Dictionary(grouping: observations, by: { $0.probe.expected.adjustedExponent })
        for adjustedExponent in byAdjustedExponent.keys.sorted() {
            guard let rows = byAdjustedExponent[adjustedExponent] else { continue }
            let counts = Dictionary(grouping: rows, by: \.classification).mapValues(\.count)
            emit([
                "record_type": "adjusted_exponent_summary",
                "adjusted_exponent": adjustedExponent,
                "total": rows.count,
                "pass": counts["pass", default: 0],
                "double_underflow_zero": counts["double_underflow_zero", default: 0],
                "double_overflow_nonfinite": counts["double_overflow_nonfinite", default: 0],
                "double_monetary_value_changed": counts["double_monetary_value_changed", default: 0],
                "current_money_magnitude_rejected": counts["current_money_magnitude_rejected", default: 0],
                "current_create_rejected_other": counts["current_create_rejected_other", default: 0],
                "durable_monetary_value_changed": counts["durable_monetary_value_changed", default: 0],
                "persistence_bit_pattern_changed": counts["double_bit_pattern_changed_after_reopen", default: 0]
            ])
        }

        // Preserve all observations around key technical/current-validation boundaries.
        let reportExponents = Set(
            Array(-325 ... -300)
            + Array(-132 ... -124)
            + Array(160...168)
            + Array(300...310)
        )

        for observation in observations {
            if reportExponents.contains(observation.probe.expected.adjustedExponent)
                || observation.classification != "pass" {
                emitObservation(observation)
            }
        }

        XCTAssertEqual(
            observations.filter { $0.classification == "missing_after_reopen" }.count,
            0,
            "Magnitude characterization lost persisted Transactions"
        )
        XCTAssertEqual(
            observations.filter { $0.classification == "double_bit_pattern_changed_after_reopen" }.count,
            0,
            "SwiftData changed persisted Double bit patterns inside the magnitude characterization envelope"
        )
    }

    private func emitObservation(_ observation: Observation) {
        var payload: [String: Any] = [
            "record_type": "observation",
            "id": observation.probe.id,
            "input": observation.probe.input,
            "coefficient": observation.probe.expected.coefficient,
            "normalized_exponent": observation.probe.expected.exponent,
            "adjusted_exponent": observation.probe.expected.adjustedExponent,
            "precision": observation.probe.expected.precision,
            "variant": observation.probe.variant,
            "classification": observation.classification,
            "current_create_valid": observation.currentCreateValid
        ]

        if let parsedDouble = observation.parsedDouble {
            payload["parsed_double"] = String(parsedDouble)
            payload["parsed_double_finite"] = parsedDouble.isFinite
            payload["parsed_double_zero"] = parsedDouble == 0
            payload["parsed_double_bit_pattern"] = String(parsedDouble.bitPattern, radix: 16)
        }
        if let serialized = observation.serializedBeforePersistence {
            payload["serialized_before_persistence"] = serialized
        }
        if let equivalent = observation.parsedEquivalent {
            payload["parsed_monetary_equivalent"] = equivalent
        }
        if let present = observation.moneyMagnitudePresent {
            payload["money_magnitude_present"] = present
        }
        if let finite = observation.moneyMagnitudeFinite {
            payload["money_magnitude_finite"] = finite
        }
        if let inserted = observation.insertedBitPattern {
            payload["inserted_double_bit_pattern"] = String(inserted, radix: 16)
        }
        if let reopened = observation.reopenedBitPattern {
            payload["reopened_double_bit_pattern"] = String(reopened, radix: 16)
        }
        if let serialized = observation.serializedAfterPersistence {
            payload["serialized_after_persistence"] = serialized
        }
        if let equivalent = observation.durableEquivalent {
            payload["durable_monetary_equivalent"] = equivalent
        }

        emit(payload)
    }
}
