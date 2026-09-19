# Confirmed Evidence Retention v1 — Implementation Plan

## Status

**Plan-only engineering design. No production code is changed by this document.**

- **Plan date:** 2026-09-18
- **Canonical repository baseline:** `8fd9ffb39237be0925cb280d8d1adfdff3f8210d`
- **Admission authority:** `docs/architecture/PHASE_1B_CONFIRMED_EVIDENCE_RETENTION_V1_ADMISSION.md`
- **Implementation authorization:** Pending mechanical engineering review of this plan.
- **Schema posture:** No SwiftData model/schema changes.

This plan translates the admitted Confirmed Evidence Retention v1 behavior into concrete repository changes, ordering, runtime states, fault boundaries, and tests.

If implementation discovers a contradiction with the admission, stop and return to the admission/review boundary. Do not solve it by quietly adding a model, field, relationship, hash, manifest, or alternate durable marker.

---

# 1. Engineering Goal

Replace the current durable-metadata → temporary-file mismatch for the existing PhotosPicker screenshot/receipt flow with one durable raw picker-supplied payload that remains subordinate to the canonical financial ledger.

The required product behavior is:

```text
Select image
→ stage picker-supplied bytes
→ Review
→ user confirms
→ durable evidence preparation
→ confirmed ledger write
→ retained evidence available after relaunch
```

while preserving:

```text
Manual entry
→ Draft
→ Review
→ Confirm
→ Transaction
```

with no evidence requirement.

The evidence subsystem may fail without making the canonical ledger unreadable, uneditable, or subject to destructive repair.

---

# 2. Existing Repository Touchpoints

The current implementation establishes these concrete seams.

## `Views/UploadView.swift`

Current responsibilities:

- requests `item.loadTransferable(type: Data.self)`;
- uses `supportedContentTypes.first` to infer extension/MIME;
- writes the selected bytes to `FileManager.default.temporaryDirectory`;
- records that temporary URL in `TransactionSource.stored_file_uri`;
- builds the preview/stub draft;
- routes to Review.

Required v1 change:

- characterize the actual returned bytes;
- stage them under a controlled temporary staging namespace;
- keep the staging URL in transient draft/session state, not in persisted-source semantics;
- keep `draft.source.stored_file_uri == nil` until a retained association actually commits.

## `Views/TransactionForm.swift`

Current `TransactionDraft` owns transient source metadata and creates a confirmation-time copy of `TransactionSource`.

Required v1 change:

- add transient staged-evidence context to `TransactionDraft`;
- allow confirmation to construct a source copy with an explicitly chosen retained locator or nil locator;
- do not mutate an existing canonical Transaction's source during ordinary edit flow.

## `Views/ReviewTransactionView.swift`

Current behavior:

- synchronous `save()`;
- direct `LedgerWrite.perform`;
- one `onSave` callback is reused for successful save and "Discard draft";
- `Cancel` only dismisses Review;
- retryable write failure keeps the draft.

Required v1 change:

- split terminal flow outcomes from nonterminal confirmation state;
- route evidence-backed confirmation through the evidence confirmation coordinator;
- expose Retry / Save without retained evidence when retention fails;
- perform explicit cleanup for Discard/Cancel;
- never signal completion for retryable failure.

## `Views/ManualEntryView.swift`

Required v1 change:

- adapt to explicit Review outcome semantics;
- preserve current evidence-free behavior;
- cancellation from Review returns to manual editing without introducing evidence state.

## `Views/TransactionDetailView.swift`

Current attachment UI treats receipt/screenshot source type as though "Original capture" exists.

Required v1 change:

- consume the evidence availability resolver;
- distinguish origin from retained locator and current availability;
- never use `source_type`, `mime_type`, or `file_size_bytes` as attachment-existence proxies.

## `Views/SettingsView.swift`

Current privacy copy says:

> "Data stays on this device."

Required v1 release change:

- replace the absolute statement with copy accurately describing local persistence, no required Lumen-operated cloud service, and possible platform-managed Apple backup/restore participation.

## `Data/LedgerWrite.swift`

Keep as the canonical durable financial-write boundary unless implementation proves a concrete change is necessary.

No evidence filesystem write should masquerade as a successful ledger commit.

## `LumenFinanceApp.swift`

Current app opens the ledger without fallback/reset.

Required v1 integration:

- only after the ledger has opened authoritatively may startup reconciliation become eligible to make destructive decisions;
- ledger-open failure means no destructive evidence reconciliation.

## `Models/Models.swift`

**No schema changes.**

In particular:

- no `EvidenceArtifact @Model`;
- no persisted lifecycle state;
- no uniqueness attribute;
- no new relationship;
- no change to `source_hash`.

The project uses file-system-synchronized Xcode groups, so new Swift source files under `LumenFinance` / `LumenFinanceTests` should not require manual `project.pbxproj` membership edits.

---

# 3. Proposed Production File/Type Structure

Exact names may be adjusted during implementation review, but responsibilities must remain cohesive and no broader abstraction should be introduced.

## New: `Data/Evidence/RetainedEvidenceLocator.swift`

Own:

- v1 locator parse/serialize;
- version classification;
- canonical UUID serialization;
- source-ID/locator-ID validation primitives;
- legacy/unsupported/invalid classification.

It must not touch the filesystem.

## New: `Data/Evidence/EvidenceIdentity.swift`

Own transient identity logic:

- parse a candidate v1 source ID as UUID;
- canonical UUID representation;
- semantic UUID owner lookup across persisted `TransactionSource` rows;
- 0 / 1 / >1 ownership classification;
- duplicate semantic-owner detection.

This is an application-level invariant helper, not persisted identity infrastructure.

## New: `Data/Evidence/EvidencePayloadInspector.swift`

Own:

- validate that supplied `Data` is an admitted decodable image representation;
- determine actual ImageIO/UTType identity when available;
- derive MIME when confidently mapped;
- return actual byte count.

It must not decode/re-encode or sanitize the image.

## New: `Data/Evidence/EvidenceFileSystem.swift`

A narrow injectable filesystem boundary for:

- directory creation;
- atomic staging write;
- durable copy/write;
- atomic finalization/rename;
- removal;
- existence/readability checks;
- file attributes;
- Application Support and temporary roots.

Production implementation uses `FileManager`.

Tests can inject failures without requiring disk exhaustion or process termination for every case.

## New: `Data/Evidence/RetainedEvidenceStore.swift`

Own filesystem lifecycle:

- STAGED;
- durable incoming/prepared payload;
- final deterministic payload;
- cleanup;
- file-protection application;
- backup-exclusion posture;
- idempotent deterministic destination behavior.

It does not decide canonical financial truth.

## New: `Data/Evidence/EvidenceOperationCoordinator.swift`

Process-wide synchronization authority for identity-critical v1 operations.

Responsibilities:

- canonical UUID is the semantic operation key;
- confirmation and destructive reconciliation use the same authority;
- prevent same-identity destructive overlap;
- provide a lease/token or equivalent that remains held across identity check → preparation → recheck → commit for confirmation;
- allow destructive reconciliation only after acquiring the same authority and revalidating state.

The implementation must not pass non-Sendable `ModelContext` across an actor boundary. SwiftData reads/writes remain on the appropriate MainActor path.

A globally serialized v1 evidence mutation implementation is acceptable if it is simpler and still satisfies the canonical-UUID authority rules. Per-UUID parallelism is not a v1 requirement.

## New: `Data/Evidence/EvidenceAvailabilityResolver.swift`

Own runtime interpretation:

- identity integrity;
- locator classification;
- source/locator UUID consistency;
- controlled physical path construction;
- current readability/existence;
- availability result.

It performs no destructive action.

## New: `Data/Evidence/EvidenceReconciler.swift`

Own conservative cleanup of positively identified never-committed v1 material.

It must not:

- delete committed v1 source rows;
- delete committed retained payloads merely because Transactions no longer reference them;
- repair/normalize historical source rows;
- act destructively if the ledger is unavailable or identity is ambiguous.

## Existing views/models

Modify only where required by the admitted behavior:

- `UploadView.swift`
- `TransactionForm.swift`
- `ReviewTransactionView.swift`
- `ManualEntryView.swift`
- `TransactionDetailView.swift`
- `SettingsView.swift`
- `LumenFinanceApp.swift`
- `LedgerPersistenceTests.swift` plus focused new evidence tests as useful.

Do not create one file/type for every conceptual Phase 1B responsibility merely because the architecture names it.

---

# 4. Exact v1 Identity Contract

The implementation must enforce all seven admitted rules.

1. New v1 retained identities must be valid UUIDs.
2. Historical persisted ID strings are never rewritten merely for normalization.
3. Locator and filesystem identity use canonical UUID serialization.
4. Identity equality uses UUID semantics, not raw-string equality.
5. Exactly one persisted source may authoritatively own a v1 UUID namespace; ambiguity fails closed.
6. First-commit operations are serialized process-wide by canonical UUID and revalidate authoritative ownership immediately before ledger persistence.
7. Destructive reconciliation uses the same canonical-UUID coordination authority and revalidates its candidate while holding that authority.

Additionally:

> **A successfully committed v1 TransactionSource is the durable commitment marker for that namespace and is not independently deleted by this capability.**

## 4.1 Canonical UUID

Use Foundation `UUID` parsing as the semantic identity boundary.

Newly serialized locator/path identity uses canonical `uuid.uuidString`.

Do not rewrite `TransactionSource.id` solely to canonicalize spelling.

Example:

```text
persisted source.id
abcdef12-3456-...

semantic UUID
ABCDEF12-3456-...

locator/path
ABCDEF12-3456-...
```

## 4.2 Semantic owner lookup

Do **not** implement the invariant as only:

```swift
source.id == canonicalUUIDString
```

For the current expected local ledger size, fetch persisted `TransactionSource` identities and parse UUID-capable IDs in memory for semantic comparison.

The lookup used for ownership enforcement must have the same equality semantics as the identity contract.

Historical non-UUID IDs remain untouched and are not considered equal to UUID S.

## 4.3 0 / 1 / >1 behavior

For a first-commit source UUID S:

```text
0 semantic owners
→ eligible to continue first-commit preparation

1 semantic owner
→ classify
→ do not create another source blindly

>1 semantic owners
→ identityConflict
→ no payload preparation/replacement/deletion
→ no new v1 commitment
```

For v1, the conservative handling of the single-owner case is:

- recognized already-committed v1 source → do not create a duplicate; surface existing/ambiguous commitment rather than pretending the current draft newly saved;
- legacy/non-v1 source occupying semantic UUID S → integrity collision; do not reuse as v1;
- malformed/inconsistent v1 source → integrity failure;
- otherwise unexplained source → integrity failure.

Do not silently re-key the draft as an automatic collision workaround in v1.

## 4.4 Duplicate identity fault behavior

Intentionally supported fault tests must include:

- two rows with the exact same UUID string;
- two rows with case-varied strings that parse to the same UUID;
- source UUID A with locator UUID B.

In all integrity-conflict cases, prove no code path:

- chooses the first row;
- replaces a payload;
- deletes a payload;
- creates another v1 association;
- performs destructive reconciliation;
- reports ordinary availability.

---

# 5. Exact Locator Grammar

Freeze the serialized v1 form as:

```text
lumen-evidence://v1/<CANONICAL-UUID>/payload
```

Interpretation:

