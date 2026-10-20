# Lumen Phase 1C — Stage A Diagnostic Implementation Proposal

## Status / authority

**PROPOSED FOR INDEPENDENT REVIEW — DOCUMENTATION ONLY. Diagnostic code and experiments are NOT AUTHORIZED.**

**Accepted direct parent:** Phase 1C executable characterization plan, recorded **ACCEPTED AT PROPOSED-PLAN LEVEL** at `89b6776ef7a186fadd40c0f3749f2a40ac9538a0` (`LUMEN_PHASE1C_REFERENCE_INITIALIZATION_AUTHORITY_EXECUTABLE_CHARACTERIZATION_PROPOSAL.md`). Its reviewed substantive checkpoint was `755c87269f6c3111c251a81fd04c6139c8755f02`.

**Governing contract:** reference-initialization authority persistence/recovery mechanism **ACCEPTED AT PROPOSED-CONTRACT LEVEL** at `bc85912862282c3bffc76d9049e8190d7afe750b`, especially §§10.4, 23 and 27. The Stage A investigation does not demonstrate any of its two-layer guarantees.

**Branch:** `docs/phase1c-reference-authority-stagea-diagnostic-proposal`, based exactly on `89b6776ef7a186fadd40c0f3749f2a40ac9538a0`. The inherited Phase 1C proposal lineage is not implementation authority. Canonical `main` at opening: `a3c996e2697bdb4f1b5ad3107076f1a75f0d8a73`, containing the unrelated methodology PR #19 merge; this proposal must not cause a wholesale proposal-chain merge into `main`.

**Question:** What *smallest possible* disposable iOS SwiftData test worker, external controller and safely isolated observer could produce credible evidence about controlled store creation, inspection effects, external termination and subsequent fresh-process inspection?

This file proposes the scope of a **future** diagnostic implementation. It neither selects validated controller APIs nor authorizes writing/running a harness, modifying any Swift, opening stores, or performing experiments. Independent approval and separate explicit owner authorization must precede executable work.

---

# 1. Strict scope

Stage A here probes four platform/harness prerequisites: (1) creation/reopening of a minimal test-only SwiftData persistent store at a controlled URL; (2) pre-open physical inventory and safe preservation/copying of the full relevant store-associated artifact set; (3) genuine externally verified termination of a disposable worker process; and (4) fresh-process inspection of an isolated copy, recording effects caused by the inspection itself.

**Only synthetic sentinel data and unique disposable stores are permitted.** The worker must not load Lumen's real canonical ledger model, `LumenApp`, `LedgerStore.open()` with its production configuration, `Seed.bootstrapIfNeeded()`, transaction/reference imports, or historical fixtures. The real app's bundle identity, data container, installation and production files are out of scope.

No diagnostic witness/control records, production `LedgerLifecycleWitnessV1`, `ReferenceInitializationAuthorityControlV1`, bootstrap authority, restoration hold, guarded acquisition, same-ledger effects/proof transaction, history conversion/migration, or Stage B work is part of this pass.

**Evidence distinction:** a store reopening successfully may demonstrate that an isolated test store can reopen under a specific toolchain. It proves *nothing* about positive lifecycle origin, store correspondence, competing-writer safety, reference-initialization atomicity, or the accepted mechanism's implementation feasibility as a whole.

---

# 2. Minimal proposed harness roles

The three roles below are logical roles; their exact binaries or XCTest/simulator tooling remain unselected until diagnostic authorization.

| Role | Responsibility | Required isolation |
| --- | --- | --- |
| **External controller** | Give each run an ID; allocate an isolated location; launch the worker; record its actual process identity and declared boundary; request/verify *external* termination; start an independently identified fresh observer; retain logs. | Controller must not run inside the worker or automatically open the source store. The worker's own event log is not sufficient proof of death. |
| **Disposable worker** | Create a persistent SwiftData ModelContainer for one minimal diagnostic-only model, explicitly configured to use a test-controlled URL; optionally save an artificial sentinel; emit synchronized pre/post API markers. | Unique diagnostic bundle/container with no production SwiftData schema, app state, user records, evidence payloads or imported reference data. |
| **Fresh observer** | Before constructing any persistent SwiftData container, record the terminated worker's artifact baseline; preserve and validate the complete relevant artifact set; open only a disposable copy and record observer-induced modifications separately. | A genuinely new process. Never initialize SwiftData directly on the preserved source or a historical fixture original. |

**Candidate packaging for later approval:** a separate disposable diagnostic iOS test target/app and external host-controlled runner, reusing only the *testing pattern* from `LumenTests/LedgerPersistenceTests.swift` (test-only `ModelConfiguration(schema:url:)`), not Lumen's production schema or app container. An independent sample project may be safer than a target inside the existing Xcode project; select only after verifying practical launch and containment. Neither alternative is admitted as an implementation decision here.

