# Lumen Phase 1C — Stage A Exact Executable Boundary Proposal

## Status / authority

**PROPOSED FOR INDEPENDENT REVIEW — DOCUMENTATION ONLY. NOT AUTHORIZED TO WRITE, BUILD, INSTALL, RUN, OR TERMINATE A DIAGNOSTIC APP.**

**Immediate accepted dependency:** Stage A A0/A1/A4 scoped diagnostic plan, independently approved and recorded at `71c74d2a29a7204331c68bbd9d1c77e9764e1396`, whose reviewed substantive checkpoint was `e5a148355943015d681e00c19593e0c18998eccd`.

**Earlier accepted dependency:** executable characterization plan at `89b6776ef7a186fadd40c0f3749f2a40ac9538a0`. Governing reference-initialization mechanism at `bc85912862282c3bffc76d9049e8190d7afe750b`, ACCEPTED AT PROPOSED-CONTRACT LEVEL only. No mechanism or product authority is modified here.

**Branch:** docs/phase1c-reference-authority-stagea-executable-boundary-proposal, created directly from the Stage A scoped-plan acceptance checkpoint. The unrelated canonical main remains separate; this proposal is not an instruction to merge the stacked Phase 1C proposal lineage.

**Decision:** Is the precise, independent, disposable project and host-controlled executable surface below acceptable for a later *separately authorized* A0/A1/A4 diagnostic implementation? This proposal fixes a reviewable file list and test oracles. It does not claim any toolchain, signal, copy, or SwiftData behavior was executed or verified.

---

# 1. Repository facts and packaging selection

Read-only inspection of canonical main verified:
- The production Xcode project is `ios-lumen-finance/Lumen.xcodeproj/project.pbxproj`, with Lumen, LumenTests and LumenUITests targets, and iOS 18.0 deployment settings.
- The production app's bundle ID in that project is `app.rork.8m36zsug0ex00d13e28li` (test bundle identities use related suffixes).
- `ios-lumen-finance/LumenTests/LedgerPersistenceTests.swift` already demonstrates test-local `ModelConfiguration(schema:url:)`, but it imports the real Lumen module, its ledger schema and Seed; it must NOT be transplanted as a whole.
- `ios-lumen-finance/Lumen/LumenApp.swift` opens the production LedgerStore and seeds reference data; neither this path nor its dependencies are part of the diagnostic.

**Selected proposed packaging: a fully separate native iOS simulator application/Xcode project, plus a macOS host-side Python 3 controller.** No new target, source membership, scheme, workspace reference or build setting in the existing production Xcode project. One new disposable diagnostic bundle ID, proposed as `org.lumenresearch.phase1c.stagea.probe`, with no App Groups, iCloud, keychain sharing, production entitlement, or shared container. A single minimal SwiftUI executable handles worker and observer roles as *different launched processes* selected by explicit arguments; the host controller is outside both.

This selection is subject to independent review of the exact boundary and, during a later authorized toolchain probe, verification that an actual Simulator and host process-control interface are available. A failure must be BLOCKED, not silently replaced with a self-thrown Swift error or a user-driven app close.

Rork can build Swift/SwiftUI apps in its cloud simulator, but its documented editor/simulator workflow does not establish that an operator can independently identify and SIGKILL the worker host PID or preserve a complete offline simulator store artifact set before relaunch. It is **not the first-choice execution host** for this forensic harness. Rork could be considered only upon separate evidence of equal host-controller, filesystem-copy and observer-isolation capabilities; no Rork project/import is authorized here.

---

# 2. Exact future source change inventory (all files NEW)

All permitted implementation additions are under a single newly created directory, `diagnostics/phase1c-stagea/`. The following is the exhaustive initial allowlist; any extra tracked file, script, entitlement, target or configuration change requires a revised boundary and separate approval.

