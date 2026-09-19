# Phase 1B — Confirmed Evidence Retention v1 Admission

## Status

**ADMITTED — exact persistence proposal authorized for implementation planning.**

- **Decision date:** 2026-09-18
- **Canonical repository baseline reviewed:** `8fd9ffb39237be0925cb280d8d1adfdff3f8210d`
- **Capability:** Confirmed Evidence Retention v1
- **Disposition:** ADMITTED
- **Schema disposition:** Proceed using the current SwiftData schema. No new persisted model, field, relationship, uniqueness constraint, or migration is authorized by this admission.
- **Important qualification:** The admitted `stored_file_uri`, `mime_type`, and `file_size_bytes` behaviors below are persisted-semantic changes even though they require no SwiftData schema change.

This document records the Phase 1B Persistence Admission Review required by:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/architecture/PHASE_1B_EVIDENCE_PROVENANCE_RESPONSIBILITIES.md`
- `docs/architecture/ADR-001-source-of-truth-and-ingestion.md`
- `docs/ROADMAP.md`
- `docs/NON_GOALS.md`

The authority order remains:

**Architecture Contract → Roadmap → Non-Goals → accepted architecture/ADR responsibilities → this exact admission → implementation plan → code/tests.**

Admission applies only to the capability and semantics recorded here. It does not authorize adjacent Phase 1B persistence work.

---

# 1. Exact Capability Reviewed

Confirmed Evidence Retention v1 addresses the current image-upload durability mismatch for the existing PhotosPicker-backed screenshot/receipt path.

Today the active flow can produce:

```text
PhotosPicker selection
        ↓
picker-supplied Data
        ↓
temporaryDirectory file
        ↓
TransactionSource.stored_file_uri = temporary file URL
        ↓
Review
        ↓
Confirm
        ↓
Transaction + TransactionSource become durable
        ↓
temporary raw file may disappear independently
```

The admitted capability changes that behavior for newly confirmed image-backed ingestion:

```text
PhotosPicker selection
        ↓
temporary staged picker-supplied representation
        ↓
TransactionDraft
        ↓
Review
        ↓
explicit user confirmation
        ↓
durably prepare one raw picker-supplied payload
        ↓
persist Transaction + TransactionSource
with recognized v1 retained-evidence locator
        ↓