The exact approach for independently terminating an iOS app process is a **feasibility question**, not an established capability. A UI dismissal, simulated error, XCTest cancellation or graceful exit cannot be labeled an abrupt external kill. If a controller cannot verify actual worker termination plus a genuinely fresh observer, report **BLOCKED / TERMINATION NOT VERIFIED** rather than silently substituting a weaker test.

---

# 3. Predeclared execution and observation constraints

- **Environment:** start with a recorded Xcode/Swift/iOS Simulator toolchain, simulator OS/device, test root and filesystem protection conditions. Simulator observations do not establish physical-device guarantees; any supported-device claim requires separately admitted device evidence.
- **Execution model:** one active disposable worker per uniquely isolated store root, controller outside it, no cloud/sync or additional writer. Do not extrapolate to multiple ModelContext writers or multiple app processes.
- **Interruption windows:** injected throw as a negative control; real external termination before first ModelContainer initialization; real termination after a positive open/save milestone; an *attempt* to interrupt during store creation. Instrumented before/after call markers do not prove interruption occurred inside a SwiftData database operation. Retain hit/miss evidence and mark unobserved windows **INCONCLUSIVE / NOT REACHED**.
- **Inherited ordinary recovery obligation:** the accepted mechanism still requires investigating ordinary termination **during** first-store creation. If the diagnostic fails to hit or reopen that state, do not call it an exceptional/unrecoverable class to make the accepted mechanism easier to satisfy.
- **No observational neutrality assumption:** opening/constructing a persistent SwiftData container or executing a nominally read-only fetch may create, recover or alter physical artifacts. Record and attribute these changes rather than calling the inspector passive.

Predeclare run IDs, expected allowed and forbidden observations, kill targets, copy method, platform and blocking criteria *before* collecting scenario results. A missing or unreadable store is an observed condition, not proof of source corruption or authority failure.

---

# 4. Bounded scenario sequence and authorization boundary

| ID | Proposed scenario | Required outcome evidence | Authority |
| --- | --- | --- | --- |
| **A0 — controller validity** | Launch an empty disposable worker; compare an injected error/graceful exit with independently verified externally caused death; relaunch a distinct observer process. | Controller events and worker identities; termination acknowledgment; new-process identity. Failed verification → **BLOCKED**, not kill-test PASS. | First tranche candidate |
| **A1 — controlled store** | Before open, inventory an empty isolated root; create minimal SwiftData store at explicit URL, save an artificial sentinel; inspect a preserved working copy in a fresh process. | Pre-open root inventory; after-create files including associated artifacts; copy validation; sentinel observation; inspector-effect delta. | First tranche candidate |
| **A4 — observer-effect control** | Independently inventory a known disposable store without container open; preserve all identifiable associated files; initialize SwiftData **only on a copy**; observe effects. Include an isolated missing-store opening negative control. | Original baseline versus post-inspection copy and source; new/changed files attributable to container initialization; evidence of safe copy isolation. | Mandatory first-tranche safeguard |
| **A2 — post-create kill** | Externally kill after a confirmed store-creation/save milestone without graceful container teardown; fresh-process inspection from preserved isolated state. | Verified termination; pre-open inventory; copy integrity; reopened behavior and observer changes. | **Not** included automatically in initial tranche |
| **A3 — creation-window kill** | Attempt termination immediately before or while the first configured SwiftData store creation/open is active. | Boundary timing and hit accuracy; external kill; pre-open evidence; partial artifacts; fresh-process effects. | **Not** included automatically in initial tranche |

**Recommended smallest separately authorized initial tranche: A0 + A1 + A4.** It establishes the independent controller, location, and observer-integrity foundations. A2/A3 remain explicit follow-on Stage A hypotheses and must be separately approved or enumerated in a later authorization. No Stage B scenario is admitted.

Even completion of A0/A1/A4 is **infrastructure feasibility**, not full Stage A characterization, and certainly not proposed-contract acceptance or production readiness.

---

# 5. Observation-integrity protocol proposed for harness review

After the worker has exited and the controller establishes that no admitted writer remains active:

1. **Pre-open physical observation.** Before any SwiftData ModelContainer construction in the observer, inventory the synthetic witness's absence, expected controlled store path, existence, node kinds, associated files and safe relevant metadata. This is *diagnostic physical evidence*, never positive lifecycle authority, provenance or confirmation of a matching control.
2. **Quiescence and preservation.** Preserve the store artifacts at a quiescent boundary, accounting for all discovered store-associated files. Copying the primary database file alone is not presumed safe or consistent. The eventual harness must validate its snapshot/copy strategy before claiming successful observation; missing associated files or concurrent writes produce **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**.
3. **Contained inspection.** Open a separately placed, isolated working copy with a known explicit diagnostic configuration. Record before/after inventories and digest/metadata evidence where safe, distinguishing original source bytes/artifacts from copy mutations that may occur during ModelContainer initialization or fetch. Do not mistake observer-induced creation for a worker-recovery result.
4. **Source-protection verification.** Verify the preserved original remains protected and that observer changes are confined to the copy. If this is not warranted, stop and mark evidence compromised or inconclusive. The copied store must not share an underlying mutable directory/root with the original.
5. **No automatic recovery.** Stage A performs no reference seeding, authority repair, control creation, import restoration, migration or destructive cleanup before evidence is secured. A later authorized diagnostic cleanup may affect disposable artifacts only.

