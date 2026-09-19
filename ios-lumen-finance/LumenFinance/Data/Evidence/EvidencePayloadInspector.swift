import Foundation
import ImageIO
import UniformTypeIdentifiers

struct EvidencePayloadInspection: Equatable, Sendable {
    let byteCount: Int
    let typeIdentifier: String?
    let mimeType: String?
}

/// Read-only characterization of the exact image bytes supplied to Lumen.
///
/// This primitive never resizes, normalizes, recompresses, strips metadata,
/// writes files, or substitutes an advertised PhotosPicker content type.
enum EvidencePayloadInspector {
    static func inspect(_ data: Data) throws -> EvidencePayloadInspection {
        guard !data.isEmpty else {
            throw EvidencePayloadInspectionError.emptyData
        }

        let source = CGImageSourceCreateIncremental(nil)
        CGImageSourceUpdateData(source, data as CFData, true)

        guard CGImageSourceGetCount(source) > 0,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceCopyPropertiesAtIndex(source, 0, nil) != nil else {
            throw EvidencePayloadInspectionError.invalidImage
        }

        let typeIdentifier = CGImageSourceGetType(source).map { $0 as String }
        let mimeType = mimeType(forTypeIdentifier: typeIdentifier)

        return EvidencePayloadInspection(
            byteCount: data.count,
            typeIdentifier: typeIdentifier,
            mimeType: mimeType
        )
    }

    static func mimeType(forTypeIdentifier identifier: String?) -> String? {
        guard let identifier else { return nil }
        return UTType(identifier)?.preferredMIMEType
    }
}

enum EvidencePayloadInspectionError: Error, Equatable {
    case emptyData
    case invalidImage
}
