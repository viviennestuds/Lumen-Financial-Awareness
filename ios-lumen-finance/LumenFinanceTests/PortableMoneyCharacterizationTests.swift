import XCTest
import SwiftData
@testable import LumenFinance

/// Phase 1C characterization only.
///
/// This test does not define production serialization and is intentionally non-acceptance.
/// It asks whether candidate decimal monetary values survive the current:
///
/// decimal text -> TransactionDraft/Double -> SwiftData save/reopen -> candidate decimal text
///
/// path with the same decimal monetary value.
///
/// A red monetary observation is evidence about the candidate domain, not authorization to
/// change Transaction.amount or any production code.
final class PortableMoneyCharacterizationTests: XCTestCase {
    private let posix = Locale(identifier: "en_US_POSIX")
    private let lexicalPattern = #"^[0-9]+(?:\.[0-9]+)?$"#

    private struct Probe: Hashable {
        let id: String
        let input: String
        let currency: String
        let group: String
        let integerDigits: Int?
        let scale: Int?
        let variant: Int?
    }

    private struct Observation {
        let probe: Probe
        let lexicalValid: Bool
        let expected: Decimal?
        let parsedDouble: Double?
        let currentCreateValid: Bool
        var reopenedDouble: Double?
        var insertedBitPattern: UInt64?
        var reopenedBitPattern: UInt64?
        var serialized: String?
        var serializedLexicalValid: Bool?
        var observed: Decimal?
        var classification: String

        var monetaryEquivalent: Bool? {
            guard let expected, let observed else { return nil }
            return NSDecimalNumber(decimal: expected).compare(NSDecimalNumber(decimal: observed)) == .orderedSame
        }
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
            .appendingPathComponent("PortableMoneyCharacterization-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory.appendingPathComponent("ledger.store"))
    }

    private func isCandidateLexical(_ text: String) -> Bool {
        text.range(of: lexicalPattern, options: .regularExpression) != nil
    }

    private func decimal(_ text: String) -> Decimal? {
        Decimal(string: text, locale: posix)
    }

    /// Candidate serializer under characterization only.
    ///
    /// The format proposal explicitly does not canonize String(Double). This probe tests it as
    /// one deterministic candidate so failures/safe observations can be measured before a
    /// serializer is admitted.
    private func candidateSerialize(_ value: Double) -> String? {
        guard value.isFinite, value > 0 else { return nil }
        return String(value)
    }

    private func digitString(count: Int, seed: UInt64, nonZeroFirst: Bool) -> String {
        guard count > 0 else { return "" }
        var state = seed | 1
        var digits: [UInt8] = []
        digits.reserveCapacity(count)

        for index in 0..<count {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            var digit = UInt8((state >> 32) % 10)
            if index == 0 && nonZeroFirst && digit == 0 {
                digit = UInt8((state >> 40) % 9) + 1
            }
            digits.append(digit)
        }

        if digits.allSatisfy({ $0 == 0 }) {
            digits[digits.count - 1] = 1
        }

        return String(bytes: digits.map { $0 + 48 }, encoding: .ascii)!
    }

    private func patternedDigits(count: Int, pattern: String, nonZeroFirst: Bool) -> String {
        guard count > 0 else { return "" }
        let source = Array(pattern.utf8)
        var bytes: [UInt8] = []
        bytes.reserveCapacity(count)
        for index in 0..<count {
            bytes.append(source[index % source.count])
        }
        if nonZeroFirst && bytes[0] == 48 {
            bytes[0] = 49
        }
        return String(bytes: bytes, encoding: .ascii)!
    }

