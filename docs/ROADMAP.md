# Lumen Canonical Roadmap

## Status

**Canonical implementation roadmap.**

This document defines the current implementation sequence, phase scope, phase boundaries, and completion criteria for Lumen.

It is subordinate to:

`docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`

If this roadmap conflicts with the Architecture Contract, the Architecture Contract wins.

Older planning notes, prompts, conversational summaries, phase labels, and implementation proposals are non-authoritative when they conflict with the checked-in Contract or this roadmap.

The purpose of this roadmap is to answer:

> What are we building, in what order, what counts as complete, and what later work must not silently leak into the active phase?

A later phase may be researched, benchmarked, or designed early where useful, but production implementation should not be pulled forward unless doing so is required to complete the active phase safely.

---

# 1. Roadmap Principles

Lumen follows these implementation principles:

- Local-first financial awareness remains the product objective.
- The user-confirmed `Transaction` remains canonical.
- All financial transaction ingestion paths converge at `Draft → Review → Confirm`.
- Manual entry remains first-class.
- Durable financial state is stabilized before machine extraction is expanded.
- Machine-generated information remains upstream of canonical financial truth.
- Deterministic validation should be preferred where deterministic verification is possible.
- Architecture should become modular before it becomes distributed.
- Remote services should be introduced only when they earn their operational complexity.
- Production features should not depend on speculative future infrastructure.
- Architectural cleanliness alone does not justify pulling future work into the current phase.
- Persistent schema changes are migrations, not ordinary refactors.
- Phase completion requires evidence of correctness, not merely visible UI completion.
- Each phase should leave the application in a valid, testable, usable state.

The current production priority is:

**Phase 1A — Core Ledger Hardening**

---

# 2. Canonical Phase Sequence

The numbered production roadmap is:

1. **Phase 1A — Core Ledger Hardening**
2. **Phase 1B — Evidence & Provenance Foundation**
3. **Phase 1C — Ownership, Portability & Data Management**
4. **Phase 2 — Native / Local Extraction**
5. **Phase 2B — Candidate Resolution, Deterministic Validation & Confidence**
6. **Phase 3A — Budgets & Cashflow Context**
7. **Phase 3B — Merchant Knowledge & Correction-Driven Improvement**
8. **Phase 4 — Awareness & Behavioral Insights**
9. **Phase 5 — Optional Cloud Intelligence**
10. **Phase 6 — Item / Product / Barcode Understanding**
11. **Phase 7 — Pre-Purchase & Advanced Behavioral Experiments**

Parallel R&D:

- **Lumen Extraction Lab**

The Extraction Lab is not a numbered production phase and must not block the core roadmap.

---

# Phase 1A — Core Ledger Hardening

## Purpose

Establish Lumen as a trustworthy local financial ledger before expanding evidence ingestion, extraction, cloud integration, budgeting, or advanced intelligence.

Phase 1A converts prototype-quality persistence and domain behavior into a foundation that can safely evolve.

The application should remain useful if OCR, AI, cloud services, and advanced extraction are never implemented.

## Entry Criteria

Phase 1A may begin when:

- the existing local Swift/SwiftUI application builds;
- manual transaction creation exists;
- Review exists;
- a local persistence path for confirmed Transactions currently exists;
- Transactions can be viewed and edited;
- Architecture Contract v1.0 is checked into the repository.

The existence of a local persistence path does **not** certify that the current persistence implementation is trustworthy.

Determining and hardening that behavior is part of Phase 1A.

---

## In Scope

### 1A.1 Persistence Integrity

Verify and harden durable SwiftData persistence behavior.

Phase 1A must address:

- silent fallback from durable production storage to ephemeral memory;
- swallowed persistence errors;
- UI flows that report success when durable writes failed;
- explicit separation between production, preview, test, and diagnostic stores;
- persistence across application relaunch;
- recoverable and understandable failure behavior.

Canonical financial records must never silently degrade from durable storage to an ephemeral store.

---

### 1A.2 Schema Evolution and Migration Safety

Establish an explicit SwiftData schema-versioning and migration strategy before substantial persistent-model changes continue.

Persisted changes involving:

- property names;
- property types;
- enums;
- relationships;
- optionality;
- identifiers;
- semantic meaning;

must be treated as migrations.

Phase 1A should:

- preserve legitimate existing financial data;
- avoid destructive reset/reseed as a production migration strategy;
- establish compatibility testing where persistent schema changes occur;
- distinguish clean-install success from migration success.

---

### 1A.3 Canonical Transaction Semantics

Audit and harden what belongs in canonical `Transaction`.

Clarify and enforce the semantics of:

- transaction identity;
- transaction type;
- amount;
- currency;
- transaction date;
- posted date;
- financial lifecycle;
- merchant;
- category;
- payment method;
- tags;
- notes;
- creation timestamp;
- modification timestamp.