RETAINED
```

The user may also explicitly confirm the financial Transaction without retaining the raw image, provided the flow truthfully records no retained locator and completes the required evidence cleanup for that outcome.

Manual entry remains independent and evidence-free.

---

# 2. Admission Summary

The following exact behavior is admitted:

1. Use the existing `TransactionSource.id` as the application identity from which v1 retained-evidence identity is derived.
2. Require new v1 retained-evidence identities to be valid UUIDs.
3. Treat UUID equality semantically rather than by arbitrary string spelling.
4. Use canonical UUID serialization for v1 locator and filesystem namespace identity.
5. Preserve historical persisted ID strings exactly; do not normalize or migrate them merely for spelling.
6. Enforce v1 source-identity uniqueness at the application boundary because the current SwiftData schema does not enforce `TransactionSource.id` uniqueness.
7. Evolve `stored_file_uri` for new v1 retained evidence into a recognized, versioned logical locator rather than a physical sandbox path.
8. Retain exactly one raw picker-supplied payload per admitted v1 source identity.
9. Store retained raw evidence in Lumen-owned Application Support storage.
10. Apply Complete file protection to the final retained payload.
11. Leave the retained payload eligible for normal platform-managed Apple backup/restore; do not deliberately mark it excluded from backup.
12. Persist `file_size_bytes` from the actual supplied `Data.count`.
13. Persist `mime_type` only when Lumen can establish the actual supplied representation type from the bytes; do not substitute `supportedContentTypes.first`.
14. Retain the picker-supplied bytes without decode/re-encode normalization.
15. Preserve embedded metadata that remains in the picker-supplied representation; do not interpret GPS, captions, capture metadata, or other image metadata into canonical financial state in v1.
16. Use transient operational states equivalent to STAGED → PREPARED → RETAINED without adding persisted lifecycle columns.
17. For retained-evidence confirmation, keep staging intact until the confirmed ledger write succeeds.
18. The explicit Save Without Retained Evidence path is the v1 exception to rule 17: after required evidence cleanup succeeds, staging may be intentionally removed before the nil-locator ledger write so the no-retained-evidence outcome is truthful.
19. Require idempotent retry behavior and deterministic destination identity.
20. Require process-wide coordination between identity-critical confirmation and destructive reconciliation.
21. Derive runtime evidence availability separately from source/origin and separately from prior commitment.
22. Permit committed retained evidence and its `TransactionSource` commitment marker to outlive their final current `Transaction` association.
23. Do not automatically delete committed retained evidence when the final Transaction reference disappears.
24. Allow automatic destructive reconciliation only for positively identified never-committed v1 material.
25. Correct privacy copy before the capability is considered release-complete.

---

# 3. Empirical Evidence — PhotosPicker Characterization

## 3.1 Diagnostic provenance

Physical-device characterization was performed with the diagnostic-only branch/PR:

- **PR:** #8 — `Diagnostic only: characterize PhotosPicker representations on device`
- **Branch:** `diagnostic/photos-picker-characterization-v1`
- **Head observed for this admission:** `9d03ae8bc42382142a17ec5be345123f4d1ab68f`
- **Base:** canonical main `8fd9ffb39237be0925cb280d8d1adfdff3f8210d`
- **Device OS:** iOS 18.5
- **Transfer request:** `item.loadTransferable(type: Data.self)`
- Picker option values were manually selected by the tester and were not programmatically attested by the app.

PR #8 is diagnostic evidence only and is not a production merge candidate.

Personal source images used for characterization are deliberately not canonical repository evidence and must not be committed to Git.

## 3.2 Key observed reports

### Same camera asset — Location ON — Automatic

```text
scenario=Camera · Location ON · Automatic
ios_version=18.5
transfer_request=item.loadTransferable(type: Data.self)
supported_content_types=public.jpeg,public.heic,com.apple.private.photos.thumbnail.standard,com.apple.private.photos.thumbnail.low
data_byte_count=2187307
decoded_type_identifier=public.jpeg
decoded_extension=jpeg
decoded_mime=image/jpeg
pixel_width=4032
pixel_height=3024
orientation=6
metadata_exif_present=yes
metadata_gps_present=yes
metadata_tiff_present=yes
exif_datetime_original_present=yes
camera_make_field_present=yes
camera_model_field_present=yes
exif_key_count=37
gps_key_count=15
tiff_key_count=9
```

### Same camera asset — Location OFF — Automatic

```text
scenario=Same camera photo · Location OFF · Automatic
ios_version=18.5
transfer_request=item.loadTransferable(type: Data.self)
supported_content_types=public.jpeg,public.heic,com.apple.private.photos.thumbnail.standard,com.apple.private.photos.thumbnail.low
data_byte_count=2186985
decoded_type_identifier=public.jpeg
decoded_extension=jpeg
decoded_mime=image/jpeg
pixel_width=4032
pixel_height=3024
orientation=6
metadata_exif_present=yes
metadata_gps_present=no
metadata_tiff_present=yes
exif_datetime_original_present=yes
camera_make_field_present=yes
camera_model_field_present=yes
exif_key_count=37
gps_key_count=0
tiff_key_count=9
```

### Same camera asset — Location ON — Current

```text
scenario=Same camera photo · Location ON · Current
ios_version=18.5
transfer_request=item.loadTransferable(type: Data.self)
supported_content_types=public.heic,com.apple.private.photos.thumbnail.standard,com.apple.private.photos.thumbnail.low
data_byte_count=1409711
decoded_type_identifier=public.heic
decoded_extension=heic
decoded_mime=image/heic
pixel_width=4032
pixel_height=3024
orientation=6
metadata_exif_present=yes
metadata_gps_present=yes
metadata_tiff_present=yes
caption_or_description_like_metadata_key_present=yes
exif_key_count=34
gps_key_count=7
tiff_key_count=12
```

### Screenshot — Automatic

```text
scenario=Screenshot · Automatic
ios_version=18.5
transfer_request=item.loadTransferable(type: Data.self)
supported_content_types=public.png,com.apple.private.photos.thumbnail.standard,com.apple.private.photos.thumbnail.low
data_byte_count=4525686
decoded_type_identifier=public.png
decoded_extension=png
decoded_mime=image/png
pixel_width=1170
pixel_height=2532
orientation=1
metadata_exif_present=yes
metadata_gps_present=no
metadata_tiff_present=yes
metadata_png_present=yes
caption_or_description_like_metadata_key_present=yes
exif_key_count=4
gps_key_count=0
tiff_key_count=1
png_key_count=1
```

## 3.3 Findings established by the physical test

For the tested iPhone/iOS 18.5/current Lumen transfer path:

- the same camera asset under Automatic arrived as JPEG;
- Current produced a materially different HEIC representation for the tested asset;
- turning the picker Location sharing option off removed the ImageIO GPS dictionary from the representation Lumen received in the controlled same-asset Automatic comparison;
- the screenshot representation contained metadata but no ImageIO GPS dictionary;
- picker-supplied representation metadata can differ from Photos-library asset context.

The experiment does **not** establish a universal platform guarantee that Location OFF removes every possible location-sensitive clue from every representation or OS version.

The admitted product statement is therefore:

> **Lumen retains the image representation supplied by the system Photos picker, including metadata remaining in that representation after the picker's sharing options and representation-format policy have been applied. Phase 1B v1 does not interpret that embedded metadata or promote it into canonical financial state.**

The conflicting manually labeled Most Compatible runs are retained as investigation context but are not authoritative for setting-specific format behavior. V1 is intentionally format-agnostic.

Caption/description-like metadata presence was observed, but the experiment did not establish that the Photos caption itself was transferred. Caption extraction is not part of this admission.

---

# 4. Empirical Evidence — Zero-Reference TransactionSource Survival

## 4.1 Diagnostic provenance

Repository characterization was performed with the diagnostic-only branch/PR:

- **PR:** #9 — `Diagnostic only: characterize zero-reference TransactionSource survival`
- **Branch:** `diagnostic/zero-reference-source-characterization-v1`
- **Final green head:** `5c9a5de1f123f90c6e26dfd5e58f7539fb9c7f99`
- **Base:** canonical main `8fd9ffb39237be0925cb280d8d1adfdff3f8210d`
- **Successful workflow run:** `35350279923`
- **Runner environment observed:** macOS 26.6.2, Xcode 26.6, iOS Simulator SDK/runtime 26.5, iPhone 16 Pro simulator.

PR #9 is diagnostic evidence only and is not a production merge candidate.

## 4.2 Final observed result

```text
LUMEN_PHASE1B_ZERO_REF shared_reopened_transactions=0 shared_reopened_sources=1
LUMEN_PHASE1B_ZERO_REF unique_same_context_sources=1
LUMEN_PHASE1B_ZERO_REF unique_reopened_transactions=0 unique_reopened_sources=1

