import Foundation
import SwiftData

enum EvidenceReconciliationMaterialKind: Hashable {
    case staging
    case incomingPayload
    case finalPayload
}

struct EvidenceReconciliationCandidate: Equatable {
    let sourceID: UUID
    let materials: Set<EvidenceReconciliationMaterialKind>
}

enum EvidenceReconciliationDisposition: Equatable {
    case cleaned
    case nothingToRemove
    case retainedPersistedOwner
    case retainedIdentityConflict
    case retainedIdentityReadFailure
    case retainedUnsafeFilesystem
    case retainedInspectionFailure
    case retainedCleanupFailure
}

struct EvidenceReconciliationResult: Equatable {
    let candidate: EvidenceReconciliationCandidate
    let disposition: EvidenceReconciliationDisposition
}

@MainActor
struct EvidenceReconciler {
    private enum Scope {
        case durable
        case staging
    }

    private enum ControlledPathValidation {
        case present
        case missing
        case unsafe
        case inspectionFailure
    }

    private let operationCoordinator: EvidenceOperationCoordinator
    private let fileSystem: any EvidenceFileSystem
    private let roots: RetainedEvidenceStorageRoots
    private let store: RetainedEvidenceStore

    init(
        operationCoordinator: EvidenceOperationCoordinator = .shared,
        fileSystem: any EvidenceFileSystem,
        roots: RetainedEvidenceStorageRoots
    ) {
        self.operationCoordinator = operationCoordinator
        self.fileSystem = fileSystem
        self.roots = roots
        self.store = RetainedEvidenceStore(
            fileSystem: fileSystem,
            roots: roots
        )
    }

    static func live(
        operationCoordinator: EvidenceOperationCoordinator = .shared
    ) throws -> EvidenceReconciler {
        let fileSystem = LocalEvidenceFileSystem()
        let roots = try RetainedEvidenceStorageRoots.observational(
            fileSystem: fileSystem
        )

        return EvidenceReconciler(
            operationCoordinator: operationCoordinator,
            fileSystem: fileSystem,
            roots: roots
        )
    }

    func discoverCandidates() -> [EvidenceReconciliationCandidate] {
        var materialsBySourceID: [
            UUID: Set<EvidenceReconciliationMaterialKind>
        ] = [:]

        discoverStagingMaterials(into: &materialsBySourceID)
        discoverDurableMaterials(into: &materialsBySourceID)

        return materialsBySourceID
            .map { sourceID, materials in
                EvidenceReconciliationCandidate(
                    sourceID: sourceID,
                    materials: materials
                )
            }
            .sorted {
                EvidenceIdentity.canonicalString(for: $0.sourceID)
                    < EvidenceIdentity.canonicalString(for: $1.sourceID)
            }
    }

    func reconcile(
        in context: ModelContext?
    ) async -> [EvidenceReconciliationResult] {
        guard let context else {
            return []
        }

        let candidates = discoverCandidates()
        var results: [EvidenceReconciliationResult] = []
        results.reserveCapacity(candidates.count)

        for candidate in candidates {
            results.append(
                await reconcile(
                    candidate,
                    in: context
                )
            )
        }

        return results
    }

    func reconcile(
        _ candidate: EvidenceReconciliationCandidate,
        in context: ModelContext
    ) async -> EvidenceReconciliationResult {
        let lease = await operationCoordinator.acquire(
            for: candidate.sourceID
        )

        let result = reconcileWhileHoldingLease(
            candidate,
            in: context
        )

        await operationCoordinator.release(lease)
        return result
    }

