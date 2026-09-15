# Phase 1A Closure — Core Ledger Hardening

## Status

**PHASE 1A — CORE LEDGER HARDENING — ACCEPTED**

Phase 1A is closed as of 2026-09-15.

The remaining formal acceptance question was whether hardened Lumen could inherit and continue using durable financial state created by the canonical pre-Phase-1A application. That question is now answered by executable evidence.

The canonical pre-hardening application produced durable SwiftData state. The hardened candidate received the historical store unchanged across the candidate-install boundary, interpreted representative historical financial relationships correctly through current application/domain behavior, performed a current ledger mutation against inherited state, and preserved the resulting state across termination and relaunch.

No production compatibility correction was required.

---

## Validated Product Candidate and Closure Commit Semantics

Phase 1A product behavior was validated through:

`8ce3fad0c449c433ca3c2fc7490a1a948c4f504a`

The canonical pre-Phase-1A historical producer is:

`dbc28ed9649d4930b45e2dcc44a7462729dfcf11`

The documentation-only closure commit that follows this record is intentionally newer than the validated product candidate.

That later closure commit does **not** extend the behavioral evidence to untested production changes. Its permitted delta is documentation/governance only: closure evidence, knowledge reconciliation, and roadmap status. No production Swift behavior, persisted model, store configuration, migration logic, or Phase 1B implementation belongs in the closure delta.

The compatibility validation infrastructure commit `8ce3fad...` differs from the prior physical-device build checkpoint `ed7dc91347a6b0d30d270aef0d77ebf4b4bd1458` only by the dedicated Phase 1A compatibility workflow, compatibility UI-test observer, and compatibility harness script. It did not change production Lumen behavior.

---

## Reference Historical Producer

`dbc28ed9649d4930b45e2dcc44a7462729dfcf11` is the reference historical producer for the pre-versioned-schema era.

The durable assurance capability is **not** one frozen SQLite file. The reusable question is:

> Can a future Lumen version inherit legitimate financial history created before versioned schemas existed?

The repository workflow can regenerate an authentic historical store from the actual historical application whenever that compatibility guarantee needs to be tested again.

---

## Final Existing-Store Compatibility Evidence

Workflow:

`Phase 1A Existing Store Compatibility`

GitHub Actions run:

`34933858277`

Historical producer:

`dbc28ed9649d4930b45e2dcc44a7462729dfcf11`

Validated candidate:

`8ce3fad0c449c433ca3c2fc7490a1a948c4f504a`

Environment:

- macOS 26.6.2
- Xcode 26.6
- iOS Simulator SDK 26.5

Historical store snapshot SHA-256:

`0ed6c7caaf48ac5452461e9ccb63aaf910a020bbb451b9adbd837596a4bc5a50`

GitHub artifact:

`10383049104`

Artifact ZIP SHA-256:

`35717a7d264b3e9c94111d368a7a601bef724ef80a3ea15bee862c0ef44d5f94`

The short-retention binary artifact is supporting evidence for the completed run, not permanent canonical infrastructure. The checked-in workflow and this closure record are the durable reproducibility/provenance layer.

---

## Compatibility Boundary Results

| Boundary | Result | Closure meaning |
| --- | --- | --- |
| Historical source resolution | PASS | The producer was the exact canonical pre-Phase-1A revision. |
| Historical build | PASS | Historical Lumen built unchanged on the recorded toolchain. |
| Candidate build-for-testing | PASS | The validated candidate built successfully. |
| Bundle identity | PASS | Historical and candidate applications used the same canonical bundle identity. |
| Candidate sample-reseeding guard | PASS | Current production bootstrap could not recreate the historical financial sample corpus and produce a false-positive compatibility result. |
| XCTest harness data continuity | PASS | The exact compatibility UI-test path preserved a host-written app-container sentinel unchanged. |
| Historical store materialization | PASS | Historical Lumen created persistent Application Support store state. |
| Historical reopen | PASS | Historical Lumen crossed its own terminate/relaunch boundary before handoff. |
| Historical store snapshot | PASS | The terminated historical store was inventoried, hashed, and preserved. |
| Candidate install continuity | PASS | The historical store inventory/hashes were unchanged immediately after candidate installation and before candidate launch. |
| Compatibility test execution | PASS | The dedicated compatibility selector entered its active test path rather than skipping. |
| Candidate ledger open | PASS | Current Lumen opened the inherited persistent ledger without entering ledger-open failure UI. |
| Historical semantic reads | PASS | Representative historical transactions, statuses, types, relationships, tags, payment methods, and source/provenance semantics were observable through current application behavior. |
| Historical corpus verification | PASS | The historical financial corpus was retrospectively verified from state that independently crossed the installation boundary unchanged. |
| Current mutation | PASS | An inherited Pending transaction was confirmed Posted through current product behavior only after read-only inherited-state assertions passed. |
| Post-mutation relaunch | PASS | The Posted mutation and representative historical graph remained observable after current-app terminate/relaunch. |
| Phase 1A compatibility gate | SATISFIED | The final previously-unmet formal Phase 1A acceptance requirement is complete. |