Machine uncertainty should not become increasingly embedded in confirmed financial state.

Existing machine-oriented fields should be audited before migration decisions are made.

---

### 1A.4 Financial State vs Ingestion State

Audit the existing `TransactionStatus` implementation and all behavioral dependencies on it.

Establish a clean conceptual distinction between:

#### Financial lifecycle

Examples:

- pending;
- posted;
- reversed;
- refunded where appropriate.

and:

#### Ingestion / review disposition

Examples:

- needs review;
- confirmed;
- ignored;
- rejected;
- suspected duplicate.

Do not perform a blind enum replacement.

Before any migration:

- inspect existing persisted values;
- inspect current Review behavior;
- inspect Transaction Detail behavior;
- inspect analytics inclusion/exclusion;
- determine what legacy records actually mean.

If a fully clean split cannot be introduced safely during Phase 1A, an explicit migration-safe intermediate state may be used and documented.

---

### 1A.5 Draft Boundary

Preserve and harden the existing `TransactionDraft` role.

The canonical financial transaction convergence remains:

`Draft → Review → Confirm → Transaction`

Manual entry must continue to use this boundary.

Phase 1A must not replace a useful existing implementation merely to match newer architectural terminology.

The Draft boundary should be prepared to support future evidence-assisted and structured-import inputs without requiring those later systems to be implemented now.

---

### 1A.6 Review and Confirmation

Review is the final user-controlled boundary before canonical financial persistence.

Ensure:

- a draft must be valid before confirmation;
- machine- or import-derived proposals cannot silently become confirmed truth;
- failed persistence does not produce success UI;
- ignored/rejected behavior is semantically clear;
- duplicate warnings do not silently change canonical state;
- confirmation results in durable, inspectable financial records.

---

### 1A.7 CRUD Correctness

Verify and harden:

- create;
- inspect;
- edit;
- delete;
- lifecycle/status changes where currently supported.

Deletion should require explicit confirmation where appropriate.

Edits should correctly update modification timestamps and durable state.

A successful UI interaction must correspond to a successful persistence operation.

---

### 1A.8 Duplicate Semantics

Audit current duplicate behavior and the meaning of `duplicate_fingerprint`.

Distinguish two different future responsibilities:

#### Evidence duplication

Examples:

- identical file;
- identical content hash;
- repeated upload of the same artifact.

#### Transaction duplication

Examples:

- same or similar merchant;
- same or similar amount;
- nearby transaction date;
- same payment method;
- other transaction-level similarity signals.

Phase 1A should clarify and harden current **transaction duplicate** behavior.

It should not prematurely implement the Phase 1B evidence architecture.

Duplicate warnings should be actionable and understandable.

Potential interactions may include:

- Save anyway;
- View likely match;
- Mark duplicate;
- Ignore;
- Cancel.

The exact UX should be admitted by implementation need rather than assumed by this roadmap.

---

### 1A.9 Analytics Correctness

Define which records contribute to:

- spending;
- income;
- net flow;
- category totals;
- weekly activity;
- current dashboard summaries;
- other existing aggregates.

Explicitly define behavior for:

- ignored records;
- rejected records;
- suspected duplicates;
- confirmed duplicates;
- pending Transactions;
- posted Transactions;
- transfers;
- refunds.

Transfers must not accidentally inflate both spending and income.

Refund behavior must be intentional.

Duplicate/review state must not unintentionally distort financial totals.

These semantics should be tested.

---

### 1A.10 Money and Currency Correctness

Audit the current `Double`-based monetary representation.

Determine whether the existing representation can safely remain for the current phase or whether migration to an **exact, currency-aware representation** is justified under the Phase 1A change-admission rule.

Potential representations may include:

- `Foundation.Decimal`;
- integer minor units with appropriate currency exponent semantics;
- another exact representation justified by the implementation.

The roadmap does not preselect the migration.

If integer minor units are considered, implementation must account for currencies that do not use two fractional digits.

Regardless of representation:

- amount semantics must be explicit;
- transaction type must not conflict with sign conventions;
- arithmetic must be sufficiently deterministic for financial behavior;
- persisted values must survive migration correctly;
- currency must be explicit;
- different currencies must not be silently aggregated as equivalent.

Cross-currency conversion is **not** required in Phase 1A.

Where no conversion exists, foreign-currency values should be excluded, separated, or clearly identified rather than incorrectly summed.

---

### 1A.11 Date and Timezone Correctness

Clarify the semantics of:

- transaction date;
- posted date;
- created timestamp;
- updated timestamp.

A user timezone may default from the device/system.

Location permission must not be required merely to determine timezone.

Date-only financial concepts must not be incorrectly shifted because of timezone conversion.

Future evidence capture timestamps and import timestamps are separate concepts and should not be conflated with financial transaction dates.

