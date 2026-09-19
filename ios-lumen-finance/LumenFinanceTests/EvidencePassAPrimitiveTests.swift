import XCTest
import SwiftData
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics
@testable import LumenFinance

final class EvidencePassAPrimitiveTests: XCTestCase {
    // MARK: - RetainedEvidenceLocator

    func testLocatorCanonicalSerializeParseRoundTrip() {
        let sourceID = UUID()
        let locator = RetainedEvidenceLocator(sourceID: sourceID)

        XCTAssertEqual(
            locator.serialized,
            "lumen-evidence://v1/\(sourceID.uuidString)/payload"
        )

        XCTAssertEqual(
            RetainedEvidenceLocator.classify(locator.serialized),
            .supported(locator)
        )
        XCTAssertEqual(
            RetainedEvidenceLocator.classify(locator.serialized, owningSourceID: sourceID.uuidString),
            .supported(locator)
        )
    }

    func testLocatorAcceptsCaseVariedUUIDSemanticallyAndSerializesCanonically() {
        let sourceID = UUID()
        let lowercased = "lumen-evidence://v1/\(sourceID.uuidString.lowercased())/payload"

        guard case .supported(let parsed) = RetainedEvidenceLocator.classify(lowercased) else {
            return XCTFail("Expected supported v1 locator")
        }

        XCTAssertEqual(parsed.sourceID, sourceID)
        XCTAssertEqual(parsed.serialized, "lumen-evidence://v1/\(sourceID.uuidString)/payload")
    }

    func testLocatorClassifiesLegacyAndUnsupportedValuesWithoutPathFallback() {
        let legacy = "file:///private/var/mobile/tmp/receipt.jpg"
        XCTAssertEqual(
            RetainedEvidenceLocator.classify(legacy),
            .legacyOpaque(legacy)
        )

        let sourceID = UUID()
        XCTAssertEqual(
            RetainedEvidenceLocator.classify("lumen-evidence://v2/\(sourceID.uuidString)/payload"),
            .unsupportedVersion("v2")
        )
        XCTAssertEqual(
            RetainedEvidenceLocator.classify(nil),
            .noRetainedLocator
        )
    }

    func testLocatorRejectsMalformedV1Grammar() {
        let sourceID = UUID().uuidString
        let malformed = [
            "lumen-evidence://v1/not-a-uuid/payload",
            "lumen-evidence://v1/payload",
            "lumen-evidence://v1/\(sourceID)",
            "lumen-evidence://v1/\(sourceID)/payload/extra",
            "lumen-evidence://v1/\(sourceID)/payload/",
            "lumen-evidence://v1/\(sourceID)/payload?x=1",
            "lumen-evidence://v1/\(sourceID)/payload#fragment",
            "lumen-evidence://user@v1/\(sourceID)/payload",
            "lumen-evidence://v1:443/\(sourceID)/payload",
            "lumen-evidence://v1/%\(sourceID)/payload"
        ]

        for value in malformed {
            XCTAssertEqual(
                RetainedEvidenceLocator.classify(value),
                .invalidLocator,
                "Expected invalid v1 locator: \(value)"
            )
        }
    }

    func testLocatorDetectsSourceAssociationMismatch() {
        let locatorID = UUID()
        let ownerID = UUID()
        let raw = RetainedEvidenceLocator(sourceID: locatorID).serialized

        XCTAssertEqual(
            RetainedEvidenceLocator.classify(raw, owningSourceID: ownerID.uuidString),
            .invalidAssociation(RetainedEvidenceLocator(sourceID: locatorID))
        )
        XCTAssertEqual(
            RetainedEvidenceLocator.classify(raw, owningSourceID: "historical-non-uuid"),
            .invalidAssociation(RetainedEvidenceLocator(sourceID: locatorID))
        )
    }

    // MARK: - EvidenceIdentity

    @MainActor
    func testSemanticOwnershipZeroOneAndExactDuplicateConflict() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let sourceID = UUID()

