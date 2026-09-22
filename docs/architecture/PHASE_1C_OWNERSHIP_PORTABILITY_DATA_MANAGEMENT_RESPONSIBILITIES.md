# Phase 1C — Ownership, Portability & Data Management Responsibility / Admission Contract

## Status

**Accepted. Documentation-only Phase 1C responsibility / admission contract.**

- **Proposal date:** 2026-09-22
- **Canonical repository baseline reviewed:** `3e9272f70bab230ad09301783ed69a80499e3873`
- **Active roadmap phase:** Phase 1C — Ownership, Portability & Data Management
- **Phase 1B dependency:** Confirmed Evidence Retention v1 is complete and frozen unless new concrete defect evidence reopens it.
- **Persistence disposition:** Durable noncanonical import-workspace state is admitted in principle as a product responsibility because resumable review has demonstrated user value. No SwiftData model, field, relationship, schema migration, canonical promotion receipt, filesystem layout, or other persistence mechanism is authorized by this document.
- **Implementation disposition:** No Pass A/B/C-style implementation sequence is selected or authorized by this document.

This document is subordinate to:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/ROADMAP.md`
- `docs/NON_GOALS.md`
- `docs/architecture/ADR-001-source-of-truth-and-ingestion.md`

Phase 1B evidence/provenance behavior is additionally constrained by its accepted responsibility, admission, implementation, and release-correctness records.

The authority order remains:

**Architecture Contract → Roadmap → Non-Goals → accepted ADR/responsibility contracts → exact admission → implementation plan → code/tests.**

This contract exists to define what Phase 1C means before implementation mechanics are selected.

---

# 1. Phase Responsibility

Phase 1C gives users ownership and portability of supported durable financial state and introduces a durable, noncanonical import workspace in which structured external data can be mapped, resolved, excluded, interrupted, and resumed.

Only explicit user confirmation may promote ready transaction proposals into the canonical ledger.

Promotion must remain unambiguous and replay-safe across persistence failures and process termination.

Ordinary transaction duplicate detection remains a separate user-facing import concern.

---

# 2. Governing Invariants

The following invariants govern Phase 1C.

> **No unresolved required financial meaning may become canonical.**

> **No already-canonical import promotion may become promotable again merely because noncanonical workspace state is stale, incomplete, or still physically present.**

> **Durability does not imply authority: portable files, resumable workspace state, and canonical financial state are distinct persistence domains with distinct ownership and lifecycle rules.**

> **Workspace existence is not proof that an import remains promotable.**

> **A workspace-local success flag is not sufficient proof that canonical promotion succeeded.**

> **Promotion replay safety is not transaction duplicate detection.**

> **Phase 1B may be consumed but must not be opportunistically redesigned as a side effect of Phase 1C.**

> **The public portable contract is not the SwiftData object graph.**

---

# 3. Three Durability Domains

Phase 1C recognizes three different durability responsibilities.

## 3.1 Portable Durability

User-owned interchange.

Examples:

- Lumen Portable JSON;
- Lumen CSV;
- downloadable template/example files;
- future explicitly admitted portable packages.

Portable durability exists so the user can inspect, retain, transform, export, and re-import supported Lumen data independently of a future cloud backend.

A portable file is not canonical merely because Lumen generated it.

## 3.2 Workspace Durability

Private, resumable, uncertain, noncanonical working state.

Potential responsibilities include:

- selected import source characterization;
- a controlled temporary source copy while required;
- parser/version context;
- column mappings;
- file-wide assumptions;
- normalized proposals;
- row-level edits;
- exclusions;
- unresolved issues;
- accepted review decisions;
- progress timestamps.

Workspace durability exists so ordinary interruption does not destroy meaningful import-review work.

It does not grant financial authority.

## 3.3 Canonical Durability

The user-confirmed ledger plus only the minimum durable control state, if any, required to establish canonical promotion authority safely.

Canonical `Transaction` remains financial truth.

A future promotion receipt, idempotency record, or other canonical-control mechanism may be considered only if an exact implementation admission demonstrates that it is required for replay-safe confirmation.

---

# 4. Canonical Portability Boundary

The intended export architecture is:

```text
Canonical durable state
        ↓
