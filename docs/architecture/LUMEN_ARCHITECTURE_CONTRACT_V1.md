# Lumen Architecture Contract v1.0

## Status

**Canonical and frozen as of v1.0.**

This document defines the current product and engineering invariants for Lumen.

Future implementation work, Rork prompts, pull requests, architecture changes, and backend decisions should conform to this contract unless an explicit Architecture Decision Record (ADR) changes it.

Architecture terminology does not by itself require code churn. Existing implementation names may continue to fulfill canonical responsibilities until there is a concrete implementation reason to rename or refactor them.

### Governance

This contract is intended to change rarely.

Implementation discoveries should normally become:

- phase acceptance criteria;
- automated tests;
- implementation documentation; or
- ADRs where an architectural decision requires explicit rationale.

They should not automatically become additional Contract clauses.

New Contract clauses or revisions should be reserved for genuinely new or changed cross-cutting product or architectural rules.

Once this document is checked into the repository, the checked-in version is authoritative over prior conversational summaries, prompts, or planning discussions.

---

# 1. Product Thesis

Lumen is a calm, local-first financial-awareness application.

Its guiding principle is:

**Financial Awareness over Financial Restriction.**

Lumen should help users understand:

- what they spent or received;
- when financial activity occurred;
- how spending and income patterns change over time;
- how activity relates to categories, merchants, payment methods, goals, budgets, and cashflow context;
- why financial patterns may be emerging from the user's own behavior and circumstances.

Lumen should not be designed around guilt, punishment, coercive budgeting, automatic financial intervention, or telling the user what they should or should not purchase.

The product should remain reflective, visually informative, user-controlled, privacy-conscious, and useful even when advanced automation is unavailable.

---

# 2. Foundational Product Loop

The foundational Lumen interaction is:

**Submit → Review/Edit → Save → View/Search/Filter → Inspect**

The user-confirmed financial record is authoritative.

Manual entry remains a first-class input method.

Machine extraction, imported data, OCR, AI, metadata, cloud providers, and external enrichment may propose information, but they do not independently create canonical financial truth.

---

# 3. Canonical Ingestion Convergence

Not every ingestion path begins with evidence or machine extraction.

The canonical convergence point is:

**Draft → Review → Confirm → Transaction**

Examples:

## Manual entry

User Input  
→ Draft  
→ Review  
→ Confirm  
→ Transaction

## Evidence-assisted input

Evidence Artifact  
→ Extraction  
→ Observations  
→ Field Candidates  
→ Resolution  
→ Draft  
→ Review  
→ Confirm  
→ Transaction

## Structured import

CSV / JSON  
→ Parse  
→ Draft(s)  
→ Review  
→ Confirm  
→ Transaction(s)

Only evidence-based inputs require the extraction pipeline.

Manual entry must never be forced through artificial EvidenceArtifact or OCR abstractions.

---

# 4. Source of Truth

The canonical financial source of truth is the user-confirmed `Transaction`.

A `Transaction` represents what Lumen considers confirmed financial history.

A Transaction should remain comparatively clean and should not become a dumping ground for:

- OCR alternatives;
- parser telemetry;
- bounding boxes;
- machine-confidence details;
- unresolved candidates;
- raw recognition output;
- temporary review state;
- provider-specific extraction metadata.

Machine uncertainty belongs to the ingestion domain.

Confirmed financial state belongs to the ledger domain.

---

# 5. Three-State Separation

Lumen must preserve a strong distinction between three categories of state.

## A. Financial state

Represents what actually happened financially.

Examples:

- Transaction;
- amount;
- currency;
- financial status;
- transaction date;
- posted date;
- merchant;
- category;
- payment method;
- tags;
- notes.

## B. Ingestion state

Represents whether input successfully became canonical financial history.

Examples:

- Draft;
- needs review;
- confirmed;
- ignored;
- rejected;
- suspected duplicate.

