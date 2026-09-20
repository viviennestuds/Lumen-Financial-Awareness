import Foundation
import SwiftData

enum ReviewFlowOutcome {
    case saved
    case savedWithoutEvidence
    case savedWithEvidenceConflict
    case discarded
    case cancelled
}

enum ReviewRetryMode {
    case plain
    case retainedEvidence
    case saveWithoutEvidence
}

enum ReviewConfirmationState {
    case idle
    case saving
    case retentionFailedRetryable
    case ledgerFailedRetryable(ReviewRetryMode)
    case preCommitIdentityConflict
}

struct ReviewConfirmationFailure {
    let state: ReviewConfirmationState
    let message: String
}

enum EvidenceConfirmationResult {
    case terminal(ReviewFlowOutcome)
    case nonterminal(ReviewConfirmationFailure)
}

enum EvidenceConfirmationIntent {
    case plain
    case retainEvidence
    case saveWithoutRetainedEvidence
}

@MainActor
struct EvidenceConfirmationCoordinator {
    typealias LedgerCommit = (ModelContext) throws -> Void

    private let operationCoordinator: EvidenceOperationCoordinator
    private let store: RetainedEvidenceStore

    init(
        operationCoordinator: EvidenceOperationCoordinator = .shared,
        store: RetainedEvidenceStore
    ) {
        self.operationCoordinator = operationCoordinator
        self.store = store
    }

    static func live(
        operationCoordinator: EvidenceOperationCoordinator = .shared
    ) throws -> EvidenceConfirmationCoordinator {
        try EvidenceConfirmationCoordinator(
            operationCoordinator: operationCoordinator,
            store: .live()
        )
    }

    func confirm(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        intent: EvidenceConfirmationIntent,
        duplicateFingerprint: String? = nil,
        ledgerCommit: LedgerCommit? = nil
    ) async -> EvidenceConfirmationResult {
        switch intent {
        case .plain:
            return confirmPlain(
                draft: draft,
                allTags: allTags,
                in: context,
                duplicateFingerprint: duplicateFingerprint,
                ledgerCommit: ledgerCommit
            )

        case .retainEvidence:
            return await confirmRetained(
                draft: draft,
                allTags: allTags,
                in: context,
                duplicateFingerprint: duplicateFingerprint,
                ledgerCommit: ledgerCommit
            )

        case .saveWithoutRetainedEvidence:
            return await confirmWithoutEvidence(
                draft: draft,
                allTags: allTags,
                in: context,
                duplicateFingerprint: duplicateFingerprint,
                ledgerCommit: ledgerCommit
            )
        }
    }

    func abandonEvidence(
        for draft: TransactionDraft,
        in context: ModelContext
    ) async -> Bool {
        guard let sourceID = draft.evidenceRetentionState.sourceID else {
            return true
        }

        guard let source = draft.source,
              EvidenceIdentity.uuid(fromSourceID: source.id) == sourceID else {
            return false
        }

        let lease = await operationCoordinator.acquire(for: sourceID)

        do {
            let owners = try EvidenceIdentity.semanticOwners(
                of: sourceID,
                in: context
            )

            if case .none = owners {
                let durableOutcome = try store.cleanupPreparedDurableMaterial(
                    for: sourceID
                )
                guard cleanupCompleted(durableOutcome) else {
                    await operationCoordinator.release(lease)
                    return false
                }
            }

            if draft.evidenceRetentionState.canAttemptRetainedEvidence {
                let stagingOutcome = try store.cleanupStaging(for: sourceID)
                guard cleanupCompleted(stagingOutcome) else {
                    await operationCoordinator.release(lease)
                    return false
                }
            }

            draft.evidenceRetentionState = .none
            await operationCoordinator.release(lease)
            return true
        } catch {
            await operationCoordinator.release(lease)
            return false
        }
    }