portable-domain representation
        ↓
Lumen Portable JSON
        ↓
Lumen CSV projection / templates where applicable
```

The reverse transaction-bearing path is:

```text
structured external input
        ↓
parse / map / validate
        ↓
portable/import proposals
        ↓
TransactionDraft(s)
        ↓
Review / batch Review
        ↓
explicit confirmation
        ↓
canonical Transaction(s)
```

Supported reference data uses an entity-appropriate preview/confirmation workflow rather than artificial `TransactionDraft` objects.

The portable-domain representation is a contract boundary. It must not be implemented as blind serialization of internal persistence objects.

---

# 5. Lumen Portable JSON

Lumen Portable JSON is the **normative, highest-fidelity portable representation of the durable state explicitly admitted to the current portability contract**.

It is not described as a lossless image of the entire application container.

Portable JSON must:

- be explicitly versioned;
- be backend-neutral;
- document included entities and fields;
- document exclusions;
- distinguish financial calendar-date semantics from timestamps;
- define monetary representation independently of Swift binary floating-point encoding;
- provide enough format-level identity to represent admitted relationships without automatically exposing every local SwiftData identifier as permanent public API;
- remain importable through Review/Confirm for transaction-bearing records;
- avoid serializing transient machine state merely because it exists in memory or internal storage.

Supported fields/entities have defined round-trip guarantees. State outside the admitted portable contract is explicitly excluded rather than silently implied.

---

# 6. Lumen CSV and Downloadable Templates

Lumen CSV is a deliberately narrower tabular projection optimized for:

- human inspection;
- spreadsheet editing;
- predictable transaction interchange;
- deterministic validation;
- a guaranteed user-controlled import path.

The downloadable blank template, example CSV, exporter column order, parser expectations, and validation documentation must derive from the same admitted CSV contract rather than becoming separately maintained schemas.

The intended product posture is:

```text
Guaranteed path
Lumen CSV / Lumen Portable JSON
→ defined semantics
→ deterministic validation
→ predictable Review