- scheme: `lumen-evidence`;
- host/version: `v1`;
- path components: exactly `/<UUID>/payload`;
- no username/password;
- no port;
- no query;
- no fragment.

The serializer emits one canonical form.

The parser may parse UUID spelling semantically, but all new serialization uses canonical `UUID.uuidString`.

Classification:

```text
nil
→ noRetainedLocator

scheme != lumen-evidence
→ legacyOpaque

lumen-evidence + unsupported version
→ unsupportedVersion

lumen-evidence v1 + malformed structure
→ invalidLocator

valid v1 syntax + UUID mismatch with source
→ invalidAssociation

valid v1 syntax + UUID match
→ supported v1 locator
```

Never:

```text
locator parsing failed
→ maybe treat string as file path
```

The logical locator contains semantic identity only. It never stores the physical app-container root.

---

# 6. Physical Storage Layout

## 6.1 Temporary staging

Controlled namespace:

```text
<temporaryDirectory>/
  LumenEvidenceStaging/
    <CANONICAL-UUID>/
      payload
```

The staged payload is transient and never becomes the persisted `stored_file_uri`.

## 6.2 Durable v1 root

```text
<Application Support>/
  LumenEvidence/
    v1/
      <CANONICAL-UUID>/
        payload.incoming
        payload
```

`payload.incoming` is incomplete/pre-commit preparation state.

`payload` is a complete durable payload at the deterministic final physical destination.

No filename extension is required for storage identity.

No merchant, amount, category, user name, location, or other sensitive domain information is included in the path.

## 6.3 Protection and backup attributes

Before the payload is considered durably prepared:

- final `payload` must use Complete file protection;
- the v1 implementation must not deliberately set the payload to be excluded from platform-managed backup;
- tests verify the attributes Lumen controls;
- tests do not claim a real Apple backup has occurred.

If strong file protection causes a foreground operation to fail, treat it as a retryable evidence failure. Do not weaken protection to make the operation succeed.

---

# 7. Actual-Byte Characterization

On PhotosPicker selection:

1. obtain `Data` with the existing `item.loadTransferable(type: Data.self)`;
2. reject empty data;
3. inspect the actual bytes with ImageIO;
4. require a valid admitted image representation;
5. obtain actual byte count;
6. derive actual type/MIME only when confidently available;
7. do not decode/re-encode;
8. stage the same supplied bytes.

Rules:

```text
valid image + identified type
→ file_size_bytes = Data.count
→ mime_type = actual mapped MIME

valid image + unknown MIME mapping
→ file_size_bytes = Data.count
→ mime_type = nil
→ retention still allowed

invalid/unusable admitted image
→ retention/load failure
```

Never fall back to `supportedContentTypes.first` as persisted actual-byte metadata.

The current PhotosPicker path should stop inventing a synthetic format-based filename for durable identity. `original_filename` remains current/known metadata only; do not invent an "original camera filename."

---

# 8. Transient Draft/Staging State

Add a non-persisted value equivalent to:

```swift
struct StagedEvidence {
    let sourceUUID: UUID
    let stagedURL: URL
    let byteCount: Int
    let mimeType: String?
}
```

Exact type name/signature may vary.

`TransactionDraft` may own optional transient staged-evidence context because it is not a SwiftData model.

For new image-backed drafts:

```text
draft.source.id
→ stable source identity string

draft.source.stored_file_uri
→ nil

draft.stagedEvidence
→ temporary staging information
```

This prevents a temporary filesystem URL from acquiring durable retained-evidence meaning.

Manual drafts have no staged evidence.

---

# 9. TransactionSource Field Outcome Matrix

The implementation must make field behavior explicit rather than opportunistic.

| Field | Retained successfully | Saved without retained evidence | Cancel / Discard | v1 rule |
| --- | --- | --- | --- | --- |
| `id` | Stable draft source ID; must parse as UUID | Same stable draft source ID | Not persisted | Do not rewrite historical IDs |
| `source_type` | Preserve current image-ingestion origin semantics | Same | Not persisted | Do not add new source classifier |
| `original_filename` | Preserve known current value; current PhotosPicker path normally nil | Same | Not persisted | Do not invent filename |
| `stored_file_uri` | Canonical v1 logical locator | nil | Not persisted | Availability is not inferred from other fields |
| `compressed_file_uri` | Preserve current value; do not set for v1 | Same | Not persisted | No derivative generation |
| `file_size_bytes` | Actual supplied `Data.count` | Actual supplied `Data.count` | Not persisted | Representation context, not availability |
| `mime_type` | Actual-byte MIME when confidently known, else nil | Same | Not persisted | Never substitute advertised picker capability |
| `uploaded_at` | Preserve current ingestion-time semantics | Same | Not persisted | No new semantic expansion |
| `captured_at` | Preserve current semantics; active path remains nil unless separately admitted | Same | Not persisted | Do not promote EXIF date |
| `source_timezone` | Preserve current ingestion-time/device context | Same | Not persisted | Not transaction truth |
| `metadata_json` | Preserve current semantics; active path remains nil | Same | Not persisted | Do not dump image metadata into it |
| `raw_extracted_text` | Preserve current stub/current semantics | Same | Not persisted | No OCR expansion |
| `parse_status` | Preserve current `.manual_review` behavior | Same | Not persisted | No new processing model |
| `source_hash` | Preserve current value; active path remains nil | Same | Not persisted | Never reinterpret as content hash |
| `created_at` | Preserve source creation semantics | Same | Not persisted | No lifecycle-status overloading |

A non-nil MIME or size never means that a retained attachment exists.

Fields not explicitly changed above preserve current semantics.

---

# 10. Review Flow State Model

Replace the current overloaded `onSave` semantics with explicit flow outcomes.

## 10.1 Terminal outcomes

