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

enum EvidenceAbandonmentResult {
    case completed
    case completedWithDurableMaterialRetained
    case stagingCleanupFailed
}

@MainActor
struct EvidenceConfirmationCoordinator {
    typealias LedgerCommit = (ModelContext) throws -> Void

    private let operationCoordinator: EvidenceOperationCoordinator
    private let storeProvider: () throws -> RetainedEvidenceStore

    init(
        operationCoordinator: EvidenceOperationCoordinator = .shared,
        store: RetainedEvidenceStore
    ) {
        self.operationCoordinator = operationCoordinator
        self.storeProvider = { store }
    }

    init(
        operationCoordinator: EvidenceOperationCoordinator = .shared,
        storeProvider: @escaping () throws -> RetainedEvidenceStore
    ) {
        self.operationCoordinator = operationCoordinator
        self.storeProvider = storeProvider
    }

    static func live(
        operationCoordinator: EvidenceOperationCoordinator = .shared
    ) -> EvidenceConfirmationCoordinator {
        EvidenceConfirmationCoordinator(
            operationCoordinator: operationCoordinator,
            storeProvider: { try RetainedEvidenceStore.live() }
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
        in context: ModelContext,
        intent: EvidenceAbandonmentIntent
    ) async -> EvidenceAbandonmentResult {
        guard let sourceID = draft.evidenceRetentionState.sourceID else {
            return .completed
        }

        if case .saveWithoutEvidenceOnly = draft.evidenceRetentionState {
            draft.evidenceRetentionState = .none
            return .completed
        }

        if case .cleanupPending(
            let pendingSourceID,
            let pendingIntent
        ) = draft.evidenceRetentionState {
            guard pendingSourceID == sourceID,
                  case .abandon(let pendingAbandonment) = pendingIntent,
                  abandonmentIntent(
                    pendingAbandonment,
                    matches: intent
                  ) else {
                return .stagingCleanupFailed
            }
        }

        guard let source = draft.source,
              EvidenceIdentity.uuid(fromSourceID: source.id) == sourceID else {
            return .stagingCleanupFailed
        }

        let store: RetainedEvidenceStore
        do {
            store = try storeProvider()
        } catch {
            return .stagingCleanupFailed
        }

        let lease = await operationCoordinator.acquire(for: sourceID)

        if case .staged = draft.evidenceRetentionState {
            draft.evidenceRetentionState = .cleanupPending(
                sourceID,
                .abandon(intent)
            )
        }

        var durableMaterialRetained = false

        do {
            let owners = try EvidenceIdentity.semanticOwners(
                of: sourceID,
                in: context
            )

            if case .none = owners {
                do {
                    let durableOutcome = try store.cleanupPreparedDurableMaterial(
                        for: sourceID
                    )
                    if !cleanupCompleted(durableOutcome) {
                        durableMaterialRetained = true
                    }
                } catch {
                    durableMaterialRetained = true
                }
            } else {
                durableMaterialRetained = true
            }
        } catch {
            durableMaterialRetained = true
        }

        do {
            let stagingOutcome = try store.cleanupStaging(
                for: sourceID
            )

            guard cleanupCompleted(stagingOutcome) else {
                await operationCoordinator.release(lease)
                return .stagingCleanupFailed
            }
        } catch {
            await operationCoordinator.release(lease)
            return .stagingCleanupFailed
        }

        draft.evidenceRetentionState = .none
        await operationCoordinator.release(lease)

        return durableMaterialRetained
            ? .completedWithDurableMaterialRetained
            : .completed
    }

    private func confirmPlain(
        draft: TransactionDraft,
        allTags: [Tag],
        in context: ModelContext,
        duplicateFingerprint: String?,
        ledgerCommit: LedgerCommit?
    ) -> EvidenceConfirmationResult {
        guard case .none = draft.evidenceRetentionState else {
            return retentionFailure(
                "This draft has an active evidence session. Choose the retained-evidence or explicit save-without-evidence path."
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
              EvidenceIdentity.uuid(fromSourceID: source.id) == staged.sourceID,
              source.stored_file_uri == nil,
              source.file_size_bytes == staged.byteCount else {
            return retentionFailure(
                "The retained photo session is no longer valid. Keep this draft open and try again or save without retained evidence."
            )
        }

        let store: RetainedEvidenceStore
        do {
            store = try storeProvider()
        } catch {
            return retentionFailure(
                "Lumen could not initialize retained-evidence storage. Your draft is still here."
            )
        }

        guard staged.stagedURL == store.paths(for: staged.sourceID).stagedPayload else {
            return retentionFailure(
                "The retained photo session no longer points to Lumen's controlled staging location."
            )
        }

        let sourceID = staged.sourceID
        let lease = await operationCoordinator.acquire(for: sourceID)

        do {
            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                await operationCoordinator.release(lease)
                return identityConflict()
            }

            _ = try store.prepareDurablePayload(for: sourceID)
            _ = try store.finalizeDurablePayload(for: sourceID)

            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                await operationCoordinator.release(lease)
                return identityConflict()
            }
        } catch {
            await operationCoordinator.release(lease)
            return retentionFailure(
                "The photo could not be retained safely. Your draft and staged photo are still available. Retry, or explicitly save without retained evidence."
            )
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
                sourceID: sourceID,
                store: store
            )
            await operationCoordinator.release(lease)
            return .nonterminal(
                ReviewConfirmationFailure(
                    state: .ledgerFailedRetryable(.retainedEvidence),
                    message: ledgerFailureMessage(error)
                )
            )
        }

        let postSaveValid: Bool
        do {
            postSaveValid = try postSaveRetainedAssociationIsValid(
                sourceID,
                in: context
            )
        } catch {
            postSaveValid = false
        }

        guard postSaveValid else {
            await operationCoordinator.release(lease)
            return .terminal(.savedWithEvidenceConflict)
        }

        _ = try? store.cleanupStaging(for: sourceID)
        draft.evidenceRetentionState = .none

        await operationCoordinator.release(lease)
        return .terminal(.saved)
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
              EvidenceIdentity.uuid(fromSourceID: source.id) == sourceID,
              source.stored_file_uri == nil else {
            return retentionFailure(
                "The photo session identity is no longer valid. No evidence was deleted."
            )
        }

        let needsCleanup: Bool

        switch draft.evidenceRetentionState {
        case .staged:
            needsCleanup = true

        case .cleanupPending(
            let pendingSourceID,
            let destructiveIntent
        ):
            guard pendingSourceID == sourceID,
                  case .saveWithoutEvidence = destructiveIntent else {
                return retentionFailure(
                    "This evidence session is already completing a different destructive action."
                )
            }
            needsCleanup = true

        case .saveWithoutEvidenceOnly:
            needsCleanup = false

        case .none:
            return retentionFailure(
                "This draft has no active retained-evidence session."
            )
        }

        let store: RetainedEvidenceStore?
        if needsCleanup {
            do {
                store = try storeProvider()
            } catch {
                return retentionFailure(
                    "Lumen could not initialize retained-evidence storage. Nothing was saved."
                )
            }
        } else {
            store = nil
        }

        let lease = await operationCoordinator.acquire(for: sourceID)

        do {
            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                let conflict = draft.evidenceRetentionState.canAttemptRetainedEvidence
                    ? identityConflict()
                    : identityConflictAfterDestructiveCleanup()
                await operationCoordinator.release(lease)
                return conflict
            }

            if needsCleanup {
                guard let store else {
                    await operationCoordinator.release(lease)
                    return retentionFailure(
                        "Lumen could not access retained-evidence storage. Nothing was saved."
                    )
                }

                if case .staged = draft.evidenceRetentionState {
                    draft.evidenceRetentionState = .cleanupPending(
                        sourceID,
                        .saveWithoutEvidence
                    )
                }

                let durableOutcome = try store.cleanupPreparedDurableMaterial(
                    for: sourceID
                )
                guard cleanupCompleted(durableOutcome) else {
                    await operationCoordinator.release(lease)
                    return retentionFailure(
                        "Lumen could not verify removal of prepared evidence. Nothing was saved."
                    )
                }

                let stagingOutcome = try store.cleanupStaging(
                    for: sourceID
                )
                guard cleanupCompleted(stagingOutcome) else {
                    await operationCoordinator.release(lease)
                    return retentionFailure(
                        "Lumen could not verify removal of the staged photo. Nothing was saved."
                    )
                }

                draft.evidenceRetentionState = .saveWithoutEvidenceOnly(
                    sourceID
                )
            }

            guard try hasZeroPersistedOwners(
                sourceID,
                in: context
            ) else {
                await operationCoordinator.release(lease)
                return identityConflictAfterDestructiveCleanup()
            }
        } catch {
            await operationCoordinator.release(lease)
            return retentionFailure(
                "Lumen could not safely complete the save-without-evidence cleanup. Nothing was saved."
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
            await operationCoordinator.release(lease)
            return .nonterminal(
                ReviewConfirmationFailure(
                    state: .ledgerFailedRetryable(.saveWithoutEvidence),
                    message: ledgerFailureMessage(error)
                )
            )
        }

        let postSaveValid: Bool
        do {
            postSaveValid = try postSaveNilLocatorAssociationIsValid(
                sourceID,
                in: context
            )
        } catch {
            postSaveValid = false
        }

        guard postSaveValid else {
            await operationCoordinator.release(lease)
            return .terminal(.savedWithEvidenceConflict)
        }

        draft.evidenceRetentionState = .none
        await operationCoordinator.release(lease)
        return .terminal(.savedWithoutEvidence)
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
        sourceID: UUID,
        store: RetainedEvidenceStore
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

    private func abandonmentIntent(
        _ lhs: EvidenceAbandonmentIntent,
        matches rhs: EvidenceAbandonmentIntent
    ) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled),
             (.discarded, .discarded):
            return true
        default:
            return false
        }
    }

    private func identityConflictAfterDestructiveCleanup() -> EvidenceConfirmationResult {
        .nonterminal(
            ReviewConfirmationFailure(
                state: .preCommitIdentityConflict,
                message: "Lumen found an ambiguous evidence identity after evidence cleanup. No transaction was saved, and retained-photo confirmation remains unavailable for this session."
            )
        )
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