Executed 2 tests, with 0 failures
TEST SUCCEEDED
```

The strengthened tests characterized both:

```text
UNIQUE
T1 → S
save/reopen
delete T1
save/reopen
→ Transactions = 0
→ TransactionSources = 1
```

and:

```text
SHARED
T1 ─┐
    ├→ S
T2 ─┘
delete T1
save/reopen
delete T2
save/reopen
→ Transactions = 0
→ TransactionSources = 1
```

After the final reference disappeared and the store reopened, the test directly fetched the surviving source and verified its persisted compatibility-bearing state, including:

- `id`;
- `stored_file_uri`;
- `source_type`;
- `original_filename`;
- `mime_type`;
- `file_size_bytes`;
- `compressed_file_uri`;
- upload/capture timestamps;
- source timezone;
- `metadata_json`;
- `raw_extracted_text`;
- `parse_status`;
- the intentionally non-cryptographic `source_hash`;
- `created_at`.

The architectural conclusion is narrowly:

> **Under Lumen's current persisted model and tested persistence path, a committed TransactionSource survives removal of its final Transaction reference across durable save and store reopen while preserving the tested persisted state.**

This is a tested Lumen-model behavior, not a general claim that SwiftData universally guarantees the same relationship behavior under all future model configurations.

If production recovery depends on this behavior, the implementation must add a permanent regression test.

---

# 5. Four Independent Runtime Questions

Confirmed Evidence Retention v1 must keep four questions independent.

## 5.1 Identity integrity

Does exactly one authoritative persisted source semantically own UUID S?

## 5.2 Commitment

Did a valid v1 retained-evidence association cross the durable ledger commit boundary at some prior point?

## 5.3 Current association

Which current Transactions, if any, reference that source?

## 5.4 Availability

Can the expected retained payload currently be resolved and read?

Therefore:

```text
valid locator                 ≠ file exists
file exists                   ≠ committed
committed source              ≠ available payload
zero Transaction references   ≠ never committed
UUID-shaped string            ≠ unambiguous namespace ownership
```

A recognized valid v1 source is a commitment marker only under the production invariant defined below.

---

# 6. Stable Identity and Commitment Rules

The following seven rules are frozen for this admitted capability.

1. **New v1 retained identities must be valid UUIDs.**
2. **Historical persisted ID strings are never rewritten merely for normalization.**
3. **Locator and filesystem identity use canonical UUID serialization.**
4. **Identity equality uses UUID semantics, not raw-string equality.**
5. **Exactly one persisted source may authoritatively own a v1 UUID namespace; ambiguity fails closed.**
6. **First-commit operations are serialized process-wide by canonical UUID and revalidate authoritative ownership immediately before ledger persistence.**
7. **Destructive reconciliation uses the same canonical-UUID coordination authority and revalidates its cleanup candidate while holding that authority.**

The current SwiftData model does **not** declare `TransactionSource.id` as a schema-enforced unique attribute. UUID generation is currently an application convention.

Therefore:

> **TransactionSource.id uniqueness for v1 is an application invariant, not a database uniqueness guarantee.**

Semantic-owner lookup must actually use UUID semantics. A raw predicate equivalent to `id == canonicalUUIDString` is insufficient if a persisted valid UUID string could use a different case/spelling.

Historical non-UUID source IDs remain valid compatibility state. They are not migrated, normalized, or automatically promoted into the v1 retained-evidence namespace.

## 6.1 Commitment-marker durability condition

A recognized v1 retained-evidence locator may first become durable on a `TransactionSource` **only through the confirmed ledger write that first establishes the corresponding canonical Transaction association**.

After successful commitment, the source may outlive its current Transaction associations without losing its historical commitment meaning.

Additionally:

> **A successfully committed v1 TransactionSource is the durable commitment marker for that namespace and is not independently deleted by Confirmed Evidence Retention v1. Any future capability that deletes committed source records must revisit this reconciliation contract before shipping.**

This condition is what permits zero-owner v1 filesystem material to be classified as potentially never committed.

---

# 7. Logical Locator Semantics

New retained v1 evidence may use a versioned logical locator in this semantic family:

```text
lumen-evidence://v1/<canonical-source-uuid>/payload
```

The exact parser/serializer grammar must be frozen by the implementation plan before production code.

Required semantics:

```text
stored_file_uri == nil
→ no retained-evidence locator is recorded