## C. Machine state

Represents what software believed while interpreting evidence.

Examples:

- Observation;
- FieldCandidate;
- provider confidence;
- Lumen confidence;
- ValidationSignal;
- ResolvedField;
- ExtractionRun;
- alternate candidates.

The canonical direction is:

**Machine uncertainty → Ingestion decision → Confirmed financial state**

These state categories should not leak unnecessarily into one another.

---

# 6. Persist Certainty; Isolate Uncertainty

This is the primary schema-review heuristic for Lumen.

**Persist durable product state. Keep uncertain processing state transient unless persistence has a demonstrated product, audit, debugging, recovery, or reprocessing purpose.**

Examples of state that should generally be persisted:

- confirmed Transactions;
- Categories;
- PaymentMethods;
- Tags;
- durable evidence metadata;
- user settings;
- future Budgets, Goals, and CashflowPhases when implemented.

Examples that should generally remain transient initially:

- Observations;
- FieldCandidates;
- ValidationSignals;
- ResolvedFields;
- ExtractionRun internals;
- temporary confidence calculations.

A processing concept does not automatically deserve its own SwiftData model or persistence table.

---

# 7. TransactionSource and EvidenceArtifact

`TransactionSource` is the current implementation name.

`EvidenceArtifact` is the canonical domain responsibility.

The existing source model should evolve toward representing:

> User-provided evidence that may support the creation, interpretation, verification, or audit of one or more financial records.

Potential artifact types include:

- receipt photo;
- screenshot;
- purchase-notification screenshot;
- email-receipt screenshot;
- CSV;
- JSON;
- paystub;
- other user-provided files.

Manual entry may remain source-free or use a lightweight manual-origin marker where useful.

Do not rename `TransactionSource` merely to make terminology match this document.

Rename or refactor only when there is concrete implementation value.

---

# 8. Evidence Relationship Direction

The long-term evidence model must not permanently assume:

**Transaction → exactly one source**

Future architecture must accommodate:

## One artifact to many transactions

Example:

CSV import  
→ Transaction A  
→ Transaction B  
→ Transaction C

## One transaction to multiple artifacts

Example:

Receipt photo ─────┐  
                   ├→ Transaction  
Email screenshot ──┘

The eventual relationship is therefore conceptually:

**Transaction ↔ EvidenceArtifact**

An explicit relationship entity such as `EvidenceLink` may be introduced when implementation needs justify it.

Phase 1A does not require prematurely implementing a full many-to-many model.

It does require avoiding new assumptions that make future migration unnecessarily difficult.

---

# 9. Evidence Fidelity and Retention

Lumen should preserve evidence fidelity during ingestion and avoid destructive preprocessing where practical.

**Long-term retention of raw evidence is a separate user-controlled and privacy-sensitive decision. Raw evidence is not required to be retained indefinitely merely because it was used during extraction or confirmation.**

Where appropriate during ingestion, interpretation, review, audit, or reprocessing, potentially useful information may include:

- original file or image;
- compressed or processed derivatives;
- raw recognized text;
- line ordering;
- spatial or bounding information;
- alternate recognition candidates;
- file metadata;
- capture/import timestamps;
- parser/provider provenance;
- unresolved alternatives.

Normalization should derive cleaner interpretations without pretending the original observation never existed.

Lumen may eventually allow users to discard original evidence while retaining sufficient non-sensitive provenance to understand how a confirmed record was created.

Retention policies should distinguish:

- evidence required temporarily for processing;
- evidence the user elects to retain;
- derived provenance worth retaining;
- information that should be discarded for privacy or storage reasons.

Evidence fidelity during interpretation does not imply indefinite evidence retention.

---

# 10. Candidate-Based Extraction

Machine-assisted extraction should produce candidates, not truth.

For ambiguous fields, Lumen may retain multiple field-level candidates.

Example:

Field: `transaction_total`