| Proposed repository path | Exact responsibility |
| --- | --- |
| `diagnostics/phase1c-stagea/Phase1CStageAProbe.xcodeproj/project.pbxproj` | Independent one-app simulator-only native target; distinct diagnostic bundle, iOS 18+ deployment, generated Info.plist, no signing for simulator, no package/target/project reference to Lumen. No production target edit. |
| `diagnostics/phase1c-stagea/Phase1CStageAProbe.xcodeproj/xcshareddata/xcschemes/Phase1CStageAProbe.xcscheme` | Dedicated shared scheme for reproducible explicit diagnostic simulator build; no production build, tests or archives. |
| `diagnostics/phase1c-stagea/Probe/StageAProbeApp.swift` | Minimal executable entry point and strict argument parser; role routing for A0-negative, A0-wait, A1-create and A1/A4-observer; fails closed for absent/invalid role, run ID, path or simulator configuration. No Lumen imports. |
| `diagnostics/phase1c-stagea/Probe/StageASentinel.swift` | Exactly one unique synthetic @Model with run ID and fixed sentinel token; no category, payment method, transaction, witness, lifecycle control or reference entity. |
| `diagnostics/phase1c-stagea/Probe/StageAStoreDriver.swift` | Explicit test-owned ModelConfiguration(schema:url:) for a store inside the run's isolated diagnostic root; A1 save/fetch milestones; intentional non-kill completion for A1; no production LedgerStore, Seed or migrations. |
| `diagnostics/phase1c-stagea/Probe/StageAObserver.swift` | Fresh-process physical pre-open assertion and isolation checks, then SwiftData construction/fetch **only** at the designated preserved working-copy URL; emit pre/post event markers outside the store artifact subtree. Missing-store copy negative control. |
| `diagnostics/phase1c-stagea/Host/controller.py` | Host orchestration, explicit simulator UDID/app path/run ID, launch and PID evidence, guarded external signal, worker quiescence, new observer launch/PID verification, scenario scheduling and immutable run manifest. |
| `diagnostics/phase1c-stagea/Host/artifact_capture.py` | Host-side lstat/no-follow inventory, approved test-root containment, original artifact baseline, quiescent full-directory byte copy, digest/identity validation, and separate source/copy pre/post inventories; no original SwiftData opens. |
| `diagnostics/phase1c-stagea/Host/oracles.py` | Fail-closed A0/A1/A4 predicates and negative controls, evidence field validation, OBSERVED/FALSIFIED/INCONCLUSIVE/BLOCKED classifications, no inference from log markers alone. |
| `diagnostics/phase1c-stagea/README.md` | Diagnostic-only operator guide: prerequisites, explicit build/run contract, simulator/toolchain capture, scenario mapping, safety checklist, unsupported conditions, evidence-limitation rules. |
| `diagnostics/phase1c-stagea/.gitignore` | Ignore disposable run artifacts, DerivedData, binaries, logs and unreviewed machine-local output. Do not modify repository-root gitignore or GitHub Actions. |

No XCTest target is proposed initially: the independent controller and `oracles.py` must evaluate cross-process evidence that an in-app XCTest assertion could not independently establish. This is not a refusal to add tests later; any additional testing file/target is a new reviewed boundary. Generated local build products/run manifests are untracked output, not new repository source files.

**Explicit no-change list:** `ios-lumen-finance/**`, `.github/workflows/**`, `docs/ROADMAP.md`, production startup/bootstrap/reconciliation, `LedgerStore`, `Seed`, `LedgerWrite`, SwiftData production models/schema/migrations, Phase 1A original fixtures or runners, Phase 1B retained evidence, imports/exports, app installation and user data. No app group or reference to the real Lumen data container is permitted.

---

# 3. Physical root, observer boundary and source-of-evidence

The diagnostic installation has its own Simulator application data container, resolved from the **specific** simulator UDID plus exact diagnostic bundle ID. Every scenario uses a new unpredictable run ID and a unique child under the diagnostic app's Application Support directory:

- `Phase1CStageA/<run-id>/source-store/`: only the worker's explicitly configured source SwiftData store URL and all of its associated artifacts, with no logging files mixed into the store subtree.
- `Phase1CStageA/<run-id>/inspection-copy/`: isolated sibling destination populated only while the worker is definitively stopped; never a hard-linked tree or symlink to source.
- `Phase1CStageA/<run-id>/events/`: synthetic worker and observer milestones, separated from store bytes.
- Host-controlled run manifest/log output is outside the app's store root, and ignored by Git.

The worker explicitly places `diagnostic.store` inside `source-store/`. The observer may receive only a separately validated `inspection-copy/diagnostic.store` location; it must never construct a SwiftData ModelContainer at the original URL, including on the missing-store negative control. Any file identified as possibly belonging to the configured store but outside the bounded captured source subtree is an immediate **BLOCKED / OBSERVATION INTEGRITY UNPROVEN** until independently resolved.

Controller path validation must resolve canonical paths and positively prove the candidate root is inside the diagnostic bundle's own Simulator container, not merely match a string containing “temp” or “Lumen”. Reject traversal, symlinks, special nodes, hard links, unexpected mounted roots, unavailable originals, and any bundle or simulator identity mismatch. No recursive cleanup outside the unique disposable run subtree. A missing/malformed run identity is a stop.

The observer is **a new OS process**, not just a new ModelContext in the worker. Reusing the diagnostic app binary is permitted only when the worker's prior process is independently confirmed gone and the observer's new PID/launch identity is recorded.

---

# 4. A0 external termination mechanism (precise proposed candidate)