---

### 1A.12 Search, Filter and Inspection

Verify current transaction-browsing behavior.

Support reliable inspection through relevant existing dimensions such as:

- text;
- transaction type;
- financial status where appropriate;
- review disposition where appropriate;
- category;
- payment method;
- date where supported.

Filters should:

- compose predictably;
- be visible when active;
- be clearable;
- not produce misleading aggregates or hidden state.

Phase 1A does not require building an advanced search platform.

---

### 1A.13 Seed and Developer Data

Ensure seed behavior is predictable and idempotent.

Development reset/reseed utilities must remain distinct from production data behavior.

Seed/test data should not:

- unexpectedly duplicate on launch;
- contaminate real financial history;
- masquerade as migration behavior.

Developer and feature-flag diagnostics should not unintentionally appear as ordinary production functionality.

---

### 1A.14 Accessibility and Core Interaction Correctness

Fix interaction problems that materially affect completion of the core ledger workflow.

Examples include:

- keyboard obscuring important fields or actions;
- inaccessible touch targets;
- missing VoiceOver labels on critical controls;
- unclear destructive actions;
- inaccessible Review controls;
- inability to reliably complete manual entry.

Phase 1A is **not** a visual redesign.

The current calm visual identity should be preserved unless a usability issue requires change.

---

### 1A.15 Automated Correctness

Establish meaningful automated coverage for correctness-sensitive behavior.

High-value areas include:

- `TransactionDraft → Transaction`;
- transaction-type semantics;
- monetary sign behavior;
- financial lifecycle behavior;
- ingestion/review disposition behavior;
- Review confirmation;
- persistence round-trip;
- save-failure behavior where testable;
- edit behavior;
- deletion behavior;
- analytics inclusion/exclusion;
- duplicate matching;
- date behavior;
- currency behavior;
- seed idempotency;
- migration compatibility where schema changes occur.

UI polish does not substitute for domain correctness.

---

## Phase 1A Change-Admission Rule

A proposed Phase 1A refactor should be implemented now only when all three conditions are satisfied:

1. The current implementation conflicts with the Architecture Contract or creates a concrete correctness, data-integrity, trust, or safety problem.
2. Delaying the change would materially increase migration cost or block near-term development.
3. The change has a credible migration, validation, regression-test, and recovery strategy.

If the primary justification is:

> "This would look architecturally cleaner."

defer it.

Examples of likely admitted work:

- silent in-memory production fallback;
- swallowed save failures;
- persistent-schema safety;
- domain-state conflation where delaying materially increases migration risk.

Examples of likely deferred work:

- renaming `TransactionSource` solely to match `EvidenceArtifact`;
- implementing a complete many-to-many evidence model before needed;
- renaming persisted snake_case Swift properties solely for style;
- introducing extraction-domain types before Phase 1B/2 requires them.

---

## Explicitly Deferred From Phase 1A

Do not implement merely as part of Phase 1A:

- Apple Vision OCR;
- production OCR;
- Observation persistence;
- FieldCandidate persistence;
- ResolvedField persistence;
- ExtractionRun infrastructure;
- CorrectionEvent persistence;
- complete EvidenceLink many-to-many modeling unless a concrete Phase 1A migration requires it;
- merchant-learning systems;
- cloud OCR/VLM providers;
- production Supabase synchronization;
- production Supabase schema as a second canonical persistence system;
- cloud authentication;
- barcode/product systems;
- item-level receipt understanding;
- production Budgets;
- production CashflowPhases;
- advanced Insights;
- family/shared accounts;
- cloud-first accounts;
- model fine-tuning;
- major UI redesign;
- `TransactionSource → EvidenceArtifact` rename solely for terminology consistency.

---

## Phase 1A Exit Criteria

Phase 1A is complete when:

- the application builds successfully;
- durable production persistence cannot silently degrade to an in-memory ledger;
- failed financial writes are surfaced rather than represented as successful saves;
- a confirmed Transaction survives application relaunch;
- canonical Transaction semantics are understood and enforced;
- financial lifecycle and ingestion/review semantics are no longer ambiguously conflated, or an explicitly documented migration-safe intermediate state has been adopted;
- `TransactionDraft` remains a stable Draft → Review convergence point;
- current CRUD flows work reliably;
- duplicate behavior is explicit and does not unintentionally distort analytics;
- current financial aggregates follow documented inclusion/exclusion semantics;
- money/currency semantics are explicit and tested appropriately;
- date/timezone semantics are explicit;
- persisted-model changes introduced during the phase have an explicit migration story;
- appropriate automated domain and persistence tests exist;
- migration compatibility is validated for schema changes introduced in the phase;
- development reset behavior cannot be mistaken for production migration behavior;
- Phase 1B can begin without first undoing Phase 1A design decisions.