- 83.19
- 88.19
- 83.79

Resolution should occur field by field rather than by selecting one entire competing transaction object.

The best candidate for merchant, amount, date, location, or payment method may come from different extraction or resolution mechanisms.

---

# 11. Confidence

Provider confidence is evidence, not certainty.

Lumen-level confidence may eventually consider:

- provider confidence;
- candidate agreement;
- structural/layout evidence;
- deterministic validation;
- merchant familiarity;
- parser/template familiarity;
- cross-engine agreement;
- correction history;
- unresolved ambiguity.

Confidence should primarily guide Review behavior.

A user-confirmed Transaction does not represent probabilistic truth.

Machine confidence therefore belongs upstream of canonical Transaction state.

Numerical confidence should not be exposed to users unless it proves understandable and useful.

---

# 12. Deterministic Validation

Use machine intelligence to propose.

Use deterministic logic to verify whenever deterministic verification is possible.

Examples include:

- subtotal + tax ≈ total;
- date parsing;
- relative dates such as Today or Yesterday;
- amount-anchor detection near terms such as TOTAL;
- transaction amount versus balance-context disambiguation;
- merchant alias matching;
- duplicate similarity rules;
- line-item arithmetic;
- known formatting and layout rules.

When deterministic evidence conflicts with an AI inference, deterministic evidence should generally be more authoritative for the deterministically verifiable claim.

---

# 13. Corrections and Learning

User corrections are potentially valuable learning signals, but ordinary edits must not automatically become machine-learning feedback.

Meaningful correction:

Machine proposed:  
`48.12`

User confirmed:  
`48.72`

Not necessarily meaningful correction:

User manually typed:  
`48.12`

then changed it before saving.

`CorrectionEvent` semantics should be designed before extraction is introduced.

Persistent correction events should begin only when machine-generated proposals exist and the distinction between proposal and user confirmation is meaningful.

Lumen should first improve through:

- merchant alias learning;
- parser/template improvements;
- deterministic validation;
- user-specific context;
- confidence calibration;
- duplicate improvements;
- resolver improvements.

Model retraining is not the default learning strategy.

---

# 14. Merchant Knowledge

Merchant identity should be distinct from the raw evidence used to discover it.

Long-term concepts may include:

- Merchant;
- MerchantAlias;
- MerchantObservation;
- MerchantResolution.

Example aliases:

- WM SUPCENTER
- WAL-MART
- WALMART.COM
- WM SUPCTR

may resolve to:

**Walmart**

Merchant normalization should be durable, explainable, provider-independent, and useful for analytics.

It should not require repeated cloud AI calls for already-known aliases.

---

# 15. Private Financial History vs Shared Knowledge

Private financial history and sanitized shared knowledge are separate architectural domains.

Private examples include:

- exact transaction amount;
- date;
- receipt;
- personal notes;
- account details;
- precise location;
- purchasing history.

Potential generic shared knowledge might include:

- `"WM SUPCTR"` commonly resolves to `"Walmart"`.

Using generic shared knowledge is not equivalent to contributing knowledge derived from private financial history.

Lumen may consume generic merchant or product knowledge without requiring users to contribute their own financial information.

**Private-to-shared contribution should be off by default unless a future explicit product decision establishes otherwise.**

Any future contribution derived from user transactions, evidence, corrections, or behavioral history must have an explicit privacy and consent model appropriate to the information involved.

Shared merchant or product knowledge must never implicitly expose private financial history.

---

# 16. Local-First Architecture

Lumen should remain useful without:

- an AI model;
- OCR API;
- cloud backend;
- continuous internet access;
- bank aggregation;
- external enrichment.

The preferred common path is:

**Local input → Local processing where practical → Review → Local confirmed Transaction**

Current canonical persistence is local SwiftData.

Cloud services are optional extensions, not the foundation of the ledger.

Lumen should prefer cohesive local modules with explicit internal boundaries over prematurely distributing core domain responsibilities across network services.