The original Phase 1A historical-store producer artifacts are **excluded entirely** from this tranche. Future §23.5 work, if authorized, must preserve originals and inspect only independently verified isolated working copies.

No platform snapshot API, SQLite journal interpretation, private Core Data table, special file extension, new schema field, or artifact retention duration is prescribed as accepted implementation here.

---

# 6. Proposed file/implementation containment and required future review

Before granting *executable* authorization, the operator must present a precise per-file change list for the chosen diagnostic form, including any Xcode target/project settings, runner scripts, test-only model, observer inventory/copy logic and evidence manifest. Files must remain isolated from normal Lumen build/release behavior; any interaction with production target configurations is a new review concern.

**Strictly prohibited without independent further authority:** changes to `LumenApp.swift`, `LedgerStore.swift`, `Seed.swift`, `LedgerWrite.swift`, any production model/schema/migration, reference importer/exporter, historical user stores, installed app bundle/data, Phase 1B evidence retention, cloud/sync, UI, normal release workflows or destructive reset. Even adding a diagnostic target or workflow is only *proposed* and requires explicit authorization.

If an isolated worker or trustworthy controller requires altering live startup behavior or opening the only historic fixture, STOP. Return a revised implementation boundary instead of treating test convenience as permission.

---

# 7. Evidence, falsification and stop rules

Each future scenario retains its stable ID and approved harness SHA; predeclared platform/toolchain; unique disposable source root; actual worker/observer process IDs as available; expected markers; controller kill acknowledgment; before-open physical inventory; validated preserved copy and associated-file manifest; post-open original/copy differences; test-only sentinel observations; and classification with limitation statement.

Allowed result categories: **OBSERVED (NARROW PLATFORM RESULT)**, **FALSIFIED ASSUMPTION**, **INCONCLUSIVE**, **NOT REACHED**, **BLOCKED / TERMINATION UNVERIFIED**, **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**, and **NOT CHARACTERIZED**. An injected error is never mislabeled a crash; a successful reopen never proves witness/store correspondence.

**Immediate STOP:** path escapes disposable root; real user/legacy data touched; worker liveness unknown during snapshot; termination not independently verified; only available artifact opened by SwiftData; copy consistency or isolation cannot be established; inspector mutates the preserved source. Preserve safe non-sensitive evidence and do not classify the damaged trace as platform success.

**Escalate without widening accepted semantics:** inability to reach creation-time interruption, unexpectedly unreadable test store, changed associated files during observation, simulator/device discrepancies, or inability to preserve the original. These are valuable negative/inconclusive findings. Ordinary interruption is not retroactively excluded from the accepted mechanism's supported failure model.

**Initial tranche exit:** A0/A1/A4 have per-row observed or blocked/inconclusive dispositions, logs and preserved-baseline evidence, with an independent summary identifying which controller, copy and SwiftData-location prerequisites were demonstrated versus merely assumed. Further A2/A3 work awaits separate review. Physical-device testing, Stage B representative witness/control records, authority ordering, historical fixtures and implementation-readiness conclusions remain outside this gate.

---

# 8. Questions for independent reviewer

1. Is A0/A1/A4 a sufficiently bounded diagnostic implementation tranche, with A2/A3 explicitly outside initial authorization?
2. Do proposed controller/worker/observer roles distinguish actual process death from a simulated error and an ordinary app dismissal without assuming specific unsupported iOS APIs?
3. Does pre-open inventory plus validated copying cover observational effects and store companion-file consistency without treating those observations as lifecycle authority?
4. Can a diagnostic implementation be isolated from production SwiftData/schema, the real app data container, Phase 1A fixture originals, and normal release workflows?
5. Are the recorded evidence fields and blocked/inconclusive/stop cases sufficient to prevent overclaiming mechanism feasibility based on narrow Stage A success?
6. Is the exact accepted-plan baseline respected without adding new authority to upstream proposal history?

**Requested disposition: review this documentation-only Stage A implementation scope.** Do not write/run diagnostic code, modify project/CI files, create test stores, execute termination tests, or begin Stage B unless the owner separately authorizes the accepted diagnostic implementation scope after review.