    private func generatedProbes() -> [Probe] {
        var probes: [Probe] = []
        var seen = Set<String>()
        var serial = 0

        func append(
            _ input: String,
            currency: String = "USD",
            group: String,
            integerDigits: Int? = nil,
            scale: Int? = nil,
            variant: Int? = nil
        ) {
            let key = "\(currency)|\(input)|\(group)"
            guard seen.insert(key).inserted else { return }
            probes.append(
                Probe(
                    id: String(format: "pm-%05d", serial),
                    input: input,
                    currency: currency,
                    group: group,
                    integerDigits: integerDigits,
                    scale: scale,
                    variant: variant
                )
            )
            serial += 1
        }

        // Required human-readable/open-gate probes from the proposed format contract.
        for (index, value) in [
            "0", "0.00", "0.01", "0.001", "52.3", "52.30", "52.300",
            "12.345", "987654321098.76", "052.30"
        ].enumerated() {
            append(value, group: "required_probe", variant: index)
        }

        // Representation probes: these exercise context without defining per-currency scale rules.
        append("52.30", currency: "USD", group: "currency_probe", integerDigits: 2, scale: 2, variant: 0)
        append("52.30", currency: "EUR", group: "currency_probe", integerDigits: 2, scale: 2, variant: 1)
        append("5200", currency: "JPY", group: "currency_probe", integerDigits: 4, scale: 0, variant: 2)
        append("12.345", currency: "KWD", group: "currency_probe", integerDigits: 2, scale: 3, variant: 3)

        // Known binary/integer precision transition probes around 2^53.
        for (index, value) in [
            "9007199254740990",
            "9007199254740991",
            "9007199254740992",
            "9007199254740993",
            "9007199254740994",
            "90071992547409.90",
            "90071992547409.91",
            "90071992547409.92",
            "90071992547409.93",
            "90071992547409.94"
        ].enumerated() {
            let parts = value.split(separator: ".", omittingEmptySubsequences: false)
            append(
                value,
                group: "binary_boundary_probe",
                integerDigits: parts[0].count,
                scale: parts.count == 2 ? parts[1].count : 0,
                variant: index
            )
        }

        // Powers/magnitude transition probes. 10^18 is still finite but exercises serializer style.
        for exponent in 0...18 {
            let power = "1" + String(repeating: "0", count: exponent)
            append(power, group: "magnitude_probe", integerDigits: exponent + 1, scale: 0, variant: exponent)
            if exponent >= 1 {
                let below = String(repeating: "9", count: exponent)
                append(below, group: "magnitude_probe", integerDigits: exponent, scale: 0, variant: 100 + exponent)
            }
        }

        // Deterministic matrix. This is a sampled characterization envelope, not an exhaustive proof.
        // It intentionally crosses likely precision boundaries.
        let patterns = ["123456789", "987654321", "314159265", "271828182"]
        for integerDigits in 1...18 {
            for scale in 0...9 where integerDigits + scale <= 22 {
                for variant in 0..<8 {
                    let integerPart: String
                    let fractionalPart: String

                    if variant < patterns.count {
                        integerPart = patternedDigits(
                            count: integerDigits,
                            pattern: patterns[variant],
                            nonZeroFirst: true
                        )
                        fractionalPart = scale == 0 ? "" : patternedDigits(
                            count: scale,
                            pattern: patterns[(variant + 1) % patterns.count],
                            nonZeroFirst: false
                        )
                    } else {
                        let seed = UInt64(integerDigits * 10_000 + scale * 100 + variant)
                        integerPart = digitString(count: integerDigits, seed: seed, nonZeroFirst: true)
                        fractionalPart = scale == 0 ? "" : digitString(
                            count: scale,
                            seed: seed ^ 0x9E37_79B9_7F4A_7C15,
                            nonZeroFirst: false
                        )
                    }

                    let value = scale == 0 ? integerPart : "\(integerPart).\(fractionalPart)"
                    append(
                        value,
                        group: "generated_matrix",
                        integerDigits: integerDigits,
                        scale: scale,
                        variant: variant
                    )
                }
            }
        }

        // Values below one exercise scale independently of integer magnitude.
        for scale in 1...12 {
            for variant in 0..<8 {
                let fraction: String
                if variant < patterns.count {
                    fraction = patternedDigits(
                        count: scale,
                        pattern: patterns[variant],
                        nonZeroFirst: false
                    )
                } else {
                    fraction = digitString(
                        count: scale,
                        seed: UInt64(scale * 1_000 + variant),
                        nonZeroFirst: false
                    )
                }
                append(
                    "0.\(fraction)",
                    group: "subunit_matrix",
                    integerDigits: 1,
                    scale: scale,
                    variant: variant
                )
            }
        }

        return probes
    }

