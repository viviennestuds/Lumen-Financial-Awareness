import Foundation
import SwiftData

/// Application-level semantic identity rules for Confirmed Evidence Retention v1.
///
/// TransactionSource.id is not schema-enforced unique. v1 therefore compares
/// parseable UUID identities semantically and never rewrites historical strings.
enum EvidenceIdentity {
    static func uuid(fromSourceID sourceID: String) -> UUID? {
        UUID(uuidString: sourceID)
    }

    static func canonicalString(for uuid: UUID) -> String {
        uuid.uuidString
    }

    @MainActor
    static func semanticOwners(
        of uuid: UUID,
        in context: ModelContext
    ) throws -> EvidenceIdentityOwnership {
        let persistedContext = ModelContext(context.container)
        persistedContext.autosaveEnabled = false

        var descriptor = FetchDescriptor<TransactionSource>()
        descriptor.includePendingChanges = false
        let sources = try persistedContext.fetch(descriptor)
        let matches = sources.filter { source in
            guard let sourceUUID = UUID(uuidString: source.id) else { return false }
            return sourceUUID == uuid
        }

        switch matches.count {
        case 0:
            return .none
        case 1:
            return .one(matches[0])
        default:
            return .conflict(matches)
        }
    }
}

enum EvidenceIdentityOwnership {
    case none
    case one(TransactionSource)
    case conflict([TransactionSource])

    var count: Int {
        switch self {
        case .none: 0
        case .one: 1
        case .conflict(let sources): sources.count
        }
    }
}
