# Phase 1B — Evidence & Provenance Responsibilities

## Status

**Accepted. Documentation-only Phase 1B responsibility contract.**

This document defines the responsibility boundaries Phase 1B should preserve before Lumen introduces new evidence/provenance persistence.

It is subordinate to:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/architecture/ADR-001-source-of-truth-and-ingestion.md`
- `docs/ROADMAP.md`
- `docs/NON_GOALS.md`

If this document conflicts with those governing sources, the higher-authority source wins.

**The responsibility contract itself does not authorize a SwiftData/schema change.**

The conceptual entities and responsibility names in this document are not instructions to create one persisted model per noun.

**Capitalized conceptual names in this contract identify responsibilities or information boundaries. They do not imply one Swift type, SwiftData model, table, or durable record per concept.**

This document deliberately distinguishes three categories:

1. **Repository findings** — factual observations about current Lumen behavior and persisted structure.
2. **Phase 1B principles** — responsibility boundaries that should govern the phase.
3. **Open design questions** — decisions that remain unresolved and must not be mistaken for approved implementation.

---

# 1. Governing Statements

Phase 1B is governed by the following statements.

> **Phase 1B may enrich what Lumen knows about the origin and interpretation of financial information without weakening user confirmation as the boundary for canonical financial state.**

> **Evidence architecture remains optional to canonical ledger use; manual input continues independently through `TransactionDraft → Review → Confirm → Transaction`.**

> **A cleaner conceptual model is not sufficient justification for a persisted-model migration.**

> **The responsibility contract itself does not authorize a SwiftData/schema change.**

Additional Phase 1B principles established by repository observation:

- **Source/origin context and evidence-artifact identity are distinct responsibilities.**
- **Ingestion-session, evidence, processing, and canonical-transaction lifecycles are distinct even where the current prototype stores pieces of them together.**
- **Durable metadata must not be mistaken for durable evidence retention.**
- **Processing responsibilities may be conceptually separate without yet being persistently separate.**
- **Conceptual durability and persistence durability are not the same thing.**
- **Legacy fields retain their demonstrated compatibility meaning until a migration is explicitly justified and validated.**

---

# 2. Canonical Financial State Remains a User-Authorization Boundary

This document uses the existing phrase **canonical financial state** consistently with the Architecture Contract and ADR-001.

A confirmed `Transaction` is Lumen's current user-authorized ledger state. It is not an assertion that the record can never later be corrected.

A legitimate later edit may change canonical state through the existing edit boundary:

```text
Existing Transaction
        ↓
User-authorized edit
        ↓
Validation
        ↓
Durable save
        ↓
Updated Transaction
```

Confirmation establishes authority for the current ledger state; it does not make that state immutable or objectively infallible forever.

---

# 3. Canonicalization Paths

## 3.1 Evidence-assisted input

The evidence-assisted conceptual path is:

```text
EvidenceArtifact
What evidence was provided?
        ↓
Observation
What did a particular process or user report from that evidence?
        ↓
FieldCandidate
What financial interpretation might that observation support?
        ↓
Resolution
Which interpretation was selected, rejected, or preferred, and why?
        ↓
TransactionDraft
What financial state is proposed?
        ↓
Review
Meaningful opportunity to inspect or change the proposal
        ↓
Confirm
Explicit user authorization
        ↓
Transaction
Canonical user-authorized financial state after durable persistence
```

**Resolution is not confirmation.**

A resolver may be highly confident that a receipt total is `$19.99`; that still produces a proposal. Canonical financial state is established only after Review, explicit confirmation, and successful durable persistence.

## 3.2 Manual input

Manual entry remains a parallel first-class path:

```text
Manual input
        ↓
TransactionDraft
        ↓
Review
        ↓
Confirm
        ↓
Transaction
```

Manual entry must not be forced through an artificial `EvidenceArtifact`, `Observation`, extraction run, or machine-confidence abstraction.

## 3.3 User assertion about evidence vs ordinary manual input

A user may make an observation **about evidence**:

```text
Receipt image
        ↓
User indicates: "That says $19.99"
        ↓
Evidence-linked Observation
```

That is distinct from ordinary manual financial entry:

```text
Blank transaction form
        ↓
User types $19.99
        ↓
