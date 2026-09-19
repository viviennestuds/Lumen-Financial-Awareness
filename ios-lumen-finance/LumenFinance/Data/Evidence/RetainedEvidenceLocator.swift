import Foundation

/// Semantic locator for Confirmed Evidence Retention v1.
///
/// This type never resolves a filesystem path. It only recognizes and serializes
/// the admitted logical identity:
/// lumen-evidence://v1/<CANONICAL-UUID>/payload
struct RetainedEvidenceLocator: Equatable, Sendable {
    static let scheme = "lumen-evidence"
    static let version = "v1"
    static let resource = "payload"

    let sourceID: UUID

    init(sourceID: UUID) {
        self.sourceID = sourceID
    }

    var serialized: String {
        "\(Self.scheme)://\(Self.version)/\(sourceID.uuidString)/\(Self.resource)"
    }

    static func classify(
        _ rawValue: String?,
        owningSourceID: String? = nil
    ) -> RetainedEvidenceLocatorClassification {
        guard let rawValue else { return .noRetainedLocator }

        guard let components = URLComponents(string: rawValue) else {
            return rawValue.lowercased().hasPrefix("\(scheme):")
                ? .invalidLocator
                : .legacyOpaque(rawValue)
        }

        guard components.scheme?.lowercased() == scheme else {
            return .legacyOpaque(rawValue)
        }

        guard components.user == nil,
              components.password == nil,
              components.port == nil,
              components.query == nil,
              components.fragment == nil else {
            return .invalidLocator
        }

        guard let host = components.host, !host.isEmpty else {
            return .invalidLocator
        }

        guard host.lowercased() == version else {
            return .unsupportedVersion(host)
        }

        // v1 has no reason to percent-encode path components. Rejecting encoded
        // forms keeps one exact grammar and avoids multiple spellings of identity.
        guard !components.percentEncodedPath.contains("%") else {
            return .invalidLocator
        }

        let segments = components.path.split(separator: "/", omittingEmptySubsequences: true)
        guard segments.count == 2,
              segments[1] == Substring(resource),
              !components.path.hasSuffix("/"),
              components.path == "/\(segments[0])/\(resource)",
              let sourceID = UUID(uuidString: String(segments[0])) else {
            return .invalidLocator
        }

        let locator = RetainedEvidenceLocator(sourceID: sourceID)

        if let owningSourceID {
            guard let ownerUUID = UUID(uuidString: owningSourceID),
                  ownerUUID == sourceID else {
                return .invalidAssociation(locator)
            }
        }

        return .supported(locator)
    }
}

enum RetainedEvidenceLocatorClassification: Equatable, Sendable {
    case noRetainedLocator
    case legacyOpaque(String)
    case unsupportedVersion(String)
    case invalidLocator
    case invalidAssociation(RetainedEvidenceLocator)
    case supported(RetainedEvidenceLocator)
}