**Proposed simulator controller:** Python 3 on the macOS host using `xcrun simctl` for install/launch/data-container resolution, plus an OS-level `SIGKILL` delivered by the *external host controller* to the launch-reported worker PID. This is a **candidate implementation**, not a verified claim about the user's accessible tools or Simulator process mappings. `simctl terminate` alone is not substituted for verified abrupt SIGKILL; ordinary termination/graceful exit is a separate negative control.

Before any kill, the controller must:
1. Record simulator UDID, app bundle identifier, unique run ID, exact diagnostic build hash and launch command/response with reported PID.
2. Independently resolve the host PID to a living executable/process identity consistent with the dedicated diagnostic app, simulator and current launch, record the initial identity, and reject ambiguous/PID-reused targets. **Never signal on a bundle-name guess or PID alone.**
3. Confirm a synthetic A0 waiting-state marker but recognize that marker does not prove process identity or future interruption.
4. Record the planned signal/target and time, issue a host `SIGKILL` only when target provenance is verified, record syscall result and subsequent independently observed process disappearance, and exclude replacement/PID reuse.
5. Launch the distinct fresh observer and record its different PID/launch evidence. If any identity, signal, death or relaunch assertion cannot be verified, classify **BLOCKED / TERMINATION UNVERIFIED** (or NOT REACHED), not PASS.

A0 controls: a deliberate worker-handled/injected error and an ordinary worker exit, each identified as **not externally killed**. If the Simulator exposes only a PID not safely attributable to the dedicated app, fail closed rather than risk signaling another process. A0 can establish only the demonstrated external death mechanism, not kill timing inside SwiftData; A2/A3 are excluded.

The worker/observer app may have to run in foreground to avoid iOS suspension. This is a toolchain feasibility condition to verify, not an assumed guarantee of instruction-level timing.

---

# 5. A4-first mandatory evidence-preservation protocol

A1's store-inspection result is inadmissible unless the corresponding A4 safeguards have passed for that run. Sequence:

1. **Quiescent boundary:** externally verify no admitted worker process remains, and there is no additional diagnostic writer. If an app/daemon or file writer cannot be excluded sufficiently for the particular copy protocol, stop with **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**.
2. **SOURCE PRE-OPEN inventory:** before the observer starts and before any new ModelContainer initialization, record source-store existence, relative paths, lstat node kinds, sizes, supported metadata, and content digests of all regular files; retain unexpected companion files rather than filtering by extension. Diagnostic events are outside this subtree.
3. **PRESERVE:** copy the complete quiescent source-store artifact subtree into a new sibling working-copy directory with bytewise independent regular files. Refuse symlinks/hard links/special files and unsafe traversal. Avoid time-of-check/time-of-use path substitution by opening source objects without following links and validating fstat identity; refuse a platform incapable of enforcing this. Record source-vs-copy file manifests and digests. Do not assume a single-file SQLite copy or matching bytes, by themselves, prove logical SQLite consistency.
4. **COPY PRE-OPEN inventory:** independently inventory the copied tree before any SwiftData call. Require all expected source artifact bytes represented and no unaccounted additional writer/change; otherwise stop. A distinct extra copy/snapshot-validation method may be necessary to establish consistency; inability to defend the copy protocol remains BLOCKED rather than inferred from a later successful fetch.
5. **FRESH INSPECTION:** launch new observer process; first record target existence/inventory without SwiftData, assert it points only at the copied root, and then construct a minimal ModelContainer on that copy. Record sentinel fetch/error and copied-artifact changes caused by container initialization or fetch.
6. **COPY POST-OPEN / SOURCE POST-OPEN:** after observer exits, independently record both inventories. Compare preserved SOURCE PRE-OPEN with SOURCE POST-OPEN by node/byte identity and relevant metadata; compare COPY PRE-OPEN with COPY POST-OPEN separately. Any source mutation, artifact escape, inconsistent copy or missing physical trace compromises inspection claims.
7. **Separate classifications:** do not promote mere observer success into source provenance, lifecycle identity, recovery permission, witness association, or accepted-mechanism success.

A4 missing-store negative control uses a new, intentionally empty **copy** root and an absent source store; the observer may cause a store to appear only in the disposable copy. Record this as an observer effect; never infer that a source store existed before observer initialization. Snapshot and inspection remain isolated from Phase 1A historical producers/originals.

Any unresolved SwiftData companion artifact behavior, copy inconsistency, or physical metadata instability receives a narrowly labeled BLOCKED/INCONCLUSIVE result with the raw safe trace retained; do not redefine the accepted ordinary failure envelope based on what was easy to copy.

---

# 6. Predeclared A0/A1/A4 scenario oracles