TransactionDraft
```

`Observation` must not become a universal bucket for every value a human enters.

---

# 4. Repository Baseline for This Responsibility Contract

This contract is grounded in repository behavior observed at canonical main commit:

`284590911989baa15bdf61efac61c2de137b9f0c`

The audit covered, at minimum:

- `Models/Models.swift`
- `Models/Enums.swift`
- `Models/FutureModels.swift`
- `Data/LedgerStore.swift`
- `Data/LedgerWrite.swift`
- `Data/Analytics.swift`
- `Data/TransactionSearch.swift`
- `Data/Seed.swift`
- `Views/ManualEntryView.swift`
- `Views/UploadView.swift`
- `Views/ReviewTransactionView.swift`
- `Views/TransactionForm.swift`
- `Views/TransactionDetailView.swift`
- current unit/persistence/UI compatibility tests relevant to source and transaction behavior.

This section records facts about the current implementation. It does not authorize changing them.

---

# 5. Repository-Grounded Findings

The Phase 1B read-only audit established the following.

1. `TransactionSource` is a **compatibility-bearing, mixed-responsibility prototype model**.
2. Source/origin classification and evidence-artifact identity are already semantically distinct.
3. Pre-confirm transaction/source **model state is non-durable**; confirmation is the current durable database boundary. Raw ingestion content may already exist temporarily before confirmation.
4. Manual Entry is genuinely evidence-free and must remain so.
5. Historical manual transactions may contain `TransactionSource`, so `TransactionSource` cannot simply mean "evidence artifact."
6. Durable source metadata can currently reference ephemeral raw content; **durable evidence retention is not established**.
7. `raw_extracted_text` and `parse_status` flatten processing concerns into `TransactionSource`; their future persistence semantics remain unresolved.
8. `source_hash` has no established cryptographic or content-fingerprint semantics.
9. Current relationship shape is `Transaction → 0..1 TransactionSource`, while one source can already be referenced by multiple transactions.
10. Cancel/discard avoids durable financial/source rows but does not explicitly clean temporary raw content.
11. Later transaction edits preserve source state but do not preserve field-level correction/edit provenance.
12. Transaction deletion and evidence/source retention are separate, currently unresolved lifecycle policies.
13. Structured location is not currently extracted; location retained inside raw selected image bytes is uncharacterized.
14. No repository evidence from this audit, by itself, justifies a schema migration.

---

# 6. `TransactionSource` Responsibility Decomposition

The Architecture Contract names `EvidenceArtifact` as the canonical evidence responsibility while retaining `TransactionSource` as the current implementation name. The repository audit shows that the legacy/current `TransactionSource` object carries more than one responsibility.

This document does **not** overturn the Architecture Contract. It refines how the current object should be interpreted:

> The evidence-artifact responsibility is one responsibility currently carried by `TransactionSource`; not every historical `TransactionSource` row is therefore semantically equivalent to an evidence artifact.

Historical `.manual_entry` source records are the clearest compatibility example.

The current fields decompose as follows.

| Current field / behavior | Current observed role | Phase 1B responsibility reading | Persistence decision |
| --- | --- | --- | --- |
| `id` | Random UUID-string model identity | Stable application identity | Existing durability preserved; future owner unresolved |
| `source_type` | Ingestion/origin classification | Origin context, sometimes artifact kind | Existing durability preserved; future decomposition unresolved |
| `original_filename` | File metadata | Evidence metadata | Future retention/privacy unresolved |
| `stored_file_uri` | Storage locator | Evidence-storage reference | Current durability mismatch requires explicit future policy |
| `compressed_file_uri` | Planned alternate locator | Evidence-storage/derivative reference | Unresolved / currently weakly exercised |
| `file_size_bytes` | Byte-size metadata | Evidence metadata | Future persistence likely low-risk but not authorized here |
| `mime_type` | File type metadata | Evidence metadata | Future persistence not decided here |
| `uploaded_at` | Ingestion timestamp | Origin/evidence lifecycle metadata | Distinct from financial transaction date |
| `captured_at` | Intended capture timestamp | Evidence metadata | Current active photo flow leaves nil; semantics unresolved |
| `source_timezone` | Current upload stores device timezone | Origin/evidence metadata | Must not be assumed to be artifact-native timezone |
| `metadata_json` | Opaque arbitrary metadata | Potential evidence metadata / processing payload | Sensitive and semantically undefined; no automatic retention assumption |
| `raw_extracted_text` | Text-like extraction/stub output | Processing / Observation responsibility | Persistence and retention unresolved |
| `parse_status` | Processing state | Processing-lifecycle responsibility | Persistence and retention unresolved |
| `source_hash` | Legacy optional string | No established content-identity contract | Must not be reinterpreted silently |
| `created_at` | Source-row creation timestamp | Lifecycle metadata | Existing compatibility preserved |
| `Transaction.confidence_score` | Legacy machine confidence on Transaction | Legacy machine-state compatibility | New confirmed transactions do not newly inherit draft confidence |
| `Transaction.duplicate_fingerprint` | Financial-event duplicate marker | Transaction-similarity responsibility | Explicitly separate from evidence/content identity |
| `Transaction.source` | Optional to-one relation from transaction | Compatibility-bearing origin/evidence association | Future cardinality unresolved |

Conceptual reassignment or separation never means "migrate this field in SwiftData now."

---

# 7. Origin Context Is Not Evidence Identity

Phase 1B must preserve the distinction between:

## Origin context

Answers:

> How did this transaction-bearing flow begin?

Examples:

- manual entry;
- receipt-photo ingestion;
- screenshot ingestion;
- CSV import;
- JSON import;
- future supported import channels.

## Evidence artifact responsibility

Answers:

> What user-provided or imported artifact exists that may support interpretation, review, audit, or reprocessing?

Examples:

- receipt image;
- screenshot;
- CSV file;
- JSON file;
- paystub file;
- future user-provided document.

The relationship is not implication in either direction.

A manual transaction may have origin context and no evidence artifact.

A structured or image ingestion flow may have both origin context and one or more evidence artifacts.

Therefore Phase 1B must not assume:

```text
origin == evidence
```

and must not use a terminology-only `TransactionSource → EvidenceArtifact` rename to conceal the distinction.

---

# 8. EvidenceArtifact Responsibility

`EvidenceArtifact` is a conceptual responsibility defined by the Architecture Contract.

It answers:

> What evidence did the user provide or import?

The responsibility may eventually include some subset of:

- stable Lumen artifact identity;
- artifact kind;
- file/media metadata;
- storage reference;
- import/capture context;
- retention state;
- integrity/content-identity metadata where justified;
- association to one or more ingestion sessions or financial records.

An `EvidenceArtifact` responsibility does **not** imply:

- every Transaction has evidence;
- raw evidence is retained forever;
- one artifact maps to exactly one Transaction;
- a new SwiftData model must be introduced immediately;
- current `TransactionSource` rows should be blindly migrated or renamed.

---

# 9. Observation and Processing-Run Responsibilities

## 9.1 Observation

An `Observation` is:

> A traceable assertion about evidence produced by a user, metadata reader, deterministic parser, OCR process, or other extractor before financial-domain interpretation.

An Observation is not canonical financial truth.

Conceptually useful attributes may include:

- observed/reported value;
- observation kind;
- source artifact;
- producing user/process;
- producing run/version where relevant;
- region/range/location within the artifact where useful;
- confidence or quality signal where meaningful.

These are responsibility examples, not a persistence schema.

### Observations belong to their producing process/run

If extraction is performed twice:

```text
OCR run A
→ "$17.99"