Progressively adaptive path
non-Lumen CSV
→ structural inspection
→ deterministic mapping candidates
→ user resolution where needed
→ Review
```

The template is the guaranteed path, not the only path.

---

# 7. Foreign Structured Formats

Phase 1C v1 admits the following direction:

- **Lumen Portable JSON:** guaranteed/versioned format;
- **Lumen CSV:** guaranteed/versioned format;
- **non-Lumen CSV:** progressively mapped where safely supportable;
- **arbitrary third-party JSON:** deferred unless a deliberately scoped adapter is separately admitted.

CSV presents a bounded row/column mapping problem.

Arbitrary JSON may require discovering nested collections, relationship graphs, account structures, and provider-specific semantics and must not silently turn Phase 1C into a general ETL platform.

Phase 1C does not promise universal bank, issuer, retailer, payment-processor, budgeting-app, or accounting-platform compatibility.

---

# 8. Real-World Import Format Research

Real financial-institution exports may be used as format research before generic CSV assumptions are frozen.

Useful characteristics include:

- transaction date versus posting date;
- signed amount versus split debit/credit columns;
- pending/posted state;
- description/payee/merchant distinctions;
- currency representation;
- account/card identifiers;
- category/type vocabularies;
- running balances;
- transaction IDs/reference numbers;
- encoding;
- delimiter conventions;
- date formats;
- decimal conventions.

Research findings must become generic structural observations, synthetic fixtures, and deterministic mapping tests.

Personal financial exports, account identifiers, transaction histories, or other private financial artifacts must not be committed to the repository merely to support format research.

A sampled institution is evidence about a file structure, not a promise of provider-specific support.

---

# 9. Portable Identity vs Persistence Identity

Portable identity and local persistence identity are separate responsibilities.

Phase 1C must not assume:

```text
SwiftData id
=
permanent public portable identity
=
overwrite authority on import
```

Portable v1 may require format-level identifiers to express relationships inside an export.

The exact identity scheme must satisfy these rules:

- local persistence identifiers are not automatically public API;
- an imported portable identifier does not by itself authorize overwriting an existing local record;
- repeated imports must have explicit semantics;
- relationships within one portable export must remain resolvable;
- reference-entity matching must distinguish identity from semantic similarity;
- a later re-import of overlapping financial history is a duplicate-awareness problem, not crash-recovery proof.

The exact format-level identifier representation must be frozen in the portable-v1 format specification before implementation.

---

# 10. Money and Date Representation

Portable representation must not inherit ambiguous internal encoding merely because the current model uses a particular Swift type.

## Money

Lumen Portable JSON v1 must represent monetary values as canonical decimal strings plus explicit currency semantics rather than making a JSON binary floating-point number the normative financial representation.

Example semantic shape:

```json
{
  "amount": "52.30",
  "currency": "USD"
}
```

The exact decimal normalization and conversion algorithm must be specified and tested before implementation.

This does **not** authorize a migration of the current canonical `Transaction.amount` storage representation.

## Dates and timestamps

Financial calendar-date meaning must be distinguished from event timestamps.

The format specification must not blindly encode every Swift `Date` with identical semantics.

Where a field represents a financial calendar date, the portable contract must use an explicit calendar-date representation with documented timezone assumptions.

Where a field represents an instant such as creation/export time, the portable contract must use an explicit timestamp representation with timezone/offset semantics.

The exact v1 field encoding must be frozen before implementation and tested against the existing Phase 1A date/timezone contract.

---

# 11. Reference-Entity Matching and Conflict Semantics

Supported reference entities may include:

- Categories;
- PaymentMethods;
- Tags;
- other entities explicitly admitted to the portable contract.

Reference data must not be forced through artificial `TransactionDraft` objects.

For imports:

- an empty receiving store may create supported reference entities after explicit import preview/confirmation;
- an established portable identity may be used when the receiving store can prove that identity under the admitted format contract;
- normalized name similarity may produce a merge/match proposal but must not silently establish identity where ambiguity exists;
- ambiguous conflicts require user resolution or deliberate creation of a separate entity;
- transaction proposals must not silently bind to a semantically similar but unconfirmed reference entity.

The exact per-entity conflict matrix belongs in the portable/import format specification.

---

# 12. Evidence and Provenance Portability

Phase 1C may project admitted evidence/source provenance without redefining Phase 1B.

The portable contract must distinguish:

```text
portable semantic/provenance context
from
installation-local retained-evidence state
```

In particular:

- `stored_file_uri` is machine-local Phase 1B locator state and must not be exported as a transferable locator;
- a locator from installation A must never cause installation B to report a readable retained image;
- imported provenance metadata without payload bytes must not fabricate local evidence availability;
- raw retained-evidence payload bytes are **not** automatically included in Lumen Portable JSON v1;
- a future evidence-bearing export package may be admitted separately if user value, privacy, integrity, and recovery semantics justify it;
- Phase 1C must not rename or redesign Phase 1B identity, locator, retention, availability, confirmation, or reconciliation semantics merely to make export easier.

The exact portable provenance field set must be defined before implementation.

---

# 13. Import File Provenance

A CSV or JSON file selected for structured import is an ingestion input.

It does not automatically become:

- a `TransactionSource`;
- Phase 1B retained evidence;
- evidence attached to each resulting Transaction;
- permanently retained provenance.

A controlled workspace copy may exist temporarily to support reliable parsing, remapping, interruption, and resume.

That temporary operational role must remain separate from transaction evidence.

---

# 14. Coherent Export Snapshot

Export must represent coherent durable state.

It must not serialize whatever happens to be visible in a UI context while unsaved mutations are pending.

The export contract must define:

- the durability boundary that qualifies state for export;
- export schema/version metadata;
- deterministic record ordering;
- stable formatting rules;
- manifest metadata where appropriate;
- behavior if durable state cannot be read consistently.

The exact snapshot mechanism is an implementation concern, but the observable result must be deterministic enough for testing and meaningful round-trip comparison.

---

# 15. Data Management and Deletion Authority

Phase 1C includes meaningful data management, but destructive scope must be truthful.

The following operations are not equivalent:

```text
delete all Transactions
```

and:

```text
erase all Lumen-managed local data
```

Committed Phase 1B evidence/source state may legitimately outlive the final current Transaction association.

User-controlled portable exports that have been saved, copied, or moved outside Lumen-managed storage are outside Lumen's erasure authority. A Lumen-managed erasure operation must not claim to delete external copies that the user controls elsewhere.

Therefore:

- Phase 1C must not implement "Clear all data" by deleting Transactions and imply complete local erasure;
- a capability that claims to erase all Lumen-managed local data must account for every admitted canonical, reference, source, retained-evidence, workspace, and relevant preference responsibility under Lumen's control;
- committed-evidence deletion requires an explicit evidence-aware deletion authority and must not bypass Phase 1B conservative retention semantics;
- if complete Lumen-managed local erasure is not safely admitted, the first Phase 1C slice must not claim to provide it;
- ordinary Category, PaymentMethod, Tag, source inspection, and other management capabilities remain independently admissible within their exact contracts.

---

# 16. Import Readiness Model

Transaction-bearing import proposals use a pre-canonical readiness model.

## READY

All required financial semantics are resolved.

The proposal may proceed to Review and explicit confirmation.

## NEEDS RESOLUTION

At least one required financial semantic remains unresolved.

The proposal must be resolved or explicitly excluded before canonical confirmation.

## INVALID / UNSUPPORTED

The input cannot safely form an admitted transaction proposal under the current import contract.

It must be corrected upstream or explicitly excluded.

These are import-workspace meanings, not canonical `Transaction` statuses.

Lumen must not persist a partially understood row as a canonical Transaction with a generic `needsReview` flag merely to defer import interpretation.

Missing optional context does not make an otherwise valid proposal unresolved.

---

# 17. Required Financial Meaning vs Optional Context

The portability/import format specification must classify fields by semantic responsibility rather than simply whether a source column exists.

The current `TransactionDraft → Review → Confirm` path mechanically requires:

- a positive finite monetary amount accepted by the current money validation;
- a currency accepted by the current ISO-currency validation;
- a non-empty merchant/counterparty representation;
- a resolved `Category` association;
- a financial status of `pending` or `posted`.

For structured import, Phase 1C additionally requires transaction direction/type and transaction-date meaning to be resolved before a proposal is READY. Draft defaults must not conceal unresolved importer meaning.

A source file does **not** need to contain a dedicated Category column. If Category is absent or cannot be mapped deterministically, Import Review must resolve the required Category association through an admitted mapping, file/group default, or user decision before confirmation.

Making Category optional in canonical creation would be a separate product/domain change and is not authorized by this contract.

Potentially optional context includes, subject to the exact format specification:

- PaymentMethod;
- Tags;
- Notes;
- posted date;
- institution-provided metadata not required for canonical financial meaning.

A required semantic may be resolved from:

- a row value;
- deterministic column structure;
- file metadata;
- a confirmed file-wide rule;
- a confirmed group-level rule;
- a row-specific user decision.

The requirement is resolved meaning, not necessarily a dedicated source column for every row.

---

# 18. Resolution Scope

When the same ambiguity can be validly resolved at more than one scope, Import Review must resolve it at the broadest valid scope.

Resolution progression:

```text
file-level resolution
        ↓