Equivalent to:

```text
.saved
.savedWithoutEvidence
.savedWithEvidenceConflict
.discarded
.cancelled
```

These may be represented by an enum or equivalent typed result.

`.savedWithEvidenceConflict` means the financial ledger commit succeeded but a post-commit evidence-integrity verification failed. The Transaction is already canonical. The UI must never offer another financial confirmation attempt for that draft/session.

## 10.2 Nonterminal confirmation states

Equivalent to:

```text
.idle
.saving
.retentionFailedRetryable
.ledgerFailedRetryable
.preCommitIdentityConflict
```

A retryable or pre-commit blocking failure is **not** completion.

Required behavior:

```text
retentionFailedRetryable
→ Review remains open
→ draft remains
→ staging remains
→ user may retry or explicitly choose Save without retained evidence

ledgerFailedRetryable
→ Review remains open
→ draft remains
→ retained-confirmation staging remains when that path was active
→ uncommitted durable material is cleaned/reconciled safely

preCommitIdentityConflict
→ no Transaction exists
→ confirmation is blocked
→ no destructive evidence mutation occurs
→ Review remains open for an explicit recovery path or abandonment
```

Post-commit evidence conflict is not represented by these nonterminal states.

The Save control is disabled while a confirmation operation is active, but button state is not the concurrency guarantee.

## 10.3 Manual-entry parent behavior

Manual entry remains source-free.

- `.saved` → current successful dismissal behavior.
- `.cancelled` → return to manual editing with the manual draft intact.
- `.discarded` → abandon according to existing UX intent.
- evidence-specific states are unreachable for evidence-free manual drafts.

## 10.4 Image-upload parent behavior

- `.saved` / `.savedWithoutEvidence` → close the completed add flow.
- `.savedWithEvidenceConflict` → financial flow is complete; close or transition out of financial confirmation without allowing resubmission, while evidence remains fail-closed internally.
- `.discarded` → cleanup staging and abandon the draft.
- `.cancelled` → cleanup staging and return to the Upload hub.
- retryable/pre-commit blocking states → remain in Review.

---

# 11. Retained Confirmation Ordering

For evidence-backed retained confirmation of UUID S:

```text
1. acquire process-wide evidence coordination for canonical UUID S

2. fresh semantic owner preflight
   0 → continue
   1 / >1 → classify/fail closed

3. validate staged payload still exists/readable

4. prepare durable payload
   staged bytes remain intact
   write/copy complete bytes to payload.incoming
   verify preparation
   if an existing zero-owner final payload from an earlier interrupted attempt exists,
   do not trust it as proof of correctness; reprepare/atomically replace from the
   still-authoritative staged bytes

5. finalize durable payload
   atomic move/replace payload.incoming → payload
   deterministic final path

6. verify the actual final payload
   readable/complete as expected
   Complete file protection applied
   not deliberately excluded from platform-managed backup

7. fresh semantic owner revalidation
   re-read authoritative persisted ownership
   0 → continue
   otherwise → abort before ledger commit

8. construct confirmation-time TransactionSource copy
   stored_file_uri = canonical v1 locator
   actual-byte mime/size retained
   legacy fields preserve admitted semantics

9. LedgerWrite.perform
   create Transaction
   attach confirmation source
   insert
   durable save

10. ledger commit succeeds
    → canonical Transaction now exists
    → source row is commitment marker
    → state is RETAINED

11. post-save integrity verification
    exactly one semantic owner S expected
    locator/source consistency expected

12. cleanup staged payload

13. release coordination
```

The complete final payload intentionally exists before ledger commit.

Final-file existence alone does not establish RETAINED state.

---

# 12. Confirmation Failure Windows

The implementation and tests must define every meaningful interruption boundary.

## Before durable preparation

Failure:

- no canonical write;
- staging remains;
- Review retryable.

## During `payload.incoming` write

Failure:

- incomplete incoming material must never masquerade as final `payload`;
- staging remains;
- cleanup incoming best-effort;
- retry remains possible.

## After incoming is complete, before finalization

Failure:

- staging remains;
- incoming may be cleaned immediately or by conservative reconciler;
- no canonical write.

## After final `payload` exists, before ledger commit

Failure/crash:

- final payload may remain with zero persisted semantic owners;
- this is the central pre-commit orphan case;
- on restart the reconciler may clean it only under the admitted authority rules;
- on an in-session retry, the existing zero-owner final payload is not trusted merely because it exists or appears complete; retry re-establishes the deterministic final payload from the still-authoritative staged bytes.

## LedgerWrite failure — retained confirmation

- canonical Transaction does not exist;
- committed locator-bearing source does not exist;
- staging remains;
- remove uncommitted final/incoming payload while authority is clear;
- if cleanup fails, leave it for reconciliation;
- Review remains retryable for retained confirmation.

## LedgerWrite failure — Save Without Retained Evidence after cleanup

If the user explicitly selected Save Without Retained Evidence and evidence cleanup already succeeded before the nil-locator ledger write:

- canonical Transaction does not exist;
- the financial draft remains;
- staging is intentionally absent because the user authorized its destruction;
- the user may retry the financial save-without-evidence operation;
- retained-evidence confirmation must not be offered again for that draft/session.

## LedgerWrite succeeds, staging cleanup fails

- Transaction remains canonical;
- source is committed marker;
- final evidence remains retained;
- leftover staging is noncanonical cleanup work;
- do not roll back the Transaction.

## Post-save identity verification fails unexpectedly

- do not undo the successful financial write;
- do not delete bytes;
- financial confirmation is terminal;
- return/record a terminal result equivalent to `.savedWithEvidenceConflict`, not a retryable confirmation state;
- expose internal evidence `identityConflict`;
- prohibit evidence mutation/destructive reconciliation for S;
- keep canonical Transaction readable/editable;
- do not permit another financial confirmation attempt for that draft/session.

