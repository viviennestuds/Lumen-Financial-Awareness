# Lumen Portable JSON v1 Persisted Transaction Status Compatibility Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C Transaction-status compatibility gate.**

Starts exactly from accepted checkpoint `7231cf364a7c95f7b9ce077cf7ea6437c22fded6`.

This proposal does not change production code, tests, persistence/schema, migrations, importer/exporter implementation, workspace/promotion machinery, or accepted monetary/currency contracts. It does not redesign `TransactionStatus`.

# 1. Decision Question

For every `TransactionStatus` value that can exist on current canonical Transactions, what does Portable JSON v1 promise at three separate layers?

```text
1. REPRESENTABILITY
Can Portable JSON v1 truthfully encode the canonical status?
            ↓
2. EXPORT COMPLETENESS
Can a complete ownership export containing that status
truthfully claim to represent the canonical Transaction?
            ↓
3. RESTORATION READINESS
Can fresh-store import → Draft → Review → Confirm
recreate equivalent supported canonical status semantics?
```

Required invariants:

```text
current canonical state != currently creatable state

easy to serialize
!= semantically admitted to Portable v1
!= currently restorable
```

# 2. Repository Trace

## 2.1 Persisted vocabulary

`TransactionStatus` is a raw-string, Codable, CaseIterable enum with five values:

```text
pending
posted
ignored
duplicate
review_needed
```

`Transaction.status` is persisted and defaults to `.pending`.

A same-schema URL-backed SwiftData test inserts one Transaction for every enum case, closes/reopens the store, and verifies the full raw-value set survives unchanged. This is candidate-generated same-schema evidence, not an authentic historical-store fixture.

## 2.2 New confirmation boundary

`TransactionDraft.status` defaults to `.pending`.

`TransactionDraft.canConfirm` requires both a valid draft and status in:

```text
pending
posted
```

`makeTransaction` guards `canConfirm`.

`ReviewTransactionView.save` also guards `draft.canConfirm` before invoking the confirmation coordinator.

The domain test `testNewInputOnlyConfirmsFinancialLifecycle` iterates every status and verifies only `pending` and `posted` can create a new Transaction through `makeTransaction`.

Therefore the ordinary new-input confirmation vocabulary is demonstrably narrower than the persisted vocabulary.

## 2.3 Existing-record editing and direct status mutation

`TransactionDraft(from:)` copies the existing canonical status.

For an existing record, `availableStatuses` exposes all `TransactionStatus.allCases`.

`apply(to:)` guards `isValid`, not `canConfirm`, and writes `txn.status = status`. Therefore existing records can preserve or edit to legacy status values through the edit path when the rest of the draft is valid.

`TransactionDetailView.statusControls` also displays every enum case and `setStatus` directly persists any selected status through `LedgerWrite`.

For pending records, Detail exposes explicit actions:

```text
Confirm posted → posted
Deny / ignore  → ignored
```

Thus `ignored` is not merely technically persistable: current product UI can create it from an existing pending canonical Transaction. The generic status control can persist all five values on an existing canonical Transaction.

This is materially different from ordinary new-input confirmation.

## 2.4 Seed/demo evidence

Current seed data creates only `pending` and `posted`.

No seed evidence establishes ordinary creation semantics for the three compatibility-bearing statuses.

## 2.5 Analytics and ledger consequences

`Analytics.active` excludes:

```text
ignored
duplicate
```

and includes:

```text
pending
posted
review_needed
```

The code comment explicitly says legacy `review_needed` records may already have been user-confirmed and should remain included until an authentic-store-tested status migration exists.

`testAnalyticsTypesStatusesAndCurrencyPolicy` verifies this behavior: ignored/duplicate values do not contribute to active totals, while a `review_needed` expense does.

Therefore exact status is not decorative metadata. It changes current financial reporting inclusion.

## 2.6 Search/list/detail behavior

Activity's `all` view can surface all Transactions. Dedicated status filters exist for pending, posted, and ignored; duplicate/review_needed do not have dedicated filter cases, but they are not removed from `all`.

`TransactionRow` displays each record's status label/tint.

`TransactionDetailView` displays a status badge and all-case status controls.

Phase 1A explicitly records that all statuses should remain displayed and existing records remain inspectable/editable.

## 2.7 Architecture evidence

The Architecture Contract distinguishes:

**Financial state**
- includes financial status.

**Ingestion state**
- includes needs review, ignored, rejected, suspected duplicate.