column-level resolution
        ↓
group-level resolution
        ↓
row-level resolution only where necessary
```

Examples include:

- one currency applies to all rows;
- one date convention applies to the file;
- Debit means expense and Credit means income;
- one source column maps to merchant/payee;
- a repeated ambiguity can be resolved as a valid group.

A 500-row import must not require 500 equivalent clicks merely to demonstrate user authority.

Row-level review remains required when ambiguity is genuinely row-specific.

---

# 19. Exclusion and Partial Selection

Unresolved or unsupported rows may be explicitly excluded.

For example:

```text
300 detected
298 READY
2 NEEDS RESOLUTION

User explicitly excludes 2
        ↓
confirmation summary:
298 will be imported
2 excluded
```

Excluded proposals do not become canonical and must not silently reappear as imported Transactions.

Exclusion is an explicit import-workspace decision and must survive ordinary interruption while the workspace remains active.

---

# 20. Durable Resumable Import Workspace

Import Review is a durable workspace, not a canonical ledger state.

Lumen must automatically preserve meaningful accepted review progress so normal interruption does not cause substantial work loss.

Meaningful semantic autosave events include:

- confirmed column mapping;
- file-wide currency selection;
- date-format resolution;
- amount-direction rule;
- group-level resolution;
- row correction;
- row exclusion;
- accepted reference mapping;
- other decisions that materially change proposal meaning/readiness.

Ephemeral presentation state such as exact scroll offset does not need the same durability guarantee.

The user must not be required to press a second "Save Import" action merely to preserve noncanonical review progress.

UI language must distinguish:

- Import in progress;
- Resume import;
- Discard import;
- Changes saved locally;

from canonical Save/Confirm language.

---

# 21. Controlled Import Source Lifecycle

For resumability, Phase 1C may retain a controlled local copy of the selected source while the import workspace requires it.

The intended lifecycle is:

```text
user selects structured file
        ↓