    private func confirmPlain(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        duplicateFingerprint: String?,
        ledgerCommit: LedgerCommit?
    ) -> EvidenceConfirmationResult {
        do {
            _ = try performLedgerWrite(
                draft: draft,
                allTags: allTags,
                in: context,
                storedFileURI: nil,
                duplicateFingerprint: duplicateFingerprint,
                ledgerCommit: ledgerCommit
            )
            return .terminal(.saved)
        } catch {
            return .nonterminal(
                ReviewConfirmationFailure(
                    state: .ledgerFailedRetryable(.plain),
                    message: ledgerFailureMessage(error)
                )
            )
        }
    }

    private func confirmRetained(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        duplicateFingerprint: String?,
        ledgerCommit: LedgerCommit?
    ) async -> EvidenceConfirmationResult {
        guard case .staged(let staged) = draft.evidenceRetentionState,
              let source = draft.source,
              EvidenceIdentity.uuid(fromSourceID: source.id) == staged.sourceID else {
            return retentionFailure(
                "The retained photo session is no longer valid. Keep this draft open and try again or save without retained evidence."
            )
        }

        let sourceID = staged.sourceID
        let lease = await operationCoordinator.acquire(for: sourceID)

        let result: EvidenceConfirmationResult

        do {
            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                result = identityConflict()
                await operationCoordinator.release(lease)
                return result
            }

            _ = try store.prepareDurablePayload(for: sourceID)
            _ = try store.finalizeDurablePayload(for: sourceID)

            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                result = identityConflict()
                await operationCoordinator.release(lease)
                return result
            }

            let locator = RetainedEvidenceLocator(
                sourceID: sourceID
            ).serialized

            do {
                _ = try performLedgerWrite(
                    draft: draft,
                    allTags: allTags,
                    in: context,
                    storedFileURI: locator,
                    duplicateFingerprint: duplicateFingerprint,
                    ledgerCommit: ledgerCommit
                )
            } catch {
                try? cleanupPreparedDurableMaterialForRetry(
                    sourceID: sourceID
                )
                result = .nonterminal(
                    ReviewConfirmationFailure(
                        state: .ledgerFailedRetryable(.retainedEvidence),
                        message: ledgerFailureMessage(error)
                    )
                )
                await operationCoordinator.release(lease)
                return result
            }

            guard try postSaveRetainedAssociationIsValid(
                sourceID,
                in: context
            ) else {
                result = .terminal(.savedWithEvidenceConflict)
                await operationCoordinator.release(lease)
                return result
            }

