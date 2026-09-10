# Lumen Non-Goals

## Status

**Canonical scope-control document.**

This document defines capabilities, behaviors, and architectural directions that must **not be treated as current implementation requirements** unless the canonical Roadmap assigns them to the active phase.

It is subordinate to:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/ROADMAP.md`

If this document conflicts with either, the Architecture Contract and Roadmap take precedence.

---

# How to Read This Document

A non-goal does not necessarily mean:

> Never.

In many cases it means:

> Not part of the active production phase. Do not implement it merely because the architecture could support it or because it may be useful later.

Lumen has intentionally explored more ideas than it is currently building.

This document exists to prevent:

- roadmap leakage;
- premature abstraction;
- speculative infrastructure;
- architecture-by-fashion;
- AI scope expansion;
- privacy regression;
- future concepts from becoming accidental requirements.

A deferred capability may enter production when the canonical Roadmap assigns it to the active phase.

If it is not already assigned, production adoption requires an explicit Roadmap revision.

If it materially changes an architectural invariant, it also requires the appropriate ADR and Contract review.

---

# Core Product Boundaries

Lumen is not intended to become:

- a guilt-driven budgeting application;
- a spending-permission system;
- an algorithmic financial disciplinarian;
- a system that decides whether a user is "allowed" to purchase something;
- an addictive engagement or streak-maximization product;
- a psychological diagnosis engine based on financial behavior;
- a substitute for professional investment, tax, legal, or regulated financial advice;
- an automatic money-movement system;
- a retailer-arbitrage or large-scale price-scraping platform.

Lumen may provide:

- financial education;
- planning context;
- awareness-oriented guidance;
- comparisons;
- reflection;
- explanations of observable financial patterns.

**The user decides.**

---

# Canonical Financial Data Boundaries

Lumen must not:

- treat OCR, AI, parser, metadata, import, or enrichment output as canonical financial truth;
- create confirmed Transactions directly from OCR, AI, imports, or enrichment in a way that bypasses `Draft → Review → Confirm`;
- require machine extraction for manual ledger use;
- require bank aggregation for the core product;
- silently aggregate different currencies as if they were equivalent;
- discard legitimate user financial history as a migration strategy;
- present failed or ephemeral writes as successful durable saves.

The user-confirmed `Transaction` remains canonical.

For transaction-bearing ingestion:

`Proposal / Input`  
→ `TransactionDraft`  
→ `Review`  
→ `Confirm`  
→ `Transaction`

There is no machine-generated shortcut around that boundary.

---

# Privacy Boundaries

Lumen should not require:

- mandatory cloud storage of financial history;
- mandatory cloud storage of receipts or screenshots;
- mandatory cloud processing;
- a cloud account for ordinary local-ledger use;
- indefinite raw-evidence retention merely because evidence was once processed;
- exact photo geolocation as a default financial-data requirement;
- automatic contribution of private financial history to shared datasets;
- automatic contribution of user corrections to training datasets.

Private-to-shared contribution is off by default unless a future explicit product decision establishes otherwise.

Evidence fidelity during interpretation does not imply permanent retention.

---

# Architecture Boundaries

Lumen is not currently trying to become:

- a microservices application;
- a cloud-first application;
- a collection of remotely deployed domain services;
- a distributed system merely because its internal responsibilities are modular;
- a second cloud persistence architecture running in parallel with an unstable local ledger.

Logical boundaries such as:

- `Ledger`
- `Ingestion`
- `Awareness`
- `Knowledge`
- `Persistence`

do not automatically imply:

- `ledger-api`
- `ingestion-api`
- `analytics-api`
- `merchant-api`

A service boundary must earn its complexity through a concrete requirement such as:

- inherently remote compute;
- materially different scaling requirements;
- meaningful security or privacy isolation;
- shared central knowledge;
- independent deployment value;
- another demonstrated operational need.

The default remains:

**Local-first modularity first. Distributed architecture by demonstrated necessity.**

---

# Backend, Identity and Synchronization Boundaries

The current roadmap does not assign production implementation of:

- Supabase synchronization;
- cross-device synchronization;
- cloud canonical persistence;
- user-facing cloud account or identity infrastructure;
- real-time multi-device state;
- synchronization conflict resolution;
- mandatory cloud backup.

This does **not** mean remote capabilities may be implemented without security.

Future remote services may still require appropriate:

- service authentication;
- API credentials;
- authorization;
- transport security;
- secret management;
- provider security controls.

The non-goal is premature **user-facing Lumen cloud identity/account infrastructure**, not secure service boundaries.

Do not deploy a production Supabase schema merely to duplicate current SwiftData models before the local domain and persistence architecture are hardened.

Cloud synchronization requires explicit future Roadmap scope.

---

# AI and Extraction Boundaries

Lumen is not currently building:

- an "AI receipt scanner" as the product identity;
- cloud OCR as a core dependency;
- hosted VLM extraction as a core dependency;
- automatic transaction truth from a language or vision model;
- model fine-tuning as an MVP requirement;
- LoRA or custom-model training as a production prerequisite;
- automatic global learning from private corrections;
- a financial domain coupled to one AI or OCR provider.

AI may eventually:

- recognize;
- propose;
- rank;
- enrich;
- explain.

It does not establish canonical truth.

Machine extraction creates candidates.

**The user confirms financial state.**

---

# Evidence Boundaries

The evidence architecture does not imply:

- every Transaction must have evidence;
- manual entry requires a fake EvidenceArtifact;
- every receipt image must be retained forever;
- every OCR line must become a persisted model;
- every candidate must become a persisted model;
- every `ValidationSignal` must become a persisted model;
- every `ExtractionRun` must be permanently stored;
- the current one-Transaction/one-source implementation is the permanent relationship;
- the complete future many-to-many evidence graph must be implemented before needed.

Preserve future compatibility without implementing future complexity prematurely.

`TransactionSource` does not need to be renamed merely to match the canonical term `EvidenceArtifact`.

---

# Import Boundaries

Phase 1C deliberately supports structured portability.

It does not imply a universal importer for arbitrary exports from every:

- bank;
- credit-card issuer;
- retailer;
- payment processor;
- finance application;
- accounting platform.

Lumen should first support:

- its own documented/versioned portable format;
- deliberately defined supported schemas.

Transaction-bearing imports must still flow through:

`Parse`  
→ `TransactionDraft(s)`  
→ `Review`  
→ `Confirm`  
→ `Transaction(s)`

Reference data such as Categories, PaymentMethods, and Tags may use entity-appropriate preview and confirmation rather than artificial `TransactionDraft` objects.

Open-ended financial-format normalization requires separate future scope.

---

# Merchant, Product and Item-Level Boundaries

Near-term implementation does not require:

- shared global merchant intelligence;
- cloud merchant normalization;
- retailer catalog ingestion;
- product databases;
- UPC/GTIN infrastructure;
- barcode-driven financial intelligence;
- receipt line-item intelligence;
- product substitution recommendations;
- store-brand replacement recommendations;
- consumable forecasting.

These concepts may remain architecturally compatible without becoming current production scope.

Merchant learning and correction-driven improvement belong to later roadmap phases.

Product and barcode intelligence remain later-phase work.

---

# Collaboration Boundaries

Near-term development does not include:

- family financial workspaces;
- household ledger sharing;
- multi-user editing;
- collaborative budgeting;
- shared user accounts;
- team or organizational finance spaces.

These features would introduce substantial:

- identity;
- authorization;
- privacy;
- synchronization;
- conflict-resolution;

requirements.

They require deliberate future product scope.

---

# Phase 1A Non-Goals

**This section is operational and applies while Phase 1A is the active production phase. It must be reviewed and replaced or retired when the Roadmap formally advances to the next phase.**

The active phase is:

**Phase 1A — Core Ledger Hardening**

Phase 1A must not expand merely through implementation momentum into:

- Apple Vision OCR;
- production OCR;
- cloud OCR or VLM integration;
- persisted `Observation`;
- persisted `FieldCandidate`;
- persisted `ResolvedField`;
- `ExtractionRun` infrastructure;
- persisted `CorrectionEvent`;
- merchant-learning systems;
- barcode/product infrastructure;
- receipt itemization;
- production Budgets;
- production CashflowPhases;
- advanced Insights;
- Supabase synchronization;
- cross-device synchronization;
- user-facing cloud accounts;
- family/shared functionality;
- production model training;
- a major visual redesign.

Phase 1A should also avoid architecture-only migrations such as:

- renaming `TransactionSource` to `EvidenceArtifact` solely for terminology consistency;
- renaming persisted snake_case Swift properties solely for stylistic preference;
- implementing a complete `EvidenceLink` many-to-many model before a concrete requirement exists;
- introducing speculative services or repositories only because future phases might eventually need them.

A deferred change may be pulled into Phase 1A only if it satisfies the Architecture Contract's Phase 1A change-admission rule.

Capabilities already assigned to later phases should remain deferred until their canonical phase becomes active unless they independently satisfy that change-admission rule.

---

# Development Practice Non-Goals

Implementation work should not optimize for:

- maximum abstraction;
- maximum number of layers;
- maximum number of protocols;
- speculative scalability;
- hypothetical providers;
- premature service extraction;
- architecture diagrams at the expense of working behavior.

Do not introduce an abstraction merely because:

> We might need this someday.

Prefer the simplest boundary that:

- obeys the Architecture Contract;
- satisfies the active phase;
- remains testable;
- protects user-owned data;
- leaves a credible path for future evolution.

---

# What Is Still Allowed

Non-goal status does not prohibit:

- research;
- architecture notes;
- controlled technical spikes;
- Extraction Lab experiments;
- benchmarking;
- future-interface exploration;
- compatibility-aware implementation choices;
- proof-of-concept integrations.

Research may happen before a production phase becomes active.

Research does **not** automatically establish production scope.

The intended progression is:

`Research`  
→ `Measure`  
→ `Demonstrated value?`

If no:

`Remain R&D / Defer`

If yes:

`Already assigned to a future Roadmap phase?`

If yes:

`Wait for that phase to become active`  
→ `Implement within its defined scope`

If no:

`Roadmap evaluation`  
→ `Roadmap revision if adopted`  
→ `ADR / Contract review if architecture changes`  
→ `Explicit production scope`

Experimental success alone does not authorize production adoption.

---

# Scope-Creep Rule

When proposed work appears outside the active roadmap phase:

1. Check the Architecture Contract.
2. Check the active Roadmap phase.
3. Check whether the capability is already assigned to a later phase.
4. Ask whether the active phase requires the capability to satisfy its exit criteria.
5. If it is not required, do not silently implement it.
6. Classify it as:
   - defer until its already-assigned phase;
   - research separately;
   - future Roadmap revision;
   - ADR evaluation if architecture is affected.

The default question is:

> **Does the active phase actually need this capability to satisfy its exit criteria?**

If the answer is no:

**Defer.**

If the capability is already assigned to a later phase:

**Defer to that phase.**

---

# Current Operational Reminder

**This section is intentionally operational and must be updated when the active production phase changes.**

Current production priority:

**Phase 1A — Core Ledger Hardening**

The current engineering objective is not:

- OCR;
- AI;
- Supabase;
- microservices;
- budgeting;
- barcode intelligence;
- advanced Insights.

It is establishing that Lumen's local financial ledger can safely evolve.

Current priorities include:

- persistence correctness;
- save-failure correctness;
- migration safety;
- canonical Transaction semantics;
- financial state versus ingestion-state clarity;
- `Draft → Review → Confirm`;
- CRUD correctness;
- duplicate semantics;
- analytics correctness;
- money/currency/date semantics;
- automated domain and persistence validation.

Everything else must earn its place through the canonical Roadmap.

---

# Maintenance Rule

This document should remain short enough to function as a fast scope-control reference.

Implementation bugs and ordinary engineering discoveries should generally become:

- tests;
- issues;
- active-phase acceptance criteria;
- implementation notes.

They should **not** automatically expand this document.

When the active production phase changes:

1. review the operational phase-specific section;
2. retire or replace stale phase-specific non-goals;
3. preserve cross-cutting product, privacy, and architecture boundaries;
4. avoid turning the document into a historical archive of every previous phase.

The Architecture Contract defines what must remain true.

The Roadmap defines what is being built and when.

This document defines what must **not silently become scope**.