OCR run B
→ "$19.99"
```

run B does not rewrite history to claim run A reported `$19.99`.

Resolution may prefer run B. Whether either run or Observation is durably persisted is a separate admission decision.

## 9.2 ExtractionRun

An `ExtractionRun` is the conceptual execution context for a particular processing attempt over evidence.

It answers questions such as:

> Which process produced these Observations, under what processing configuration/version, and as part of which attempt?

A future run responsibility may group:

- the evidence/artifact processed;
- processing method or provider;
- provider/model/parser version where relevant;
- start/completion/failure state;
- run-level error context;
- produced Observations;
- processing configuration needed for meaningful reprocessing or audit.

Those examples do not authorize a persisted `ExtractionRun` model.

Current Lumen has no explicit processing-run identity/history; processing output such as `raw_extracted_text` and `parse_status` is flattened onto `TransactionSource`.

Phase 1B therefore needs the responsibility boundary, not necessarily durable run history.

---

# 10. FieldCandidate Responsibility

A `FieldCandidate` answers:

> What financial-domain interpretation might one or more observations support?

Examples:

```text
Observation: text "$19.99" near TOTAL
        ↓
FieldCandidate: transaction amount = 19.99 USD
```

or:

```text
Observation: merchant text "WM SUPCTR"
        ↓
FieldCandidate: merchant = Walmart
```

Candidate state remains upstream of canonical Transaction state.

Candidate persistence is not authorized by this document.

---

# 11. Resolution, ValidationSignal, and ResolvedField Responsibilities

## 11.1 Resolution

`Resolution` answers:

> Why was one candidate selected, rejected, or preferred relative to alternatives?

Resolution may use:

- deterministic validation;
- candidate agreement;
- provider confidence;
- layout evidence;
- merchant knowledge;
- user choice;
- explicit review interaction;
- future validation signals.

Most importantly:

> **Resolution prepares a proposal; it does not replace Review/Confirm.**

## 11.2 ValidationSignal

A `ValidationSignal` is conceptual evidence used to support, reject, rank, or qualify a candidate or interpretation.

Examples may include:

- subtotal + tax approximately equals total;
- date parses to a supported civil date;
- text near a TOTAL anchor supports an amount candidate;
- multiple extraction methods agree;
- a merchant alias deterministically resolves;
- a candidate conflicts with another deterministic constraint.

A ValidationSignal does not establish canonical financial state and does not automatically deserve persistence.

## 11.3 ResolvedField

A `ResolvedField` is the conceptual result of field-level resolution before the financial proposal is adopted as canonical state.

It may answer:

> Which candidate/value is currently preferred for this proposed field, and what resolution context supports that choice?

**`Resolution` is the decision process/context; `ResolvedField` is the resulting preferred field-level interpretation produced by that resolution.**

A ResolvedField remains upstream of `TransactionDraft → Review → Confirm`.

This document does not require one persisted `Resolution`, `ResolvedField`, or `ValidationSignal` model.

---

# 12. Draft, Review, Confirm, Transaction Responsibilities

`TransactionDraft` remains the financial proposal boundary.

Review remains a meaningful opportunity for the user to inspect, alter, exclude, or otherwise resolve proposed financial state.

Confirm remains explicit authorization to adopt the resulting valid proposal.

A new canonical Transaction exists only after the durable financial write succeeds.

Evidence processing must not create canonical transaction-bearing state merely because evidence was selected, staged, processed, or resolved.

Evidence itself may someday have an independent durable lifecycle before transaction confirmation, such as a resumable inbox. If introduced, that must be explicit evidence retention and must not blur the financial canonicalization boundary.

---

# 13. Confirmed-Field Provenance and Correction Responsibilities

The long-term provenance question is broader than:

> Which receipt produced this transaction?

The responsibility is:

> **How did this canonical user-authorized value become what it currently is?**

Possible origins include:

- manual input;
- evidence-derived machine proposal accepted unchanged;
- evidence-derived proposal corrected during Review;
- structured import accepted or corrected;
- user-authored evidence annotation;
- later authorized edit;
- future multiple-evidence resolution.

## 13.1 Transaction-level and field-level provenance are different

Transaction-level provenance may answer:

> This transaction originated from receipt-photo ingestion.

Field-level provenance may eventually answer:

```text
Amount
$19.99
→ receipt-backed proposal
→ user confirmed unchanged