            _ = try? store.cleanupStaging(for: sourceID)
            draft.evidenceRetentionState = .none
            result = .terminal(.saved)
        } catch {
            result = retentionFailure(
                "The photo could not be retained safely. Your draft and staged photo are still available. Retry, or explicitly save without retained evidence."
            )
        }

        await operationCoordinator.release(lease)
        return result
    }

    private func confirmWithoutEvidence(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        duplicateFingerprint: String?,
        ledgerCommit: LedgerCommit?
    ) async -> EvidenceConfirmationResult {
        guard let sourceID = draft.evidenceRetentionState.sourceID,
              let source = draft.source,
              EvidenceIdentity.uuid(fromSourceID: source.id) == sourceID else {
            return retentionFailure(
                "The photo session identity is no longer valid. No evidence was deleted."
            )
        }

        let lease = await operationCoordinator.acquire(for: sourceID)
        let result: EvidenceConfirmationResult

        do {
            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                result = identityConflict()
                await operationCoordinator.release(lease)
                return result
            }

            if draft.evidenceRetentionState.canAttemptRetainedEvidence {
                let durableOutcome = try store.cleanupPreparedDurableMaterial(
                    for: sourceID
                )
                guard cleanupCompleted(durableOutcome) else {
                    result = retentionFailure(
                        "Lumen could not verify removal of prepared evidence. Nothing was saved."
                    )
                    await operationCoordinator.release(lease)
                    return result
                }

                let stagingOutcome = try store.cleanupStaging(for: sourceID)
                guard cleanupCompleted(stagingOutcome) else {
                    result = retentionFailure(
                        "Lumen could not verify removal of the staged photo. Nothing was saved."
                    )
                    await operationCoordinator.release(lease)
                    return result
                }

                draft.evidenceRetentionState = .saveWithoutEvidenceOnly(
                    sourceID
                )
            }

            do {
                _ = try performLedgerWrite(
                    draft: draft,
                    allTags: allTags,
                    in: context,
                    storedFileURI: nil,
                    duplicateFingerprint: duplicateFingerprint,
                    ledgerCommit: ledgerCommit
                )
            } catch {
                result = .nonterminal(
                    ReviewConfirmationFailure(
                        state: .ledgerFailedRetryable(.saveWithoutEvidence),
                        message: ledgerFailureMessage(error)
                    )
                )
                await operationCoordinator.release(lease)
                return result
            }

            guard try postSaveNilLocatorAssociationIsValid(
                sourceID,
                in: context
            ) else {
                result = .terminal(.savedWithEvidenceConflict)
                await operationCoordinator.release(lease)
                return result
            }

            draft.evidenceRetentionState = .none
            result = .terminal(.savedWithoutEvidence)
        } catch {
            result = retentionFailure(
                "Lumen could not safely complete the save-without-evidence cleanup. Nothing was saved."
            )
        }

        await operationCoordinator.release(lease)
        return result
    }

    private func performLedgerWrite(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        storedFileURI: String?,
        duplicateFingerprint: String?,
        ledgerCommit: LedgerCommit?
    ) throws -> Transaction {
        try LedgerWrite.perform(
            in: context,
            commit: ledgerCommit
        ) {
            let transaction = try draft.makeTransaction(
                allTags: allTags,
                storedFileURI: storedFileURI
            )
            transaction.duplicate_fingerprint = duplicateFingerprint
            context.insert(transaction)
            return transaction
        }
    }

    private func hasZeroPersistedOwners(
        _ sourceID: UUID,
        in context: ModelContext
    ) throws -> Bool {
        guard case .none = try EvidenceIdentity.semanticOwners(
            of: sourceID,
            in: context
        ) else {
            return false
        }
        return true
    }

    private func postSaveRetainedAssociationIsValid(
        _ sourceID: UUID,
        in context: ModelContext
    ) throws -> Bool {
        guard case .one(let source) = try EvidenceIdentity.semanticOwners(
            of: sourceID,
            in: context
        ) else {
            return false
        }

        guard case .supported(let locator) = RetainedEvidenceLocator.classify(
            source.stored_file_uri,
            owningSourceID: source.id
        ) else {
            return false
        }

        return locator.sourceID == sourceID
    }

    private func postSaveNilLocatorAssociationIsValid(
        _ sourceID: UUID,
        in context: ModelContext
    ) throws -> Bool {
        guard case .one(let source) = try EvidenceIdentity.semanticOwners(
            of: sourceID,
            in: context
        ) else {
            return false
        }

        return source.stored_file_uri == nil
    }

    private func cleanupPreparedDurableMaterialForRetry(
        sourceID: UUID
    ) throws {
        let outcome = try store.cleanupPreparedDurableMaterial(
            for: sourceID
        )

        guard cleanupCompleted(outcome) else {
            return
        }
    }

    private func cleanupCompleted(
        _ outcome: EvidenceCleanupOutcome
    ) -> Bool {
        switch outcome {
        case .nothingToRemove, .removedKnownMaterial:
            return true
        case .retainedUnexpectedContents,
             .retainedUnexpectedNodeKinds:
            return false
        }
    }

    private func identityConflict() -> EvidenceConfirmationResult {
        .nonterminal(
            ReviewConfirmationFailure(
                state: .preCommitIdentityConflict,
                message: "Lumen found an ambiguous evidence identity. Nothing was saved or deleted."
            )
        )
    }

    private func retentionFailure(
        _ message: String
    ) -> EvidenceConfirmationResult {
        .nonterminal(
            ReviewConfirmationFailure(
                state: .retentionFailedRetryable,
                message: message
            )
        )
    }

    private func ledgerFailureMessage(
        _ error: Error
    ) -> String {
        (error as? LedgerWriteError)?.errorDescription
            ?? "The transaction could not be saved to this device. Your draft is still here."
    }
}