---

## Required Phase 1A Validation Report

A Phase 1A implementation report must separately state the following.

### Build Validation

Does the current project compile and build successfully?

### Clean-Install Validation

Does a newly installed application initialize and function correctly?

### Existing-Store Compatibility

Can a store created by the pre-Phase-1A application still be opened with legitimate financial information preserved?

### Migration Validation

For each persisted schema change:

- what changed;
- what migration occurred;
- how old data was represented;
- how the migration was tested;
- whether equivalent financial information survived.

### Domain Tests

Which financial/domain behaviors are automatically tested?

### Persistence Tests

Which durability, save/reload, or migration behaviors are automatically tested?

### Known Deferrals

What identified issues were deliberately deferred?

Why were they deferred?

Which future phase owns them?

**"Build succeeded" alone is not sufficient Phase 1A validation.**

---

# Phase 1B — Evidence & Provenance Foundation

## Purpose

Introduce the durable architecture required for user-provided financial evidence without yet attempting sophisticated production extraction.

Phase 1B establishes how receipts, screenshots, files, and other evidence relate to Drafts and confirmed Transactions.

---

## Entry Criteria

- Phase 1A exit criteria are satisfied.
- Canonical Transaction semantics are stable enough to build ingestion around.
- Persistence and migration practices are established.
- `TransactionDraft` is a reliable convergence point.

---

## In Scope

### Evidence Responsibility

Evolve the current `TransactionSource` implementation toward the canonical `EvidenceArtifact` responsibility.

This does not require a terminology-only rename.

Define:

- evidence identity;
- evidence metadata;
- evidence provenance;
- source type;
- capture/import timestamps where relevant;
- original-file identity;
- content hash where useful;
- processing status;
- retention state.

### Evidence Retention

Establish explicit distinction between:

- evidence temporarily required for processing;
- evidence the user elects to retain;
- durable provenance worth keeping;
- evidence the user chooses to discard.

Evidence fidelity during interpretation must not imply indefinite raw-file retention.

### Evidence Relationships

Define how evidence may eventually support:

- one artifact → many Transactions;
- one Transaction → many artifacts.

Avoid deepening a permanent one-Transaction/one-source assumption.

Introduce an explicit `EvidenceLink` only when implementation value justifies it.

### Draft Integration

Extend the existing `TransactionDraft` so future evidence-assisted input can populate proposals without becoming canonical truth.

### Provenance

Define an appropriate durable provenance or versioned extraction snapshot strategy where concrete audit/reprocessing value exists.

### Future Processing Contracts

Define transient domain contracts for:

- `Observation`;
- `FieldCandidate`;
- `ValidationSignal`;
- `ResolvedField`;
- `ExtractionRun`.

These concepts do not automatically become persisted SwiftData models.

### Correction Events

Define `CorrectionEvent` semantics.

Do not persist every edit, keystroke, or manual correction.

Persistent correction learning is deferred until meaningful machine proposals actually exist.

---

## Explicitly Deferred From Phase 1B

- sophisticated production OCR;
- cloud VLM extraction;
- merchant learning;
- model training;
- barcode intelligence;
- item-level understanding;
- automatic transaction creation;
- mandatory raw-image retention;
- mandatory cloud storage.

---

## Phase 1B Exit Criteria

Phase 1B is complete when:

- evidence can enter Lumen without automatically becoming canonical financial truth;
- evidence-assisted input can converge on the same Draft/Review boundary as manual entry;
- evidence identity and provenance are representable;
- retention behavior is privacy-conscious and explicit;
- future one-to-many and many-to-many evidence relationships remain possible;
- machine-state concepts are separated from canonical Transaction state;
- Phase 2 extraction can be implemented without redesigning Transaction.

---

# Phase 1C — Ownership, Portability & Data Management

## Purpose

Ensure users can understand, manage, export, and re-import their durable financial data before richer automation increases system complexity.

Phase 1C establishes meaningful local data ownership rather than export-only portability.

---

## Entry Criteria

- Phase 1A exit criteria are satisfied.
- Phase 1B exit criteria are satisfied.
- Canonical durable state and evidence/provenance boundaries are stable enough to serialize intentionally.

---

## In Scope

### Export

Implement:

- stable versioned JSON export;
- useful CSV export;
- export schema/version metadata;
- export manifest where appropriate;
- documented representation of supported durable state.

### Structured Import

Implement supported structured import.

For transaction-bearing imported records, support:

- JSON import from Lumen's documented/versioned portable schema;
- a deliberately scoped and documented CSV schema;
- import preview;
- field validation;
- import duplicate-awareness using existing transaction semantics;
- `TransactionDraft` generation;
- Review before confirmation.

Transaction-bearing imports must follow:

`Structured Transaction Data → Parse → TransactionDraft(s) → Review → Confirm → Transaction(s)`