---

# 13. Save Without Retained Evidence

This is an explicit user-authorized outcome, not an automatic downgrade.

For image-backed UUID S:

```text
acquire coordination S
        ↓
fresh semantic-owner check

0 owners
→ continue

1 owner
→ classify / fail closed
→ NO durable evidence deletion

>1 owners
→ identity conflict
→ NO durable evidence deletion

        ↓ only when fresh owner count == 0

remove known uncommitted durable v1 material for S
(final payload first, then incoming as applicable)
        ↓
remove staging LAST
        ↓
verify all known session evidence is absent
        ↓
LedgerWrite:
Transaction + source metadata
stored_file_uri = nil
        ↓
.savedWithoutEvidence
```

For v1, do not claim `.savedWithoutEvidence` while Lumen knows that an uncommitted durable v1 payload for that same session/identity remains because cleanup failed.

If cleanup required for this explicit outcome fails:

- keep Review active;
- surface a retryable cleanup/retention error;
- preserve staging when durable cleanup fails before the staging-removal step;
- do not falsely tell the user that Lumen completed the no-retained-evidence outcome.

If all evidence cleanup succeeds, staging is intentionally gone, and the subsequent nil-locator ledger write fails:

- the financial draft remains retryable;
- the user may retry Save Without Retained Evidence;
- retained-evidence confirmation is no longer available for that draft/session.

This choice avoids introducing a new durable cleanup marker solely to remember failed deletion.

Manual Entry remains available independently if the evidence-backed flow cannot complete.

---

# 14. Cancel and Discard

For image-backed drafts:

```text
Cancel / Discard
→ no ledger write
→ ensure no identity-critical confirmation for this draft/session is still active
→ acquire canonical-UUID coordination before durable evidence deletion
→ fresh semantic-owner validation

0 owners
→ cleanup known never-committed final payload if present
→ cleanup known never-committed incoming material

1 / >1 owners or ambiguous state
→ fail closed for durable evidence deletion
→ retain final/incoming material
→ do not guess that durable material is disposable

ALL cases
→ best-effort cleanup of this active draft/session's transient staging
→ no durable TransactionSource is created by Cancel / Discard
→ no retained locator is recorded by Cancel / Discard
```

Staging cleanup authority is session-local and distinct from authority to delete durable final/incoming material. Durable evidence ambiguity therefore does not, by itself, justify retaining the active draft/session's transient staging once Cancel / Discard has ended that session.

A staging or durable cleanup failure must not be reported as confirmed deletion of bytes. Unknown or ambiguous durable material is retained rather than guessed away.

No resumable ingestion session is introduced in v1.

Manual-entry Cancel/Discard behavior remains independent because there is no staged evidence.

---

# 15. Process-Wide Coordination

## 15.1 Confirmation

The coordination boundary for S covers:

```text
identity preflight
→ preparation
→ finalization
→ authoritative identity recheck
→ LedgerWrite
→ post-save verification
```

The pre-commit recheck must read current persisted ownership, not merely re-evaluate a cached preflight collection.

An actor type by itself is not proof that the entire identity-critical operation is mutually exclusive: Swift actors may be reentrant across `await`. The coordinator must use a lease/token, queued critical section, non-reentrant gate, or equivalent mechanism whose exclusivity for canonical UUID S survives suspension points until the operation explicitly releases it.

## 15.2 Reconciliation

Filesystem scanning/discovery may occur without holding S.

Before destructive action:

```text
discover candidate S
→ acquire same coordination authority for canonical UUID S
→ fresh authoritative ledger/source read
→ semantic ownership calculation
→ revalidate filesystem candidate
→ delete only if still positively authorized
```

This closes the race where the reconciler could otherwise delete a just-finalized pre-commit payload while confirmation is about to persist its locator.

## 15.3 Single-process assumption

V1 assumes one Lumen process controls:

- first commitment of v1 evidence;
- destructive reconciliation of v1 evidence.

A future second process, app extension, independent background writer, or sync engine that can mutate these resources requires the concurrency/uniqueness strategy to be revisited.

---

# 16. Runtime Availability Resolution

Views call a resolver; they do not interpret raw fields independently.

Resolution order:

```text
source qualifies for v1 identity?
        ↓
establish semantic owner uniqueness globally
        ↓
parse locator
        ↓
verify locator UUID == source UUID
        ↓
construct controlled physical path from canonical UUID
        ↓
inspect filesystem
        ↓
return runtime state
```

Possible internal states include:

- `noEvidenceExpected`;
- `noRetainedLocator`;
- `available`;
- `expectedButUnavailable`;
- `legacyOpaque`;
- `unsupportedVersion`;
- `invalidLocator`;
- `invalidAssociation`;
- `identityConflict`.

A source object handed to a view is not sufficient proof of unique ownership. Duplicate semantic owners elsewhere in SwiftData must cause identity conflict rather than ordinary availability.

---

# 17. Transaction Detail UX

Replace the current shortcut:

```text
source_type == receipt_photo/screenshot
→ "Original capture"
```

with resolver-backed truth.

Representative behavior:

```text
manual / no evidence expected
→ No attachment

receipt-origin + no retained locator
→ Original image not retained

valid committed locator + available payload
→ Retained image available
→ permit v1 local preview/inspection if included in implementation scope

valid committed locator + payload unavailable
→ Retained image expected but currently unavailable

legacy locator/source
→ Historical source context
→ do not claim v1 retained availability

identity conflict / invalid association
→ Evidence unavailable due to an internal consistency issue
→ no evidence mutation
```

User-facing wording may be calmer than internal state names.

No GPS/caption/metadata interpretation UI is added.

---

# 18. Reconciliation Algorithm