Lumen establishes a stable controlled workspace input
        ↓
parse / map / resolve / autosave / resume
        ↓
explicit confirmation OR explicit discard
        ↓
workspace source becomes eligible for retirement
```

Requirements:

- the import must not depend indefinitely on an external Files-picker URL remaining available;
- the controlled copy contains potentially sensitive financial information and must use appropriate local protection;
- durability is justified only while required for the admitted workspace/recovery behavior;
- canonical commitment or a durably accepted explicit discard must establish retirement eligibility;
- once canonical commitment succeeds or explicit discard is durably accepted, the workspace must immediately lose edit and promotion authority;
- cleanup failure may temporarily over-retain the workspace material;
- surviving workspace files after canonical commitment or durably accepted discard must never restore edit or promotion authority;
- the implementation must preserve accepted discard across interruption strongly enough that physical cleanup failure cannot resurrect the discarded workspace as resumable/promotable;
- the controlled import source is not automatically Phase 1B retained evidence.

The exact directory layout, file-protection API, and snapshot representation are implementation decisions requiring review.

---

# 22. Active/Promotable Workspace Authority

Phase 1C v1 admits at most **one active/promotable import workspace** at a time.

An active/promotable workspace is one whose proposals may still be edited/resolved and eventually promoted.

If an active workspace exists, starting another import requires the user to:

- resume it; or
- explicitly discard it before starting the new import.

However:

> **Physical workspace existence is not import authority.**

A workspace whose canonical promotion is already established **or whose explicit discard has been durably accepted**, but whose cleanup has not completed, is nonpromotable cleanup residue, not an active import.

Such residue:

- must never become editable/promotable again;
- belongs to cleanup/reconciliation responsibility;
- does not conceptually regain the active-import slot merely because files remain;
- must not permanently strand future importing solely because cleanup residue cannot be deleted.

An implementation may temporarily sequence new-import creation behind safe cleanup where necessary, but persistent cleanup failure must have a recovery posture that does not convert successful prior canonicalization or durably accepted discard into an indefinite denial of all future imports.

---

# 23. Confirmation and Canonical Promotion

Completion is a real authority boundary.

Conceptually:

```text
ACTIVE WORKSPACE
noncanonical
        ↓
explicit user confirmation
        ↓
PROMOTION ATTEMPT
        ↓
canonical persistence
        ↓
COMMITTED
        ↓
workspace loses edit/promotion authority
        ↓
RETIRING
        ↓
RETIRED
```

These are responsibility states, not an authorization to add persisted enums.

After canonical commitment succeeds, stale workspace material must not permit the accepted proposal set to be promoted again.

Explicit discard is the symmetric non-promotion terminal boundary:

```text
ACTIVE WORKSPACE
        ↓
explicit user discard
        ↓
discard durably accepted
        ↓
workspace loses edit/promotion authority
        ↓
RETIRING
        ↓
RETIRED
```

If physical cleanup fails after either canonical commitment or durably accepted discard, the residue remains noneditable and nonpromotable.

The product must treat committed cleanup residue as completed/nonpromotable; UI may use wording equivalent to:

> Import completed — finishing cleanup.

Discard cleanup residue must likewise be treated as discarded/nonpromotable rather than resumable.

Neither kind of residue may be presented as:

> Resume import.

---

# 24. Confirmation / Recovery Authority

The durable fact proving that a confirmation boundary's canonical effects crossed into canonical state cannot rely only on a separately written workspace flag.

The following is insufficient:

```text
canonical effects commit
        +