Merchant
Walgreens
→ receipt-backed proposal
→ user confirmed unchanged

Category
Medical
→ manually selected

Date
Sep 15
→ machine proposed Sep 14
→ corrected by user during Review
```

Phase 1B does not automatically require field-level provenance persistence in its first implementation.

The responsibility contract requires only that the architecture avoid making such explanation impossible without a future destructive redesign.

## 13.2 Review correction must remain epistemically honest

Example:

```text
OCR Observation
"$17.99"
        ↓
Candidate / Resolution
amount = $17.99 selected
        ↓
TransactionDraft
$17.99
        ↓
Review
user changes to $19.99
        ↓
Confirm
        ↓
Transaction
$19.99
```

Future provenance may truthfully say:

```text
Machine proposal: $17.99
User review correction: $19.99
Confirmed value: $19.99
```

Lumen must not rewrite that story as though OCR or the resolver determined `$19.99`.

## 13.3 CorrectionEvent semantics

`CorrectionEvent` is a conceptual learning/provenance responsibility, not authorization for a persisted event table.

A meaningful correction requires a distinguishable proposal and a distinguishable user-authorized result.

Example:

```text
Machine proposal
amount = $48.12
        ↓
Review
user changes amount to $48.72
        ↓
Confirmed Transaction
amount = $48.72
```

This may eventually constitute a meaningful correction signal because Lumen can compare what a machine/import process proposed with what the user ultimately authorized.

By contrast:

```text
Manual Entry
user types $48.12
then changes it to $48.72 before confirmation
```

is not automatically a machine-correction event. It may be ordinary draft editing.

Similarly, a later authorized edit to an existing Transaction is provenance-worthy history, but it must not automatically be treated as training feedback or a parser correction unless the product can establish what prior machine proposal is actually being corrected.

Therefore Phase 1B preserves these rules:

- correction semantics require identifiable proposal-vs-confirmed meaning;
- ordinary keystrokes and draft edits are not automatically CorrectionEvents;
- later canonical edits are not automatically machine-learning corrections;
- persistent correction learning should not begin before meaningful machine proposals exist;
- private correction history must not silently become shared/training data.

The exact persisted representation, if any, remains unresolved.

---

# 14. Lifecycle Separation

Phase 1B treats four lifecycles as distinct.

## 14.1 Ingestion-session lifecycle

```text
selected / initiated
→ staged
→ reviewed
→ completed / cancelled / failed
```

This describes the user/process session that brought input into Lumen.

## 14.2 Evidence lifecycle

Conceptually:

```text
available
→ staged / retained
→ associated
→ optionally deleted / expired
```

The exact persisted states are unresolved.

## 14.3 Processing lifecycle

Conceptually:

```text
unprocessed
→ processing
→ processed / failed / needs review
→ optionally reprocessed
```

Processing history may or may not deserve persistence depending on demonstrated reprocessing, debugging, audit, or product value.

## 14.4 Canonical transaction lifecycle

```text
TransactionDraft
→ Review
→ Confirm
→ Transaction
→ later edit / status change
→ optional delete
```

These lifecycles may influence each other, but none should silently stand in for another.

---

# 15. Current Durability Mismatch

The current upload flow can produce:

```text
photo selected
        ↓
bytes written to temporaryDirectory
        ↓
TransactionSource.stored_file_uri records that temporary URL
        ↓
Review
        ↓
Confirm
        ↓
TransactionSource becomes durable
        ↓