        guard case .none = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Expected zero semantic owners")
        }

        let first = TransactionSource(id: sourceID.uuidString, source_type: .receipt_photo)
        context.insert(first)
        try context.save()

        guard case .one(let owner) = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Expected one semantic owner")
        }
        XCTAssertEqual(owner.persistentModelID, first.persistentModelID)
        XCTAssertEqual(owner.id, sourceID.uuidString)

        let second = TransactionSource(id: sourceID.uuidString, source_type: .screenshot)
        context.insert(second)
        try context.save()

        guard case .conflict(let owners) = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Expected duplicate semantic-owner conflict")
        }
        XCTAssertEqual(owners.count, 2)
    }

    @MainActor
    func testSemanticOwnershipTreatsCaseVariedUUIDStringsAsConflictWithoutRewritingThem() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let sourceID = UUID()
        let canonical = sourceID.uuidString
        let lowercased = canonical.lowercased()

        let first = TransactionSource(id: canonical, source_type: .receipt_photo)
        let second = TransactionSource(id: lowercased, source_type: .screenshot)
        context.insert(first)
        context.insert(second)
        try context.save()

        guard case .conflict(let owners) = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Expected case-varied UUIDs to conflict semantically")
        }

        XCTAssertEqual(owners.count, 2)
        XCTAssertEqual(Set(owners.map(\.id)), Set([canonical, lowercased]))
        XCTAssertEqual(first.id, canonical)
        XCTAssertEqual(second.id, lowercased)
        XCTAssertEqual(EvidenceIdentity.canonicalString(for: sourceID), canonical)
    }

    @MainActor
    func testHistoricalNonUUIDSourceRemainsUntouchedAndDoesNotOwnUUIDNamespace() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let historicalID = "legacy-manual-source"
        let source = TransactionSource(id: historicalID, source_type: .manual_entry)
        context.insert(source)
        try context.save()

        let target = UUID()
        guard case .none = try EvidenceIdentity.semanticOwners(of: target, in: context) else {
            return XCTFail("Historical non-UUID ID must not own an unrelated UUID namespace")
        }

        XCTAssertNil(EvidenceIdentity.uuid(fromSourceID: historicalID))
        XCTAssertEqual(source.id, historicalID)
    }

    @MainActor
    func testSingleLegacyRowOccupyingSemanticUUIDIsVisibleAndNotReusableAsFreeIdentity() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let sourceID = UUID()
        let legacyURI = "file:///tmp/historical-receipt.jpg"
        let persistedSpelling = sourceID.uuidString.lowercased()
        let source = TransactionSource(
            id: persistedSpelling,
            source_type: .receipt_photo,
            stored_file_uri: legacyURI
        )
        context.insert(source)
        try context.save()

        guard case .one(let owner) = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Expected the legacy row to occupy the semantic UUID")
        }

        XCTAssertEqual(owner.persistentModelID, source.persistentModelID)
        XCTAssertEqual(owner.id, persistedSpelling)
        XCTAssertEqual(
            RetainedEvidenceLocator.classify(owner.stored_file_uri, owningSourceID: owner.id),
            .legacyOpaque(legacyURI)
        )
    }

    @MainActor
    func testSemanticOwnershipIgnoresUnsavedInsertionWithoutDisturbingCallerState() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let sourceID = UUID()
        let source = TransactionSource(id: sourceID.uuidString, source_type: .receipt_photo)

        context.insert(source)

        XCTAssertTrue(context.hasChanges)
        XCTAssertTrue(
            context.insertedModelsArray.contains {
                $0.persistentModelID == source.persistentModelID
            }
        )

        guard case .none = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Unsaved insertion must not become a persisted semantic owner")
        }

        XCTAssertTrue(context.hasChanges)
        XCTAssertEqual(source.id, sourceID.uuidString)
        XCTAssertTrue(
            context.insertedModelsArray.contains {
                $0.persistentModelID == source.persistentModelID
            }
        )
    }

    @MainActor
    func testSemanticOwnershipSeesPersistedOwnerThroughUnsavedDeletionWithoutDisturbingCallerState() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let sourceID = UUID()
        let source = TransactionSource(id: sourceID.uuidString, source_type: .receipt_photo)
        context.insert(source)
        try context.save()

        context.delete(source)

        XCTAssertTrue(context.hasChanges)
        XCTAssertTrue(
            context.deletedModelsArray.contains {
                $0.persistentModelID == source.persistentModelID
            }
        )

        guard case .one(let owner) = try EvidenceIdentity.semanticOwners(of: sourceID, in: context) else {
            return XCTFail("Unsaved deletion must not hide the persisted semantic owner")
        }
        XCTAssertEqual(owner.persistentModelID, source.persistentModelID)
        XCTAssertEqual(owner.id, sourceID.uuidString)

        XCTAssertTrue(context.hasChanges)
        XCTAssertTrue(
            context.deletedModelsArray.contains {
                $0.persistentModelID == source.persistentModelID
            }
        )
    }

    @MainActor
    func testSemanticOwnershipUsesPersistedIDThroughUnsavedMutationWithoutDisturbingCallerState() throws {
        let container = try inMemoryContainer()
        let context = container.mainContext
        let persistedID = UUID()
        let pendingID = UUID()
        let source = TransactionSource(id: persistedID.uuidString, source_type: .receipt_photo)
        context.insert(source)
        try context.save()

        source.id = pendingID.uuidString

        XCTAssertTrue(context.hasChanges)
        XCTAssertEqual(source.id, pendingID.uuidString)

        guard case .one(let owner) = try EvidenceIdentity.semanticOwners(of: persistedID, in: context) else {
            return XCTFail("Persisted UUID must remain authoritatively owned during an unsaved ID mutation")
        }
        XCTAssertEqual(owner.persistentModelID, source.persistentModelID)
        XCTAssertEqual(owner.id, persistedID.uuidString)

        guard case .none = try EvidenceIdentity.semanticOwners(of: pendingID, in: context) else {
            return XCTFail("Unsaved UUID mutation must not create persisted ownership")
        }

        XCTAssertTrue(context.hasChanges)
        XCTAssertEqual(source.id, pendingID.uuidString)
    }

    // MARK: - EvidencePayloadInspector

    func testPayloadInspectorReportsActualPNGAndDoesNotMutateBytes() throws {
        let data = try encodedTestImage(type: .png)
        let before = data
        let result = try EvidencePayloadInspector.inspect(data)

        XCTAssertEqual(data, before)
        XCTAssertEqual(result.byteCount, data.count)
        XCTAssertEqual(result.typeIdentifier, UTType.png.identifier)
        XCTAssertEqual(result.mimeType, "image/png")
    }

    func testPayloadInspectorReportsActualJPEG() throws {
        let data = try encodedTestImage(type: .jpeg)
        let result = try EvidencePayloadInspector.inspect(data)

        XCTAssertEqual(result.byteCount, data.count)
        XCTAssertEqual(result.typeIdentifier, UTType.jpeg.identifier)
        XCTAssertEqual(result.mimeType, "image/jpeg")
    }

    func testPayloadInspectorReportsHEICWhenEncoderIsAvailable() throws {
        let data: Data
        do {
            data = try encodedTestImage(type: .heic)
        } catch TestImageEncodingError.encoderUnavailable {
            throw XCTSkip("HEIC encoding is unavailable in this test environment")
        }

        let result = try EvidencePayloadInspector.inspect(data)
        XCTAssertEqual(result.byteCount, data.count)
        XCTAssertEqual(result.typeIdentifier, UTType.heic.identifier)
        XCTAssertEqual(result.mimeType, "image/heic")
    }

    func testPayloadInspectorRejectsEmptyAndRandomBytes() {
        XCTAssertThrowsError(try EvidencePayloadInspector.inspect(Data())) { error in
            XCTAssertEqual(error as? EvidencePayloadInspectionError, .emptyData)
        }

        XCTAssertThrowsError(try EvidencePayloadInspector.inspect(Data([0x00, 0x01, 0x02, 0x03]))) { error in
            XCTAssertEqual(error as? EvidencePayloadInspectionError, .invalidImage)
        }
    }

    func testUnknownTypeIdentifierMapsToNilMimeWithoutInventingMetadata() {
        XCTAssertNil(EvidencePayloadInspector.mimeType(forTypeIdentifier: "com.example.lumen-unmapped-image"))
        XCTAssertNil(EvidencePayloadInspector.mimeType(forTypeIdentifier: nil))
    }

    // MARK: - Helpers

    @MainActor
    private func inMemoryContainer() throws -> ModelContainer {
        let schema = LedgerStore.schema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        return container
    }

    private enum TestImageEncodingError: Error {
        case imageCreationFailed
        case encoderUnavailable
    }

    private func encodedTestImage(type: UTType) throws -> Data {
        let pixels: [UInt8] = [
            255, 0, 0, 255,     0, 255, 0, 255,
            0, 0, 255, 255,     255, 255, 255, 255
        ]

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                width: 2,
                height: 2,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: 8,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw TestImageEncodingError.imageCreationFailed
        }

        let output = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(
            output,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw TestImageEncodingError.encoderUnavailable
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw TestImageEncodingError.encoderUnavailable
        }

        guard let bytes = CFDataGetBytePtr(output) else {
            throw TestImageEncodingError.imageCreationFailed
        }
        return Data(bytes: bytes, count: CFDataGetLength(output))
    }
}