Run only after authoritative ledger open succeeds.

Potential integration points:

- one startup pass after `LedgerStore.open()` succeeds and the model container is available;
- opportunistic retry after known cleanup failure.

Do not run destructive reconciliation from the ledger-open failure UI.

## 18.1 Staging namespace

Because v1 has no resumable draft persistence, recognized leftover staging material from a prior process/session is never canonical.

Cleanup is allowed when:

- it is inside Lumen's controlled staging root;
- its directory identity parses as a canonical UUID;
- no current process operation owns that UUID.

Unknown/malformed material defaults to retention rather than broad directory deletion.

## 18.2 Durable v1 namespace

For each recognized canonical UUID S:

```text
scan/discover
        ↓
acquire coordination S before deletion
        ↓
fresh ledger ownership read
```

### Zero semantic owners

If S is positively recognized v1 material and owner count remains zero under coordination:

- `payload.incoming` → cleanup candidate;
- final `payload` → pre-commit orphan cleanup candidate;
- remove empty controlled source directory after successful cleanup.

This reasoning is valid only because committed v1 source markers are never independently deleted by this capability.

### Exactly one owner with supported matching v1 locator

- final payload exists/readable → committed context; retain;
- final payload missing/unreadable → expected-but-unavailable; do not rewrite ledger;
- stale incoming + healthy final payload → incoming is eligible for cleanup under coordination;
- incoming exists while final is unavailable → retain conservatively; v1 does not auto-promote/repair.

### One owner but nil/legacy/malformed/unsupported/mismatched locator

No destructive v1 cleanup based on that source state.

### More than one semantic owner

Identity conflict.

No destructive evidence cleanup for S.

### Ledger unavailable

No destructive evidence cleanup at all.

---

# 19. Committed-But-Unreferenced Evidence

The permanent v1 rule is:

```text
committed source
+ valid v1 locator
+ zero current Transaction references
→ previously committed retained evidence
→ retain
```

Confirmed Evidence Retention v1 does not independently delete:

- the source commitment marker;
- the committed payload.

A later user-owned data-management capability may define evidence deletion.

The permanent regression suite must protect zero-reference source survival while v1 reconciliation depends on it.

---

# 20. Privacy Copy

Before release-complete status, replace the absolute Settings statement:

> "Data stays on this device."

The final UI must communicate both:

- local persistence / no required Lumen-operated cloud service;
- platform-managed Apple backup/restore may include Lumen data according to platform/device backup settings.

Candidate:

> **Lumen stores your financial data locally and does not require a Lumen-operated cloud service. Your device's backup settings may include Lumen data in platform-managed Apple backups.**

Do not claim custom encryption or guaranteed backup.

---

# 21. Test Architecture

Use deterministic unit/integration tests for the majority of failure windows. Reserve true process/device characterization for behavior that cannot be established deterministically.

## 21.1 Locator tests

Prove:

- canonical serialize/parse roundtrip;
- differently cased valid UUID parses to same semantic identity;
- malformed UUID rejected;
- extra path component rejected;
- missing payload component rejected;
- query/fragment/userinfo/port rejected;
- unsupported `v2` classified unsupported;
- legacy `file://` string stays legacy/opaque;
- parser failure never becomes filesystem path fallback;
- source UUID / locator UUID mismatch → invalid association.

## 21.2 Semantic identity tests

Prove:

- zero owner;
- one owner;
- two exact-string duplicate owners → conflict;
- case-varied strings for same UUID → conflict;
- historical non-UUID IDs remain untouched;
- one legacy/non-v1 source semantically occupying UUID S blocks first v1 commitment rather than being reused;
- identity lookup uses UUID semantics rather than raw equality.

## 21.3 Payload inspector tests

Use generated/non-personal test images.

Prove:

- JPEG detection;
- HEIC detection where supported by test environment;
- PNG detection;
- `Data.count` preservation;
- valid image with unknown MIME mapping can retain with nil MIME;
- invalid bytes fail validation;
- no encode/re-encode mutation is performed.

No personal Picker Lab asset is committed as a fixture.

## 21.4 Store/filesystem tests

With injected temporary roots:

- staging write;
- incoming write;
- deterministic final path;
- atomic finalization;
- repeated preparation converges on one destination;
- failure creating directory;
- failure writing incoming;
- failure finalizing;
- failure deleting stage;
- failure deleting orphan;
- final payload attributes request/verify Complete protection;
- payload is not deliberately excluded from backup;
- unknown/malformed directories are not broadly deleted.

## 21.5 Confirmation tests

Prove:

- retained happy path;
- source locator becomes durable only inside successful confirmed ledger write;
- staging remains until ledger commit succeeds;
- successful commit cleans staging;
- retention failure keeps Review/draft retryable;
- retained-confirmation ledger failure leaves zero canonical Transactions / zero locator-bearing committed v1 sources and preserves staging;
- retry converges on one source identity and one payload;
- retry re-prepares/replaces an existing zero-owner deterministic final payload from staged bytes rather than trusting its existence;
- final payload protection, backup-exclusion posture, and readability are verified after finalization and before ledger commit;
- save without evidence persists nil locator with actual-byte MIME/size metadata;
- save-without-evidence requires a fresh zero-owner result before any durable v1 evidence deletion;
- save-without-evidence removes staging last;
- save-without-evidence does not complete if required cleanup cannot be verified;
- if save-without cleanup succeeds but the nil-locator ledger write fails, the draft remains financially retryable while retained-evidence confirmation is unavailable;
- post-commit evidence integrity conflict is terminal for financial confirmation and cannot trigger a second Transaction submission;
- repeated confirmation does not create a second Transaction/source blindly;
- concurrent double-submit for same semantic UUID yields at most one first commitment;
- same-UUID confirmations cannot simultaneously enter the identity-critical region even when the implementation suspends/awaits filesystem or MainActor work;
- case-varied semantic UUID requests share the same coordination authority;
- pre-commit identity conflict prevents commit;
- injected post-commit identity conflict preserves Transaction and bytes and returns internal conflict state.

