# Phase 1C — Reference-Initialization Authority Executable Characterization Proposal

## Status and authority boundary

**PROPOSED FOR INDEPENDENT REVIEW — DOCUMENTATION ONLY. Executable characterization is NOT authorized by this proposal.**

**Direct accepted dependency:** Exact reference-initialization persistence/recovery mechanism at `bc85912862282c3bffc76d9049e8190d7afe750b`, especially its §§10.4, 12–14, 23–24, and 27. The accepted capability in aggregate Portable contract §21.6 is consumed without reopening; the mechanism is accepted at proposed-contract level in §21.7.

**Branch construction:** `docs/phase1c-reference-authority-characterization-proposal` starts exactly at the accepted mechanism checkpoint above, rather than opportunistically rebasing the mechanism onto canonical `main`. At opening, canonical `main` was `a3c996e2697bdb4f1b5ad3107076f1a75f0d8a73` (after methodology PR #19); the Phase 1C composition baseline was `c7dd2ea639df6db0e98f942f5d906b522d28cf30`. This branch inherits the previously accepted Phase 1C *proposal lineage* for read/review continuity, **not new production authority**, and does not contain the unrelated newer methodology merge. Its incremental diff is this document alone. These lines are not a request to merge the entire proposal ancestry to main.

**Governing rules:** Architecture Contract, Roadmap, Non-Goals, accepted Phase 1C responsibility/admission contract, accepted mechanism, and existing implementation/testing evidence. The full Portable JSON/CSV v1 contract remains unaccepted. A characterization plan cannot admit production state, schema or migration by describing an experiment.

**Decision question:** Which demonstrable SwiftData/filesystem/process guarantees are available in the explicitly supported iOS environments, and what additional evidence would be needed to decide whether an isolated candidate assembly satisfies the *already accepted* reference-initialization authority mechanism?

No source code, test harness, CI workflow, SwiftData model, store, filesystem record, schema, migration, legacy fixture, UI or running application is changed by this gate. No experiment may run until a separate reviewed and authorized executable diagnostic scope exists.

---

# 1. Evidence already available, and evidence still missing

The live canonical source contains:

- `Lumen/LumenApp.swift`: `LedgerStore.open()` precedes `Seed.bootstrapIfNeeded()`, then the container is exposed. The current startup has no authority-witness/control gate.
- `Lumen/Data/LedgerStore.swift`: unversioned baseline schema, default persistent ModelConfiguration, and an injectable container factory; it does not prove controlled-location creation or interruption recovery.
- `Lumen/Data/Seed.swift`: independent Category/PaymentMethod/Tag emptiness checks and one current LedgerWrite save; this is *not* the accepted future coherent authority contract.
- `Lumen/Data/LedgerWrite.swift`: synchronous save/rollback and injectable commit failure on a clean context; this is not evidence of process-crash atomicity.
- `LumenTests/LedgerPersistenceTests.swift`: actual disk-store reopen and in-process injected-error/retry cases, with a test-only `ModelConfiguration(schema:url:)` factory. Those tests do not forcibly terminate a process during a real SwiftData write.
- Phase 1A historical-store compatibility runner/workflow: useful authentic historical-producer evidence, **not** permission to mutate authentic user data or claim authority migration.
- Phase 1B controlled Application Support/evidence filesystem discipline: reusable technique/evidence, not a proven lifecycle-witness durability protocol.

This proposal does not claim that simulator/device versions, SwiftData internals, rename durability, store companion-file behavior, or the availability of an external iOS process controller have already been characterized. Unsupported assumptions must appear as explicit unknowns in the eventual experiment record.

---

# 2. Predeclared supported failure model — initial characterization target

The following is the **pre-test hypothesis/envelope**, recorded now rather than defined from successful trials. It is not a proven platform guarantee.

**Execution scope:** one authorized app process at a time; account for all permitted in-process asynchronous tasks and multiple ModelContext writers. Cloud/sync, extensions, independent app processes and multi-process writers are not silently admitted. Excluding multi-process writers does *not* make multiple in-process contexts serial.

**Ordinary interruption scope:** application process termination/relaunch after a durable establishing witness is produced, including before store creation, during SwiftData configured-store creation/open, after store creation with no control, after a matching control commit while the witness is establishing, during witness replacement, and after bound witness commit. Termination before witness completion must also be probed for non-authorizing partial/missing witness observations. Process termination includes abrupt externally caused exit rather than only throwing an application error or gracefully tearing down a container. The exact accessible kill mechanisms and boundaries require Stage A validation.

**Environment scope:** run on an explicitly recorded Xcode/Swift/iOS simulator environment first, then on physical-device environments wherever simulator-only evidence cannot establish supported-product guarantees. Record device class, OS/build, filesystem location and data protection conditions. Do not generalize a single simulator observation to all supported devices or to power loss.

**Threats and exceptions:** compare legitimate own-store interruption with an unrelated substituted store and competing creation under one stated enforceable execution model. External hostile tampering, genuine storage loss, or independently diagnosed corruption can be outside a narrower admitted guarantee, but path presence, first-open failure, a missing control, or difficulty of recovery are not independent proof of such exceptions. Store location and companion-file atomicity are **unknown**, not presumed.

**Predeclared expected obligations:** legitimate normally recoverable interruptions must admit a finite, non-destructive same-lifecycle continuation; unrelated or unproven stores must never gain fresh control/mutation authority. If a mid-creation trace is unreadable, record the trace and determine whether it is recoverable, a distinct diagnosed exceptional failure or a mechanism/platform insufficiency; do not move it outside the supported envelope after seeing the failure. Exceptional classification requires a prior rule and independently justified observation.

The executing gate must refine measurable scenario inputs and legitimate exceptional criteria **before** collecting results, and preserve the superseded and final predeclared model versions. It may not weaken accepted §10.4/§23 obligations to fit a tool limitation.

---

# 3. Two stages with a hard evidentiary boundary

## Stage A — Isolated platform and harness feasibility probes

Use disposable, isolated stores with minimal representative SwiftData objects, not a modified production ledger. Probe: controlled ModelConfiguration store URL and actual store-associated filesystem observations; initial creation, close/reopen and post-kill reopen; basic local witness whole-record write/replacement and invalid-node observations; controlled-process lifecycle instrumentation; competing container opens where testable. Include a negative control distinguishing simulated throw from actual process exit.

**What Stage A can establish:** observed API behavior, harness feasibility, measurable kill windows, which persistent artifacts exist, what survived a real termination in a specific environment, and which platform documentation must be consulted.

**What Stage A cannot establish:** full two-layer authority correctness, correspondence from a path alone, concurrency safety for all admitted writers, canonical effect/proof coupling, historical migration, or implementability of the final production mechanism. A successful reopen is **not** an authority proof.

Stage A is a candidate separately authorized diagnostic pass, not authorized here.

## Stage B — Mechanism-property characterization

Only after the relevant diagnostic mechanism and its scope have separate admission/authorization, use representative *test-only* witness/control records, isolated store namespaces and purpose-built barriers to challenge accepted authority properties. A representative diagnostic control may help characterize a transaction, but its existence does **not** admit a new production SwiftData model or schema.

Exercise both ordinary bootstrap/resolution and imported reference confirmation as distinct controlled effect/proof cases. Compare a legitimate interrupted store against fabricated unrelated-store substitutions, competing creator attempts and deliberate stale eligibility reads. Include durable fresh hold/release, workspace terminalization assumptions, missing bound stores and authentic historical-store classification where the diagnostic design can do so without writing to historical originals.

Stage B cannot be called complete on Stage A results. A candidate's success may justify a further exact implementation proposal, **not** automatically authorize production implementation. If the diagnostic design itself requires disputed schema or storage authority, stop and request the proper admission before running it.

---

# 4. Requirements-to-evidence coverage matrix

Coverage labels: **A** = direct exploratory Stage A observation; **B** = candidate mechanism-property Stage B evidence; **BLOCKED** = cannot close until a separately admitted representative protocol/schema/workspace/legacy approach exists. A mapping is not a claim of executed coverage.

| Accepted mechanism requirement | Candidate evidence and oracle | Route / unresolved dependency |
| --- | --- | --- |
| §23.1 and §23.9 — initial witness, replacement, validity and binding interruption | Create/replace whole test-only witness; terminate before/during/after writes; inspect missing, valid, truncated, malformed, unsupported version, unsafe-node and missing-bound-store outcomes in a fresh process. No uncertain witness may authorize freshness. | A for filesystem feasibility; B for lifecycle binding, cross-store proof; actual durability and protection behavior unproven. |
| §23.2 — initial ledger authority-control binding | Witness/no store; own new store/no control; saved matching control with witness still establishing; duplicate, malformed or mismatched controls. Require only authorized same-lifecycle binding and fail-closed conflicting state. | A tests basic store creation/reopen; B requires separately admitted diagnostic control model. |
| §23.3 — canonical effect/proof atomicity | Fault before/during/after real save and on reopen for complete Category + PaymentMethod + Tag ordinary initialization **and separately** imported reference confirmation, each with resolution control. Accept only all authorized effects + resolved or no effects + prior control. | B; test-only representative graph/control required; current injected `LedgerWrite` errors are insufficient. |
| §23.4 — restoration hold, abandonment, relaunch and release ordering | Durable eligible→hold with no workspace; recovery after termination; terminalize promotional authority before release; termination between those steps; reject old promotable workspace after eligible release. | B for hold/control; full workspace promotion/discard semantics BLOCKED until separately authorized diagnostic workspace representation. |
| §23.5 — historical compatibility | Open authentic Phase 1A-produced fixture without mechanism witness; classify unknown/unproven and prevent inferred seeding. Preserve original and compare sentinel state. | Read-only legacy-fixture diagnostics after explicit safety review; migration/conversion tests BLOCKED pending separate admission. |
| §23.6 — noninheritance on store loss/reset | Bound witness plus missing/replaced store must not silently create new store or inherit old initialization authority. Distinguish explicit new-ledger creation with new lifecycle ID. | B for test-only assembly; destructive reset workflow BLOCKED and not admitted. |
| §23.7 — positive recovery **and** negative substitution | Every predeclared ordinary interruption after witness creation, including mid-store creation, requires an evidenced disposition; own recoverable store continues under T. Inject unrelated store with same observable witness/control absence and competing creators; no unauthorized control creation. | A characterizes URL/creation/termination behavior; B establishes candidate correspondence; lifecycle-namespace approach **conditional**, not accepted implementation. |
| §23.8 — guarded acquisition and stale operations | Two ordinary contenders; ordinary vs fresh hold; two ModelContexts, async scheduling, stale read then delayed commit, acquisition/commit barriers, termination/reopen and release. Exactly one authority/effect order; no late stale writes. | B, dependent on separately authorized diagnostic guard or fencing strategy; a MainActor claim alone is not evidence. |

**Coverage disposition rule:** report separately as **directly observed**, **supported by an explicit documented platform guarantee plus applicable observations**, **proxy-only**, **blocked**, **not reached**, **falsified**, or **not characterized**. Never mark an entire §23 requirement PASS when only an exploratory proxy passed.

---

# 5. Actual termination, fresh-process recovery and observation design

A proposed diagnostic controller launches a disposable app/helper process with a unique run ID and isolated test container/store root, observes an instrumented *predefined* boundary, terminates that process externally, and then launches a **fresh process** that performs read-only classification before any repair/normal initialization. Possible simulator or UI-test orchestration must first be validated on the available platform; this document does not assume a given XCTest, simctl, device-control or helper-process API can terminate an iOS app at an exact instruction.

**Separate three evidence kinds:**

1. **Deterministic injected error or suspended task:** validates local rollback/stale-work logic, not termination durability.
2. **Externally observed process termination and recovery:** validates a real process-exit trace in that toolchain; an instrumentation marker alone does not prove interruption occurred during a database syscall. Use controller termination acknowledgment, boundary markers, repeatable barriers and post-relaunch fresh-process observations; report windows too narrow to hit.
3. **Physical-device characterization:** required for claimed guarantees not established by simulator; distinguish simulator/device and normal termination from OS crash, device reboot, sudden power loss or protected-file unavailability. Do not equate successful trials with universal crash atomicity.

Before observing the recovered store, disable any ordinary bootstrap or recovery mutation in the *diagnostic harness* so the observation cannot be contaminated by the code under test. Capture read-only witness/control interpretation first, then authorize candidate recovery in a separate phase with a traceable transition. Use only artificial sample/reference values and disposable data. Never kill or mutate a real user's Lumen install or historical production container.

Plan two approaches for hard-to-hit mid-write boundaries: (a) predeclared process coordination points immediately before/after the persistence call and (b) repeated timed interruption attempts with recorded hit accuracy. Neither is equivalent to proving every instruction-level interleaving. Triangulate against official platform contracts and adversarial counterexamples.

---

# 6. Scenario registry, oracles, and evidence artifacts

Every executable scenario must acquire a stable ID before test runs and record: accepted requirement mapping; stage A/B; baseline SHA and harness SHA; predeclared execution/failure model version; platform/device/OS/Xcode/SwiftData environment; initial witness/store/control/workspace state; fault or kill boundary; expected **allowed** recovery outcomes; forbidden outcomes; observed controller/process exit evidence; fresh-process observation before mutation; any later candidate recovery result; status and falsifying trace. Include timing/iteration counts and negative controls, but never infer a universal durability theorem from repeated success.

Minimum proposed scenario families:

- **W** — witness creation, replacement, invalidity and binding interruptions (§23.1/§23.9).
- **C** — initial control absence/presence, duplicates and mismatches (§23.2).
- **T** — canonical ordinary-bootstrap versus imported-reference effect/proof transactions (§23.3).
- **H** — hold, no-workspace relaunch, terminalization and abandonment (§23.4).
- **L** — authentic historical no-proof store; safe classification (§23.5).
- **N** — missing/replaced bound store and noninheritance (§23.6).
- **S** — legitimate first establishment and adversarial substitution/competing creation (§23.7).
- **G** — guarded acquisition, two contexts and stale delayed writes (§23.8).

The future evidence package should retain a manifest, environment/toolchain, exact scenario inputs, pre-test expected outcomes, controller logs/exit evidence, application-side non-sensitive event markers, raw allowed observations, fresh-process recovery snapshots, pass/fail/inconclusive classifications, and a conclusion with documented limitations and reviewer references. Keep diagnostics free of real financial contents, evidence images, private paths or device secrets. Evidence may be stored in a later authorized repo knowledge note or CI artifact; no new artifact format, workflow or retention duration is selected here.

A contradictory supported trace is a **falsifier** even if many other trials passed. A missing kill acknowledgment, inaccessible test boundary or unmeasurable crash window is **INCONCLUSIVE**, not a pass. A missing source-of-truth observation is a test gap, not grounds for inferring eligibility.

---

# 7. Predeclared stopping, escalation and decision rules

- **Stop for safety:** accidental use of a non-disposable store, risk of altering authentic historical state, unexpected non-isolated filesystem access, or diagnostic code escaping into production paths. Do not continue until containment is demonstrated.
- **Stop for mechanism falsification:** adoption of unrelated store, unauthorized/stale canonical write, split durable effect/control state, invalid-witness authority, or permanent stranding of an ordinarily recoverable witnessed store without justified continuation. Preserve trace and reopen the applicable mechanism design/evidence boundary; do not relabel it exceptional after the test.
- **Stop for evidence insufficiency:** external termination cannot be verified, a claimed kill window cannot be observed, simulator evidence cannot support a device claim, or the test-only control/guard model cannot represent the property. Report **BLOCKED/INCONCLUSIVE** and request a narrower authorized diagnostic design; do not certify mechanism readiness.
- **Complete Stage A** only with an explicit per-probe observed/unsupported/inconclusive inventory, platform assumptions, and a technically bounded recommendation for Stage B. Stage A does not grant Stage B authorization.
- **Complete Stage B** only after every §23 row has an explicit coverage disposition; unresolved/blocked rows remain open. A claim of implementation readiness requires all applicable properties supported by sufficient platform documentation and executable observations in admitted environments, with no outstanding counterexample. Test count alone does not earn that conclusion.
- **No automatic implementation:** even a satisfactory evidence package proceeds to independent review and any separately required schema, historical-compatibility, concurrency-primitive, migration and implementation admissions. A failed hypothesis may warrant revisiting the accepted mechanism; it must not silently weaken its guarantees.

---

# 8. Reviewer questions and requested disposition

1. Does the matrix cover the entirety of accepted §§23.1–23.9 without treating platform-probe results as mechanism admission?
2. Is the failure/recovery model meaningfully predeclared, particularly around ordinary termination *during* store creation and the legitimate-versus-substituted-store distinction?
3. Does the proposed termination controller produce distinguishable evidence for injected errors, actual process exits, and fresh-process recovery, while acknowledging simulator/device limits?
4. Are diagnostic representative records, historical fixtures, workspace behavior and production schema/migration authority separated appropriately?
5. Are the scenario oracles, retained evidence, negative controls, and stop conditions falsifiable without being interpreted as universal guarantees from repeated success?
6. Is the branch baseline correctly limited to the accepted mechanism lineage and explicitly independent of unrelated canonical-main methodology history?

**Requested result: review and approve/refine this documentation-only experimental plan.** Do not interpret approval of this proposal as permission to write/run a diagnostic harness or to modify Swift, production startup/bootstrap, store configuration, reference/import code, SwiftData models, schemas, historical stores, CI or UI. After a separate review and explicit authorization, select the smallest contained Stage A diagnostic work and evaluate its evidence before considering Stage B.