The workflow's final report reached:

`furthest_boundary=POST_MUTATION_RELAUNCH`

with:

`failed_boundary=NONE`

and:

`phase1a_compatibility_gate=SATISFIED`

---

## Representative Historical Corpus

The public/domain-level compatibility observer validated representative historical records including:

- **OpenAI** — posted expense, Subscriptions, Credit Card, `#recurring`, manual-entry provenance, and historical notes;
- **Paycheck Direct Deposit** — posted income, Paycheck, Bank Transfer, and `#recurring`;
- **HSA Pharmacy Purchase** — posted expense, Medical / HSA, HSA payment method, `#reimbursable`, receipt-photo provenance, and parsed source state;
- **Dollar Tree** — inherited Pending expense, Household, Debit Card, `#essential`, receipt-photo provenance, then current `Pending → Posted` mutation.

The compatibility observer remained financially read-only until all required inherited-state assertions passed.

Only after Phase A passed did the observer execute the deliberate current-version mutation against the inherited Dollar Tree record.

---

## Forensic Corroboration Is Not the Compatibility Contract

Independent inspection of the preserved SwiftData/SQLite snapshot was useful forensic corroboration for this completed run. It confirmed that the historical store contained the expected seven historical transactions and associated source/reference relationships.

That inspection does **not** become part of Lumen's permanent compatibility contract.

Future compatibility validation must not depend on:

- private SwiftData/Core Data table names;
- private SQLite schema layout;
- a specific `default.store`/WAL/checkpoint pattern;
- particular store-file sizes;
- a requirement that a specific physical store file receive mutation bytes.

Those are persistence-framework implementation details.

The durable compatibility contract remains:

`historical producer → durable historical state → candidate-install continuity → supported application/domain read → legitimate current mutation → relaunch durability`

Likewise, the observed WAL behavior in the accepted run is evidence about that run, not a future invariant. The product-level invariant is that the mutation persisted and the relaunched application read it back correctly.

---

## Phase 1A Validation Report

### Build Validation — SATISFIED

The project builds successfully. The final compatibility candidate built successfully for the simulator workflow, and the preceding canonical source also produced a validated unsigned arm64 physical-iPhone-compatible IPA.

### Clean-Install Validation — SATISFIED

A canonical unsigned device build was installed and exercised on a physical iPhone. Core product navigation, manual interaction, Review/Save, transaction inspection, status transition, filters, reporting behavior, and local persistence were usable.

### Existing-Store Compatibility — SATISFIED

Run `34933858277` established that hardened Lumen can inherit, interpret, mutate, and continue using financial state produced by the canonical pre-Phase-1A application.

### Migration Validation — SATISFIED / NOT APPLICABLE TO PHASE 1A MODEL CHANGES

Phase 1A introduced no persisted model-definition change between the canonical pre-Phase-1A producer and the validated candidate. The baseline and hardened application retained the unversioned schema/default store configuration while compatibility evidence was being established.

Therefore no Phase 1A schema migration was required to validate.

The separate roadmap requirement to prove that a legitimate pre-Phase-1A store still opens with financial information preserved was **not** treated as not-applicable. It was the final formal closure gate and is now satisfied by the historical-store workflow.

Future persisted-model changes remain migrations and must follow the Architecture Contract and roadmap requirements.

### Domain Tests — SATISFIED WITH DOCUMENTED BOUNDS

Phase 1A established automated coverage for the correctness-sensitive ledger behavior admitted into the phase, including transaction semantics, draft conversion, monetary/sign behavior, search/filter semantics, analytics behavior, FlowLayout regression, and related domain behavior.

### Persistence Tests — SATISFIED

The retained persistence suite covers successful durable operations and failed-write recovery semantics. The final historical-store workflow adds authentic application-version compatibility evidence on top of those tests.

### Known Deferrals — DOCUMENTED BELOW

Phase acceptance does not imply every adjacent ledger/product design question is complete.

---

## B1 and B2 Disposition at Closure

### B1 — SwiftUI Keyboard Toolbar Invalid-Frame Investigation

The hosted semantic-XCTest/focus invalid-frame mechanism remains unresolved and environment-sensitive.

Physical product evidence did **not** reproduce a user-facing blocker. On an installed physical iPhone, ordinary interaction successfully exercised Amount, Merchant, Notes, the keyboard Done toolbar, Review, Save, navigation, filters, and subsequent ledger inspection without the hosted invalid-frame failure.

Disposition:

- investigation remains open;
- hosted mechanism remains unexplained;
- product-blocker status is **non-blocking**;
- no production keyboard/focus correction is warranted by current evidence.

### B2 — Hosted Onboarding/Preferences Relaunch Investigation