session.json later writes "finished=true"
```

because process termination can occur between those writes.

The reverse ordering is also insufficient.

All canonical effects authorized by one import confirmation boundary must obey that boundary's atomicity/replay-safety contract. If reference-entity proposals are confirmed through a separate explicit confirmation boundary, that boundary is evaluated separately. If reference-entity effects and Transactions are authorized together, they share the same atomicity/replay-safety obligation.

A valid implementation must satisfy one of these property families:

## A. Atomic canonical promotion proof

The canonical persistence authority commits:

```text
all canonical effects authorized by the confirmation
+
durable promotion proof
```

within the same atomic authority boundary.

or:

## B. Provably idempotent promotion

A stable promotion identity and canonical persistence behavior guarantee that replaying the same promotion cannot duplicate or inconsistently reapply any canonical effect authorized by that confirmation boundary.

This contract does not select between those mechanisms.

A future implementation may propose another mechanism only if it proves equivalent replay safety.

Any new canonical-control persistence required by the selected mechanism needs an exact persistence admission. This document does not authorize a promotion-receipt model, idempotency field, relationship, uniqueness constraint, or migration.

---

# 25. Batch Atomicity

Phase 1C v1 must use all-or-nothing canonicalization for the canonical effects authorized by one explicitly confirmed accepted proposal set within a deliberately supported import-size envelope.

For a transaction-only confirmation boundary, this is conceptually:

```text
298 accepted proposals
        ↓
one confirmation
        ↓
either:
0 canonical Transactions created
or:
298 canonical Transactions created
```

If the same confirmation boundary also authorizes reference-entity creation or updates, those effects participate in the same all-or-nothing boundary. Reference entities confirmed through a separate explicit boundary are evaluated independently.

Chunked/partial canonicalization is not admitted merely for implementation convenience.

If empirical performance or persistence behavior demonstrates that supported v1 imports cannot safely use all-or-nothing promotion, the contract must be revisited before introducing proposal-level partial-commit semantics.

This does not prevent the user from excluding rows before confirmation.

---

# 26. Promotion Replay Safety vs Transaction Duplicate Detection

Two different problems must remain separate.

## Promotion replay safety

Question:

> Did this exact confirmed promotion already cross into canonical state?

This is a deterministic authority/recovery question.

It must be answered through the canonical promotion mechanism, not merchant/date/amount similarity.

## Transaction duplicate detection

Question:

> Does this newly selected import contain financial records that appear to overlap existing Transactions?

This is an import-review/product question.

It may use existing duplicate semantics, deterministic comparisons, warnings, and user judgment.

Therefore:

- retrying the same interrupted promotion must not rely on heuristic duplicate detection;
- selecting the same or overlapping file on a later day is a new import workflow and may legitimately surface duplicate warnings;
- a promotion identity must not be treated as a general transaction-deduplication key.

---

# 27. Repeated Import Semantics

Phase 1C must distinguish:

```text
same confirmation operation replayed after interruption
```

from:

```text
user intentionally selects the same/overlapping data again later
```

The first is governed by promotion replay safety and must not duplicate canonical state.

The second is governed by ordinary import duplicate-awareness and explicit Review.

Importing the same portable file twice does not automatically grant overwrite/delete authority over previously imported Transactions.

The exact duplicate-warning and match UX belongs in implementation design, but the authority distinction is frozen here.

---

# 28. Round-Trip Ownership Guarantee

The Phase 1C target is:

```text
installation A
        ↓
export admitted portable-v1 state
        ↓
fresh/empty installation B
        ↓
import
        ↓
preview / proposal resolution
        ↓
Review / explicit confirmation
        ↓