## 21.6 Reconciliation tests

Prove:

- final payload + zero owners → cleanup only after coordination + fresh zero-owner recheck;
- incoming + zero owners → cleanup;
- confirmation active for S → reconciler cannot destructively act on S;
- owner appears between discovery and destructive phase → recheck prevents deletion;
- Cancel/Discard cleanup of a known final orphan requires coordination + fresh zero-owner validation;
- one committed owner + zero Transactions → retain;
- duplicate owners → retain;
- nil/legacy/malformed/unsupported locator → no destructive inference;
- source/locator mismatch → retain;
- ledger unavailable → no destructive cleanup;
- committed source marker is never independently deleted;
- uncertainty defaults to retention.

## 21.7 Availability resolver tests

Prove:

- source type alone does not imply availability;
- MIME/size alone do not imply availability;
- valid unique committed owner + file → available;
- valid unique committed owner + missing file → expectedButUnavailable;
- duplicate semantic owner + file → identityConflict, not available;
- unsupported/invalid/mismatched locator is distinguishable;
- historical locator remains compatibility state.

## 21.8 Permanent zero-reference regression

Promote the PR #9 finding into production regression coverage once the implementation relies on it:

```text
unique:
commit T1 → S
save/reopen
delete T1
save/reopen
assert S survives with v1 locator/identity/compatibility state

shared:
commit T1 + T2 → S
delete T1
save/reopen
delete T2
save/reopen
assert S survives
```

Add a nearby comment that Confirmed Evidence Retention v1 recovery semantics rely on this behavior and relationship/delete changes require architecture review.

## 21.9 Existing-store compatibility

Run the authentic Phase 1A existing-store compatibility workflow against the production candidate.

Required:

- historical store opens;
- historical source/locator values are unchanged;
- historical `source_hash` values are unchanged;
- no schema migration is triggered by this feature;
- current code can still mutate/relaunch the historical ledger.

## 21.10 Manual-entry regression

Prove manual:

```text
input
→ draft
→ review
→ confirm
→ transaction
```

works with no source, no staging, no evidence store, and no evidence availability requirement.

---

# 22. Fault-Injection Matrix

The filesystem boundary must make these failures deterministic in tests.

| Boundary | Expected result |
| --- | --- |
| Stage write fails | No Review transition; no durable state |
| Incoming directory creation fails | Review retryable; staging retained |
| Incoming write fails | Review retryable; staging retained; partial cannot masquerade as final |
| Finalization fails | Review retryable; staging retained |
| Final payload protection/backup/readability verification fails | No ledger commit; staging retained; retained confirmation retryable |
| Identity preflight conflict | No filesystem mutation for first commitment |
| Pre-commit recheck conflict | No ledger commit; staging retained; no destructive ambiguity handling |
| Retained-confirmation ledger save fails | No canonical Transaction; staging retained; uncommitted final cleaned/reconciled |
| Save-without-evidence ledger save fails after cleanup | No canonical Transaction; draft remains; evidence stays intentionally absent; retained-evidence retry is unavailable |
| Staging cleanup fails after successful commit | Ledger remains committed; evidence retained; cleanup can retry |
| Post-save integrity check fails | Ledger + bytes retained; terminal saved-with-evidence-conflict result; no second financial confirmation; no automatic rollback |
| Orphan cleanup fails | Material retained for later retry; ledger unchanged |
| Ledger cannot open | No destructive reconciliation |
| Resolver cannot understand locator | Attachment unavailable/unsupported; ledger unchanged |

Where a true process termination window cannot be fully represented by injected errors, use a focused integration/characterization test in addition to deterministic unit coverage.

---

# 23. Reversibility / Production Failure Posture

This is a formal acceptance property:

> **Evidence-subsystem failure must degrade attachment functionality, never canonical-ledger readability or editability.**

Therefore:

```text
buggy locator parser
→ Transaction still loads
→ attachment unavailable
→ file retained

missing payload
→ Transaction unchanged

unsupported future locator
→ source preserved
→ no path guessing

identity conflict
→ bytes retained
→ mutation prohibited
→ Transaction unchanged

reconciler uncertainty
→ retain

ledger unavailable
→ no evidence deletion

historical locator
→ preserve opaque value

evidence implementation defect
→ never trigger automatic ledger reset/reseed
```

No automatic destructive repair is permitted merely because evidence state looks inconsistent.

---

# 24. Admission-to-Implementation Traceability

Every production change must map to admitted/required behavior, and every required behavior must map to code ownership and proof.

