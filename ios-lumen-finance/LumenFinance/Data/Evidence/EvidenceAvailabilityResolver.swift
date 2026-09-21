import Foundation
import SwiftData

enum EvidenceAvailabilityState: Equatable {
    case noEvidenceExpected
    case noRetainedLocator
    case available
    case expectedButUnavailable
    case legacyOpaque
    case unsupportedVersion(String)
    case invalidLocator
    case invalidAssociation
    case identityConflict
}

enum EvidencePhysicalObservation: Equatable {
    case notApplicable
    case regularPayloadReadable
    case missing
    case unreadable
    case unexpectedNodeKind(EvidenceFileNodeKind)
    case inspectionFailure
}

struct EvidenceAvailabilityResolution: Equatable {
    let state: EvidenceAvailabilityState
    let physicalObservation: EvidencePhysicalObservation

    static let noEvidenceExpected = EvidenceAvailabilityResolution(
        state: .noEvidenceExpected,
        physicalObservation: .notApplicable
    )
}

@MainActor
struct EvidenceAvailabilityResolver {
    private let fileSystem: any EvidenceAvailabilityFileSystem

    init(
        fileSystem: any EvidenceAvailabilityFileSystem
    ) {
        self.fileSystem = fileSystem
    }

    static func live() -> EvidenceAvailabilityResolver {
        EvidenceAvailabilityResolver(
            fileSystem: LocalEvidenceFileSystem()
        )
    }

    func resolve(
        source: TransactionSource?,
        in context: ModelContext
    ) throws -> EvidenceAvailabilityResolution {
        guard let source else {
            return .noEvidenceExpected
        }

        if let sourceID = EvidenceIdentity.uuid(
            fromSourceID: source.id
        ) {
            let ownership = try EvidenceIdentity.semanticOwners(
                of: sourceID,
                in: context
            )

            switch ownership {
            case .none, .conflict:
                return identityConflict()

            case .one(let persistedOwner):
                guard persistedOwner.persistentModelID ==
                        source.persistentModelID else {
                    return identityConflict()
                }

                return resolvePersistedSource(
                    persistedOwner,
                    sourceID: sourceID
                )
            }
        }

        return resolveNonV1IdentitySource(source)
    }

    private func resolvePersistedSource(
        _ source: TransactionSource,
        sourceID: UUID
    ) -> EvidenceAvailabilityResolution {
        let classification = RetainedEvidenceLocator.classify(
            source.stored_file_uri,
            owningSourceID: source.id
        )

        return resolveClassification(
            classification,
            sourceID: sourceID
        )
    }

    private func resolveNonV1IdentitySource(
        _ source: TransactionSource
    ) -> EvidenceAvailabilityResolution {
        let classification = RetainedEvidenceLocator.classify(
            source.stored_file_uri,
            owningSourceID: source.id
        )

        switch classification {
        case .noRetainedLocator:
            return EvidenceAvailabilityResolution(
                state: .noRetainedLocator,
                physicalObservation: .notApplicable
            )

        case .legacyOpaque:
            return EvidenceAvailabilityResolution(
                state: .legacyOpaque,
                physicalObservation: .notApplicable
            )

        case .unsupportedVersion(let version):
            return EvidenceAvailabilityResolution(
                state: .unsupportedVersion(version),
                physicalObservation: .notApplicable
            )

        case .invalidLocator:
            return EvidenceAvailabilityResolution(
                state: .invalidLocator,
                physicalObservation: .notApplicable
            )

        case .invalidAssociation:
            return EvidenceAvailabilityResolution(
                state: .invalidAssociation,
                physicalObservation: .notApplicable
            )

        case .supported:
            return EvidenceAvailabilityResolution(
                state: .invalidAssociation,
                physicalObservation: .notApplicable
            )
        }
    }

    private func resolveClassification(
        _ classification: RetainedEvidenceLocatorClassification,
        sourceID: UUID
    ) -> EvidenceAvailabilityResolution {
        switch classification {
        case .noRetainedLocator:
            return EvidenceAvailabilityResolution(
                state: .noRetainedLocator,
                physicalObservation: .notApplicable
            )

        case .legacyOpaque:
            return EvidenceAvailabilityResolution(
                state: .legacyOpaque,
                physicalObservation: .notApplicable
            )

        case .unsupportedVersion(let version):
            return EvidenceAvailabilityResolution(
                state: .unsupportedVersion(version),
                physicalObservation: .notApplicable
            )

        case .invalidLocator:
            return EvidenceAvailabilityResolution(
                state: .invalidLocator,
                physicalObservation: .notApplicable
            )

        case .invalidAssociation:
            return EvidenceAvailabilityResolution(
                state: .invalidAssociation,
                physicalObservation: .notApplicable
            )

        case .supported(let locator):
            guard locator.sourceID == sourceID else {
                return EvidenceAvailabilityResolution(
                    state: .invalidAssociation,
                    physicalObservation: .notApplicable
                )
            }

            return observePayload(for: sourceID)
        }
    }

    private func observePayload(
        for sourceID: UUID
    ) -> EvidenceAvailabilityResolution {
        let roots: RetainedEvidenceStorageRoots
        let paths: RetainedEvidencePaths

        do {
            roots = try RetainedEvidenceStorageRoots.observational(
                fileSystem: fileSystem
            )
            paths = roots.paths(for: sourceID)
        } catch {
            return unavailable(.inspectionFailure)
        }

        let evidenceRoot = roots.durableV1Root
            .deletingLastPathComponent()
        let applicationSupportRoot = evidenceRoot
            .deletingLastPathComponent()

        for directory in [
            applicationSupportRoot,
            evidenceRoot,
            roots.durableV1Root,
            paths.durableDirectory
        ] {
            let directoryKind: EvidenceFileNodeKind

            do {
                directoryKind = try fileSystem.nodeKind(
                    at: directory
                )
            } catch {
                return unavailable(.inspectionFailure)
            }

            if directoryKind == .missing {
                return unavailable(.missing)
            }

            guard directoryKind == .directory else {
                return unavailable(
                    .unexpectedNodeKind(directoryKind)
                )
            }
        }

        let kind: EvidenceFileNodeKind

        do {
            kind = try fileSystem.nodeKind(
                at: paths.finalPayload
            )
        } catch {
            return unavailable(.inspectionFailure)
        }

        switch kind {
        case .missing:
            return unavailable(.missing)

        case .regularFile:
            do {
                _ = try fileSystem.read(paths.finalPayload)
                return EvidenceAvailabilityResolution(
                    state: .available,
                    physicalObservation: .regularPayloadReadable
                )
            } catch {
                return unavailable(.unreadable)
            }

        case .directory, .symbolicLink, .other:
            return unavailable(
                .unexpectedNodeKind(kind)
            )
        }
    }

    private func unavailable(
        _ observation: EvidencePhysicalObservation
    ) -> EvidenceAvailabilityResolution {
        EvidenceAvailabilityResolution(
            state: .expectedButUnavailable,
            physicalObservation: observation
        )
    }

    private func identityConflict() -> EvidenceAvailabilityResolution {
        EvidenceAvailabilityResolution(
            state: .identityConflict,
            physicalObservation: .notApplicable
        )
    }
}