The hosted `UserDefaults.standard` lifecycle/reset mechanism remains unresolved.

Physical product scope passed: on the same installed physical-iPhone application, ordinary force-close/reopen preserved onboarding completion, the changed reporting/default currency preference, SwiftData financial state, and transaction/status state.

The Phase 1A historical-store workflow separately established SwiftData continuity through its GitHub Actions/XCTest validation environment. That evidence does **not** retroactively explain the earlier Rork-hosted UserDefaults behavior.

Disposition:

- investigation remains open;
- hosted UserDefaults mechanism remains unexplained;
- physical product persistence is validated;
- no production persistence correction is warranted by current evidence.

Neither B1 nor B2 prevents Phase 1A acceptance.

---

## Accepted Scope and Deliberate Deferrals

Phase 1A acceptance covers the hardened core ledger contract, including:

- durable production persistence without silent in-memory fallback;
- surfaced financial-write failures;
- canonical Draft → Review → Confirm behavior;
- reliable current CRUD/status behavior within the admitted model;
- transaction duplicate semantics and advisory override behavior;
- documented analytics inclusion/exclusion behavior;
- explicit money/currency behavior that avoids silent cross-currency aggregation;
- bounded date/timezone semantics;
- seed/developer-data separation;
- automated domain/persistence evidence;
- authentic pre-Phase-1A existing-store compatibility.

The following remain deliberate future work rather than residual Phase 1A failure:

- migration from `Double` to an exact/currency-aware money representation if and when admitted by a future migration plan;
- adoption of a versioned persisted schema when an actual persisted-model evolution requires it;
- further decomposition of legacy mixed status semantics where future product needs justify migration;
- richer civil-date semantics where current date representation becomes insufficient;
- FX conversion and richer multi-currency reporting while preserving original transaction currency;
- true dark appearance design; the current dark-mode contrast defect should be addressed as bounded UI work rather than reopening Phase 1A;
- broader accessibility validation beyond the core interaction evidence completed in Phase 1A;
- the unresolved hosted B1 mechanism;
- the unresolved hosted B2/UserDefaults mechanism;
- all evidence/provenance/extraction work owned by Phase 1B and later phases.

These deferrals define the boundary of what was accepted. They do not subtract from the acceptance decision.

---

## Compatibility Workflow Reuse Policy

`Phase 1A Existing Store Compatibility` is an intentionally invoked migration/compatibility assurance tool, not routine pull-request CI.

Rerun historical-store compatibility when a change materially affects the historical persistence guarantee, such as:

- a persisted financial model changes;
- schema versioning or migration strategy changes;
- migration logic is introduced or modified;
- the SwiftData store configuration or location changes;
- the persistence framework changes;
- a release explicitly needs the pre-versioned historical compatibility guarantee.

Do **not** require the full historical simulator/XCUITest workflow for ordinary changes such as:

- documentation-only edits;
- visual/UI polish with no persistence impact;
- analytics changes that do not alter persisted schema/store compatibility;
- unrelated feature work with no historical-store boundary change.

The workflow should continue to classify validation-infrastructure failures separately from product compatibility failures.

---

## Phase 1B Handoff

The active production roadmap phase after this closure is:

**Phase 1B — Evidence & Provenance Foundation**

Phase 1B begins from the ledger invariant established in Phase 1A:

> **Phase 1B may enrich Lumen's knowledge of where financial information came from without weakening the canonical Transaction boundary established in Phase 1A.**

The first Phase 1B activity should freeze responsibility boundaries before production implementation.

Questions to resolve include:

- what `EvidenceArtifact` owns;
- what remains the responsibility of the current `TransactionSource` implementation;
- how one Transaction may eventually relate to multiple artifacts and one artifact to multiple Transactions;
- what belongs to an artifact versus an `Observation`;
- when extracted information becomes a `FieldCandidate`;
- what constitutes resolution;
- which provenance survives confirmation;
- how evidence retention/deletion behaves independently of confirmed Transactions;
- how photo capture metadata, including location, remains evidence/context rather than automatic transaction truth;
- what information remains local-only and what may eventually cross an explicit remote-processing boundary.

OCR text, EXIF metadata, photo coordinates, receipt addresses, timestamps, confidence values, merchant guesses, and future VLM output may all become valuable upstream evidence.

None may silently become canonical `Transaction.amount`, `Transaction.date`, `Transaction.merchant`, `Transaction.place`, or other confirmed financial truth outside the established Draft/Review/Confirmation rules.

---

## Final Governance Disposition

**PHASE 1A — CORE LEDGER HARDENING — ACCEPTED**

The phase is closed.

No additional Phase 1A experiment is required by current evidence.

Future work should preserve this closure record, keep B1/B2 as bounded knowledge investigations rather than reopening the phase, and proceed with Phase 1B responsibility-boundary design under the existing Architecture Contract, roadmap, and non-goals.