raw temporary file may later disappear independently
```

Therefore:

> **Current Lumen can durably remember that evidence existed while failing to guarantee durable retention of the evidence itself.**

And:

> **`TransactionSource` currently provides durable source metadata, but it does not establish durable evidence retention.**

Phase 1B must not imply that evidence is retained merely because durable metadata references it.

This mismatch is a concrete Phase 1B problem, but this document does not yet select the persistence solution.

---

# 16. Evidence Identity, Content Identity, and Security Responsibilities

Security/privacy responsibilities must remain distinct.

| Responsibility | Question | Current Phase 1B posture |
| --- | --- | --- |
| Artifact identity | Which Lumen evidence artifact is this? | Prefer stable, meaning-free application identity |
| Content identity | Are these exact bytes the same? | Optional fingerprint only if a concrete capability requires it |
| Authenticity | Did an expected actor/system produce this data? | No special cryptographic mechanism currently justified for ordinary local evidence |
| Authorization | May this actor access the artifact? | Future concern as resources cross user/device/backend boundaries |
| Confidentiality | Can an unauthorized party learn the content? | Separate storage-security/threat-model concern |
| Encoding | How are bytes represented for storage/transport? | Representation only; not a security guarantee |

## 16.1 Artifact identity vs content identity

A random Lumen identifier answers:

> Which Lumen artifact is this?

A content digest answers:

> Do these bytes match these other bytes?

They are not the same responsibility.

Two ingestion events may legitimately have different artifact IDs while referring to identical bytes.

## 16.2 Legacy `source_hash`

> **The legacy `TransactionSource.source_hash` field has no defined cryptographic or content-identity contract. Existing values must not be reinterpreted, recomputed, normalized, backfilled, or migrated as cryptographic content fingerprints without a separately admitted migration/compatibility contract.**

If Phase 1B later requires byte-level duplicate detection, integrity comparison, or export verification, it must define:

- the exact purpose;
- the chosen construction;
- what bytes are fingerprinted;
- where the result is stored;
- retention duration;
- deletion semantics;
- whether the fingerprint may leave the device;
- correlation/privacy consequences;
- migration behavior for existing `source_hash` values.

A conveniently named legacy field is not authorization to silently change semantics.

## 16.3 A fingerprint is not automatically privacy-neutral

A raw cryptographic digest can correlate two copies of the same file if another party possesses the same bytes.

Therefore:

```text
delete raw evidence
keep fingerprint forever
```

must not be assumed privacy-neutral.

Keyed fingerprints, HMACs, signatures, bearer capabilities, and other cryptographic mechanisms are not Phase 1B requirements unless a concrete trust boundary later demonstrates the need.

---

# 17. Cardinality Requirements Without Schema Authorization

Current repository structure allows:

```text
Transaction
→ zero or one TransactionSource
```

while tests demonstrate that one `TransactionSource` may already be referenced by multiple Transactions.

Therefore current persistence is not semantically one-to-one.

Future architecture must preserve the possibility that:

```text
one EvidenceArtifact
→ supports multiple Transactions
```

and:

```text
one Transaction
→ may be supported by multiple EvidenceArtifacts
```

Examples include:

- one CSV or statement supporting many transactions;
- receipt + email confirmation supporting one transaction;
- multiple screenshots supporting one transaction.

> **Cardinality requirements do not authorize a many-to-many join model by themselves.**

Implement only the relationship machinery required by the first admitted Phase 1B capability.

---

# 18. Retention and Deletion Responsibilities

Two rules are stable enough to govern Phase 1B:

> **Deleting raw evidence must not silently delete or rewrite a confirmed Transaction.**

> **Retaining a confirmed Transaction must not require indefinite retention of raw evidence.**

> **Loss, deletion, corruption, or unavailability of non-canonical evidence must degrade provenance or explainability explicitly; it must not silently alter confirmed financial state.**

For example:

```text
Before
Amount: $19.99
Receipt retained and inspectable