    private func emit(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            XCTFail("Could not encode characterization evidence")
            return
        }
        print("PMCHAR|\(text)")
    }

    @MainActor
    func testCurrentDoubleDurablePortableMoneyCandidate() throws {
        let probes = generatedProbes()
        XCTAssertGreaterThan(probes.count, 1_000, "Characterization envelope unexpectedly shrank")

        var observations = probes.map { probe in
            let lexical = isCandidateLexical(probe.input)
            let expected = lexical ? decimal(probe.input) : nil
            return Observation(
                probe: probe,
                lexicalValid: lexical,
                expected: expected,
                parsedDouble: nil,
                currentCreateValid: false,
                reopenedDouble: nil,
                insertedBitPattern: nil,
                reopenedBitPattern: nil,
                serialized: nil,
                serializedLexicalValid: nil,
                observed: nil,
                classification: lexical && expected != nil ? "not_evaluated" : "candidate_lexical_or_decimal_rejected"
            )
        }

        var indexByID: [String: Int] = [:]
        for index in observations.indices {
            indexByID[observations[index].probe.id] = index
        }

        try withStore { url in
            try autoreleasepool {
                let store = try container(at: url)
                defer { withExtendedLifetime(store) {} }
                let context = store.mainContext

                let category = Category(
                    id: "portable-money-characterization-category",
                    name: "Portable Money Characterization",
                    group: .custom,
                    color: "#000000",
                    icon: "number",
                    is_default: false,
                    created_at: Date(timeIntervalSince1970: 1_700_000_000)
                )
                try LedgerWrite.perform(in: context) {
                    context.insert(category)
                }

                var transactions: [Transaction] = []
                transactions.reserveCapacity(observations.count)

                for index in observations.indices {
                    guard observations[index].lexicalValid, observations[index].expected != nil else {
                        continue
                    }

                    let probe = observations[index].probe
                    let draft = TransactionDraft()
                    draft.amountText = probe.input
                    draft.currency = probe.currency
                    draft.transaction_type = .expense
                    draft.merchant_name = "Portable Money Characterization"
                    draft.category = category
                    draft.transaction_date = Date(timeIntervalSince1970: 1_700_000_000)
                    draft.status = .pending

                    observations[index].parsedDouble = draft.amount
                    observations[index].currentCreateValid = draft.canConfirm

                    guard draft.canConfirm else {
                        observations[index].classification = "current_create_rejected"
                        continue
                    }

                    let transaction = try draft.makeTransaction(allTags: [])
                    transaction.id = probe.id
                    transaction.created_at = Date(timeIntervalSince1970: 1_700_000_000)
                    transaction.updated_at = transaction.created_at

                    observations[index].insertedBitPattern = transaction.amount.bitPattern
                    transactions.append(transaction)
                }

                try LedgerWrite.perform(in: context) {
                    for transaction in transactions {
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

                    observations[index].reopenedDouble = transaction.amount
                    observations[index].reopenedBitPattern = transaction.amount.bitPattern

                    guard observations[index].insertedBitPattern == transaction.amount.bitPattern else {
                        observations[index].classification = "double_bit_pattern_changed_after_reopen"
                        continue
                    }

                    guard let serialized = candidateSerialize(transaction.amount) else {
                        observations[index].classification = "candidate_serializer_failed"
                        continue
                    }

                    observations[index].serialized = serialized
                    let serializedLexical = isCandidateLexical(serialized)
                    observations[index].serializedLexicalValid = serializedLexical

                    guard serializedLexical, let observed = decimal(serialized) else {
                        observations[index].classification = "candidate_serializer_nonportable_lexical"
                        continue
                    }

                    observations[index].observed = observed
                    observations[index].classification =
                        observations[index].monetaryEquivalent == true
                        ? "pass"
                        : "monetary_value_changed"
                }
            }
        }

        let generated = observations.filter { $0.probe.group == "generated_matrix" || $0.probe.group == "subunit_matrix" }
        let passed = observations.filter { $0.classification == "pass" }
        let generatedPassed = generated.filter { $0.classification == "pass" }

        let classifications = Dictionary(grouping: observations, by: \.classification)
            .mapValues(\.count)

        emit([
            "record_type": "meta",
            "test_role": "characterization",
            "serializer_candidate": "Swift.String(Double)",
            "persistence_path": "TransactionDraft -> Transaction.amount(Double) -> LedgerWrite/SwiftData save -> store close/reopen -> String(Double)",
            "comparison": "Decimal monetary-value equality; source spelling is not compared",
            "total_probe_count": observations.count,
            "generated_probe_count": generated.count,
            "currency_contexts": ["USD", "EUR", "JPY", "KWD"]
        ])

        emit([
            "record_type": "summary",
            "total_probe_count": observations.count,
            "total_pass_count": passed.count,
            "generated_probe_count": generated.count,
            "generated_pass_count": generatedPassed.count,
            "classifications": classifications
        ])

        // Aggregate generated evidence by integer-digit count and scale.
        let matrixGroups = Dictionary(grouping: generated) {
            "\($0.probe.integerDigits ?? -1)|\($0.probe.scale ?? -1)"
        }
        for key in matrixGroups.keys.sorted() {
            guard let rows = matrixGroups[key], let first = rows.first else { continue }
            let counts = Dictionary(grouping: rows, by: \.classification).mapValues(\.count)
            emit([
                "record_type": "matrix_cell",
                "integer_digits": first.probe.integerDigits ?? -1,
                "scale": first.probe.scale ?? -1,
                "total": rows.count,
                "pass": counts["pass", default: 0],
                "monetary_value_changed": counts["monetary_value_changed", default: 0],
                "serializer_nonportable_lexical": counts["candidate_serializer_nonportable_lexical", default: 0],
                "current_create_rejected": counts["current_create_rejected", default: 0],
                "persistence_bit_pattern_changed": counts["double_bit_pattern_changed_after_reopen", default: 0]
            ])
        }

        // Always preserve the required/open-gate probes and currency/binary/magnitude probes.
        let alwaysReportGroups = Set([
            "required_probe",
            "currency_probe",
            "binary_boundary_probe",
            "magnitude_probe"
        ])

        for observation in observations where alwaysReportGroups.contains(observation.probe.group) {
            emitObservation(observation)
        }

        // Preserve every generated counterexample, not only a pass/fail count.
        for observation in generated where observation.classification != "pass" {
            emitObservation(observation)
        }

        // Harness sanity only: characterization outcomes themselves do not fail the XCTest.
        XCTAssertEqual(
            observations.filter { $0.classification == "missing_after_reopen" }.count,
            0,
            "Characterization harness lost persisted Transactions rather than observing money semantics"
        )
        XCTAssertEqual(
            observations.filter { $0.classification == "double_bit_pattern_changed_after_reopen" }.count,
            0,
            "SwiftData changed persisted Double bit patterns inside the characterization envelope"
        )
    }

    private func emitObservation(_ observation: Observation) {
        var payload: [String: Any] = [
            "record_type": "observation",
            "id": observation.probe.id,
            "group": observation.probe.group,
            "input": observation.probe.input,
            "currency": observation.probe.currency,
            "lexical_valid": observation.lexicalValid,
            "current_create_valid": observation.currentCreateValid,
            "classification": observation.classification
        ]

        if let integerDigits = observation.probe.integerDigits {
            payload["integer_digits"] = integerDigits
        }
        if let scale = observation.probe.scale {
            payload["scale"] = scale
        }
        if let variant = observation.probe.variant {
            payload["variant"] = variant
        }
        if let parsedDouble = observation.parsedDouble {
            payload["parsed_double"] = String(parsedDouble)
            payload["parsed_double_bit_pattern"] = String(parsedDouble.bitPattern, radix: 16)
        }
        if let reopenedDouble = observation.reopenedDouble {
            payload["reopened_double"] = String(reopenedDouble)
            payload["reopened_double_bit_pattern"] = String(reopenedDouble.bitPattern, radix: 16)
        }
        if let serialized = observation.serialized {
            payload["serialized"] = serialized
        }
        if let serializedLexicalValid = observation.serializedLexicalValid {
            payload["serialized_lexical_valid"] = serializedLexicalValid
        }
        if let equivalent = observation.monetaryEquivalent {
            payload["monetary_equivalent"] = equivalent
        }

        emit(payload)
    }
}