recognized supported v1 locator
→ intended v1 retained-evidence association

legacy/other historical value
→ opaque compatibility state
→ preserve unchanged

malformed v1 locator
→ invalid / unavailable
→ fail closed

unsupported future version
→ unsupported
→ fail closed

locator UUID != owning source UUID
→ invalid association
→ fail closed
```

Parser failure must never fall through to arbitrary filesystem-path interpretation.

Physical paths are constructed by Lumen from validated semantic identity; arbitrary locator path components are never appended directly to the filesystem root.

---

# 8. Actual Supplied Representation Semantics

For newly ingested v1 image evidence:

> **Advertised picker capabilities describe what may be supplied; persisted evidence metadata describes what was actually supplied.**

Therefore:

- `file_size_bytes` is the actual supplied `Data.count`;
- `mime_type` describes the actual supplied bytes when type identification is confidently available;
- if the bytes are a valid admitted image but a MIME/UTType mapping cannot be established confidently, `mime_type` may remain nil;
- `supportedContentTypes.first` must not be used as a substitute for actual-byte characterization;
- valid raw bytes must not be decode/re-encoded merely to normalize format.

Historical `mime_type` and `file_size_bytes` values are not backfilled, normalized, or reinterpreted.

These fields describe ingestion representation context, not current attachment availability.

For example, this is coherent:

```text
source_type       = receipt_photo
mime_type         = image/jpeg
file_size_bytes   = 2187307
stored_file_uri   = nil
```

It means a JPEG representation of that size participated in ingestion but no retained-evidence locator is recorded. It does **not** assert that an attachment currently exists.

---

# 9. Physical Retention Policy

For this exact v1 capability:

- retain one raw picker-supplied payload;
- use Lumen-owned Application Support storage;
- do not use `temporaryDirectory` as the durable locator target;
- use Complete file protection for the final retained payload;
- do not add custom encryption;
- do not deliberately exclude the retained payload from normal platform-managed backup/restore participation;
- do not claim that any specific Apple backup has actually occurred;
- do not require a filename extension for physical identity;
- do not generate a thumbnail, compressed derivative, normalized JPEG, OCR sidecar, or metadata sidecar.

The admitted cardinality is:

```text
one v1 source identity
→ zero or one retained raw picker-supplied payload
```

This does not redefine the future conceptual evidence cardinality.

---

# 10. Operational Lifecycle

STAGED, PREPARED, and RETAINED are operational meanings, not persisted SwiftData statuses.

## STAGED

The picker-supplied representation is held in temporary ingestion storage and remains owned by the active draft/session.

## PREPARED

A complete durable payload exists in Lumen-controlled durable storage, but the confirmed ledger association has not yet committed.

## RETAINED

The confirmed ledger write succeeds with the recognized v1 locator-bearing `TransactionSource`.

Filesystem existence alone never establishes RETAINED state.

The admitted crash-safety preference is:

> **A complete but unreferenced prepared payload is safer than a committed locator whose payload was never successfully established.**

Therefore the retained-evidence confirmation path must place a complete final payload before the ledger commit and preserve staging until that ledger commit succeeds.

The explicit **Save Without Retained Evidence** path is intentionally different. Once that user-authorized path has established zero committed owners and successfully removed all known evidence for the active session, including staging, it may perform the financial ledger write with `stored_file_uri == nil`. If that later ledger write fails, the financial draft remains retryable but retained-evidence confirmation is no longer retryable because the user already authorized destruction of the staged evidence.

---

# 11. Failure and Recovery Semantics

## 11.1 Pre-commit integrity failure

Before successful ledger commitment:

```text
identity ambiguity / invalid association / failed revalidation
→ abort confirmation
→ no canonical Transaction
→ Review remains active
→ staging remains retryable
→ no destructive evidence mutation based on ambiguous state
```

## 11.2 Post-commit integrity failure

If the durable ledger write has already succeeded and a subsequent verification finds an unexpected evidence integrity problem:

```text
canonical Transaction
→ remains committed