equivalent supported canonical state
```

"Equivalent" means that fields/entities explicitly included in the current portable contract preserve their defined semantics after the required import/confirmation workflow.

It does **not** mean:

- identical application containers;
- identical machine-local file paths;
- restoration of excluded transient extraction state;
- restoration of raw retained evidence bytes unless an evidence-bearing package is separately admitted;
- identical internal SwiftData object identity;
- silent bypass of Review because the file originated from Lumen.

Round-trip tests must be defined against the admitted portable contract, not against every byte of application storage.

---

# 29. Schema and Persistence Admission

This contract admits **responsibilities**, not a storage implementation.

The following are admitted in principle:

- resumable pre-canonical import work;
- semantic autosave;
- temporary controlled import-source retention while required;
- replay-safe canonical promotion;
- cleanup/retirement after confirm/discard.

The following are **not** authorized by this contract:

- new SwiftData import-workspace models;
- a persisted `ImportSession`;
- persisted `ImportRow`, `ColumnMapping`, or `ImportIssue` entities;
- a promotion-receipt model;
- new idempotency fields on `Transaction`;
- import-session IDs stamped onto every Transaction;
- a new schema version or migration;
- a specific filesystem directory layout;
- a specific serialization mechanism for workspace state.

A file-backed internal snapshot under Lumen-controlled storage may be evaluated.

SwiftData may be evaluated.

Another local mechanism may be evaluated.

The selected mechanism must be the smallest one that satisfies resumability, privacy, crash recovery, cleanup, compatibility, and replay-safety requirements.

If canonical-control persistence is required, it must receive an exact persistence/migration admission before implementation.

---

# 30. Explicit Phase 1C Non-Goals

This contract does not authorize:

- Phase 2 OCR / Apple Vision implementation;
- hosted OCR or VLM extraction;
- arbitrary JSON normalization;
- universal bank/issuer CSV support;
- a general ETL engine;
- cloud synchronization;
- a second canonical cloud database;
- cloud accounts;
- automatic transaction creation that bypasses Review/Confirm;
- conversion of import files into retained transaction evidence by default;
- redesign of Phase 1B evidence internals;
- committed-evidence deletion without a separate evidence-aware deletion contract;
- a misleading "clear all data" operation;
- multiple concurrent active/promotable import workspaces;
- a generic import-project manager;
- merchant-learning systems;
- item-level receipt understanding;
- barcode/product infrastructure;
- reward accounting;
- benefits automation;
- a generalized financial rules engine;
- schema changes merely because conceptual import entities exist.

---

# 31. Validation Responsibilities

Future implementation plans must define deterministic evidence for at least:

## Portable format

- schema/version handling;
- deterministic serialization;
- deterministic ordering;
- money/date encoding;
- documented exclusions;
- malformed/unsupported version rejection;
- empty and representative datasets.

## Round trip

- Lumen portable export → fresh store → import → Review/Confirm → equivalent supported canonical state;
- supported reference-entity restoration;
- excluded state remains truthfully excluded.

## Generic CSV mapping

- known header aliases;
- date-format ambiguity;
- signed amount semantics;
- debit/credit pairing;
- file-level assumptions;
- row-specific exceptions;
- explicit exclusion;
- unsupported structures.

## Workspace durability

- accepted semantic decisions survive relaunch;
- noncanonical workspace does not create Transactions by itself;
- a durably accepted discard removes edit/promotion authority without modifying existing canonical Transactions;
- process termination or cleanup failure after accepted discard does not resurrect the workspace as resumable/promotable;
- discard cleanup residue does not permanently consume the active/promotable workspace slot;
- controlled source lifetime follows the admitted lifecycle.

## Promotion/recovery

- successful canonical promotion cannot be replayed into duplicate or inconsistently repeated canonical effects;
- every canonical effect authorized by one confirmation boundary obeys that boundary's atomicity/replay-safety contract;
- process termination after canonical persistence but before workspace cleanup does not reopen promotion authority;
- failed canonical persistence leaves the workspace retryable;
- cleanup failure biases toward temporary over-retention rather than duplicate canonicalization;
- cleanup residue never regains edit/promotion authority.

## Existing-store compatibility

Any schema/persistence change later admitted for Phase 1C must include authentic existing-store compatibility and migration validation appropriate to that exact change.

---

# 32. Admission Decision Register

This section maps the Phase 1C design questions to the responsibility decisions frozen by this proposal.

## 1. Portable v1 scope and round-trip guarantees

**Decision:** Define an explicit supported portable-domain contract. JSON is the normative, highest-fidelity portable representation for admitted state; CSV is narrower. Round-trip means semantic equivalence for admitted fields/entities, not container identity.

## 2. Portable identity and repeated-import semantics

**Decision:** Portable identity is distinct from persistence identity. Portable identifiers do not automatically authorize overwrite. Same-promotion replay is distinct from later repeated import.

## 3. Money and date representation

**Decision:** Money uses explicit decimal-string + currency semantics in portable JSON. Financial calendar dates and event timestamps must be represented according to distinct documented semantics. No canonical money-storage migration is authorized.

## 4. Reference-entity matching/conflicts

**Decision:** Exact established identity may match; semantic/name similarity is a proposal, not automatic identity. Ambiguity requires explicit resolution.

## 5. Evidence/provenance projection

**Decision:** Project admitted semantic provenance only. Do not export machine-local `stored_file_uri` as transferable identity. Raw evidence bytes are not automatically part of portable JSON v1.

## 6. Import-file provenance

**Decision:** Import source files are workflow inputs, not automatically TransactionSource/evidence. Temporary workspace retention may be used only for the import lifecycle.

## 7. Coherent snapshot semantics

**Decision:** Export only coherent durable state with deterministic representation/version metadata. Unsaved/transient UI state is not portable truth.

## 8. Data deletion / clear-data authority

**Decision:** Do not claim erasure of all Lumen-managed local data unless every admitted durable responsibility under Lumen's control, including retained evidence, is covered. Transaction deletion alone is not complete local erasure, and user-controlled exported copies outside Lumen-managed storage remain outside that authority.

## 9. Batch persistence / failure semantics

**Decision:** Use all-or-nothing v1 promotion for all canonical effects authorized by one confirmation boundary within the supported size envelope. Partial/chunked canonicalization requires contract revision backed by evidence.

## 10. Transient vs durable import concepts

**Decision:** Meaningful review progress has earned durability. Individual conceptual entities have not automatically earned separate persisted models.

## 11. Guaranteed formats vs foreign formats

**Decision:** Lumen JSON and Lumen CSV are guaranteed. Non-Lumen CSV may be progressively mapped. Arbitrary JSON is deferred unless a specific adapter is admitted.

## 12. Import readiness / required vs optional meaning

**Decision:** READY / NEEDS RESOLUTION / INVALID-UNSUPPORTED are pre-canonical proposal states. Required meaning must be resolved; optional context may remain absent. Under the current canonical creation contract, Category is required for confirmation even though a source file need not contain a Category column.

## 13. Resumable workspace durability

**Decision:** Import Review is an automatically preserved, resumable noncanonical workspace. A controlled source copy may be retained while required and retired after confirm/discard. Once explicit discard is durably accepted, edit/promotion authority is revoked even if cleanup residue remains. Persistence mechanism remains unselected.

## 14. Active import-session cardinality

**Decision:** At most one active/promotable workspace in v1. Nonpromotable residue after established promotion or durably accepted discard is not import authority and must not permanently consume the feature's active slot.

## 15. Confirmation/recovery authority

**Decision:** Every canonical effect authorized by one import confirmation boundary must share that boundary's atomicity/replay-safety contract. Canonical promotion proof must share the canonical authority boundary or promotion must be provably idempotent. A separate workspace success flag is insufficient. Exact mechanism requires later admission.

## 16. Promotion identity vs duplicate detection

**Decision:** Promotion replay safety is deterministic canonical-control behavior. Transaction duplicate-awareness is a separate import-review concern and must not serve as crash-recovery proof.

---

# 33. Next Step After Contract Review

If this contract is accepted and made canonical, the next step is **not** to add import models or start coding the importer.

The next sequence is:

```text
Phase 1C responsibility contract accepted
        ↓
define exact Lumen Portable JSON / CSV v1 format contract
        ↓
define exact first implementation capability
        ↓
persistence / recovery admission where required
        ↓
ADMIT / REVISE / DEFER / REJECT
        ↓
only then:
smallest implementation plan + tests
```

Real-world CSV format research may proceed in parallel as non-production evidence gathering.

No production implementation, schema migration, promotion receipt, workspace storage mechanism, or implementation-pass sequence is inferred merely from acceptance of this responsibility contract.