The architecture may therefore evolve as a modular monolith where that remains the simplest and most trustworthy implementation.

Independent services should be introduced only when a workload demonstrates a meaningful reason for an independent execution boundary, such as:

- materially different scaling requirements;
- security or isolation requirements;
- remote processing that cannot reasonably occur locally;
- optional cloud synchronization;
- shared cross-user knowledge;
- provider integration;
- deployment or operational independence that materially improves the product.

Microservices are not an architectural objective.

A future service boundary must earn its complexity.

---

# 17. Cloud and Service Boundary

Cloud OCR, cloud semantic models, Supabase, synchronization services, merchant enrichment services, or other providers may be added later.

They must remain adapters or explicitly bounded services around Lumen's domain model.

A provider or remote service may:

- produce observations;
- produce candidates;
- enrich metadata;
- assist with ambiguous interpretation;
- synchronize explicitly selected durable state where future product requirements permit.

A provider or remote service must not:

- write directly to canonical Transactions without the required domain/review rules;
- silently bypass Review for machine-derived financial truth;
- become required for ordinary manual ledger use;
- redefine Lumen's core domain architecture;
- make loss of network access equivalent to loss of the user's core ledger.

Switching providers should not require redesigning the Transaction model.

Remote services should be introduced because they solve a demonstrated product or operational requirement better than the local application can—not because a particular roadmap phase is presumed to require microservices.

---

# 18. AI Role

AI is a capability, not the architecture.

AI may:

- propose;
- rank;
- extract;
- enrich;
- explain;
- assist with ambiguous interpretation.

AI does not:

- silently establish financial truth;
- replace user confirmation;
- become mandatory for core usage;
- justify collecting financial evidence without explicit product need;
- automatically diagnose user psychology or spending motives.

Lumen should remain useful if no AI capability is available.

---

# 19. Current Local Extraction Preference

Given Lumen's current native Swift/SwiftUI implementation, Apple's local Vision/VisionKit capabilities are the preferred **Phase 2 baseline to investigate**.

This is an implementation preference under the current platform architecture, not a permanent dependency of the Lumen domain model.

Potential responsibilities include:

- text recognition;
- alternate candidates;
- confidence;
- bounding regions;
- barcode recognition;
- document structure;
- local preprocessing.

Low-confidence or unresolved evidence may later escalate to optional cloud assistance.

Any cloud extraction path must feed observations or candidates into the same domain-independent resolution pipeline rather than becoming an alternative source of canonical financial truth.

If the platform architecture changes or superior local capabilities become available, the extraction implementation may change without requiring a redesign of Lumen's financial domain.

The durable architectural preference is **local-first extraction**, not permanent dependence on a particular framework.

---

# 20. Barcode and Product Intelligence

Barcode/product intelligence is architecturally compatible but not near-term scope.

Potential future concepts include:

- Product;
- PurchaseItem;
- ProductIdentifier;
- UPC / GTIN;
- MerchantProductObservation.

Its future purpose is item-level financial understanding.

It must not delay:

- ledger hardening;
- evidence architecture;
- portability;
- local extraction baseline;
- cashflow/budget context;
- awareness features.

---

# 21. Durable Persistence Integrity

Canonical financial records must never silently degrade from durable persistence to ephemeral persistence.

An in-memory store is appropriate for:

- previews;
- unit tests;
- isolated development;
- explicitly labeled diagnostics.

It must never silently masquerade as the user's real ledger.

Persistence failures must be surfaced, recovered, or handled explicitly.

A failed write must not be presented to the user as a successful durable save.

---

# 22. Roadmap Authority

The numbered canonical roadmap is authoritative whenever older phase references, matrix labels, or conversation summaries conflict with it.

Canonical phases are:

- Phase 1A — Core Ledger Hardening
- Phase 1B — Evidence & Provenance Foundation
- Phase 1C — Ownership, Portability & Data Management
- Phase 2 — Native / Local Extraction
- Phase 2B — Candidate Resolution, Deterministic Validation & Confidence
- Phase 3A — Budgets & Cashflow Context
- Phase 3B — Merchant Knowledge & Correction-Driven Improvement
- Phase 4 — Awareness & Behavioral Insights
- Phase 5 — Optional Cloud Intelligence
- Phase 6 — Item / Product / Barcode Understanding
- Phase 7 — Pre-Purchase & Advanced Behavioral Experiments

Parallel R&D:

- Lumen Extraction Lab

---

# 23. Convergence Rule

All ingestion paths converge at:

**Draft → Review → Confirm**

Only evidence-based inputs require the extraction pipeline.

This rule is authoritative when future ingestion systems are designed.

---

# 24. Architecture Terminology Does Not Justify Code Churn

Conceptual naming and implementation naming do not have to match immediately.

Do not rename, split, migrate, distribute, or rebuild code merely because architecture diagrams use a newer term or a different deployment model appears more sophisticated.

Refactoring must have implementation value, reduce concrete risk, improve correctness, or materially reduce future migration cost.

Architectural cleanliness alone is insufficient justification.

---

# 25. Persistent Model Changes Are Migrations

Changes to persisted SwiftData model:

- property names;
- types;
- relationships;
- enums;
- semantics;
- optionality;
- identifiers;

must be treated as persistence migrations, not ordinary source-code refactors.

Existing stored data must be explicitly considered.

No persisted field should be renamed or removed through blind search-and-replace.

Migration mechanisms should be selected deliberately based on the actual schema change.

---

# 26. Migration and Persistence Compatibility Testing

Any Phase 1A change that modifies persisted financial models must include appropriate automated persistence or migration compatibility validation.

Testing should demonstrate, where applicable:

**Old persisted state → New application version → Migration → Equivalent financial information survives**

A clean install building successfully is not proof of migration safety.

---

# 27. No Destructive Migration Strategy

Deleting and reseeding the user's store is a development utility.

It is not a production migration strategy.

Production schema evolution must preserve legitimate user-owned financial history unless the user explicitly chooses destructive reset behavior.

---

# 28. Phase 1A Change-Admission Rule

A proposed Phase 1A refactor should be implemented now only when all of the following are true:

1. The existing implementation conflicts with this contract or creates a concrete correctness, data-integrity, trust, or safety problem.
2. Delaying the change would materially increase migration cost or block near-term development.
3. The change has a credible migration, validation, regression-test, and recovery story.

If the primary justification is:

> "This would look architecturally cleaner."

defer it.

---

# 29. Testing Principle

Lumen has moved beyond prototype-only validation.

Core ledger behavior requires automated proof of correctness.

High-value areas include:

- Draft → Transaction conversion;
- signed cashflow behavior;
- persistence round-trips;
- save failure behavior;
- status transitions;
- editing;
- deletion;
- search and filters;
- duplicate rules;
- analytics inclusion/exclusion;
- date handling;
- currency behavior;
- seed idempotency;
- migration compatibility.

UI polish does not substitute for domain correctness.

---

# 30. Extraction Lab

The Lumen Extraction Lab is an approved parallel R&D track.

It is:

- not production architecture;
- not an MVP dependency;
- not allowed to block Phase 1 work;
- not a default production-data collection mechanism.

Its purpose is to benchmark extraction technologies against controlled ground truth.

Useful benchmark metrics include:

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

Review Burden may measure:

- fields highlighted per transaction;
- fields corrected per transaction;
- time-to-confirm;
- zero-correction transactions;
- one-correction transactions;
- two-plus-correction transactions.

Production adoption should be earned through measurable improvement.

The Lab should remain useful even if Lumen never ships a VLM or fine-tuned model.

---

# 31. Model Fine-Tuning