**Transaction-bearing imported records must enter through `TransactionDraft(s) → Review → Confirm`.**

Supported reference data such as:

- Categories;
- PaymentMethods;
- Tags;

may be restored through an explicit import preview/confirmation workflow appropriate to those entities and must **not** be forced through artificial `TransactionDraft` objects.

Imports must never silently create canonical financial truth.

Transaction-bearing imports must pass through Review before confirmation.

Non-transaction durable entities must use an explicit confirmation workflow appropriate to their domain.

Phase 1C does **not** require compatibility with arbitrary CSV exports from every:

- bank;
- credit-card issuer;
- retailer;
- payment processor;
- budgeting application.

Additional external format adapters may be introduced deliberately later.

### Round-Trip Ownership

The target round-trip is conceptually:

`Lumen durable data`
→ `Versioned export`
→ `Fresh Lumen installation/store`
→ `Import`
→ `Preview / Draft(s)`
→ `Review / Confirmation`
→ `Equivalent supported canonical state`

For transaction-bearing data:

`Export`
→ `Import`
→ `TransactionDraft(s)`
→ `Review`
→ `Confirm`
→ `Transaction(s)`

For supported reference data:

`Export`
→ `Import`
→ `Entity-specific preview`
→ `Confirm`
→ `Category / PaymentMethod / Tag / other supported entity`

"Equivalent" refers to the durable fields and entities explicitly supported by the portable format.

Potential supported durable state may include:

- Transactions;
- Categories;
- PaymentMethods;
- Tags;
- relevant durable provenance;
- other explicitly versioned canonical data.

**Round-trip ownership does not require restoration of transient extraction state or raw evidence that was intentionally excluded, discarded, or governed by a separate retention policy.**

The export format should not serialize the entire internal object graph merely because internal state exists.

### Data Management

Implement or harden:

- category management;
- payment-method management;
- tag management;
- evidence/source inspection;
- clear-data controls;
- safe development reseed utilities;
- import validation infrastructure.

---

## Explicitly Deferred From Phase 1C

- arbitrary bank CSV compatibility;
- open-ended financial-file normalization;
- cloud synchronization;
- mandatory cloud backups;
- OCR-based imports;
- cloud accounts;
- automatic reconciliation across institutions.

---

## Phase 1C Exit Criteria

Phase 1C is complete when:

- user-owned canonical data can be exported in a documented versioned format;
- supported transaction-bearing imports produce `TransactionDraft(s)` and never bypass Review;
- supported reference data can be restored through explicit entity-appropriate preview/confirmation;
- a supported Lumen export can be re-imported with supported canonical fields preserved appropriately;
- round-trip ownership is validated without requiring restoration of transient extraction state;
- core classifications and reference data can be managed;
- relevant evidence/source metadata can be inspected;
- portability does not depend on a future cloud backend.

---

# Phase 2 — Native / Local Extraction

## Purpose

Establish a useful on-device extraction baseline for deliberately supported financial evidence.

Given the current native Swift/SwiftUI implementation, Apple Vision/VisionKit is the preferred baseline to investigate.

This is a current platform implementation preference, not a permanent Lumen domain dependency.

---

## Entry Criteria

- Phase 1A exit criteria are satisfied.
- Phase 1B exit criteria are satisfied.
- **Phase 1C exit criteria are satisfied.**
- Evidence can be represented without becoming canonical truth.
- `TransactionDraft` accepts evidence-assisted proposals.

Research, benchmarking, or Extraction Lab work related to local extraction may occur before Phase 1C completion.

Production Phase 2 implementation must respect the canonical phase sequence.

---

## Supported-Evidence Matrix

Before Phase 2 implementation expands, define and version a deliberately narrow supported-evidence matrix.

The matrix should identify each evidence type as something such as:

- Supported;
- Experimental;
- Deferred;
- Unsupported.

Potential future examples might include:

| Evidence Type | Example Status |
| --- | --- |
| Receipt photo | To be decided |
| Purchase screenshot | To be decided |
| Card-notification screenshot | To be decided |
| Email-receipt screenshot | To be decided |
| Multi-page PDF | To be decided |
| Paystub | To be decided |
| Handwritten financial note | To be decided |

This roadmap does **not** decide the initial matrix.

Phase 2 must decide it intentionally before implementation.

Unsupported evidence must degrade safely to:

- manual entry;
- manual Review;
- unsupported-format messaging;

rather than causing implicit scope expansion.

---

## In Scope

For supported evidence, local extraction may propose:

- recognized text;
- merchant candidates;
- amount candidates;
- date candidates;
- relative-date clues;
- source metadata;
- optional payment clues;
- bounding/layout information;
- alternate recognition candidates;
- provider confidence.

Results feed `TransactionDraft`.

