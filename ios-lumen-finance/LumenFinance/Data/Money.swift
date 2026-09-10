import Foundation

/// Display/derived arithmetic only. The persisted Double representation is unchanged.
nonisolated enum Money {
    static func magnitude(_ amount: Double) -> Decimal? {
        guard amount.isFinite else { return nil }
        return Decimal(string: String(abs(amount)), locale: Locale(identifier: "en_US_POSIX"))
    }

    static func format(_ amount: Double, currency: String, signed: Bool = false) -> String {
        guard amount.isFinite else { return "Invalid amount (\(currency))" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.currencyCode = currency
        let value = signed ? amount : abs(amount)
        let base = formatter.string(from: NSNumber(value: value)) ?? "\(value) \(currency)"
        return signed && amount > 0 ? "+\(base)" : base
    }
}