Model fine-tuning, LoRA, or custom-model training is a future R&D possibility only.

It is not:

- an MVP requirement;
- a production dependency;
- the default improvement strategy.

It should only be considered after:

- a sufficiently large and legitimate benchmark/correction corpus exists;
- conventional parsing and resolver improvements have been exhausted;
- measured evidence shows adaptation would materially improve the product;
- privacy and consent requirements are explicitly satisfied.

---

# 32. Product Safeguard

Lumen contains two broad intelligence programs.

## Ingestion intelligence

Can Lumen accurately understand the financial information the user gives it?

Relevant phases include:

- 1B;
- 2;
- 2B;
- 3B;
- 5;
- 6.

## Awareness intelligence

Once Lumen understands the data, can it give the user useful financial context?

Relevant phases include:

- 3A;
- 4;
- 7.

Awareness intelligence is the reason ingestion intelligence exists.

Extraction technology must not become the product objective.

---

# 33. Current Highest-Priority Engineering Work

Current production priority is:

## Phase 1A — Core Ledger Hardening

Focus on:

- trustworthy SwiftData persistence;
- explicit save failure handling;
- schema/version/migration safety;
- canonical Transaction semantics;
- separation of financial lifecycle from ingestion disposition where justified;
- manual entry reliability;
- Draft → Review → Confirm behavior;
- edit/delete correctness;
- categories;
- payment methods;
- reusable tags;
- notes;
- timestamps;
- currency/date correctness;
- list/search/filter;
- transaction inspection;
- duplicate-awareness semantics;
- realistic seed/reset behavior;
- automated domain and persistence tests;
- future Phase 1B compatibility.

Phase 1A should leave Lumen genuinely useful even if machine extraction never ships.

---

# 34. Explicit Non-Goals for Current Development

Lumen is not currently building:

- Plaid or equivalent bank aggregation as a core dependency;
- automatic bank scraping;
- automatic transaction truth from OCR;
- auto-saving machine-extracted records;
- mandatory AI;
- mandatory cloud OCR;
- mandatory Supabase sync;
- mandatory cloud accounts;
- mandatory cloud image storage;
- automatic money movement;
- automatic micro-transfers;
- algorithmic purchase restriction;
- guilt-based gamification;
- psychological diagnosis from spending;
- retailer arbitrage;
- retailer scraping infrastructure;
- automatic store-brand replacement recommendations;
- barcode/product systems in Phase 1;
- model fine-tuning in production;
- automatic sharing of private financial history;
- mandatory sharing of correction data;
- family/shared financial workspaces in the near term;
- heavy background workflow infrastructure;
- forcing users to obtain third-party OCR API keys;
- cycling free API accounts or similar provider workarounds;
- microservices merely for architectural fashion or speculative scale.

These require explicit future product decisions.

---

# 35. Canonical Engineering Rules

When uncertain, apply these rules:

**Financial Awareness over Financial Restriction.**

**The user-confirmed Transaction is canonical.**

**All ingestion paths converge at Draft → Review → Confirm.**

**Machine extraction creates candidates, not truth.**

**Resolve fields independently.**

**Provider confidence is evidence, not certainty.**

**Deterministic validation outranks AI inference where deterministic verification is possible.**

**Persist certainty; isolate uncertainty.**

**Keep Transaction clean.**

**Financial state, ingestion state, and machine state are distinct.**

**Local processing is the preferred common path.**

**Prefer cohesive local modules; distribute only when a service boundary earns its complexity.**

**Cloud intelligence is optional escalation.**

**AI is a provider-level capability, not domain architecture.**

**Shared knowledge must remain separate from private financial history.**

**Private-to-shared contribution is off by default unless explicitly changed by future product policy.**

**Persistent model changes are migrations.**

**Durability failures must never masquerade as successful saves.**

**Extraction exists to improve financial awareness; financial awareness does not exist to justify extraction technology.**