| Scenario | Expected evidence necessary for narrow OBSERVED result | Forbidden inference / blocked result |
| --- | --- | --- |
| **A0-negative: injected error** | Worker declares and performs controlled error path; controller observes exit/response, **no external signal**. | Not a crash. Any reported kill PASS is a falsified oracle. |
| **A0-negative: ordinary exit** | Worker exits intentionally; independently recorded exit identity, **no external signal**. | Exit alone never verifies A0 external kill. |
| **A0: external SIGKILL** | Verified unique worker PID/process attribution, external host SIGKILL action and return, independently confirmed process death, distinct fresh observer process. | Unknown PID/signal/death/freshness → BLOCKED / TERMINATION UNVERIFIED. Do not infer interruption inside SwiftData. |
| **A1: controlled create/save/reopen** | Initial empty source-store baseline; explicit store URL and synthetic sentinel commit marker; worker quiesced; A4 full source-copy isolation proof; fresh observer fetches matching run sentinel **on copy**; source stays unchanged; copy effects recorded. | Reopen success without A4 proof → BLOCKED / OBSERVATION INTEGRITY UNPROVEN, never A1 PASS. No claim about Lumen seeding or lifecycle authority. |
| **A4: known-store observer effect** | No observer-side SwiftData source open; source pre-open capture, preserved copy pre-open and post-open artifacts, protected unchanged source, attributable copy mutations or verified no-change observation. | Unknown companion/copy consistency, writer activity or original modification → BLOCKED. No assumption that “read-only” implies no writes. |
| **A4-negative: missing store** | Pre-open source absence verified; independent empty working-copy root; observer opening copy and any newly created artifacts are attributed to inspection; source remains absent. | A store newly created by inspection must never be described as a recovered original. |

A0/A1/A4 are **infrastructure feasibility only**. A2 actual post-save abrupt-kill crash recovery and A3 attempted mid-creation kill, physical-device behavior, witness/control durability, true authority correspondence, same-ledger effect/proof atomicity, racing ModelContexts, restoration hold and Stage B remain **NOT CHARACTERIZED** after this tranche. A negative trace is retained even if repeated positive runs succeed.

---

# 7. Minimal run evidence, execution prerequisites, and stop rules

A later executable controller must emit a separate JSON manifest per run containing: approved source commit and built diagnostic binary hash; exact scenario ID; predeclared predicate/version; run ID; specific simulator UDID, runtime, Xcode/Swift compiler versions; simulator data protection caveats; disposable root and identity verification (no private host path disclosure in shareable summary); worker launch args, PID and independent identity evidence; controller action/signal/return and process-death observation (where applicable); observer launch and new PID; synthetic boundary markers; source inventory pre-open; original source and copied artifact digest manifests; copy verification; copy pre/post inspection; source post-inspection; sentinel observation/error; admitted and forbidden outputs; result category; reason and limitations.

The host must preflight the dedicated app bundle, simulator ID, source path containment, no active diagnostic runner for that test root, runtime permission and build reproducibility. Evidence sharing must not expose private filesystem paths, local device identifiers beyond what's necessary for safe local replay, personal data or production Lumen records. No CI jobs or automatic repeated execution are included.

**STOP** if: any reference to the real app's container, production bundle/schema/startup or historical original; uncontrolled process target; unknown active writer; unknown companion artifacts; symlink/special path escape; isolated copy cannot be defended; observer source opened/mutated; missing baseline; or a new file required outside the approved list. Preserve only safely collectible synthetic evidence. Do not delete or reset installed Lumen or historical data.

Available outcome labels remain **OBSERVED (NARROW PLATFORM RESULT)**, **FALSIFIED ASSUMPTION**, **INCONCLUSIVE**, **NOT REACHED**, **BLOCKED / TERMINATION UNVERIFIED**, **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**, **NOT CHARACTERIZED**. Assertions are not a substitute for independently captured external evidence.

---

# 8. Required independent review and subsequent owner decision

The reviewer should inspect (a) separate project/target with exact eleven-file allowance; (b) host PID attribution and external SIGKILL feasibility with failure-closed condition; (c) Simulator container isolation and actor role separation; (d) pre-open source, preserved copy pre/post, original post-inspection distinctions and copy consistency limits; (e) A0/A1/A4 oracles including A4 as prerequisite to accepting A1; and (f) remaining excluded work and authority discipline.

**Requested disposition: APPROVE/REFINE THIS DOCUMENTATION-ONLY EXACT EXECUTABLE BOUNDARY.** That approval still must be followed by **a separate explicit owner authorization to write the listed files**. An even later, distinct owner decision is required before building, installing, launching, killing, copying, inspecting stores or executing diagnostic scenarios, unless the owner expressly combines executable implementation and initial running in that later authorization.

No production Swift/schema/CI changes, no diagnostic code or runs, no Rork build/import, no A2/A3, no historical fixture use, no Stage B and no mechanism acceptance promotion are performed or authorized by this document.