After evidence loss/deletion
Amount: $19.99
Transaction remains canonical
Receipt-based origin may remain known
Raw supporting evidence: unavailable
```

The invariant does not require every form of provenance to survive evidence deletion. Derived provenance may itself be privacy-sensitive and subject to explicit retention/deletion policy. The requirement is that evidence loss be represented honestly rather than silently rewriting canonical ledger state or implying that unavailable evidence remains inspectable.

"Delete evidence" is not one undifferentiated boolean. Phase 1B must reason independently about:

| Retained object/context | Example | Policy status |
| --- | --- | --- |
| Raw artifact content | Original image/file | Unresolved; user/privacy-sensitive |
| Derivative content | Thumbnail/compressed copy | Unresolved |
| Storage locator | Local file URI/path | Must track actual retention rather than imply nonexistent content |
| Original filename | User/file-system metadata | Unresolved; potentially sensitive |
| Application artifact ID | Meaning-free Lumen identity | Likely useful while semantic artifact record exists |
| Content fingerprint | SHA-like/keyed fingerprint if ever defined | Purpose/retention/privacy must be explicit |
| Capture/import timestamp | When content entered or was captured | Retention semantics unresolved |
| Precise location metadata | EXIF GPS or future location observation | Highly sensitive; separate policy required |
| Raw extracted/OCR text | Processing output | Potentially highly sensitive; persistence unresolved |
| Derived observations | Machine/user assertions about evidence | Persistence/retention unresolved |
| Resolution history | Why an interpretation was preferred | Persistence unresolved |
| Confirmed provenance | How canonical values came to be | May survive raw evidence where justified and privacy-appropriate |
| Canonical Transaction | User-authorized ledger state | Independent of indefinite raw-evidence retention |

## 18.1 Transaction deletion is not automatically evidence deletion

The current product deletes the Transaction without an explicit evidence/source deletion policy.

Phase 1B must not infer either:

```text
delete transaction
→ delete evidence
```

or:

```text
delete transaction
→ keep evidence forever
```

The policy is unresolved.

Future UX may need to distinguish:

- Delete Transaction;
- Delete raw evidence;
- Delete retained processing/provenance context;
- Delete ingestion history where such history exists.

## 18.2 Cancellation is distinct from deletion

Current cancellation/discard prevents a durable Transaction/TransactionSource write but does not explicitly remove the temporary raw file.

Future Phase 1B behavior must distinguish:

- user cancels before confirmation;
- user discards a draft;
- a write fails and the user may retry;
- the user confirms and elects to retain evidence;
- the user confirms but elects not to retain raw evidence;
- future resumable ingestion if ever implemented.

Ingestion-session cleanup is therefore a first-class responsibility even before durable evidence retention is selected.

---

# 19. Sensitive Metadata and Location

Phase 1B must treat sensitive context according to explicit purpose and retention rules.

Potentially sensitive evidence context includes:

- filenames;
- file paths/storage locators;
- raw OCR/extracted text;
- merchant/address text;
- capture timestamps;
- exact GPS coordinates;
- document metadata;
- healthcare-related receipt text;
- content fingerprints;
- future faces or other incidental image content.

Current repository evidence establishes:

- no structured latitude/longitude model;
- no semantic-place model;
- active upload sets `captured_at` to nil;
- active upload sets `metadata_json` to nil;
- no explicit EXIF/location parsing occurs in the current upload flow.

It does **not** establish that selected image bytes have had EXIF/GPS stripped.

Therefore the current factual statement is:

> **Lumen does not currently parse or model location; the location content of selected raw image bytes has not been characterized.**

Phase 1B must not claim either that location is retained as structured state or that source-image location has been removed without evidence.

Exact photo geolocation must not automatically become canonical transaction location.

A future semantic place confirmed by the user may legitimately outlive raw GPS evidence depending on the eventual privacy and retention policy.

---

# 20. Local Processing and Future Remote Processing

Lumen remains local-first.

Ordinary manual ledger use must not depend on remote processing.

Where evidence processing is available locally, Phase 1B/Phase 2 should prefer local processing where practical, consistent with the Architecture Contract.

Future remote providers may eventually:

- inspect explicitly selected evidence;
- produce Observations;
- produce candidates;
- provide enrichment;
- return processing metadata.

A remote provider must not:

- write canonical Transactions directly;
- bypass Review/Confirm;
- become required for manual entry;
- redefine the evidence/provenance model around provider-specific structures;
- silently expand what evidence leaves the device.

Any future remote path must explicitly define:

- what content leaves the device;
- purpose;
- provider;
- retention expectations;
- authentication/authorization boundary where applicable;
- failure/degraded behavior;
- what remains usable offline.

Signed tokens, HMACs, custom cryptographic provenance chains, and custom encryption protocols are not Phase 1B requirements merely because they may become useful across future remote trust boundaries.

---

# 21. Failure and Degraded Behavior

Phase 1B must preserve the following behavior principles.

## 21.1 Manual entry remains independently usable

If evidence loading, parsing, OCR, provider access, or future cloud processing is unavailable:

```text
Manual input
→ TransactionDraft
→ Review
→ Confirm
→ Transaction
```

must remain usable.

## 21.2 Evidence-processing failure must not create false financial success

A failed evidence-processing attempt may result in:

- retry;
- manual review;
- manual fallback;
- discard;
- future retained evidence awaiting processing if that capability is explicitly admitted.

It must not silently produce canonical financial state.

## 21.3 Financial write failure preserves retryable proposal state

Current Phase 1A behavior already protects this boundary: failed durable transaction creation does not leave a durable Transaction/TransactionSource graph, and the draft remains retryable.

Phase 1B must not weaken this behavior.

## 21.4 Evidence persistence may eventually have an independent failure boundary

If Phase 1B later persists raw evidence independently of the Transaction confirmation write, the system must explicitly define what happens when:

- evidence persistence succeeds but transaction confirmation fails;
- transaction confirmation succeeds but evidence retention fails;
- cleanup fails;
- processing fails after evidence retention;
- retained evidence becomes unavailable/corrupt.

This contract identifies the responsibility; it does not choose an atomicity strategy yet.

---

# 22. Machine Uncertainty and Legacy Confidence

Current behavior provides a useful precedent.

A draft may contain machine confidence for Review, but newly created confirmed Transactions deliberately do not inherit that confidence automatically.

Historical Transactions may still contain legacy `confidence_score` values and those values must be preserved until an explicitly justified, compatibility-tested migration says otherwise.

The Phase 1B rule is:

> **Machine uncertainty belongs upstream of canonical Transaction state unless a specific durable historical responsibility earns persistence.**

This does not prohibit durable processing/provenance records in the future. It prohibits putting uncertainty on canonical financial state merely because the machine produced it.

---

# 23. Conceptual Durability vs Persistence Durability

Phase 1B must preserve this distinction:

> **A concept can be architecturally important without its instances deserving durable persistence.**

Examples that may be conceptually required while remaining transient in an initial implementation include:

- `Observation`;
- `FieldCandidate`;
- `ValidationSignal`;
- `Resolution` / `ResolvedField`;
- `ExtractionRun` details;
- temporary machine confidence;
- correction-learning inputs.

Likewise, the responsibility contract does not require one database table/model per responsibility.

Persistence must be earned by demonstrated product, audit, recovery, debugging, reprocessing, portability, or integrity value.

---

# 24. Phase 1B Persistence Admission Review

Completion or acceptance of this responsibility contract does **not** authorize the first Phase 1B persisted-model change.

> **Contract acceptance ≠ Persistence Admission.**

Before any new persisted model, relationship, property semantics, or migration is introduced for Phase 1B, conduct an explicit:

## Phase 1B Persistence Admission Review

The review must answer:

1. **What exact capability are we implementing?**
2. **What current-model limitation blocks that capability safely?**
3. **What durable responsibility is required?**
4. **Why can the required state not remain transient?**
5. **What gives the state stable identity?**
6. **What is its lifecycle?**
7. **What are its retention and deletion semantics?**
8. **What sensitive information can it contain?**
9. **What relationship cardinality does this exact capability require now?**
10. **What survives raw-evidence deletion?**
11. **What happens when processing fails?**
12. **What happens when persistence/cleanup partially fails?**
13. **Does evidence-free manual entry continue to work independently?**
14. **How is current/historical `TransactionSource` state interpreted?**
15. **What migration is required, if any?**
16. **How will authentic existing-store compatibility be validated?**
17. **What automated tests prove durability, deletion, failure, migration, and canonical-boundary behavior?**
18. **What rollback/recovery strategy exists if the change fails in production?**

If those questions cannot be answered credibly, the persistence change has not earned admission.

The review must conclude with one of four dispositions:

- **ADMITTED** — The exact persistence proposal reviewed is authorized for implementation. Admission applies only to that exact proposal and does not authorize adjacent models, relationships, migrations, or follow-on schema work.
- **REVISE** — The capability is valid, but the persistence proposal does not yet satisfy this contract.
- **DEFER** — The responsibility is real, but durable persistence has not yet earned its cost or necessity.
- **REJECT** — The proposal conflicts with governing architecture, privacy, compatibility, or demonstrated product need.

A migration justified primarily by:

> "The conceptual model would look cleaner."

must be deferred.

---

# 25. Smallest Likely Implementation Boundary — Not Yet Selected

The audit makes one potential first capability especially visible:

```text
durable evidence retention
+
meaningful artifact identity/metadata
+
explicit lifecycle/deletion behavior
```

because current durable metadata can point to temporary content.

However:

> **This responsibility contract does not select or approve that implementation.**

The first implementation capability must be selected only after this contract is reviewed and accepted, then evaluated through the Phase 1B Persistence Admission Review.

The smallest good implementation may persist substantially less than the conceptual architecture suggests.

For example, it may eventually persist only:

- durable artifact identity;
- the minimum necessary artifact metadata;
- the storage/retention semantics required by the selected capability;
- the minimum relationship required by that capability;

while keeping Observation/Candidate/Resolution/processing details transient until later phases demonstrate persistence value.

That would be a valid implementation of the responsibility boundaries.

---

# 26. Explicit Phase 1B Non-Goals

This document does not authorize or require:

- sophisticated production OCR;
- Apple Vision implementation merely because Phase 2 plans local extraction;
- cloud OCR/VLM integration;
- Supabase synchronization;
- cloud accounts or cross-device sync;
- automatic transaction creation;
- merchant-learning systems;
- barcode/product intelligence;
- item-level receipt understanding;
- a generalized rules engine;
- payment-instrument/reward/benefit implementation;
- a terminology-only `TransactionSource → EvidenceArtifact` rename;
- a complete many-to-many evidence graph;
- `EvidenceLink` merely because future cardinality may require it;
- `Observation`, `FieldCandidate`, `Resolution`, `ResolvedField`, `ValidationSignal`, `ExtractionRun`, or provenance models merely because the responsibilities exist;
- persistent CorrectionEvents before meaningful machine proposals exist;
- cryptographic provenance chains;
- HMAC-signed SwiftData records;
- blockchain/audit-ledger architecture;
- custom encryption protocols;
- indefinite raw-image retention;
- mandatory cloud evidence storage;
- exact GPS as canonical transaction truth.

---

# 27. Open Design Questions

The following remain unresolved and must not be read as approved implementation decisions.

## 27.1 Evidence identity and storage

- Does the first Phase 1B capability require a new persisted artifact identity or can existing identity be adapted safely?
- What qualifies as retained evidence versus a staged temporary file?
- Where should retained raw evidence live?
- Are derivatives/thumbnails retained separately?
- How is unavailable/corrupt retained evidence represented?

## 27.2 Content identity

- Does Phase 1B actually need persisted byte-level fingerprinting?
- Is the first use case duplicate-evidence detection, integrity comparison, export verification, or something else?
- What is the privacy/retention policy for fingerprints?
- Should fingerprints survive raw-content deletion?
- How should legacy `source_hash` values coexist with any newly defined fingerprint capability?

## 27.3 Origin modeling

- Where should durable origin/ingestion classification live long term?
- How should historical `.manual_entry` `TransactionSource` rows be represented without inventing evidence?
- Does origin belong on a transaction, draft/ingestion record, evidence record, or another responsibility?

No answer is implied by this document.

## 27.4 Processing persistence

- Which processing facts, if any, deserve durable history?
- Is a failed parse meaningful after the user successfully creates a transaction manually?
- When does reprocessing value justify storing multiple run outputs?
- What retention controls apply to raw OCR text and observations?

## 27.5 Provenance depth

- Is transaction-level provenance sufficient for the first Phase 1B implementation?
- Which future features require field-level provenance?
- How should later authorized edits affect prior provenance?
- What provenance should remain when raw evidence is deleted?

## 27.6 Correction semantics

- What minimum proposal identity is required before Lumen can say a machine/import proposal was corrected?
- Which fields deserve correction tracking once meaningful machine proposals exist?
- How should corrections interact with reprocessing and provider/version changes?
- Which correction facts are private provenance versus future learning input?
- What user control is required before any private correction could contribute outside the user's local/private context?

## 27.7 Deletion semantics

- What does "Delete evidence" mean for raw content, derivatives, fingerprints, OCR text, observations, provenance, and semantic context?
- What happens to unreferenced evidence after Transaction deletion?
- Is orphan cleanup immediate, deferred, user-controlled, or retention-policy driven?
- Should an ingestion session leave any durable trace after cancellation?

## 27.8 Location and sensitive metadata

- Should retained raw evidence preserve original EXIF exactly?
- If precise location is present, should it be stripped, retained, separately controlled, or transformed?
- When may a user-confirmed semantic place survive deletion of precise location evidence?
- Which metadata is required for legitimate provenance versus merely available?

## 27.9 Relationship cardinality

- What relationship machinery does the first admitted capability actually require?
- When, if ever, does one Transaction → multiple artifacts become a production requirement?
- When does the current source-sharing behavior need an explicit inverse or relationship object?

## 27.10 Ingestion outcomes

- Should Save, Discard, Cancel, Retry, and future Resume be represented as distinct ingestion-session outcomes?
- What cleanup/retention action should each trigger?
- Does future resumable evidence ingestion justify durability before Transaction confirmation?

---

# 28. Review Checklist for This Contract

Before accepting this responsibility contract, verify that it:

- preserves ADR-001's `TransactionDraft → Review → Confirm → Transaction` boundary;
- keeps manual entry evidence-free;
- does not equate origin with evidence;
- treats `TransactionSource` as compatibility-bearing rather than a schema to replace by naming preference;
- distinguishes repository findings from principles and open questions;
- does not assign cryptographic meaning to legacy `source_hash`;
- distinguishes artifact identity from content identity;
- distinguishes durable metadata from durable evidence retention;
- preserves independent ingestion/evidence/processing/transaction lifecycles;
- preserves the possibility of future many-to-many evidence without authorizing it now;
- defines `Observation`, `FieldCandidate`, `ExtractionRun`, `ValidationSignal`, `ResolvedField`, and `Resolution` as responsibilities without authorizing persistence;
- distinguishes meaningful proposal correction from ordinary manual editing;
- keeps processing-state persistence unresolved unless demonstrated value exists;
- treats deletion and retention as explicit privacy/product responsibilities;
- does not claim current raw images strip or retain structured location without evidence;
- preserves future explainability of review corrections and later edits;
- requires a separate Persistence Admission Review before schema work;
- selects no concrete Phase 1B implementation capability by itself.

---

# 29. Next Step After Contract Acceptance

If this contract is accepted, the next step is **not** to create evidence models.

The next step is:

```text
Responsibility contract accepted
        ↓
Select one concrete Phase 1B capability
        ↓
Phase 1B Persistence Admission Review
        ↓
ADMITTED / REVISE / DEFER / REJECT
        ↓
Only if ADMITTED:
smallest exact admitted implementation + migration/compatibility tests
```

No production/schema work should be inferred merely from acceptance of this document.