It states that machine uncertainty, ingestion decisions, and confirmed financial state should remain distinct.

The Roadmap likewise identifies:

```text
financial lifecycle:
pending / posted / ...

ingestion-review disposition:
needs review / ignored / rejected / suspected duplicate
```

and explicitly warns not to perform a blind enum replacement before inspecting persisted values and behavior.

Phase 1A then adopted an explicit migration-safe intermediate state:

- existing status raw values and historical inclusion remain unchanged;
- ignored/duplicate are excluded from analytics;
- pending/posted/review_needed are included;
- legacy `review_needed` may already have been explicitly confirmed;
- new confirmed input is restricted to pending/posted;
- ignoring a new draft discards it rather than creating a canonical ignored Transaction;
- existing records remain inspectable/editable with all legacy statuses;
- no status split/remap/migration is authorized without authentic-store evidence.

This is strong evidence that `ignored`, `duplicate`, and `review_needed` are compatibility-bearing canonical state even though their conceptual responsibility is not considered clean long-term financial lifecycle modeling.

# 3. Five-Status Semantic Matrix

| Status | Demonstrated durable/canonical use | Ordinary new confirmation | Existing edit/preserve | Current semantic evidence | Analytics consequence | JSON representation | Current fresh-store ordinary restoration |
|---|---|---|---|---|---|---|---|
| `pending` | yes: seed/tests/persistence | yes | yes | financial lifecycle | included | exact token feasible | READY |
| `posted` | yes: seed/tests/persistence | yes | yes | financial lifecycle | included | exact token feasible | READY |
| `ignored` | yes: persistence/tests; current Detail can set it | no | yes | ingestion/review disposition carried on canonical Transaction | excluded | exact token feasible | NOT READY through ordinary new confirmation |
| `duplicate` | yes: persistence/tests; existing Detail all-case control can set it | no | yes | duplicate/review disposition carried on canonical Transaction | excluded | exact token feasible | NOT READY through ordinary new confirmation |
| `review_needed` | yes: persistence/tests; Phase 1A records legacy confirmed possibility | no | yes | review disposition / legacy compatibility state carried on canonical Transaction | included | exact token feasible | NOT READY through ordinary new confirmation |

"Demonstrated" here means repository behavior/tests/current UI capability. It does not claim an authentic historical user store contains every value.

# 4. Conflict / Tension With the Architecture Contract

There is a real but already-documented architectural tension:

```text
Architecture responsibility model:
financial lifecycle != ingestion/review disposition

Current persisted model:
one Transaction.status enum carries both
```

Portable v1 must not resolve this tension by rewriting history.

Specifically, the portable contract must not infer that an existing canonical:

```text
ignored      → pending or posted
duplicate    → pending or posted
review_needed → pending or posted
```

Nor may it omit those Transactions merely because the current ordinary creation path is narrower.

At the same time, admitting the exact raw token for compatibility does not declare the mixed status model ideal or permanent.

# 5. Representability Analysis

All five current persisted raw values are unambiguous, stable strings in the current model.

There is no lexical/structural obstacle to Portable JSON v1 encoding the exact canonical token.

Unlike out-of-domain money:

```text
status compatibility problem
!= inability to spell the canonical value
```

The substantive question is semantic admission and restoration.

# 6. Export-Completeness Analysis

The repository establishes observable current consequences for the exact tokens, especially analytics inclusion/exclusion and existing-record inspection/editability.

Therefore a complete ownership export can truthfully represent the current canonical status only by preserving the exact admitted compatibility-bearing status semantics.

Silently omitting a Transaction, dropping its status, or normalizing the token to `pending`/`posted` would make the export less truthful than canonical state.

Recommended export classification:

```text
pending        → admitted current financial-lifecycle status
posted         → admitted current financial-lifecycle status
ignored        → admitted legacy/current canonical compatibility status
duplicate      → admitted legacy/current canonical compatibility status
review_needed  → admitted legacy/current canonical compatibility status
```

"Compatibility status" means Portable JSON preserves existing canonical truth. It does not authorize these values for ordinary new-input confirmation.

Under this proposal, the presence of any of the five exact admitted tokens does **not by itself** make an otherwise complete Portable JSON v1 ownership export incomplete.

# 7. Restoration-Readiness Analysis

## 7.1 pending / posted

These are currently reproducible through the ordinary:

```text
import proposal
→ Draft
→ Review
→ explicit Confirm
→ canonical Transaction
```