They do not directly save canonical Transactions.

---

## Phase 2 Exit Criteria

Phase 2 is complete when:

- a deliberately versioned supported-evidence matrix exists;
- supported evidence can produce useful local draft candidates;
- unsupported evidence degrades safely rather than silently expanding scope;
- extraction remains optional;
- manual completion remains possible;
- machine proposals cannot bypass Review;
- provider-specific implementation can be replaced without redesigning canonical Transaction;
- local extraction failures do not compromise the ledger.

---

# Phase 2B — Candidate Resolution, Deterministic Validation & Confidence

## Purpose

Improve extraction reliability while preserving uncertainty and user authority.

---

## In Scope

### Field-Level Resolution

Support:

- candidate ranking;
- independent field resolution;
- multiple candidates where ambiguity remains.

Do not require one extraction provider to produce one complete authoritative transaction object.

### Deterministic Validation

Potential validation includes:

- subtotal + tax ≈ total;
- total-anchor detection;
- transaction amount vs balance distinction;
- date parsing;
- relative-date resolution;
- layout/spatial heuristics;
- deterministic merchant aliases;
- evidence identity checks;
- transaction duplicate heuristics.

### Confidence

Establish Lumen-level confidence semantics based on relevant signals such as:

- provider confidence;
- candidate agreement;
- deterministic validation;
- layout evidence;
- merchant familiarity;
- parser/template familiarity;
- unresolved ambiguity.

Confidence should primarily guide Review behavior.

### Review Assistance

Use uncertainty to:

- prefill likely values;
- emphasize questionable fields;
- reduce unnecessary user attention;
- avoid hiding ambiguity.

### Provenance

Where useful, allow a resolved field to explain why it was selected.

---

## Production Regression Fixtures

By Phase 2B completion, maintain a small versioned production fixture corpus for extraction/resolution regression testing.

Fixtures may cover examples such as:

- basic receipt;
- transaction notification;
- ambiguous receipt total;
- ambiguous date;
- merchant alias variation;
- duplicate evidence;
- difficult layout.

Fixtures should have stable expected observations, candidates, validations, or resolutions appropriate to the test.

The production regression corpus answers:

> **Did today's implementation make Lumen worse than yesterday?**

This is distinct from the Extraction Lab, which answers:

> **Which extraction technology or approach performs better?**

Some samples may overlap, but their governance and purpose remain separate.

---

## Phase 2B Exit Criteria

Phase 2B is complete when:

- ambiguity is represented rather than hidden;
- fields can be resolved independently;
- deterministic validation is applied where possible;
- Review directs attention toward uncertain fields;
- machine confidence remains upstream of canonical Transaction state;
- resolver behavior is measurable;
- representative extraction/resolution fixtures are versioned;
- regression validation can detect meaningful degradation in known production behavior.

---

# Phase 3A — Budgets & Cashflow Context

## Purpose

Build the financial-context layer that makes Lumen more than a transaction logger.

---

## In Scope

Potential production scope includes:

- Budgets;
- budget allocations;
- CashflowPhases;
- weekly windows;
- biweekly windows;
- monthly windows;
- custom windows;
- recurring phase definitions;
- current-phase awareness;
- phase comparison;
- Goals;
- planned-versus-actual context.

---

## Product Direction

Budgeting remains awareness-oriented rather than punitive.

Lumen should help users understand:

- what they planned;
- what occurred;
- where they are in a cashflow cycle;
- how patterns differ between phases.

It should not impose moral judgment on individual purchases.

---

## Phase 3A Exit Criteria

Phase 3A is complete when:

- users can define useful financial context around confirmed Transactions;
- current financial activity can be understood relative to plans or phases;
- irregular or paycheck-driven budgeting patterns are supported intentionally;
- budgeting remains optional;
- budgeting does not become a prerequisite for ordinary ledger use;
- the experience remains aligned with Financial Awareness over Financial Restriction.

---

# Phase 3B — Merchant Knowledge & Correction-Driven Improvement

## Purpose

Allow Lumen to improve through ordinary software, local knowledge, and meaningful correction signals before relying on custom-model training.

---

## In Scope

Potential scope includes:

- `Merchant`;
- `MerchantAlias`;
- local alias learning;
- alias suggestions;
- parser/template familiarity;
- user-specific resolution improvements;
- confidence calibration;
- extraction performance tracking;
- resolver improvements.

### Correction Events

Persist meaningful machine-proposal → user-confirmation correction events where they materially support:

- learning;
- calibration;
- resolver improvement;
- merchant normalization;
- auditability.

Do **not** treat:

- every edit;
- every keystroke;
- ordinary manual drafting;

as machine-learning feedback.

A meaningful correction requires a useful distinction between:

1. what Lumen proposed;
2. what the user ultimately confirmed.

The lifecycle is therefore:

`Phase 1B`
→ define `CorrectionEvent` semantics

`Phase 2 / 2B`
→ machine proposals and resolution exist

`Phase 3B`
→ meaningful corrections become useful durable improvement signals

---

## Privacy Boundary

Private financial history remains distinct from shared knowledge.

Private-to-shared contribution remains off by default unless a future explicit product decision establishes otherwise.

Local correction learning should not require users to contribute private financial activity to a shared system.

---

## Phase 3B Exit Criteria

Phase 3B is complete when:

- recurring merchant representations can become increasingly consistent;
- useful corrections can improve later resolution without model training;
- meaningful CorrectionEvents are distinguished from ordinary edits;
- confidence or resolver performance can improve based on legitimate signals;
- private financial history remains structurally distinct from shared knowledge;
- private-to-shared contribution remains off by default.

---

# Phase 4 — Awareness & Behavioral Insights

## Purpose

Turn trustworthy financial history into useful, calm financial awareness.

This is the primary product payoff of the ingestion and ledger work that precedes it.

---

## In Scope

Potential scope includes:

- category trends;
- spending rhythms;
- logging cadence;
- phase comparisons;
- recurring merchants;
- subscription awareness;
- planned-versus-actual summaries;
- meaningful visualizations;
- gentle milestones;
- configurable reminders;
- recurring financial patterns.

Insights should begin with observable and explainable facts.

Advanced AI interpretation is not required.

---

## Product Guardrails

Insights should avoid:

- guilt;
- punishment;
- unsupported psychological assumptions;
- coercive spending recommendations;
- manipulative engagement loops.

Lumen may surface:

> "You logged $X this week."

without turning that into:

> "You spent too much and should feel bad."

---

## Phase 4 Exit Criteria

Phase 4 is complete when:

- Lumen surfaces useful context beyond raw transaction lists;
- insights are grounded in understandable underlying data;
- meaningful trends can be inspected;
- notifications remain optional and non-punitive;
- unsupported psychological inference is avoided;
- awareness features continue to function locally where practical.

---

# Phase 5 — Optional Cloud Intelligence

## Purpose

Introduce remote intelligence only where measured local limitations justify it.

Phase 5 is specifically about **optional remote intelligence**.

It does not automatically introduce cloud synchronization, cloud accounts, or a general backend platform.

---

## Entry Principle

A remote capability should be added because it measurably improves a user outcome that cannot be achieved adequately through the local implementation.

"Cloud" is not itself a product feature.

---

## Potential Scope

Examples may include:

- cloud OCR;
- hosted VLM extraction;
- specialized remote enrichment;
- optional advanced interpretation.

Remote providers return:

- observations;
- candidates;
- enrichment;
- explanations;

into existing Lumen domain boundaries.

They do not redefine canonical Transaction.

---

## Service-Boundary Requirement

A remote capability must demonstrate a meaningful reason to exist outside the local application.

Examples include:

- inherently remote compute;
- materially different scaling needs;
- independent security or isolation requirements;
- centralization required by the product;
- independent deployment that provides clear value;
- shared cross-user knowledge where explicitly approved.

A roadmap phase does not earn a microservice merely because it is later or more sophisticated.

---

## Privacy and Data-Egress Boundary

Remote processing must remain optional and user-controlled.

Users should be able to understand:

- what data leaves the device;
- why it leaves the device;
- which capability requires it;
- which provider receives it where applicable.

Transmitted data should be minimized to the demonstrated needs of the capability.

Provider behavior around:

- retention;
- logging;
- privacy;
- storage;
- training usage where relevant;

must be explicitly evaluated before production adoption.

Phase 5 cannot be considered complete merely because remote processing is technically functional.

---

## Failure Boundary

Remote-service failure should degrade the optional capability rather than the core application.

Preferred behavior:

`Cloud extraction unavailable`
→ local/manual Review remains available.

`Remote enrichment unavailable`
→ canonical ledger remains usable.

`Hosted model unavailable`
→ machine assistance degrades gracefully.

Unacceptable behavior:

`Remote service unavailable`
→ user's local financial history becomes inaccessible.

---

## Synchronization Scope

**Cross-device or cloud synchronization is not implied by Phase 5.**

If synchronization is introduced later, it requires explicit roadmap scope and architectural evaluation.

If optional synchronization is eventually introduced, the preferred failure behavior remains:

`Sync unavailable`
→ local work continues and synchronization waits.

This roadmap does not currently assign production synchronization to a numbered phase.

---

## Phase 5 Exit Criteria

**Phase 5 is complete only when every remote capability introduced during the phase satisfies all applicable requirements.**

For every such capability:

- it measurably improves a demonstrated product outcome;
- remote processing remains optional;
- remote processing is user-controlled;
- users can understand what data leaves the device and why;
- transmitted data is minimized appropriately;
- provider retention/privacy behavior has been explicitly evaluated;
- remote-service failure degrades only the optional capability;
- the core ledger remains usable without the remote service;
- machine-generated results still flow through existing Draft/Review boundaries where they represent proposed financial information;
- provider replacement does not require redesigning canonical Transaction.

---

# Phase 6 — Item / Product / Barcode Understanding

## Purpose

Extend Lumen from transaction-level understanding toward item-level purchasing context where product value justifies the additional complexity.

---

## Potential Scope

Examples include:

- `PurchaseItem`;
- `Product`;
- `ProductIdentifier`;
- UPC;
- GTIN;
- receipt itemization;
- barcode recognition;
- OCR/barcode reconciliation;
- item-level categories;
- item-level tags;
- merchant/product observations.

---

## Scope Guardrail

Phase 6 must be informed by actual product needs and Extraction Lab evidence.

The existence of technically interesting barcode or product capabilities does not itself justify implementation.

---

## Exit Criteria

To be defined when Phase 6 becomes active.

This phase remains deliberately provisional and must be reconciled against observed product value and the Architecture Contract before implementation begins.

---

# Phase 7 — Pre-Purchase & Advanced Behavioral Experiments

## Purpose

Explore optional awareness experiences before or around purchases without turning Lumen into a financial intervention system.

---

## Potential Scope

Examples may include:

- purchase-impact context;
- save-for-it workflows;
- wishlist or revisit-later experiences;
- recurring-consumable awareness;
- item-level behavioral context;
- additional user-defined financial profiles;
- optional advanced awareness experiments.

---

## Guardrail

Lumen may inform.

The user decides.

Phase 7 must not convert:

**Financial Awareness**

into:

**Financial Restriction**

Features should not become automatic purchasing intervention, coercive budgeting, or algorithmic permission systems.

---

## Exit Criteria

To be defined when Phase 7 becomes active.

This phase remains deliberately provisional and must be reconciled against observed product value, user needs, and the Architecture Contract before implementation begins.

---

# Parallel R&D — Lumen Extraction Lab

## Purpose

The Lumen Extraction Lab is a separate experimental track for comparing extraction technologies against controlled ground truth.

It is not production architecture.

It is not an MVP dependency.

It must not block the numbered production roadmap.

---

## May Inform

The Lab may inform:

- Phase 2;
- Phase 2B;
- Phase 5;
- Phase 6.

---

## Must Not Block

The Lab must not block:

- Phase 1A;
- Phase 1B;
- Phase 1C;
- Phase 3A;
- Phase 4.

---

## Potential Corpus

The controlled corpus may include:

- synthetic receipts;
- controlled personal receipts;
- deliberately difficult examples;
- transaction screenshots;
- purchase notifications;
- email-receipt images;
- structured documents where appropriate.

Production financial history must not silently become Lab training or benchmark data.

---

## Metrics

Potential benchmark measures include:

- merchant Top-1 accuracy;
- amount Top-1 accuracy;
- date Top-1 accuracy;
- field-level accuracy;
- line-item accuracy;
- Candidate Recall@3;
- Auto-Accept Precision;
- latency;
- resource consumption;
- cost;
- offline capability;
- failure modes;
- Review Burden.

Review Burden may include:

- fields highlighted per transaction;
- fields corrected per transaction;
- time-to-confirm;
- zero-correction transactions;
- one-correction transactions;
- two-plus-correction transactions.

The Lab should optimize for:

**correctness + trustworthiness + lower user correction burden**

rather than OCR accuracy alone.

---

## Extraction Lab vs Production Regression Corpus

These are related but distinct systems.

### Extraction Lab

Answers:

> Which technology or approach performs better?

It may be:

- exploratory;
- comparative;
- provider-oriented;
- experimental.

### Production Regression Corpus

Answers:

> Did today's implementation make Lumen worse than yesterday?

It should be:

- stable;
- versioned;
- deterministic where possible;
- tied to expected application behavior.

Some controlled samples may be shared between them, but their purpose and governance remain distinct.

---

# Service Evolution Guidance

Lumen begins as a local-first application with cohesive internal modules.

Likely responsibility boundaries include:

- Ledger;
- Ingestion;
- Awareness;
- Knowledge;
- Persistence.

Conceptually:

```text
Lumen
│
├── Ledger
│   ├── Transaction
│   ├── Category
│   ├── PaymentMethod
│   └── Tag
│
├── Ingestion
│   ├── TransactionDraft
│   ├── Evidence
│   ├── Review
│   ├── Validation
│   └── Resolution
│
├── Awareness
│   ├── Cashflow
│   ├── Budgets
│   ├── Analytics
│   └── Insights
│
├── Knowledge
│   └── Merchant normalization
│
└── Persistence
    └── SwiftData