retained bytes
→ remain

evidence subsystem
→ fails closed
→ exposes an internal identity/integrity conflict
→ prohibits destructive evidence mutation
→ does not automatically roll back or repair the financial Transaction
```

Evidence-subsystem failure must degrade attachment functionality, not canonical-ledger readability or editability.

## 11.3 Evidence retention failure

Retention failure must not be presented as successful retention.

The Review flow must remain retryable and may offer an explicit user-authorized path to save the financial Transaction without retained evidence.

A completed "save without retained evidence" outcome must truthfully record no retained locator.

## 11.4 Financial write failure

A failed durable Transaction write must never be presented as a successful canonical save, but retry semantics depend on which user-authorized path was active.

### Retained-evidence confirmation

If the retained-confirmation ledger write fails:

- no canonical Transaction may be presented as saved;
- the financial draft remains retryable;
- staging remains available so retained confirmation may be retried;
- prepared/final uncommitted evidence is cleaned where safely possible;
- failed cleanup becomes conservative reconciliation work, not proof of user-visible retention.

### Save Without Retained Evidence

If the user explicitly chose Save Without Retained Evidence, required evidence cleanup succeeds, staging is intentionally removed, and the subsequent nil-locator ledger write fails:

- no canonical Transaction may be presented as saved;
- the financial draft remains retryable;
- staged evidence is intentionally absent;
- the user may retry the financial save-without-evidence operation;
- retained-evidence confirmation is no longer available for that draft/session;
- Lumen must not imply that the destroyed staging can be restored.

---

# 12. Reconciliation Authority

The reconciler may discover broadly, but it may destroy narrowly.

> **The reconciler destroys only positively identified never-committed v1 material. Inability to establish valid commitment is not, by itself, permission to delete.**

For canonical UUID S, destructive cleanup requires:

- material is positively recognized as belonging to the v1 evidence namespace;
- authoritative ledger state is available;
- the semantic ownership calculation shows zero persisted source owners for S;
- the reconciler acquires the same process-wide coordination authority used by confirmation for S;
- ownership and candidate assumptions are freshly re-read/revalidated while that authority is held;
- no committed v1 source marker has been independently deleted by this capability.

Examples:

```text
recognized v1 preparation S
+ ledger readable
+ 0 semantic owners
+ coordination acquired
+ fresh recheck still 0
→ eligible for conservative cleanup
```

Whereas:

```text
one authoritative committed owner
duplicate UUID owners
legacy source
nil/malformed/unsupported locator
source/locator UUID mismatch
ledger unavailable
active identity-critical operation
uncertain state
→ retain / skip
→ no destructive automated action
```

**Ambiguity reduces authority; it does not increase it.**

Confirmation and destructive reconciliation must share the same process-wide coordination authority so reconciliation cannot delete a payload in the pre-commit window between durable finalization and ledger commitment.

The admitted v1 concurrency model assumes one Lumen process owns creation and destructive reconciliation of v1 evidence. A future app extension, independent background writer, sync engine, or second process that can mutate the same evidence/SwiftData state is an architecture trigger requiring this coordination strategy to be revisited.

---

# 13. Runtime Availability Semantics

Availability is derived at runtime and does not require a new persisted status field.

The implementation may use states equivalent to:

- no evidence expected;
- no retained locator recorded;
- available;
- expected but unavailable;
- legacy/opaque locator;
- unsupported version;
- invalid locator;
- invalid source/locator association;
- identity-integrity conflict.

The exact Swift enum names are implementation details.

The important distinction is:

```text
expectedButUnavailable
→ ownership/commitment is unambiguous
→ expected payload cannot currently be read