| Requirement | Planned owner | Required proof |
| --- | --- | --- |
| Stable UUID retained identity | EvidenceIdentity + draft source | identity/retry tests |
| Semantic UUID equality | EvidenceIdentity | case-variant duplicate tests |
| Versioned logical locator | RetainedEvidenceLocator | parse/serialize/malformed/version tests |
| Source/locator consistency | Locator + availability resolver | UUID mismatch tests |
| Actual-byte metadata | EvidencePayloadInspector + UploadView | JPEG/HEIC/PNG/size tests |
| Picker-supplied byte fidelity | UploadView + RetainedEvidenceStore | byte-equality/no-reencode tests |
| One raw payload | RetainedEvidenceStore | deterministic layout tests |
| Application Support storage | RetainedEvidenceStore | integration path assertion |
| Complete protection | RetainedEvidenceStore | file-attribute integration assertion |
| Backup eligibility posture | RetainedEvidenceStore | exclusion attribute assertion |
| STAGED/PREPARED/RETAINED | Draft + store + confirmation flow | failure-window suite |
| First-commit uniqueness | EvidenceIdentity + coordinator | 0/1/>1 tests |
| Concurrent confirmation safety | EvidenceOperationCoordinator | double-submit tests |
| Confirmation/reconciler race safety | Shared coordinator | discovery-vs-confirmation race test |
| Durable commitment marker | LedgerWrite + confirmed source construction | locator first-durability test |
| Marker survival | SwiftData relationship current behavior | permanent zero-reference regression |
| Marker not independently deleted | Reconciler / deletion behavior | deletion/reconciliation tests |
| Runtime availability | EvidenceAvailabilityResolver | state matrix tests |
| Save without evidence | Review flow + store cleanup | nil-locator + cleanup tests |
| Cancel/discard cleanup | Review/Upload flow | staging cleanup tests |
| Financial write failure retry | LedgerWrite + Review | injected save failure |
| Conservative reconciliation | EvidenceReconciler | ambiguity/ledger-unavailable tests |
| Manual path independence | ManualEntryView | manual regression |
| Historical compatibility | parser/resolver + existing store | authentic existing-store workflow |
| `source_hash` untouched | source-copy behavior | legacy regression |
| Privacy disclosure | SettingsView | UI/release assertion |

Reverse review rule:

> **If a proposed production modification cannot identify an ADMITTED/REQUIRED row that justifies it, challenge or remove it.**

---

# 25. Explicit Non-Changes

The production implementation must not modify or introduce:

- SwiftData schema/model version solely for this capability;
- `@Attribute(.unique)` on source IDs;
- `EvidenceArtifact @Model`;
- Observation/ExtractionRun/FieldCandidate/ValidationSignal/ResolvedField/CorrectionEvent persistence;
- many-to-many evidence relationships;
- `source_hash` semantics;
- content hashes/deduplication;
- OCR;
- captions;
- GPS parsing;
- semantic location;
- image normalization;
- compressed derivative generation;
- `compressed_file_uri` use;
- cloud evidence storage;
- custom encryption;
- cross-process locks;
- committed-evidence deletion UI;
- automatic deletion of committed evidence when deleting a Transaction;
- historical source-ID normalization.

---

# 26. Implementation Sequence

## Pass A — Identity, locator, and actual-byte primitives

Add:

- locator parser/serializer;
- semantic UUID identity lookup;
- actual-byte payload inspector;
- focused unit tests.

No UI behavior change yet.

## Pass B — Storage lifecycle and injected filesystem boundary

Add:

- controlled staging root;
- Application Support v1 root;
- incoming/final lifecycle;
- file protection/backup posture;
- deterministic cleanup behavior;
- filesystem fault tests.

No ledger integration until these tests are green.

## Pass C — Confirmation coordination

Add:

- process-wide coordinator;
- transient staged evidence on draft;
- retained confirmation ordering;
- preflight/recheck/postcondition behavior;
- save-without-evidence path;
- terminal/nonterminal Review state split;
- duplicate/concurrency/failure tests.

## Pass D — Runtime availability and UI truthfulness

Add:

- availability resolver;
- Transaction Detail rendering by resolver state;
- no source-type attachment shortcut;
- debug/test-visible identity conflict distinction.

## Pass E — Reconciliation

Add:

- startup post-ledger-open reconciliation;
- shared coordination with confirmation;
- zero-owner cleanup;
- committed-marker preservation;
- zero-reference permanent regression;
- race/failure tests.

## Pass F — Release correctness

- update Settings privacy copy;
- run full unit/UI suite;
- run authentic existing-store compatibility workflow;
- exercise physical-device retained-confirm/relaunch path;
- verify manual entry;
- verify no schema migration;
- verify no personal diagnostic assets entered production repository.

Each pass should remain within the exact admission boundary.

---

# 27. Mechanical Engineering Review Checklist

Before production code begins, review this plan by asking:

1. Does every proposed production change have admission authority?
2. Does every REQUIRED invariant have an implementation owner?
3. Does every critical state/failure window have deterministic proof?
4. Can any evidence failure, ambiguity, or unavailable file damage, rewrite, reset, or make the canonical ledger unavailable?
5. Does source identity use UUID semantics everywhere that namespace ownership matters?
6. Does any path silently use `supportedContentTypes.first` as actual retained type?
7. Can a v1 locator become durable outside the confirmed ledger write?
8. Can confirmation and destructive reconciliation race for the same identity?
9. Can a committed v1 source marker be independently deleted?
10. Can a duplicate source identity cause a first-row-wins filesystem decision?
11. Can parser failure fall through to arbitrary path handling?
12. Can Transaction deletion implicitly delete committed evidence?
13. Can a retryable failure accidentally fire a terminal Review callback?
14. Can a save-without-evidence outcome be claimed while Lumen knows retained v1 bytes remain?
15. Are manual entry and historical stores unchanged?
16. Is any unadmitted Phase 1B concept being materialized "while we are here"?

If any answer exposes a contradiction, revise the plan before production implementation.

---

# 28. Exit Criteria for the Plan

This plan is ready for production implementation only after review confirms:

- no unadmitted persistence/schema work;
- locator grammar is accepted;
- UUID semantic ownership strategy is accepted;
- process-wide coordination strategy is accepted;
- source-marker durability dependency is accepted and regression-covered;
- field outcome matrix is accepted;
- retained/save-without/cancel/failure ordering is accepted;
- reconciliation deletion authority is accepted;
- all critical failures are injectable/testable;
- compatibility/reversibility posture is accepted.

After that review, the first production-code implementation pass may begin.

The diagnostic PRs #8 and #9 remain unmerged investigation vehicles. They may be closed after their evidence is represented in accepted canonical documentation.