subject to the other unresolved field/entity gates.

They are READY on the status-restoration axis.

## 7.2 ignored / duplicate / review_needed

The ordinary new-input `TransactionDraft.canConfirm` path rejects these values.

Changing them to `pending` or `posted` would not be equivalent:

- `ignored` and `duplicate` currently alter analytics inclusion;
- `review_needed` is intentionally included under the Phase 1A compatibility policy;
- all three have distinct visible labels and existing-record behavior.

Therefore current ordinary confirmation is **not** an equivalent restoration path.

However, the repository also demonstrates that canonical Transactions can persist these exact statuses and that existing canonical records can preserve/change them after creation. The storage model itself does not make exact restoration impossible.

The proposed contract consequence is:

> **Portable JSON v1 admits all five exact current canonical status tokens. For `ignored`, `duplicate`, and `review_needed`, fresh-store round-trip requires a specifically admitted compatibility-restoration path inside the explicit import Review/Confirm authority boundary that restores the exact status token and its admitted semantics. Until that capability is implemented and validated, such imported records are recognized and truthfully representable but are NOT READY for canonical promotion.**

This is a contract requirement, not authorization to bypass Review/Confirm.

The compatibility-restoration context must itself carry distinct semantic authority: it is restoration of previously canonical state from a supported Lumen round-trip representation, not ordinary creation with a hidden exception to `TransactionDraft.canConfirm`.

The governing invariant is:

```text
restoration authority != creation authority

ordinary creation semantics
!=
supported Lumen round-trip restoration semantics
```

Conceptually:

```text
ordinary creation
pending / posted
        ↓
Review / explicit confirmation
        ↓
canonical Transaction

supported Lumen compatibility restoration
ignored / duplicate / review_needed
        ↓
recognized as restoration of previously canonical Lumen state
        ↓
Review / explicit confirmation
        ↓
exact canonical compatibility status
```

Admission of that restoration authority must not make `ignored`, `duplicate`, or `review_needed` valid choices for ordinary new/manual creation, foreign-source mapping, generic structured import, OCR/extraction proposals, or any other non-restoration ingestion path.

Review/Confirm must remain meaningful user authority. A restoration context may authorize preservation of an otherwise non-creatable canonical status, but it must not become a generic bypass around confirmation.

This proposal does not design UI, add a persisted restoration flag, specify importer mechanics, or modify `TransactionDraft`. A future implementation must merely be able to establish that compatibility-status admission is occurring under an authorized supported-Lumen restoration context rather than silently widening ordinary creation.

# 8. Meaning of Equivalent Supported Canonical State

For this status gate, repository evidence supports **exact status-token preservation**, not substitution by a supposedly equivalent financial state.

Reason:

1. exact tokens are already durable canonical fields;
2. exact tokens have observable analytics/display/edit consequences;
3. no repository evidence defines a lossless alternate representation of those consequences;
4. the Architecture Contract warns against blindly reclassifying the mixed model before migration evidence exists.

Therefore, for a Transaction whose status is admitted by this proposal:

```text
round-trip status equivalence
=
same admitted status token
+
same admitted status semantics
```

A future status-model migration may define a different semantic mapping, but this proposal does not.

# 9. Alternatives Considered

## A. Export all five and silently use ordinary confirmation mappings

Rejected.

Serialization would be easy, but restoration would silently change canonical semantics.

## B. Export only pending/posted

Rejected for complete Portable JSON ownership export.

It would omit compatibility-bearing canonical state or require lossy status normalization.

## C. Export all five, but permanently exclude the three legacy statuses from round-trip guarantees

Not recommended.

It would preserve ownership visibility but leave a known durable canonical field outside the stated fresh-store round-trip objective even though exact storage is technically possible.

## D. Admit all five exact tokens; distinguish ordinary lifecycle statuses from compatibility statuses; require explicit compatibility restoration for the latter

**Recommended.**

This preserves current canonical truth, does not bless legacy statuses as ordinary new-input lifecycle choices, and keeps restoration under explicit Review/Confirm authority.

## E. Redesign/split/migrate TransactionStatus now

Rejected for this gate.

The Architecture Contract itself requires migration evidence before such a change, and no authentic historical-store mapping evidence authorizes it here.

# 10. Recommended Narrow Portable JSON v1 Disposition

Portable JSON v1 should admit exactly the five current canonical status tokens for Transaction compatibility:

```text
pending
posted
ignored
duplicate
review_needed
```

They have two admission classes:

```text
ordinary financial-lifecycle:
pending
posted

canonical compatibility:
ignored
duplicate
review_needed
```

The second class is an ownership/round-trip compatibility classification, not a claim that ingestion/review disposition belongs permanently in the canonical financial lifecycle model.

For complete Portable JSON v1 export:

- preserve the exact admitted token;
- do not normalize or omit;
- any of the five tokens is representable and does not by itself defeat export completeness.

For import/restoration:

- `pending` and `posted` are READY on the status axis through ordinary confirmation;
- `ignored`, `duplicate`, and `review_needed` are recognized compatibility states but NOT READY for canonical promotion until the import workflow has an explicitly admitted compatibility-restoration operation that preserves the exact token after Review/Confirm;
- that operation must not make those statuses ordinary new/manual creation choices.

# 11. Exact Proposed Contract Language

> **Portable JSON v1 Transaction status admits the exact tokens `pending`, `posted`, `ignored`, `duplicate`, and `review_needed` for preservation of current canonical Transaction state.**

> **`pending` and `posted` are the ordinary currently creatable financial-lifecycle statuses. `ignored`, `duplicate`, and `review_needed` are admitted as canonical compatibility statuses because current durable Transactions can carry them; this admission does not classify them as preferred financial-lifecycle modeling or authorize them for ordinary new-input confirmation.**

> **A complete Portable JSON v1 ownership export must preserve the exact admitted canonical status token. It must not omit a Transaction, drop its status, or silently map `ignored`, `duplicate`, or `review_needed` to `pending` or `posted`. The presence of an admitted compatibility status does not by itself make the export incomplete.**

> **For status round-trip equivalence under v1, restoration must reproduce the same admitted status token and its admitted observable semantics unless a future separately accepted migration contract defines another lossless semantic mapping.**

> **Fresh-store import of `ignored`, `duplicate`, or `review_needed` is recognized but NOT READY for canonical promotion through the current ordinary confirmation path. Supported round-trip requires a specifically admitted compatibility-restoration path within explicit Review/Confirm authority. That authority is restoration-specific: it must be identifiable as restoration of previously canonical state from a supported Lumen round-trip representation, must not silently widen ordinary creation or non-restoration ingestion, and must not bypass meaningful user confirmation or coerce status merely to become confirmable.**

> **Status compatibility admission does not redesign `TransactionStatus`, migrate existing stores, alter analytics policy, or resolve categoryless state, type/direction, identity, serializer, or ingestion-workspace design.**

# 12. CSV Scope

This proposal decides the normative Portable JSON v1 status compatibility contract.

Lumen CSV v1 also carries a `status` column and must not silently normalize an exact shared status token. Whether all five compatibility statuses are admitted to CSV's narrower round-trip/export claim is left to the CSV/full-format gate unless separately reviewed.

# 13. Unresolved Dependencies

This proposal does not resolve:

- categoryless canonical-state restoration;
- unsigned type/direction semantics;
- portable identity;
- serializer spelling;
- date semantics;
- status-model split/migration;
- exact implementation of compatibility restoration;
- authentic historical-store prevalence/meaning of the three compatibility statuses;
- CSV completeness/round-trip scope beyond the no-silent-normalization invariant.

Implementation validation for compatibility restoration will eventually need to prove:

```text
Portable JSON exact status
→ fresh store
→ parse / preview
→ explicit Review / Confirm
→ exact canonical status
→ expected analytics/display behavior
```

without making compatibility statuses ordinary new-input choices.

# 14. Review Questions

Independent review should decide whether:

1. all five exact persisted tokens should be admitted to Portable JSON v1;
2. `ignored`, `duplicate`, and `review_needed` should be labeled canonical compatibility statuses rather than ordinary financial-lifecycle statuses;
3. their presence should remain compatible with a complete ownership export;
4. exact token preservation is required for v1 status round-trip equivalence;
5. a dedicated compatibility-restoration path within Review/Confirm is the right contract requirement;
6. restoration authority is explicitly distinct from ordinary creation/non-restoration ingestion authority;
7. such records should remain NOT READY for promotion until that path exists;
8. CSV admission should remain separate;
9. this preserves the Architecture Contract's financial-vs-ingestion distinction without rewriting existing canonical truth.

Until independent review passes, these status semantics remain **PROPOSED FOR REVIEW**.