identityConflict
→ authoritative namespace ownership cannot be established
→ evidence mutation/destructive reconciliation prohibited
```

Views must not infer attachment availability merely from `source_type`, `mime_type`, `file_size_bytes`, or non-nil source existence.

---

# 14. Retention and Deletion Policy

Confirmed Evidence Retention v1 deliberately separates:

- temporary/session cleanup;
- never-committed v1 orphan cleanup;
- deletion of committed retained evidence.

Automatic cleanup is admitted for:

- cancelled staging;
- discarded staging;
- incomplete preparation;
- failed-confirmation preparation;
- positively identified crash-before-commit v1 material;
- other positively identified never-committed v1 material under the reconciliation rules above.

Automatic deletion is **not** admitted merely because the final current Transaction reference disappears.

A committed source and evidence payload may therefore become:

```text
previously committed
+
zero current Transaction references
+
still retained
```

This is an intentional v1 consequence.

> **Transaction deletion does not imply evidence deletion in Confirmed Evidence Retention v1.**

User-directed management/deletion of committed-but-unreferenced evidence is a separate capability, naturally related to later ownership/data-management work.

---

# 15. TransactionSource Compatibility Rules

`TransactionSource` remains a compatibility-bearing mixed-responsibility model.

Confirmed Evidence Retention v1 does not rename or replace it.

For new v1 image-backed ingestion:

- `source_type` continues to describe origin;
- `stored_file_uri` records the retained locator only after the confirmed retained association commits;
- `mime_type` and `file_size_bytes` describe the supplied ingestion representation when established;
- all fields not explicitly changed by this admission preserve their current semantics;
- `compressed_file_uri` is not repurposed and remains unused by this capability;
- `source_hash` is not assigned cryptographic/content-fingerprint meaning;
- historical source rows and historical locator strings remain unchanged;
- historical non-UUID IDs remain compatibility state;
- manual entry remains allowed to have no source.

No `EvidenceArtifact @Model` is authorized.

---

# 16. Privacy and Sensitive Metadata

The retained raw representation may include sensitive embedded metadata, including GPS, capture timestamps, camera/device information, description-like metadata, or incidental private image content.

V1 does not:

- parse GPS into canonical transaction location;
- infer semantic places;
- parse Photos captions;
- claim Location OFF produces universally sanitized metadata;
- strip/re-encode the retained image merely to remove metadata;
- create structured geolocation state;
- upload evidence to a Lumen-operated cloud;
- contribute evidence or derived private information to shared learning.

The physical characterization supports only claims about the tested iOS 18.5 path.

---

# 17. Privacy Copy Release Requirement

Current Settings copy states:

> "Data stays on this device."

That becomes too absolute once retained Application Support evidence intentionally participates in normal platform-managed Apple backup/restore behavior.

Production implementation may begin before the copy is finalized, but Confirmed Evidence Retention v1 is **not release-complete** until the privacy language accurately conveys both:

1. Lumen stores its financial data locally and does not require a Lumen-operated cloud service.
2. Platform-managed Apple backup/restore may include Lumen data according to device/platform backup settings.

Candidate semantic wording:

> **Lumen stores your financial data locally and does not require a Lumen-operated cloud service. Your device's backup settings may include Lumen data in platform-managed Apple backups.**

Exact UI wording may be polished while preserving those facts.

---

# 18. Phase 1B Persistence Admission Review Answers

## 18.1 What exact capability are we implementing?

Durable retention of one raw picker-supplied image representation for the current screenshot/receipt ingestion path after user confirmation, with honest runtime availability and conservative cleanup.

## 18.2 What current-model limitation blocks that capability safely?

Durable `TransactionSource` metadata currently points to a temporary raw file that may disappear independently.

## 18.3 What durable responsibility is required?

An intentional retained-evidence association, stable application identity, logical locator, and raw payload lifecycle.

## 18.4 Why can the required state not remain transient?

The retained artifact must remain available after app relaunch and must distinguish committed evidence from temporary ingestion material.

## 18.5 What gives the state stable identity?

The existing `TransactionSource.id`, constrained by v1 to parse as a UUID and enforced as an application-level semantically unique identity.

## 18.6 What is its lifecycle?

STAGED → PREPARED → RETAINED, with explicit cancellation, retry, failure, and conservative reconciliation behavior.

## 18.7 What are its retention and deletion semantics?

Committed evidence may outlive Transactions. V1 cleans positively identified never-committed material but does not independently delete committed source markers or committed retained payloads.

## 18.8 What sensitive information can it contain?

The raw image may contain financial content, incidental image content, filenames/context, embedded timestamps, GPS, camera metadata, and other image metadata.

## 18.9 What relationship cardinality does this exact capability require now?

No relationship expansion. Current Transaction → zero/one source remains. Existing one-source-to-many-Transactions behavior is preserved. One v1 source retains zero/one raw payload.

## 18.10 What survives raw-evidence deletion?

This capability does not yet define user-directed deletion of committed raw evidence. Canonical Transactions are independent of evidence availability. Historical/source context survives according to existing persisted fields and future admitted deletion policy.

## 18.11 What happens when processing fails?

No OCR/extraction is introduced. Existing preview/stub processing may fail without creating canonical financial state; manual entry remains independently usable.

## 18.12 What happens when persistence/cleanup partially fails?

Retained-confirmation pre-commit failures preserve retryable draft/staging state and avoid false success. Save Without Retained Evidence follows its explicitly admitted exception: after successful user-authorized evidence cleanup, a subsequent financial write failure preserves the financial draft but not staging. Post-commit integrity failures preserve canonical ledger state and bytes while evidence operations fail closed. Cleanup uncertainty defaults to retention.

## 18.13 Does evidence-free manual entry continue to work independently?

Yes. No evidence model or retention subsystem is required for manual entry.

## 18.14 How is current/historical TransactionSource state interpreted?

Historical values remain compatibility state. Legacy locator strings are opaque. `source_hash` is not reinterpreted. Non-UUID historical IDs remain untouched. New v1 semantics apply only to recognized v1 locators/identities.

## 18.15 What migration is required?

No SwiftData schema migration is required or authorized. Persisted-semantic changes are explicitly limited to new v1 values of `stored_file_uri`, `mime_type`, and `file_size_bytes`.

## 18.16 How will authentic existing-store compatibility be validated?

The existing Phase 1A authentic historical-store compatibility workflow remains required to stay green for any production implementation. New v1 tests must additionally prove legacy values are unchanged and unresolved as v1.

## 18.17 What automated tests prove the behavior?

The implementation plan must include locator, identity, actual-byte metadata, storage, file protection, backup-eligibility, confirmation ordering, failure injection, retry/concurrency, reconciliation, zero-reference regression, legacy compatibility, manual-entry regression, save-without-evidence, and UI availability-state tests.

## 18.18 What rollback/recovery strategy exists if the change fails in production?

Evidence failure must degrade attachment functionality only. Canonical Transactions continue to load/edit. Unsupported/broken locators fail closed. Raw files are retained when authority is uncertain. No automatic ledger reset, destructive evidence repair, or historical locator rewrite is permitted.

---

# 19. Explicitly Not Admitted

This admission does **not** authorize:

- a new `EvidenceArtifact @Model`;
- an `Observation` persisted model;
- an `ExtractionRun` persisted model;
- `FieldCandidate` persistence;
- `ValidationSignal` persistence;
- `Resolution` or `ResolvedField` persistence;
- `CorrectionEvent` persistence;
- field-level provenance tables;
- many-to-many evidence relationships;
- `@Attribute(.unique)` on `TransactionSource.id`;
- any other SwiftData schema change;
- reinterpretation, recomputation, normalization, migration, or backfill of `source_hash`;
- SHA/HMAC/content hashing or evidence deduplication;
- OCR;
- Photos-caption extraction;
- GPS/location interpretation;
- semantic-place resolution;
- image normalization/re-encoding;
- thumbnail/compressed derivative generation;
- use of `compressed_file_uri` for this feature;
- cloud evidence storage;
- custom encryption;
- cross-process locking;
- app-extension/background independent writers;
- user-directed committed-evidence deletion UI;
- automatic deletion of committed evidence when a Transaction is deleted;
- automatic migration/normalization of historical source IDs or locators.

Adjacent capability work requires separate admission when persistence semantics are involved.

---

# 20. Release Acceptance Conditions

Confirmed Evidence Retention v1 is not release-complete until all of the following are demonstrated:

- current image selection reaches Review without canonical persistence;
- retained confirmation survives force-close/relaunch with readable evidence;
- cancel/discard performs explicit staging cleanup and cleans any known never-committed final/incoming v1 material only under canonical-UUID coordination with a fresh zero-owner validation;
- failed retention remains retryable;
- explicit save-without-evidence requires zero committed owners before destructive cleanup, produces no retained locator, and does not falsely claim retained evidence;
- retained-confirmation ledger failure leaves no canonical Transaction, preserves the financial draft, and preserves staging for retained retry;
- save-without-evidence ledger failure after successful evidence cleanup leaves no canonical Transaction, preserves the financial draft, keeps evidence intentionally absent, and does not offer retained-evidence retry for that session;
- retries converge on one logical source/payload and do not trust a pre-existing zero-owner final payload as proof of correctness;
- repeated/concurrent confirmation cannot create duplicate committed v1 identities;
- semantic UUID duplicate owners fail closed;
- case-varied UUID duplicate owners fail closed;
- source UUID / locator UUID mismatch fails closed;
- malformed/unsupported locators never fall back to arbitrary filesystem paths;
- final payload uses Complete protection;
- final payload is not deliberately marked excluded from platform-managed backup;
- missing/unreadable payload degrades to unavailable without changing the Transaction;
- identity conflict is distinguishable internally from ordinary unavailable evidence;
- post-commit evidence integrity conflict is terminal for financial confirmation and cannot permit a second Transaction submission for the same draft/session;
- reconciler cannot delete a payload while confirmation for the same identity is active;
- reconciler refuses destructive action when ledger state is unavailable or ambiguous;
- committed zero-reference source survival is protected by a permanent regression test;
- committed v1 source rows are not independently deleted by this capability;
- historical source/locator/hash values remain unchanged;
- manual entry remains evidence-free and fully usable;
- authentic existing-store compatibility remains green;
- privacy copy no longer makes the unqualified "Data stays on this device" claim and accurately discloses local storage plus possible platform-managed Apple backup/restore participation.

---

# 21. Known v1 Consequences and Deferred Questions

The following are intentionally not solved by this admission:

- committed-but-unreferenced evidence may accumulate because conservative v1 retention does not automatically delete it;
- user-visible management/deletion of such evidence remains a later capability;
- Photos captions have not been characterized sufficiently for extraction;
- no content fingerprint is defined;
- no cross-process identity/concurrency mechanism exists;
- future many-to-many evidence may require a new persistence design;
- remote/cloud evidence handling remains out of scope;
- detailed evidence portability/export belongs to later ownership/data-management work;
- the current `TransactionSource` remains a mixed compatibility-bearing model rather than a final conceptual evidence schema.

These are not defects that authorize scope expansion inside Confirmed Evidence Retention v1.

---

# 22. Final Disposition

**Confirmed Evidence Retention v1 — ADMITTED.**

The current SwiftData schema is sufficient for the exact admitted capability provided the production implementation enforces the identity, commitment, coordination, recovery, and compatibility rules in this document.

The next required artifact is the separate plan-only implementation design.

Production code should not begin until that plan receives engineering review against this admission.

Diagnostic PRs #8 and #9 must remain unmerged. After the evidence in this document is accepted into canonical `main`, those investigation PRs may be closed without merging.