    private func reconcileWhileHoldingLease(
        _ candidate: EvidenceReconciliationCandidate,
        in context: ModelContext
    ) -> EvidenceReconciliationResult {
        var removedKnownMaterial = false

        for scope in scopes(for: candidate) {
            let ownership: EvidenceIdentityOwnership

            do {
                ownership = try EvidenceIdentity.semanticOwners(
                    of: candidate.sourceID,
                    in: context
                )
            } catch {
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedIdentityReadFailure
                )
            }

            switch ownership {
            case .none:
                break

            case .one:
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedPersistedOwner
                )

            case .conflict:
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedIdentityConflict
                )
            }

            switch validateControlledPath(
                for: scope,
                sourceID: candidate.sourceID
            ) {
            case .missing:
                continue

            case .unsafe:
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedUnsafeFilesystem
                )

            case .inspectionFailure:
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedInspectionFailure
                )

            case .present:
                break
            }

            let cleanupOutcome: EvidenceCleanupOutcome

            do {
                switch scope {
                case .durable:
                    cleanupOutcome = try store.cleanupPreparedDurableMaterial(
                        for: candidate.sourceID
                    )

                case .staging:
                    cleanupOutcome = try store.cleanupStaging(
                        for: candidate.sourceID
                    )
                }
            } catch {
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedCleanupFailure
                )
            }

            switch cleanupOutcome {
            case .nothingToRemove:
                continue

            case .removedKnownMaterial:
                removedKnownMaterial = true

            case .retainedUnexpectedContents,
                 .retainedUnexpectedNodeKinds:
                return EvidenceReconciliationResult(
                    candidate: candidate,
                    disposition: .retainedUnsafeFilesystem
                )
            }
        }

        return EvidenceReconciliationResult(
            candidate: candidate,
            disposition: removedKnownMaterial
                ? .cleaned
                : .nothingToRemove
        )
    }

    private func scopes(
        for candidate: EvidenceReconciliationCandidate
    ) -> [Scope] {
        var scopes: [Scope] = []

        if candidate.materials.contains(.finalPayload)
            || candidate.materials.contains(.incomingPayload) {
            scopes.append(.durable)
        }

        if candidate.materials.contains(.staging) {
            scopes.append(.staging)
        }

        return scopes
    }

    private func validateControlledPath(
        for scope: Scope,
        sourceID: UUID
    ) -> ControlledPathValidation {
        let paths = roots.paths(for: sourceID)

        switch scope {
        case .durable:
            let evidenceRoot = roots.durableV1Root
                .deletingLastPathComponent()
            let applicationSupportDirectory = evidenceRoot
                .deletingLastPathComponent()

            return validateDirectoryChain([
                applicationSupportDirectory,
                evidenceRoot,
                roots.durableV1Root,
                paths.durableDirectory
            ])

        case .staging:
            return validateDirectoryChain([
                roots.stagingRoot.deletingLastPathComponent(),
                roots.stagingRoot,
                paths.stagingDirectory
            ])
        }
    }

    private func validateDirectoryChain(
        _ directories: [URL]
    ) -> ControlledPathValidation {
        for directory in directories {
            let kind: EvidenceFileNodeKind

            do {
                kind = try fileSystem.nodeKind(at: directory)
            } catch {
                return .inspectionFailure
            }

            if kind == .missing {
                return .missing
            }

            guard kind == .directory else {
                return .unsafe
            }
        }

        return .present
    }

    private func discoverStagingMaterials(
        into materialsBySourceID: inout [
            UUID: Set<EvidenceReconciliationMaterialKind>
        ]
    ) {
        guard directoryChainIsPresentAndControlled([
            roots.stagingRoot.deletingLastPathComponent(),
            roots.stagingRoot
        ]) else {
            return
        }

        guard let identityDirectories = try? fileSystem
            .contentsOfDirectory(at: roots.stagingRoot) else {
            return
        }

        for directory in identityDirectories {
            guard let sourceID = canonicalSourceID(for: directory),
                  (try? fileSystem.nodeKind(at: directory)) == .directory,
                  let items = try? fileSystem.contentsOfDirectory(
                    at: directory
                  ) else {
                continue
            }

            for item in items where item.lastPathComponent == "payload" {
                guard (try? fileSystem.nodeKind(at: item)) == .regularFile else {
                    continue
                }

                materialsBySourceID[
                    sourceID,
                    default: []
                ].insert(.staging)
            }
        }
    }

    private func discoverDurableMaterials(
        into materialsBySourceID: inout [
            UUID: Set<EvidenceReconciliationMaterialKind>
        ]
    ) {
        let evidenceRoot = roots.durableV1Root
            .deletingLastPathComponent()
        let applicationSupportDirectory = evidenceRoot
            .deletingLastPathComponent()

        guard directoryChainIsPresentAndControlled([
            applicationSupportDirectory,
            evidenceRoot,
            roots.durableV1Root
        ]) else {
            return
        }

        guard let identityDirectories = try? fileSystem
            .contentsOfDirectory(at: roots.durableV1Root) else {
            return
        }

        for directory in identityDirectories {
            guard let sourceID = canonicalSourceID(for: directory),
                  (try? fileSystem.nodeKind(at: directory)) == .directory,
                  let items = try? fileSystem.contentsOfDirectory(
                    at: directory
                  ) else {
                continue
            }

            for item in items {
                let materialKind: EvidenceReconciliationMaterialKind

                switch item.lastPathComponent {
                case "payload":
                    materialKind = .finalPayload

                case "payload.incoming":
                    materialKind = .incomingPayload

                default:
                    continue
                }

                guard (try? fileSystem.nodeKind(at: item)) == .regularFile else {
                    continue
                }

                materialsBySourceID[
                    sourceID,
                    default: []
                ].insert(materialKind)
            }
        }
    }

    private func directoryChainIsPresentAndControlled(
        _ directories: [URL]
    ) -> Bool {
        for directory in directories {
            guard let kind = try? fileSystem.nodeKind(at: directory),
                  kind == .directory else {
                return false
            }
        }

        return true
    }

    private func canonicalSourceID(
        for directory: URL
    ) -> UUID? {
        let name = directory.lastPathComponent

        guard let sourceID = UUID(uuidString: name),
              EvidenceIdentity.canonicalString(for: sourceID) == name else {
            return nil
        }

        return sourceID
    }
}
