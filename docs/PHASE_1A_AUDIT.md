# Phase 1A audit and validation evidence — 2026-09-10

## Effective baseline and authority

All four governing documents were read in full before implementation. No contradiction was found between them and the work order. No governing document is being modified.

Expected SHA: `dbc28ed9649d4930b45e2dcc44a7462729dfcf11`.
Effective workspace baseline / initial HEAD: `46bb52010e3664ed2bbc5d3df9ada64909b62653`, clean working tree.

The expected object is unavailable: `git show` failed with `not our ref` / `bad object` (exit 128). This non-shallow workspace's visible history cannot establish ancestry/equivalence to that SHA or enumerate commits newer than an unavailable object. No history was rewritten or fetched manually. This is a baseline identity limitation, not proof the GitHub commit does not exist.

Visible history, oldest first:
- `928560cbad13b67d2c89de358b8275c1b2756466` — initial app implementation.
- `5051595eec22948c2418790e87a93af50f7204ab` — Architecture Contract + history metadata only.
- `5ba4577c32899b34b06917d67e1b6c847a2a82e3` — Roadmap + history metadata only.
- `be822c8397c31d0d22c5a4ba916aa6264c0fd352` — Non_Goals + history metadata only.
- `3960563a9e3ed67dc341ec1f17b20f9ffc4b98d4` — Non_Goals → NON_GOALS path rename + history metadata only.
- `46bb52010e3664ed2bbc5d3df9ada64909b62653` — ADR-001 + history metadata only.

All named implementation audit targets exist. TransactionDraft is in Views/TransactionForm.swift. No stale implementation path substitution was needed.

## Pre-change validation (before any implementation edits)

Working directory: `/home/user/rork-app` (Linux x86_64, kernel 6.1.158+). No local xcodebuild, xcrun, or swift executable was available. No toolchain was installed.

1. `runChecks({"appPath":"ios-lumen-finance"})`: PASS, remote simulator build. Device/Release build expressly unverified. Tool did not expose exact xcodebuild invocation, scheme, configuration, destination UDID, runtime version, warning list, or numeric exit status.
2. `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests","LumenFinanceUITests"]})`: execution FAILED before tests. 0 passed, 0 failed; no tests established as executed. Log says test build succeeded, then `build-for-testing produced no .xctestrun for scheme "LumenFinance"; the scheme may have no test targets`.
   - Project: LumenFinance.xcodeproj; scheme reported: LumenFinance; configuration shown: Debug-iphonesimulator; architecture arm64.
   - Runtime version and destination UDID not exposed. Both test targets compiled/linked. No scheme or test plan was checked in at baseline.
   - PRE-EXISTING warnings: `Metadata extraction skipped. No AppIntents.framework dependency found.` in app/unit/UI targets. No AppShortcuts found is a note, not a domain failure.
   - Remote result path reported: `.limbuild-sandbox/result-bundles/build-1789026476725168000/build.xcresult` under the runner workspace. The advertised `/tmp/rork-swift-test-ios-lumen-finance.log` is not readable in this local sandbox. Raw runner artifacts are not claimed as preserved locally.

Exact baseline repository commands (cwd project root):
```
git status --short
git rev-parse HEAD
git rev-parse --is-shallow-repository
git show --no-patch --format=fuller dbc28ed9649d4930b45e2dcc44a7462729dfcf11
git log --all --format='%H %s' --name-status
git status --porcelain=v1
git ls-tree -r --name-only HEAD
uname -a
command -v xcodebuild
command -v xcrun
command -v swift
```
The first chained git invocation stopped at the unavailable expected SHA; its requested range log/diff did not run. Subsequent all-history inspection succeeded.

## Read-only findings / final admission matrix (recorded before implementation)

Paths below are relative to ios-lumen-finance/LumenFinance unless stated. Line references describe the effective baseline. A=current concrete problem; B=material cost of delay; C=safe execution. NO migration means no stored field/raw value/relationship or historical interpretation is changed. Behavioral gates on new input are not retroactive remapping.

| Finding / evidence | Authority | A: current risk | B: delay cost | Migration? | Authentic fixture required? / available? | Regression / recovery | Decision and C rationale |
|---|---|---|---|---|---|---|---|
| App initialization silently falls back to memory; LumenFinanceApp:14–29 | Contract 21; Roadmap 1A.1 | Ledger appears durable when it is not | Blocks trustworthy ledger use | NO | NO / N/A | Throwing container factory; startup failure test; retry same store, never erase | FIX NOW: explicit unavailable screen, no fallback |
| Swallowed canonical writes; Review:238–246; Detail:78–81,239–257 | Contract 21; ADR:67–106; 1A.7 | False success, dirty visible state after failed commit | Blocks correctness and later ingestion | NO | NO / N/A | Synchronous guarded commit + rollback; injected commit failures and disk reopen CRUD | FIX NOW: small write boundary, no global error framework |
| Review duplicate property creates relationship-connected Transaction objects; Review:26–28; Form:54–69; Tag inverse Models:112 | Contract 3/29; ADR | Rendering may mutate managed inverse relationships before confirmation (static risk, not baseline-runtime proven) | Deepens bypass of Review | NO | NO / N/A | Scalar duplicate checks repeatedly leave context/tag inverse unchanged | FIX NOW: no model creation during read-only matching |
| Invalid draft can save through ignored or edit paths; Form:29–32; Review:208–210; Detail:239 | 1A.5–7; ADR edits | NaN/infinite/zero/blank/invalid edits; status controls overwrite edit buffer | More invalid durable records | NO | NO / N/A | Validation in conversion/apply, failure rollback, unchanged legacy amount retained on unrelated edit | FIX NOW: validate every write and isolate editing |
| Mixed persisted status enum; Enums:50–55, all Review/Detail/filter/analytics references | Contract 5/25/26; 1A.4 | Lifecycle/review conflated; review_needed can already be explicitly saved | New mixed records increase future mapping burden | YES for split/remap | YES / NO | Need baseline store with all five values, explicit preservation/mapping and failure recovery | PREPARE ONLY: no enum/raw value/remap; retain existing semantics; separately gate new confirmation to pending/posted |
| Mark ignored creates canonical record; Review:208–210 | Contract 3–5; 1A.6; ADR | Rejected input becomes ledger state | More legacy excluded records | NO for discard-only new-input action | NO / N/A | Discard performs no write; existing ignored records preserved, inspectable/excluded as before | FIX NOW: discard new draft rather than create ignored Transaction; legacy edits preserve statuses |
| confidence_score copied from machine stub; Form:64; Upload:205; Detail:163; Seed:164 | Contract 4/11; 1A.3 | Machine uncertainty embedded in ledger; no analytics dependency | Further accumulation before evidence phase | YES for removal/relocation | YES / NO | Need legacy confidence nil/0/fractions/1 and preservation of provenance | PREPARE ONLY: no persisted field removal/relocation; the independent new-input guard is listed below |
| duplicate_fingerprint literal soft-match; Review:241; Models:195 | 1A.8; Contract 25 | Not a content hash; naming ambiguous | Small, no behavior currently depends on it | YES for reinterpret/remove | YES / NO | Preserve old strings; matching tests | PREPARE ONLY: preserve soft-match advisory semantics, no evidence identity claim |
| Duplicate matcher ignores currency/type and creates random candidate IDs; Analytics:100–106 | 1A.8/10 | False warnings between unrelated financial events | Blocks safe review | NO | NO / N/A | Currency/type/merchant/window/payment tests; deterministic nearest result; no auto duplicate status | FIX NOW: scalar similarity, preserve advisory fingerprint meaning |
| Optional source reference; Models:202; manual source nil | Contract 7/8; Non-Goals Evidence | No immediate cardinality defect requiring migration | New cascade or required source would increase 1B cost | YES for relationship change | YES / NO | Source-free manual and shared-source preservation tests | DEFER relationship redesign; do not cascade source deletion |
| Supabase naming comments; Models header, Enums header, FutureModels | Contract 16/24; Non-Goals Backend | Comments overpromise future 1:1 sync; no current cloud dependency | No material migration need | YES if properties renamed | YES / NO | Keep model files byte-identical | DEFER naming/DTO cleanup; current local schema is authority |
| Double stored money; Models:186/252; Form init rounds to 2 places | 1A.10; Contract 25/26 | Binary arithmetic, unrelated edit rounding, transfer misleading plus sign | Data accuracy worsens | YES for stored representation migration | YES / NO | Legacy finite/negative/high precision/zero- and three-exponent currencies required | PREPARE ONLY: no stored monetary representation migration; independent derived/edit safeguards listed below |
| Aggregates mix currencies, rows relabel using preference; Analytics all sums; AppState:44–51; Row:53; Detail:96/139 | Non-Goals financial boundaries; 1A.9/10 | Misleading monetary truth | Blocks useful summaries | NO | NO / N/A | Selected-currency sums, explicit exclusion notices, original-currency row formatting tests | FIX NOW: no FX, no conversion |
| Transfer/refund/status math; Analytics:34,50–62; Models signedAmount | 1A.9/10 | Transfer shown as incoming although sums exclude; refund policy implicit | Near-term correctness requires explicit policy | NO for derived presentation | NO / N/A | Expense out; income/refund in; transfers neutral; ignored/duplicate excluded; legacy review_needed included | FIX NOW derived presentation/tests; preserve legacy financial inclusion semantics |
| Date-only UI backed by Date instants, preference ignored; AppState:33–41; Analytics:37–42; Form:17–18; all date displays | 1A.11; Contract 25 | Device timezone changes can shift historical day; original zone not recorded | Migration ambiguity already exists | YES for stored civil-date semantics | YES / NO | Need legacy instants near midnight/DST with known original zone; cannot infer lost information | PREPARE ONLY: no civil-date migration or historical date reinterpretation; independent disclosure/test seam listed below |
| Seed errors swallowed, samples mixed with real history; Seed:15–32; Root:32 | 1A.1/13; Contract 27 | Read failure treated as empty, unexpected sample records | Contaminates ledger and future migration | NO | NO / N/A | Defaults only, per-table idempotence, failed commit rollback/retry | FIX NOW: no automatic sample Transactions; never delete existing samples |
| Reset unconfirmed/all data, debug defaults production on; Settings:105,137–146; Flags:26 | Contract 27; 1A.13/14 | Accidental unrecoverable deletion | Immediate safety risk | NO | NO / N/A | Remove live-ledger developer reset route, test default initialization | FIX NOW: disable destructive developer utility in live ledger rather than implement portability phase |
| Upload swallows load/write errors and fabricates parsed authority; Upload:155–205 | Contract 4/21; 1A.6; Non-Goals AI | Failed photo load becomes successful-looking review | Misleads user now | NO for failure/label correction | NO / N/A | Guard read/write; cancel-safe task; explicit sample disclosure; preserve existing source representation | FIX NOW: bounded errors and labels only; independent retention work listed below |
| Filters omit nil manual origin; Transactions:48; status only pending shown Row:41 | 1A.12; Contract 7 | Manual transactions disappear under manual filter; hidden excluded statuses | Blocks inspect workflow | NO | NO / N/A | Composing filters/search tests; display every status | FIX NOW |
| Unconsumed feature flags and broad Dynamic Type/layout issues | 1A.14; Non-Goals development scope | Debug toggles overpromise; broad audit needed | Nonblocking if debug hidden | NO | NO / N/A | Add critical action labels/keyboard dismissal only | DEFER: broad flag/layout work; independent critical control fixes listed below |
| Empty tests and nonreproducible scheme; tests targets + absent xcscheme | Contract 29; 1A.15 | No proof of correctness; baseline execution blocked | Prevents safe evolution | NO | NO / N/A | Check in shared test scheme; focused unit/persistence/UI coverage; run build/test | FIX NOW; runner capability remains a possible blocker |

The following rows separate the independently admitted guards from the migration candidates above; they clarify the same pre-implementation decisions, not additional feature scope.

| Finding / evidence | Authority | A: current risk | B: delay cost | Migration? | Authentic fixture required? / available? | Regression / recovery | Decision and C rationale |
|---|---|---|---|---|---|---|---|
| New confirmation copies draft confidence, Form:64 | Contract 4/11 | New machine uncertainty accumulates in canonical records | Deepens ingestion coupling | NO | NO / NOT APPLICABLE | New confirmation nil confidence; legacy metadata edit preservation tests | FIX NOW: stop new copying, no legacy rewrite |
| New confirmation accepts review/ignored/duplicate status, Review/Form | Contract 3/5; 1A.6 | Rejected/new review state persists as financial lifecycle | More ambiguous records | NO | NO / NOT APPLICABLE | canConfirm gate + all-status conversion tests | FIX NOW: only pending/posted for new input; existing status values unchanged |
| Unrelated edits round money; Double addition; Form:40; Analytics sums | 1A.10 | Precision loss and floating-point accumulation | More silent value changes | NO | NO / NOT APPLICABLE | Original amount preserved on unchanged text; decimal intermediate sum tests | FIX NOW: no stored amount conversion |
| Timezone preference appears effective but is ignored, Settings/AppState | 1A.11 | User assumes dates follow chosen zone | Misleading ledger inspection | NO | NO / NOT APPLICABLE | Explicit calendar/clock tests; device-zone disclosure | FIX NOW: stop offering ineffective timezone control; stored preference retained |
| Critical add/clear/keyboard controls, Root/Form/Transactions | 1A.14 | Essential actions unlabeled or difficult with keyboard | Blocks core workflow | NO | NO / NOT APPLICABLE | Accessibility IDs/labels and keyboard Done; UI workflow test source | FIX NOW: no visual redesign |
| Temporary evidence files, fabricated old hashes and retention, Upload/Detail | Contract 9; Roadmap 1B | Legacy file may be absent; old hashes are UUIDs, not content identity | Requires explicit retention/provenance policy | YES for legacy semantic rewrite | YES / NO | Preserve legacy metadata; do not promise temporary evidence is permanent | PREPARE ONLY: Phase 1B ownership; no retroactive rehash/cascade |
| VersionedSchema adoption, App schema initialization | 1A.2; Contract 25/26 | No executable migration chain yet | Blocks future persisted mutations | YES, treat adoption as compatibility-sensitive | YES / NO | First capture effective-baseline store; version baseline without renaming fields; test open before adding migration | PREPARE ONLY: strategy documented, adoption not forced |

## Legacy-state preservation decision (before implementation)

Serious persisted candidates considered: status split, exact stored money, confidence relocation, fingerprint semantics, civil dates, versioned schema adoption. Optional source redesign/naming are deferred, not justified FIX NOW candidates.

No authentic legacy store was generated or preserved. Baseline app compiled but test runner executed no tests; local SwiftData/CoreSimulator unavailable. The returned remote test log/artifact paths cannot be read here. A fixture constructed later using the unchanged/new app would not be labelled a baseline fixture.

Consequently NO persisted candidate is admitted to mutation in this pass. Models.swift, Enums.swift and FutureModels.swift remain untouched. Default production store path/configuration/schema list must remain the same. Existing-store compatibility remains NOT VALIDATED even if post-change disk round-trips succeed.

## Explicit intermediate semantics

- Existing statuses/raw values and historical inclusion remain unchanged: ignored/duplicate records excluded; pending/posted/review_needed included. Legacy review_needed may already have been explicitly confirmed by baseline Save; it is not silently deleted or reclassified.
- New confirmed input must select pending or posted. Ignoring a new draft discards it without creating a canonical record. Existing records remain inspectable/editable with all legacy statuses; exclusion is not deletion.
- Legacy confidence and soft-match fields are preserved. New confirmation does not copy machine confidence. Fingerprints remain transaction-similarity annotations, never evidence hashes.
- Stored amounts remain Double magnitudes; expenses reduce flow, income/refunds add flow, transfers do not affect net flow. Income totals include refunds and will be labelled accordingly. No account-balance direction is inferred for transfers.
- Aggregates use only selected currency; other currencies are not converted. Weekly means transaction dates in the calendar week, not creation timestamps; labels disclose this.
- Existing Date values remain instants interpreted in the device calendar/timezone. Civil-date recovery/migration is unresolved; no timezone permission or heuristic date rewriting is introduced.
- Automatic initialization creates reference defaults only, never financial samples. Existing samples cannot be reliably distinguished from real records, so none are automatically deleted.

## Post-change evidence

### Build/test chronology and environment

All invocations below were made through the managed tools from project root (`/home/user/rork-app`). App source lives in `ios-lumen-finance`; Xcode executes remotely, not on this Linux host.

1. After hardening and test-source addition: `runChecks({"appPath":"ios-lumen-finance"})` — PASS simulator app build. This does not build/run the test suite or certify device Release.
2. `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests","LumenFinanceUITests"]})` — FAIL at test compilation, exit 65. 0 tests executed; 0 passed, 0 failed. Known diagnostics: `Category is ambiguous for type lookup` between LumenFinance.Category and Objective-C Category, plus resulting generic inference errors in LedgerPersistenceTests. This error was INTRODUCED by the new tests, not a baseline defect.
   - Tool log identifies Xcode `/Applications/Xcode-26.4.app`, iPhoneSimulator26.4 SDK, arm64, Debug-iphonesimulator, project/scheme LumenFinance. SDK version is not proof of an available/executed simulator runtime.
   - Remote result path: `.limbuild-sandbox/result-bundles/build-1789027132096008000/build.xcresult`. Actual xcodebuild invocation and destination were not exposed; do not invent them.
3. Qualified test references as `LumenFinance.Category` and retained each disk-test ModelContainer with explicit lifetime protection. These source corrections have NOT been test-build revalidated.
4. Requested the same `swiftTest` invocation after the corrections. Tool refused execution due to its attempt limit. No test build, test run, results bundle, or exit status was produced for this request. No bypass/repeated retry was attempted.
5. Final `runChecks({"appPath":"ios-lumen-finance"})` — PASS simulator app build. Device/Release and test compilation remain unverified by this mechanism.

### Static validation

These commands ran successfully (exit 0) against the effective baseline:
```
git diff --check
git diff --stat 46bb52010e3664ed2bbc5d3df9ada64909b62653
git diff --exit-code 46bb52010e3664ed2bbc5d3df9ada64909b62653 -- docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md docs/ROADMAP.md docs/NON_GOALS.md docs/architecture/ADR-001-source-of-truth-and-ingestion.md ios-lumen-finance/LumenFinance/Models ios-lumen-finance/LumenFinance/Assets.xcassets ios-lumen-finance/LumenFinance.xcodeproj/project.pbxproj
git status --short
git diff --numstat 46bb52010e3664ed2bbc5d3df9ada64909b62653
git rev-parse HEAD
```
The protected-path diff is empty: governing docs, all three model files, assets/icon, and project.pbxproj are byte-identical to baseline. Final HEAD remains the effective baseline; no manual Git commit/push/history operation was performed.

Repository-wide post-change searches found no `try?` or `try!` in production Swift. The sole explicit production `.save()` is inside LedgerWrite. Transaction creation in Review and edit/delete/status mutations use that boundary. Seed's reference insertion uses it too. The retained sample-transaction generator has no production call site. All aggregate callers now supply currency explicitly. These are static observations, not executed persistence proof.

### Implemented changes and admission rationale

- **LumenFinanceApp; new LedgerStore:** before, failed durable open silently substituted memory. After, retry/unavailable UI uses the same durable store/schema/configuration; no reset/fallback. Contract 21 and Roadmap 1A.1 require this.
- **New LedgerWrite/LedgerWriteError; Review; Detail:** before, failures dismissed or played success feedback. After, clean-context guarded synchronous mutation/save, rollback on failure, retained draft/error UI, and success only after return. No speculative repository/service stack.
- **TransactionForm; ManualEntry:** finite-positive/currency/merchant/category validation reaches create and edit; original amount survives unrelated edits without two-decimal truncation; missing legacy posted date is not synthesized by an unrelated edit. Default currency applied once. Keyboard completion is available.
- **Review; Analytics:** no relationship-connected model construction during duplicate reads. Matching is scalar, currency/type-aware, exact stored-magnitude-aware, payment-compatible and deterministic within the existing elapsed 72-hour window. Warning changes button to Save anyway, never auto-marks duplicate. Existing soft-match metadata meaning remains advisory.
- **Review/Form; Upload:** new rejected draft creates no Transaction; new confirmations use pending/posted; confidence is not newly copied into canonical state. All old enum cases/fields remain untouched and legacy edits preserve metadata. Stub now labels fabricated fields honestly, propagates load/write failures and avoids fake captured timestamps/content hashes.
- **Money; Analytics; AppState; Dashboard; Insights; Row; Detail:** derived decimal addition, original-currency formatting, currency-specific summaries with exclusion disclosure; transfers displayed without incoming plus sign; refund/legacy status policies stated. No FX, no exact-money storage claim.
- **TransactionSearch; Transactions; Row:** source-free manual entries remain discoverable under the manual filter; shared predicate is testable; all statuses are displayed, clear-search labelled.
- **Seed; Root; Settings; FeatureFlags:** defaults only, explicit seed errors, no auto financial samples, no live-ledger destructive reset route, debug panel off. Existing data is not deleted/reseeded. Device-timezone limitations disclosed; unused preference not migrated.
- **Shared LumenFinance.xcscheme and tests:** explicit test targets and regression sources replace prototype-only assurance. Whether the new scheme fixes the original runner artifact problem is still NOT VALIDATED.

### Test inventory (authored, not executed)

- LumenFinanceTests.swift: **9 domain test methods** covering conversion/metadata boundary, invalid creates/edits, new confirmation statuses, unchanged legacy amount/metadata, analytics types/statuses/currencies, duplicate event distinction, timezone/month windows, composable search/manual origin, money labels/stub honesty.
- LedgerPersistenceTests.swift: **7 persistence/failure test methods** covering disk create/reopen/edit/status/delete/reopen; failed create rollback of source/tags and retry; failed edit/delete rollback; seed failure/retry/idempotency; read-only duplicate checks/discard leaving no graph; all legacy-valued records round-tripping through unchanged schema and shared-source retention; startup failure/no fallback and clean-context precondition.
- LumenFinanceUITests.swift: **1 core workflow test** creates a unique test-owned record, reviews/saves, relaunches/inspects, posts/edits, relaunches and deletes only that record. It does not reset the application store. If interrupted it can leave that clearly test-named record.
- Existing LumenFinanceUITestsLaunchTests.swift: **1 unchanged launch/screenshot method**, possibly invoked per UI configuration by XCTest.
- There are 18 method definitions, NOT 18 passing tests. Latest compilation of corrected tests is not validated. None of the domain/persistence/UI assertions executed in this run.

The legacy-values round-trip test explicitly does not claim an authentic baseline fixture. It creates records under the current unchanged schema to exercise serialization, not migration.

### Validation categories

- Build: **PASS** simulator app only.
- Clean install: **NOT VALIDATED**. No observed fresh installation/initialized ledger workflow.
- Existing-store compatibility: **NOT VALIDATED**. No authentic pre-change store was available; byte-identical models reduce risk but do not prove compatibility.
- Migration: **NOT APPLICABLE** to shipped changes. **NO PERSISTED SCHEMA MIGRATION OCCURRED.** Proposed persisted migrations remain unvalidated and unimplemented.
- Domain tests: **NOT VALIDATED**, 9 authored, 0 executed/passed/failed assertions.
- Persistence tests: **NOT VALIDATED**, 7 authored, 0 executed/passed/failed assertions.
- UI/runtime workflow: **NOT VALIDATED**. App artifacts compiled; no observed execution of the CRUD/relaunch scenario.

### Warning/failure delta

- PRE-EXISTING: expected baseline SHA unavailable in this checkout; baseline test runner produced no xctestrun; AppIntents metadata extraction warnings; absent local Apple toolchain.
- INTRODUCED: Category test-compile ambiguity and dependent generic errors (exit 65). Qualified in source; successful correction not independently compiled by the test runner. Container-lifetime issue found in static review and corrected before any execution.
- VALIDATION BLOCKER: test tool rejected revalidation after the correction; no further test invocation permitted this run.
- RESOLVED IN SOURCE / APP-BUILD VERIFIED ONLY: silent ephemeral fallback, swallowed production saves, duplicate-query model creation, invalid edit bypass, automatic samples/live reset, cross-currency relabelling/aggregation. Runtime/regression proof remains pending.
- Final build tool reported no warnings, but did not expose a complete warning inventory; this is not a claim of zero compiler/runtime warnings.

### Known deferrals and smallest continuation point

1. Restore test execution (runner artifact/attempt-limit issue); compile corrected tests, execute all targets, inspect xcresult counts and failures. This blocks Phase 1A completion. No more persisted mutations should begin first.
2. Reconcile requested SHA with the actual repository checkout; establish whether source trees match. Baseline ancestry remains unknown.
3. Preserve a genuine effective-baseline application store, including all statuses, source-free/shared-source records, precision/currency/date boundaries and optional metadata. Then open it with the hardened app without deletion/reseed. Existing-store compatibility is outstanding even with an unchanged schema.
4. Versioned schema adoption and status/civil-date/exact-money migrations: PREPARE ONLY, Phase 1A follow-up with authentic fixture/recovery evidence. Persisted status mapping and civil-date origin are not guessed. Versioning strategy adoption and robust date semantics remain phase-exit concerns.
5. Confidence/fingerprint field relocation: PREPARE ONLY; historical metadata stays as-is. Full evidence provenance/retention belongs to 1B; content identity is not implemented.
6. Many-to-many evidence, renaming/snake_case cleanup, Supabase, advanced analytics/budgets/OCR: DEFER to governing phases; do not block bounded ledger hardening merely for cleanliness.
7. Broad feature-flag/Dynamic Type redesign: DEFER; no demonstrated reason to expand scope. Critical controls have limited fixes but VoiceOver/keyboard workflow is not runtime validated.
8. Monetary limits remain: persisted binary Double, decimal input precision/currency-exponent enforcement and pathological aggregate-overflow handling are not fully solved. Decimal intermediates do not make the store exact. These require focused tests and deliberate rules before claiming money correctness complete.
9. Existing seeded payment methods may contain fictional institution/last-four metadata; retained default templates still contain it. No legitimate existing payment records were rewritten. Review this trust issue in the next bounded seed pass; do not automatically erase legacy values.

**PHASE 1A NOT YET COMPLETE.** The application compiles and admitted source-level guards are implemented, but automated execution, durability/relaunch evidence, authentic existing-store compatibility, executable schema-evolution practice, and date/money edge semantics remain insufficient for the Roadmap exit criteria.

### Diff scope

26 changed/added files: 22 app/configuration files, 3 test files, 1 audit report. Before this report's final expansion, the snapshot diff was 1,082 insertions / 310 deletions; final `git diff --stat` is authoritative. No governing documents, persisted model definitions, icon/assets, or project.pbxproj changed. Initial visible governance-only commits remain separate from this implementation diff.

## Checkpoint validation continuation — 2026-09-10

This section supersedes the earlier unexecuted-test status for this continuation only. The prior chronology is retained as historical evidence, not rewritten. This report is not governance.

### Starting identity and frozen scope

- Canonical pre-hardening identity supplied by the owner: `dbc28ed9649d4930b45e2dcc44a7462729dfcf11`.
- Canonical candidate supplied by the owner: `45207849da53cd67eb3f33d2e7cd8f1d1d6bba91`, externally verified by the owner as its direct child. That relationship is accepted for this continuation; it was not independently verified here.
- Actual starting HEAD: `ba07db07c3ac1153539366ba8436b322cecf2df6`; clean working tree. This checkout contains the previous hardening implementation and shared scheme.
- One object-availability check per canonical SHA returned `not our ref` / `could not get object info` (exit 128). No further history reconciliation, active checkout replacement, reset, manual commit, or push was attempted. Exact tree equivalence to the unavailable GitHub candidate is not claimed. All executable results below identify the actual tested checkout.
- All four canonical governance documents and the prior audit were read in full. Governance and persisted model files were never modified.
- Production and tests were restored byte-for-byte to starting HEAD after the unsuccessful/unvalidated experiments below. The only retained continuation change is this evidence section.

### Execution chronology and exact mechanisms

All tools were invoked from project root. No actual remote `xcodebuild` command, destination UDID, current Xcode/runtime version, numeric runner exit status, or downloadable xcresult was exposed in this continuation. Earlier SDK details must not be reused as current runtime evidence.

1. **Unchanged starting checkout, full existing suite:**
   `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests","LumenFinanceUITests"]})`
   returned **14 passed, 7 failed**. Tests genuinely executed. This establishes that the previous Category correction and existing shared scheme permit compilation/execution in this run; neither needed modification.
2. **Minimal rollback experiment:** inserted `context.processPendingChanges()` immediately before rollback, then ran:
   `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests/LedgerPersistenceTests/testFailedCreateRollsBackSourceAndTagsThenCanRetry","LumenFinanceTests/LedgerPersistenceTests/testFailedEditStatusAndDeleteRestoreCommittedState"]})`
   returned **0 passed, 2 failed**, with the same tag-relationship and amount-restoration failures. The experiment was ineffective and removed.
3. **Unverified corrective experiment:** prepared explicit pre-write snapshots of affected transactions/tag inverses in LedgerWrite, passed affected records from Review/Detail and corresponding tests without relaxing assertions, and made FlowLayout return measured width for an unconstrained proposal. Then ran:
   `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests/LedgerPersistenceTests/testFailedCreateRollsBackSourceAndTagsThenCanRetry","LumenFinanceTests/LedgerPersistenceTests/testFailedEditStatusAndDeleteRestoreCommittedState","LumenFinanceUITests/LumenFinanceUITests/testManualReviewSaveRelaunchInspectEditStatusAndDelete"]})`
   returned **0 passed, 0 failed**, with `Simulator device failed to launch app.rork.8m36zsug0ex00d13e28li.` No test executed in this attempt. This is a runner/runtime launch blocker, not evidence that the proposed corrections worked or failed. Its underlying cause could not be established. No automatic unchanged launch retry was performed.
4. **Restore frozen candidate:** all five temporarily edited files were restored to starting HEAD using file edits. This avoids retaining production corrections without the required failing-test-to-pass evidence chain.
5. **Final restored app build:** `runChecks({"appPath":"ios-lumen-finance"})` returned **PASS**, simulator build only. Device/Release remains unverified. This does not override the executed test failures on the same restored source.

Every swiftTest response advertised `/tmp/rork-swift-test-ios-lumen-finance.log`; attempts to read that path returned file-not-found locally. `rork-agent logs runtime --errors --limit 100` returned no runtime logs on both diagnostic requests. The remote test summaries are the available evidence; detailed per-assertion results, launch failure diagnostics, and workflow checkpoints are not available.

### Test counts and classifications

Counts below describe the first full run, not cumulative retries. The two targeted failed executions in attempt 2 are additional invocations of the same persistence methods. Source inventory is 18 methods; the launch method ran four configurations, yielding 21 reported outcomes. No skipped tests were reported; the tool supplied no separate skip inventory.

| Area | Methods in source | Executed outcomes | Passed | Failed | Result |
|---|---:|---:|---:|---:|---|
| Domain | 9 | 9 | 9 | 0 | PASS |
| Persistence | 7 | 7 | 5 | 2 | FAIL |
| Primary UI workflow | 1 | 1 | 0 | 1 | FAIL |
| Existing launch/screenshot | 1 | 4 | 0 | 4 | ENVIRONMENT failure |
| Total | 18 | 21 | 14 | 7 | FAIL |

The area breakdown follows the complete failed-case list, source inventory, and aggregate result. No per-case success transcript was returned.

- **PRODUCTION DEFECT:** `testFailedCreateRollsBackSourceAndTagsThenCanRetry` reports `XCTAssertTrue failed`. The applicable assertion is `tags.allSatisfy { $0.transactions.isEmpty }`. A failed create does not restore the expected in-memory inverse relationships. Do not call this proven on-disk corruption: no independent disk reopen at the failure point is present in this method.
- **PRODUCTION DEFECT:** `testFailedEditStatusAndDeleteRestoreCommittedState` reports `XCTAssertEqual failed: ("88.5") is not equal to ("42.19")`. The referenced canonical transaction still exposes the attempted edit after the commit throws and rollback returns. The write boundary's assumption that rollback alone restores all visible values is invalid in this execution. Underlying SwiftData internals are not established. On-disk values were not separately reopened at that failure point.
- **PRODUCTION DEFECT (localization provisional):** `testManualReviewSaveRelaunchInspectEditStatusAndDelete` reports `Invalid frame dimension (negative or non-finite).` FlowLayout currently returns infinity for an unspecified/infinite width proposal and is a concrete suspect, but the returned summary has no stack or last completed workflow step. The attempted finite-width correction never reached executable validation and was reverted. Introduction in the hardening commit is not established; this layout predates it in the available local history.
- **ENVIRONMENT:** `testLaunch` fails four configurations with `Internal error: Attachments cannot be added to the test because activities are disabled. (NSInternalInconsistencyException)`. Screenshot assertions were not removed or skipped to conceal the limitation.
- **ENVIRONMENT (cause unestablished):** attempt 3 cannot launch the app; no assertions execute. No test-configuration change is justified by the limited launch diagnostic alone.
- No observed failure was reclassified as TEST DEFECT or TEST ASSUMPTION to make the suite pass.

### Domain evidence

All nine existing methods passed: draft confirmation/machine boundary; invalid create/edit validation; new-input lifecycle gate; unrelated-edit high-precision Double and legacy metadata preservation; analytics types/statuses/currencies/decimal intermediates; duplicate currency/type distinction; explicit date windows; composable search/source-free manual origin; formatting and stub authority.

The aggregate test covers expenses, income, refunds, transfers, pending/posted/review_needed inclusion, ignored/duplicate exclusion, foreign-currency exclusion, and 0.1 + 0.2 through decimal intermediate arithmetic. The formatting test checks explicit USD/EUR labeling. This is evidence for the tested cases, not an exhaustive money/date guarantee or observed original-currency UI presentation.

### Persistence evidence and limits

The five passing methods are:

- `testDiskCreateReopenEditStatusDeleteReopen`: actual URL-backed store; defaults, create, container reopen, edit with status change, reopen assertions, delete and reopen absence. This is same-build persistence evidence, not an app clean install or process relaunch.
- `testSeedIdempotencyAndFailureRetryWithoutSamples`: injected seed failure, successful retry, stable category IDs/reference counts, zero automatic financial Transactions.
- `testRepeatedDuplicateReadAndDiscardLeaveNoDurableGraph`: repeated matching leaves context/tag inverses untouched; explicit save leaves zero Transactions. This tests the read path, not tapping Discard in the UI.
- `testAllLegacyValuesRoundTripUnchangedSchemaAndSharedSourceSurvivesDelete`: all legacy statuses, precision/currency/confidence/fingerprint round-trip, shared source survives deleting one transaction. These records are generated by the candidate and are NOT an authentic parent-created fixture.
- `testContainerFailureNeverFallsBackAndDirtyContextIsNotDiscarded`: injected factory failure is not replaced with another container; dirty-context guard prevents mutation and leaves hasChanges true. It does not directly assert preservation of a separate already-committed transaction during another transaction's rollback.

The two failing methods prevent certification of failed-create atomicity/relationship integrity/retry and failed-edit/status/delete restoration. Their other assertions cannot be independently marked passing from a failed-case summary. In particular:

- Transaction/source counts and retry are asserted, but the failed test is not a complete passing proof and does not reopen disk between failure and retry.
- The edit buffer, status/timestamps and failed delete are asserted in the failed combined method; independent outcomes are not available.
- Success feedback is structurally after the write return, and the failure test checks control does not reach a success flag; actual haptics/error UI were not successfully exercised.
- Dedicated failure-point disk reopen, standalone status failure, unrelated committed-state preservation, and UI save-error behavior remain additional evidence needs, not claims satisfied by compilation.

Temporary store tests create a UUID directory containing `ledger.store`, use fresh ModelContainers at the same URL where specified, and remove the entire temporary directory after each test. Those artifacts were not exported or preserved as legacy fixtures.

### Clean-install and authentic existing-store evidence

**CLEAN-INSTALL VALIDATION — NOT VALIDATED.** The UI workflow failed; no completed workflow checkpoints were exposed. It uses a unique test-owned record but does not guarantee a fresh installation/store. The subsequent simulator launch failed. The passing URL-backed unit-test CRUD method cannot substitute for startup/main-context/UI/relaunch validation. This missing end-to-end durability evidence blocks conservative checkpoint acceptance independently of the known rollback failures.

**AUTHENTIC BASELINE STORE — NOT GENERATED.** This Linux x86_64 host has no xcodebuild, xcrun or Swift executable. The canonical baseline object is unavailable locally, and the available remote build/test interface did not provide an isolated baseline execution and store export/import channel. No baseline worktree/checkout was substituted into the active app, no candidate-created fixture was relabeled, and no SQLite/WAL/SHM/sidecar/external-storage artifacts were copied. Clean close, full artifact preservation, transfer and candidate reopen therefore did not occur.

**EXISTING-STORE COMPATIBILITY — NOT VALIDATED.** Legitimate parent-created data preservation under candidate startup/write handling remains unproven. Unchanged model source and same-build round-trip success are insufficient. Its absence also blocks conservative acceptance of this first durability checkpoint.

**MIGRATION VALIDATION — NOT APPLICABLE.** No persisted model, field, enum, relationship, or historical data migration occurred.

### Warning/failure delta and retained diff

- PRE-EXISTING: prior missing-xctestrun and Category test compilation issues; local Apple toolchain absence; legacy launch/screenshot test and its runner incompatibility. Prior AppIntents warnings are historical only; this continuation did not expose a compiler-warning inventory.
- RESOLVED: the previous compile/execution blockage no longer exists on the first full run, without any scheme or test-source change. This does not establish why the earlier remote harness failed.
- NEWLY EXPOSED, not introduced by continuation: two rollback defects and the UI invalid-frame failure in unchanged starting source.
- INTRODUCED: no retained code/test changes or demonstrated new build failure. The unverified experiment was removed; its launch failure is not attributed to a production source cause without diagnostics.
- REMAINING: rollback failures, UI runtime failure, screenshot activity limitation, unexplained simulator launch blocker, inaccessible detailed artifacts, missing clean-install and authentic existing-store evidence.

Temporary edits, all reverted: Data/LedgerWrite.swift; Views/ReviewTransactionView.swift; Views/TransactionDetailView.swift; Views/TransactionForm.swift; LumenFinanceTests/LedgerPersistenceTests.swift. No tests were weakened, removed or skipped. No shared scheme, project configuration, governance, model or asset changes were retained.

Retained continuation diff: **docs/PHASE_1A_AUDIT.md only**, appending this evidence. Exact GitHub-SHA comparison is unavailable; the verified local continuation base is `ba07db07c3ac1153539366ba8436b322cecf2df6`.

Validation commands:
```
git rev-parse HEAD
git status --short
git log -3 --format='%H %P %s'
git cat-file -t 45207849da53cd67eb3f33d2e7cd8f1d1d6bba91
git cat-file -t dbc28ed9649d4930b45e2dcc44a7462729dfcf11
git diff --exit-code ba07db07c3ac1153539366ba8436b322cecf2df6 -- ios-lumen-finance docs/architecture docs/ROADMAP.md docs/NON_GOALS.md
git diff --check HEAD
git diff --stat ba07db07c3ac1153539366ba8436b322cecf2df6
```
The protected-path comparison passed after restoration. The final simulator app build passed on that restored source. Neither validates the failed tests.

### Checkpoint acceptance and Phase 1A status

1. Domain tests: **PASS** — 9/9 in the full run.
2. Persistence tests: **FAIL** — 5/7; two material rollback failures.
3. Introduced build failures resolved: **PASS** — restored app builds; first full suite compiled/executed; no retained new code.
4. Production test failures resolved: **FAIL** — original failures remain.
5. Direct executable durability evidence: **FAIL** against acceptance — successful disk CRUD exists, but failure/rollback evidence demonstrates broken guarantees and additional cases remain unproven.
6. Validation-discovered defects resolved: **FAIL** — no correction has the required passing-test/suite chain.
7. Clean install: **NOT VALIDATED** — absence blocks acceptance because real startup/UI/relaunch durability is unproven.
8. Existing-store compatibility: **NOT VALIDATED** — absence blocks acceptance because authentic parent data has not been opened/preserved.

**PHASE 1A HARDENING CHECKPOINT NOT YET ACCEPTED**

Smallest decisive reason: failed create/edit rollback does not restore the in-memory canonical graph/values in executed tests. The candidate must not be presented as a validated hardening checkpoint.

**PHASE 1A NOT YET COMPLETE**

Continue only with a working test/runtime environment: minimally correct the demonstrated rollback/UI defects, rerun failing tests and the complete applicable suites, then obtain real clean-install/relaunch and authentic baseline-store evidence. Remaining Roadmap money/date edge semantics and schema-evolution strategy decisions from the original audit remain deferred; checkpoint validation does not authorize migrations. No Phase 1B or other later-phase work began.

## Run 3 — failed-write recovery correction — 2026-09-10

This section records a focused executable correction, superseding the preceding unresolved persistence-recovery disposition only. Earlier results remain historical evidence. This document is not governance.

### Starting state and authority

- Actual starting HEAD: `b48c4818ed7dad8a2fc907198c2e9c5064725bd0`; working tree clean.
- Owner-supplied canonical chain: baseline `dbc28ed9649d4930b45e2dcc44a7462729dfcf11` → hardening candidate `45207849da53cd67eb3f33d2e7cd8f1d1d6bba91` → evidence-only continuation `1917d358f9b89018c73386534a42f0c39cf859c7`. This GitHub relationship is accepted as supplied, not independently re-established here.
- Local HEAD is a child of the previously tested `ba07db07c3ac1153539366ba8436b322cecf2df6`. A direct app-tree comparison against that local checkpoint passed; the docs comparison showed only the prior +131-line audit continuation. Thus production matched the expected previously tested hardening implementation. Exact equivalence to the unavailable canonical GitHub tree is not claimed; no history reconciliation/reset was pursued.
- Read all four governing documents and this prior audit in full, plus the requested write/draft/UI/test implementations. Additional inspection was limited to model relationships, the schema factory, directly related write/test call sites and SwiftData/debugging reference material.
- NO TEST-CONTRACT CONTRADICTION FOUND. Contract §§4–5/21, Roadmap 1A.1/1A.6/1A.7 and ADR-001 lines 67–72/102–106 require separation of attempted input from successfully persisted canonical state. Both original failing assertions remain intact.

### Exact execution chronology

All invocations used `swiftTest` with `appPath: "ios-lumen-finance"`. Selectors below are under `LumenFinanceTests/LedgerPersistenceTests/` unless qualified otherwise. No tests ran in parallel.

1. **Unchanged production AND original tests**, selectors:
   - `testFailedCreateRollsBackSourceAndTagsThenCanRetry`
   - `testFailedEditStatusAndDeleteRestoreCommittedState`
   Result: **0 passed / 2 failed**. Same original failures: `XCTAssertTrue failed` for the held tag inverse and `88.5` versus `42.19` for held canonical amount. Both reproduced YES.
2. **Test-only state-layer diagnostics**, selectors:
   - `testFailedCreateHeldReferences`, `testFailedCreateSameContext`, `testFailedCreateFreshContext`, `testFailedCreateReopenedStore`
   - `testFailedEditHeldReference`, `testFailedEditSameContext`, `testFailedEditFreshContext`, `testFailedEditReopenedStore`
   Result: **6 passed / 2 failed**. Only the held-reference cases failed; same-context, fresh-context and reopened-store cases passed independently for both operations.
3. **Test-only identity/refresh diagnostics**, selectors `testFailedCreateHeldReferences` and `testFailedEditHeldReference` with added before/after-refetch observations in failure messages.
   Result: **0 passed / 2 failed**, retaining assertions on values captured BEFORE the diagnostic refetch. Returned evidence establishes that a subsequent fetch heals the SAME held instances; details below. This was additional diagnosis, not an unchanged retry or production strategy.
4. **Test-only independent cases**, selectors:
   - `testFailedCreateRetryHasExactlyOneDurableGraph`
   - `testFailedEditRetainsDraftAndRetryPersistsAfterReopen`
   - `testFailedStatusIndependentlyRestoresCommittedState`
   - `testFailedDeleteIndependentlyPreservesCommittedState`
   - `testFailedWritePreservesUnrelatedCommittedTransaction`
   Result: **2 passed / 3 failed**. Edit retry and independent delete passed. Create retry failed with Cocoa validation error 1560/1570, including a relationship-connected Transaction missing required amount/created fields. Status and unrelated-write tests failed on held B's attempted values. The failed unrelated case did not alone certify its other assertions.
5. **One production correction:** after rollback, synchronously fetch Transactions and Tags before rethrowing the failure. No other recovery strategy was implemented in Run 3.
6. **Directly affected tests:** all 15 selectors from steps 1, 2 and 4 in a single targeted invocation.
   Result: **15 passed / 0 failed**, 16 seconds. Both original method bodies/assertions remained unchanged.
7. **Complete persistence suite:** `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests/LedgerPersistenceTests"]})`.
   Result: **20 passed / 0 failed**, 14 seconds. All 20 source methods executed; no skips reported and no separate skip inventory supplied.
8. **Complete domain regression suite, after persistence passed:** `swiftTest({"appPath":"ios-lumen-finance","onlyTesting":["LumenFinanceTests/LumenFinanceTests"]})`.
   Result: **9 passed / 0 failed**, 13 seconds. All nine existing domain methods are unchanged.
9. **Final application build:** `runChecks({"appPath":"ios-lumen-finance"})`.
   Result: **PASS**, simulator build. Device/Release not verified. No UI suite, screenshot tests, clean-install workflow, baseline store generation, or compatibility/migration run was attempted.

### State-layer diagnosis before correction

**FAILED CREATE**

- A — Held Tags: one selected tag retained inverse count 1 instead of 0. In the same observation, context.hasChanges was false, fetched and counted Transactions were 0, TransactionSources were 0, and no Transaction→source graph was present.
- B — Same-context Tag refetch: all inverses correct/empty; no Transaction or source. Additional diagnostic explicitly found `heldContext=true`, `sameInstance=true`, and both held/fetched inverse counts 0 AFTER this fetch.
- C — Fresh ModelContext on the same container: empty financial/source graph and correct tag inverses.
- D — Fresh ModelContainer reopening the URL after the original autoreleasepool ends: no Transaction/source and correct durable tag inverses.
- Classification: stale held-reference relationship state immediately after rollback; same-context fetch refreshes those very objects. Not detached replacements, not demonstrated durable corruption. The ghost was not harmless: the separate retry test exposed a validation failure before correction.

**FAILED EDIT**

- A — Held Transaction: attempted amount 88.5, posted status, attempted posted date and updated timestamp, EUR currency, changed merchant/transaction date/notes/category/payment/tags remained visible instead of the committed values. Source and legacy metadata were included in the comparison.
- B — Same-context fetch by stable application id: committed amount 42.19, pending status, nil posted date, original updated timestamp and original relationships/fields. Additional identity evidence: `heldContext=true`, `heldContextNil=false`, `sameInstance=true`, `samePersistentID=true`; the original reference's amount changed to 42.19 after that fetch.
- C — Fresh ModelContext on the same container: committed state and expected relationship graph.
- D — Fresh ModelContainer after releasing the original local scope: committed state and graph.
- Classification: stale held-object values until refetch, not context detachment, not a separately persisted attempted edit. Fresh/reopened storage was correct BEFORE the correction.

The narrow application-level cause is that LedgerWrite returned from its failure path before synchronizing observable held models with the committed state already exposed by a fetch. Private SwiftData cache internals are not established by these observations.

### Recovery design and anti-thrashing

Selected hypothesis: retain rollback for discarding pending writes, then use the demonstrated same-context fetch behavior to refresh held Transactions and Tags before propagating failure to callers.

Implementation: two read-only fetches in LedgerWrite's catch path, plus two explanatory comment lines. Successful writes are unchanged. The clean-context guard, autosave policy, mutation/commit ordering, save-failure propagation, caller success gating and draft ownership remain unchanged. Recovery performs no compensating save and never rewrites persisted fields.

This intentionally reads both entity sets on the failure path rather than introducing snapshots, model reattachment, per-operation recovery registries, replacement contexts or a repository layer. Tradeoff: a failed write incurs a Transaction/Tag read; this is not a per-success cost and no large-ledger performance claim was tested.

Strategies attempted in Run 3: **one**. Result: all targeted, complete persistence and domain tests passed. Anti-thrashing stop rule **not triggered**. Prior-run processPendingChanges/snapshot experiments were not reinstated. No unvalidated production experiment needed reversion in Run 3.

### Acceptance evidence after correction

**Failed create:** held and same-context graphs clean before any test-side healing fetch; context.hasChanges false; no canonical Transaction or inappropriate source graph. Independent failure-point reopened-store test proves zero Transactions/sources and empty tag inverses. Original draft remains valid, its amount/source identity/filename survive, retry succeeds, and held plus reopened relationships contain exactly one Transaction and one source with exactly one selected-tag membership/inverse.

**Failed edit:** original held object, same-context refetch, fresh context and reopened store all match the complete pre-write field/relationship snapshot. Amount, status, posted_date and updated_at are explicitly compared. Original attempted TransactionDraft retains amount, status, posted date, notes and selected relationships; retry on the same canonical reference persists the intended edit, which survives full container reopen with single relationship membership.

**Failed status:** independent outcome passes; pending status, nil posted date, original updated timestamp, all other canonical fields and graph restored in held/fetched/reopened state.

**Failed delete:** independent outcome passes; B remains present with its fields, tag/category/payment/source relationships and shared source. It passed before correction too; no deletion redesign was introduced.

**Unrelated committed state:** A and B are both committed before an admitted write on B fails. A's held/fresh/reopened full state is unchanged; B returns to committed state, graph/source counts are preserved, and the context is clean. No unrelated unsaved mutation bypasses the existing guard. The existing dirty-context protection test also remains passing.

**Evidence boundaries:** these tests inject a commit closure that throws before a durable save; they are not physical disk-full/corrupt-store fault simulations. A secondary error while executing the recovery fetches is not independently injected; fetch errors propagate rather than being swallowed. No claim is made here that unreadable storage can always refresh held objects. Reopen tests use same-build stores, autoreleasepool scope release and a new container at the same URL; they are not app-process relaunches or authentic baseline compatibility fixtures. No detailed xcresult/runtime metadata was exposed; the advertised test-log path was again absent locally. Method outcomes and returned assertion diagnostics are the available execution artifacts.

### Final retained diff and disposition

- **PRODUCTION:** `ios-lumen-finance/LumenFinance/Data/LedgerWrite.swift` — +4 lines, failure-path Transaction/Tag refresh.
- **TESTS:** `ios-lumen-finance/LumenFinanceTests/LedgerPersistenceTests.swift` — +348 lines, 13 additional independent diagnostic/recovery methods and test helpers. All seven original methods and assertions preserved without removal or weakening.
- **EVIDENCE:** this appended Run 3 section only.
- Domain tests, UI/views (including FlowLayout), persisted models, schema factory, project/scheme, assets and governance are unchanged. No manual commit, push, staging, reset or history rewrite was performed.
- Final simulator app build and protected-path comparisons passed. UI INVALID-FRAME — **NOT VALIDATED** in Run 3; its earlier failure is not declared fixed. Screenshot infrastructure was not touched.

**FAILED-WRITE RECOVERY VALIDATED** for the demonstrated failure contract and executed cases: original failures reproduced → state-layer evidence → one minimal correction → 15/15 targeted → 20/20 complete persistence → 9/9 unchanged domain → simulator build PASS.

**PHASE 1A HARDENING CHECKPOINT NOT YET ACCEPTED.**

**PHASE 1A NOT YET COMPLETE.**

Next hardening-checkpoint evidence stage, not started:
1. Clean-install/relaunch validation.
2. Authentic pre-hardening existing-store compatibility.

Broader previously documented Phase 1A Roadmap concerns remain separate: money/input/currency-exponent and aggregate-overflow edge semantics; date/timezone semantics; schema-evolution strategy and compatibility-sensitive migration decisions; existing reference-template trust and remaining core-interaction evidence. No such work, migration or Phase 1B work began. Run 3 stops at the validated persistence objective.

## Run 4 — runtime checkpoint validation, blocked in Manual Entry — 2026-09-10

### Starting checkpoint and authority

- Canonical baseline supplied: `dbc28ed9649d4930b45e2dcc44a7462729dfcf11`.
- Owner-supplied canonical chain: baseline → `45207849da53cd67eb3f33d2e7cd8f1d1d6bba91` → `1917d358f9b89018c73386534a42f0c39cf859c7` → validated recovery `0845a5c09f7fc3e33d5096a4d363e784bed4f0ee`.
- Actual starting HEAD: `2988d5400a4734f1ac2b610632fd55957cba2f52`, parent `b48c4818ed7dad8a2fc907198c2e9c5064725bd0`.
- Starting tree was dirty only in two existing `.rork/history/main` assistant records. App, tests and documentation had no starting modifications. Those history changes were not edited or reverted by this run.
- Direct production comparison against the previous local Run 3 starting checkpoint showed exactly the validated four-line LedgerWrite correction. Tests also contained the expected +348-line persistence additions; the audit contained the +107-line Run 3 continuation. Production therefore matched the expected Run 3 implementation. Exact canonical GitHub tree equivalence is not claimed, and no history reconciliation/reset was attempted.
- Read Contract, Roadmap, NON_GOALS, ADR-001 and the prior audit in full using bounded reads. Read the requested UI test, form/manual/review/detail views, app startup, LedgerStore, LedgerWrite and Seed. Additional app inspection was limited to RootView and the shared theme/components used by the failing Manual Entry layout. No broad audit or closed failed-write recovery redesign occurred.
- No material governance disagreement. Run 3 persistence conclusions remain supported. The earlier attribution of the primary UI failure to a Lumen production defect remains provisional: this run establishes a separate FlowLayout return-value defect, but does not establish the primary UI failure's product-versus-framework/runner cause.

### Executed chronology

All calls used `appPath: "ios-lumen-finance"`; tests were invoked serially. No production modification preceded steps 1–5.

1. Complete persistence baseline: `swiftTest` selector `LumenFinanceTests/LedgerPersistenceTests` — **20 executed / 20 passed / 0 failed**, 24 seconds.
2. Complete domain baseline: selector `LumenFinanceTests/LumenFinanceTests` — **9 executed / 9 passed / 0 failed**, 9 seconds. Runtime work proceeded only after both were green. No skipped tests or separate skip inventory were reported.
3. Added test-only checkpoint recording to the original functional workflow, without changing its actions/assertions or production UI. Selector `LumenFinanceUITests/LumenFinanceUITests/testManualReviewSaveRelaunchInspectEditStatusAndDelete` — **0 passed / 1 failed**:
   `Invalid frame dimension (negative or non-finite). [last completed: 3 Manual Entry opened]`
4. Added finer test checkpoints around amount/merchant focus and entry, plus issue source-location/detail/symbol extraction. Ran the same functional selector on unchanged production — **0 passed / 1 failed**, same message and checkpoint. No source location, detailed description or symbolicated stack was returned. The last completed checkpoint immediately precedes `amount.tap()`; the subsequent amount-focused checkpoint was not reached.
5. Added an isolated SwiftUI-hosted diagnostic: selector `LumenFinanceTests/FlowLayoutTests/testFlowLayoutReturnsFiniteMeasuredSize` — **0 passed / 1 failed**:
   `XCTAssertTrue failed - FlowLayout.sizeThatFits proposal=unspecified returned (inf, 36.33333333333333)`.
   This supplies actual executable evidence of FlowLayout's non-finite return, not proof that it caused step 3's keyboard/focus-time UI failure.
6. One minimal production hypothesis in TransactionForm.swift: replace the returned unconstrained width with measured row content width, excluding trailing spacing; retain finite proposal width. Ran both selectors from steps 3 and 5 together — **1 passed / 1 failed**. The isolated FlowLayout test passed, but the primary UI test still failed with the identical invalid-frame message at checkpoint 3. Therefore this did NOT complete the required same-functional-test correction chain.
7. Reverted that entire production correction. Direct comparison confirmed **all production source byte-identical to starting HEAD**, including TransactionForm and LedgerWrite. No accepted UI correction is retained. No second production hypothesis was attempted.
8. Final restored-source complete persistence suite — **20 executed / 20 passed / 0 failed**, 16 seconds.
9. Final restored-source complete domain suite — **9 executed / 9 passed / 0 failed**, 10 seconds.
10. `runChecks({"appPath":"ios-lumen-finance"})` — **PASS**, simulator application build. Device/Release success remains unverified. Build success does not override the UI/layout failures.

The isolated layout diagnostic remains checked in as a known-failing regression on the restored implementation. It was not rerun unchanged after restoration; its pre-correction failure is the applicable evidence for the byte-identical restored production path. The temporary correction's diagnostic PASS must not be reported as a final-tree PASS. The final 20/20 and 9/9 counts are the named persistence/domain classes, not a claim that every test in the app test target passes.

### Runtime localization and diagnostic limits

**PRIMARY UI FAILURE — REPRODUCED.**

Observed: application launched; initial ledger/add control became available; Manual Entry opened and its amount field existed. Failure was recorded while tapping that amount field, before the amount-focused checkpoint, field entry, Review or any confirmed Transaction. All later CRUD/relaunch stages are NOT REACHED. No created test Transaction or completed terminate/relaunch cycle is claimed.

**UI ROOT CAUSE — NOT ESTABLISHED.**

The test-level issue override preserves and forwards the original XCTIssue, appending the last checkpoint and available issue details. It does not suppress failures, add screenshot attachments, use activities, disable diagnostics, or add production telemetry. Additional issue metadata yielded no returned source/stack localization. The hosted layout test independently proves FlowLayout's unspecified-width result is infinite, but correcting it left the real functional failure unchanged. Consequently FlowLayout is not established as the sole/sufficient cause of the primary failure. No speculative keyboard, sheet, navigation or theme correction was made.

Evidence access: the advertised `/tmp/rork-swift-test-ios-lumen-finance.log` was absent locally. `rork-agent logs runtime --errors --limit 100` returned no runtime logs. Current test responses did not expose an xcresult download, simulator UDID/runtime version, current Xcode version or numeric runner exit status. No screenshot-infrastructure investigation or launch/screenshot test execution occurred.

### Clean-store and application-lifecycle evidence

- **CLEAN-STORE PROVENANCE — NOT ESTABLISHED.** No fresh simulator data, uninstall/reinstall, isolated persistent location or test launch seam was used. Unique merchant naming is not freshness evidence.
- **Initial persisted Transaction count — UNKNOWN.** The existing application store was not counted or reset. No claim of zero initial financial history or zero automatically inserted samples is made from this UI run.
- App startup reached usable navigation and Manual Entry. Source inspection shows LedgerStore opens a durable configuration with no fallback, and startup requires Seed.bootstrapIfNeeded before displaying RootView. However genuine fresh-store initialization, initial reference counts, reference idempotence across app relaunch and zero automatic sample history remain **NOT VALIDATED at application level**.
- Application launch — **PASS**. Manual Entry route — reached, but complete Manual Entry interaction — **FAIL** at amount focus.
- Review; Confirm; created Transaction visible; relaunch #1; Inspect; status transition; relaunch #2; Edit; relaunch #3; edited value preserved; Delete; final relaunch; deleted test-owned record absent — **NOT REACHED** individually.
- Storage-level reopen evidence remains valid in the 20 passing persistence tests. It is not substituted for process/application relaunch.

### Authentic-store gate and migration classification

The required runtime prerequisites did not pass. Therefore the authentic-store capability probe was **NOT REACHED**, and no baseline fixture experiment or infrastructure build attempt was made.

Run 4 capability statuses: canonical baseline Apple execution — UNKNOWN; baseline SwiftData store generation — UNKNOWN; clean baseline close — UNKNOWN; complete artifact preservation — UNKNOWN; artifact transfer — UNKNOWN; candidate reopen of that exact store — UNKNOWN. These statuses describe the complete baseline-to-candidate experiment, not the already-demonstrated ability to execute candidate XCTest. No new claim that the full experiment is possible or impossible is established.

**AUTHENTIC BASELINE STORE — NOT GENERATED.** No baseline workspace, store, clean-close procedure, SQLite/WAL/SHM/sidecars/external artifacts, preservation, transfer or candidate reopen exists from Run 4. No candidate-created fixture is represented as legacy.

**EXISTING-STORE COMPATIBILITY — NOT VALIDATED.** The prior documented environment limitation remains unresolved; Run 4 stopped at the runtime gate rather than conducting a new compatibility capability verdict. The required final report's `NOT VALIDATED — ENVIRONMENT LIMITATION` classification carries forward that prior limitation, not an attempted baseline-open failure or a freshly proven absence of every primitive.

**MIGRATION VALIDATION — NOT APPLICABLE.** Persisted models/schema/semantics are unchanged. No migration work began.

### Classification and retained diff

- **PRODUCT DEFECT, EXECUTABLY ISOLATED:** FlowLayout returns infinite width for an unspecified proposal. The finite-size experiment fixed that isolated assertion but not the primary functional workflow; production correction was reverted under the work order's retention rule.
- **PRIMARY RUNTIME FAILURE, CAUSAL CLASSIFICATION UNRESOLVED:** invalid frame while focusing Manual Entry amount. No evidence justifies definitively blaming either Lumen or the runner/framework for this particular failure.
- **RUNNER / ENVIRONMENT LIMITATIONS:** detailed test-log path unavailable locally; no runtime logs/source stack returned. Historical screenshot activity limitations remain separate and were not revisited. Baseline-store artifact capabilities were not newly evaluated.
- **PRE-EXISTING NON-BLOCKING ISSUES:** broader money/date/schema-strategy/reference-template concerns remain deferred for this bounded run, not declared resolved or phase-complete.
- **RESOLVED DURING RUN 4:** diagnostic visibility now establishes the last completed UI checkpoint and next failing action. No product UI failure was resolved. Run 3 recovery remains green and unchanged.
- **PRODUCTION retained diff:** none; all production source restored to starting HEAD.
- **TESTS retained diff:** LumenFinanceUITests.swift +44 diagnostic lines; new FlowLayoutTests.swift +54 lines containing one known-failing isolated regression and its hosting probe. All original functional assertions/actions and both original regression classes remain unchanged. There is no new clean-store seam or reset mechanism.
- **EVIDENCE retained diff:** this appended Run 4 section only. Pre-existing history-file changes are outside the authored diff.
- Final `git diff --check HEAD` and protected-path comparisons passed before this evidence append; final documentation/static validation is performed again at completion. No manual Git commit, push, staging, checkout or history mutation was performed.

### Disposition and exact continuation point

- Domain behavior — PASS (9/9).
- Persistence behavior — PASS (20/20).
- Failed-write recovery — PASS, unchanged and covered by the complete persistence suite.
- Primary UI workflow — FAIL.
- Genuine clean-store initialization — NOT VALIDATED.
- Application relaunch durability — NOT VALIDATED.
- Authentic existing-store compatibility — NOT VALIDATED.

**RUNTIME VALIDATION NOT YET COMPLETE.** Smallest demonstrated runtime blocker: invalid-frame failure during the Manual Entry amount tap, after the field appears and before focus/entry completes. Localization of that failure is the next unfinished step; repeating the disproven finite-width-only correction is not justified.

**EXTERNAL EXISTING-STORE COMPATIBILITY EVIDENCE REQUIRED** remains an outstanding prior requirement, not a declaration that Run 4 reached runtime completion or proved every hosted compatibility capability unavailable.

**PHASE 1A HARDENING CHECKPOINT NOT YET ACCEPTED.** State 1: runtime validation incomplete.

**PHASE 1A NOT YET COMPLETE.** No later roadmap work began. Resume from the green lower-layer baseline and the localized failing UI action, not from a broad audit or a LedgerWrite redesign.

## Run 5 — independent FlowLayout fix and functional UI isolation — 2026-09-12

### Starting source, authority and scope

- Owner-supplied canonical chain: baseline `dbc28ed9649d4930b45e2dcc44a7462729dfcf11` → hardening `45207849da53cd67eb3f33d2e7cd8f1d1d6bba91` → Run 2 `1917d358f9b89018c73386534a42f0c39cf859c7` → Run 3 `0845a5c09f7fc3e33d5096a4d363e784bed4f0ee` → Run 4 `c33e1c58553ca3c7ff34bbcc09e7816d08fa8103`. Accepted as supplied; no identity reconciliation was attempted.
- Actual starting HEAD: `e02711218c76199f38f9de66b429e1dbfe704c82`, parent `2988d5400a4734f1ac2b610632fd55957cba2f52`. Starting modifications were confined to two pre-existing history records: `00mtv8wmmg000_i9a273jbmauf2597a2fim_assistant.json` and `00mtvjiovm000_dcn8imxva4azx74vrck00_assistant.json`. App, tests and docs were initially clean.
- Direct production diff against Run 4's local starting checkpoint `2988d5400a4734f1ac2b610632fd55957cba2f52` was empty. App/docs delta comprised exactly Run 4's audit +95, FlowLayoutTests +54, and UI-test diagnostics +44 lines. Expected Run 4 production, Run 3 LedgerWrite recovery, and Run 4 diagnostics/regression were present. Commit-message wording was not used as validation evidence; exact canonical GitHub tree equivalence is not independently claimed.
- Read all four governing documents and the full prior audit with bounded reads. No governance changes or broad audit. Read the requested form/manual/UI/FlowLayout tests; related inspection was limited to shared form focus/toolbar references, theme/card layout, RootView/Upload navigation ancestors, and AppState/Onboarding/app startup after executable evidence exposed onboarding at the first relaunch. No persisted models, LedgerWrite, schema, or default-data behavior changed.
- Run 5 admits two independent tracks. Defect A's retention no longer depends on Defect B passing. Fresh-store certification, lifecycle certification, authentic compatibility, migrations and later phases remain out of scope.

### Serial execution chronology

All XCTest calls used `swiftTest` with `appPath: "ios-lumen-finance"`. Abbreviations below are exact selectors: P=`LumenFinanceTests/LedgerPersistenceTests`; D=`LumenFinanceTests/LumenFinanceTests`; U=`LumenFinanceTests`; F=`LumenFinanceTests/FlowLayoutTests/testFlowLayoutReturnsFiniteMeasuredSize`; C=`LumenFinanceUITests/LumenFinanceUITests/testManualReviewSaveRelaunchInspectEditStatusAndDelete`. Probe methods are in `LumenFinanceUITests/LumenFinanceUITests`: `testProbeAmountSemanticTap`, `testProbeMerchantSemanticTap`, `testProbeNotesSemanticTap`, `testProbeNonTextControlTap`, `testProbeAmountCoordinateTap`.

1. Unchanged production: P — **20 executed / 20 passed / 0 failed**, 26 seconds.
2. Unchanged production: D — **9 executed / 9 passed / 0 failed**, 12 seconds. UI correction began only after both baselines passed.
3. Unchanged production: U — **30 executed / 29 passed / 1 failed**. Sole failed case F: `XCTAssertTrue failed - FlowLayout.sizeThatFits proposal=unspecified returned (inf, 36.33333333333333)`. The complete non-UI target is reliably executable in this run.
4. Explicit requested isolated reproduction before editing: F — **1 executed / 0 passed / 1 failed**, same assertion/result.
5. Minimal finite-width FlowLayout correction: F — **1/1 PASS**, 8 seconds.
6. Same corrected production: P — **20/20 PASS**, 18 seconds.
7. Same corrected production: D — **9/9 PASS**, 11 seconds.
8. Same corrected production: U — **30/30 PASS**, 16 seconds.
9. `runChecks({"appPath":"ios-lumen-finance"})` — **PASS**, simulator application build. Defect A's independent acceptance chain is complete; correction retained.
10. Added test-only pre-tap geometry capture, preserving canonical taps/actions/assertions. C — **0 passed / 1 failed**, invalid frame at `3 Manual Entry opened`, diagnostic stage `amount semantic tap requested`. Geometry returned below.
11. Five independently reportable interaction probes on FlowLayout-only production — **4 passed / 1 failed**. Only Notes failed: same invalid-frame issue, last checkpoint `notes pre-tap keyboard=false`, stage `notes semantic tap requested`. Amount semantic/coordinate, Merchant and non-text Income probes passed. Successful text probes assert keyboard appearance and exact local draft text; no probe saves a Transaction.
12. One Defect B production hypothesis: move the existing Done action from a keyboard ToolbarItemGroup to a navigation trailing ToolbarItem, visible only when focusedField is non-nil; preserve all focused modifiers/state and surrounding layout. C + Notes probe — **0 passed / 2 failed**. C no longer failed at amount focus: fields, Review, Confirm and first terminate/relaunch completed; it failed to find Activity because the returned UI contained Get Started. Notes completed tap/keyboard presentation and typed `Focus probe`, then its placeholder-based value query failed after the placeholder disappeared; the response also noted SwiftUI vertical TextField/TextView automation-type mismatch.
13. Improved test-only localization: retain all canonical actions, add a strict 10-second Activity existence assertion before the existing tap (never re-complete onboarding); query Notes' entered value independently of its vanished placeholder. Same toolbar experiment, C + Notes — **1 passed / 1 failed**. Notes PASS. C still failed: `XCTAssertTrue failed - Activity must become available after launch without repeating onboarding [last completed: 9 first relaunch completed] [diagnostic stage: inspect: waiting for Activity; Get Started exists=true]`, source `LumenFinanceUITests.swift:69` at execution. No onboarding or persistence production correction was attempted.
14. Reverted the entire Defect B toolbar experiment; retained only Defect A. C + all five corrected probes — **5 passed / 1 failed**. Sole failure C: original invalid-frame error at `3 Manual Entry opened`, stage `amount semantic tap requested`, same finite pre-tap geometry. All five standalone probes, including Notes, passed in this final invocation.
15. Final retained production: F — **1/1 PASS**, 10 seconds.
16. Final retained production: P — **20/20 PASS**, 9 seconds.
17. Final retained production: D — **9/9 PASS**, 12 seconds.
18. Final retained production: U — **30/30 PASS**, 15 seconds.
19. Final `runChecks` — **PASS**, simulator application build. Device/App Store Release validation is not established.

Counts are per invocation, not summed retries. No skips or separate skip inventory were returned. The complete unit target does not include the UI target. Launch/screenshot tests were not executed. Tests were not run in parallel. No execution-credit interruption occurred.

### Defect A — independent validated correction

**FLOWLAYOUT DEFECT — VALIDATED FIX.**

Production path: `ios-lumen-finance/LumenFinance/Views/TransactionForm.swift`, FlowLayout.sizeThatFits. Replaced the one-line return with:

```swift
let measuredWidth = max(0, (rows.max() ?? 0) - spacing)
let width = maxWidth.isFinite ? max(0, maxWidth) : measuredWidth
return CGSize(width: width, height: totalHeight)
```

Valid finite proposals retain their width; unspecified/infinite proposals report measured row content without trailing spacing, rather than infinity. Row construction, heights, placement and tag UI are unchanged. The unchanged hosted regression checks unspecified, infinite, zero and finite proposals, including finite/nonnegative output and measured unconstrained content width. It failed before and passed after; P, D, U and build also passed. This fix is independently retainable despite C remaining red.

### Pre-tap geometry and differential interaction evidence

Captured through XCUI test APIs, not production telemetry. All reported rectangles below existed, were hittable, finite, positive-sized, non-null and non-empty:

| Element | x | y | width | height |
|---|---:|---:|---:|---:|
| Amount | 64.33333333333333 | 240.0 | 297.66666666666663 | 41.0 |
| Merchant | 40.0 | 383.0 | 322.0 | 22.0 |
| Income control | 122.66666666666667 | 190.33333333333334 | 74.33333333333333 | 33.66666666666666 |
| Notes, after scrolling, initial failed probe | 40.0 | 536.3333333333333 | 322.0 | 35.66666666666663 |

Amount/Merchant/Income values were returned in both pre-experiment and final canonical failures. Notes geometry is from its initial failed probe, not an independently returned final-pass snapshot. The runner returns failed-case diagnostics, not each passing probe's console transcript.

| Probe | FlowLayout-only initial | Toolbar experiment | Final, toolbar restored |
|---|---|---|---|
| Amount semantic | PASS | Reached/passed in C before later failure | PASS standalone; C FAIL during tap |
| Merchant semantic | PASS | Reached/passed in C before later failure | PASS |
| Notes semantic | FAIL during tap | Tap/keyboard reached; query error, then corrected probe PASS | PASS |
| Income non-text semantic | PASS | Not separately rerun | PASS |
| Amount coordinate | PASS | Not separately rerun | PASS |

Coordinate tapping is diagnostic only; C always retains amount.tap(). Income PASS proves the interaction returned, the amount field remained present and no keyboard appeared; it is not a claim that selected-color rendering was separately verified. Notes' initial failure and final restored-toolbar PASS show that its behavior is not a deterministic toolbar-on failure in every invocation. No universal semantic-versus-coordinate defect, amount-specific defect, or failure of all TextFields is established.

### Defect B — hypothesis, outcome and limits

**PRIMARY UI ROOT CAUSE — NOT YET ESTABLISHED.** Narrowest useful localization: the canonical sequence's shared text-focus/presentation path, with keyboard-toolbar presentation strongly implicated by the production experiment. Pre-focus XCUI geometry is valid; discovery and pre-tap queries succeed. The available evidence does not distinguish the precise instant of responder change, keyboard presentation, accessory measurement or keyboard-safe-area recomputation.

Supporting research, not substitute execution evidence: [keyboard-toolbar exact-warning reproduction without any Spacer](https://stackoverflow.com/questions/79325386/swiftui-warning-with-toolbar-item-placement-keyboard) and [matching Spacer/Done toolbar plus the exact warning and zero-width toolbar constraints](https://stackoverflow.com/questions/79728378/swiftui-toolbarplacement-keyboard-not-showing-buttons-on-first-appearance). These are community reports on other environments, not Apple confirmation or proof of this runner's internals. They motivated testing toolbar placement rather than clamping unrelated frames.

One production hypothesis was attempted. With keyboard accessory placement removed but Done/focus handling preserved, C advanced beyond the original boundary twice; restoring the toolbar brought back the original C failure. This materially improves localization, but does not prove the bare Spacer alone caused the issue, eliminate invocation-order/state effects, or yield a passing canonical workflow. No second materially different hypothesis was attempted; the two-failed-hypothesis anti-thrashing threshold was not triggered. Work stopped rather than broadening into onboarding/lifecycle fixes.

The experimental first-relaunch failure persisted after a 10-second Activity wait; Get Started was observed. Source inspection found the existing onboarding setter/read in AppState and Get Started mutation intact. Why onboarding reappeared is unresolved; no conclusion about transaction durability or runner-only fault follows. The two experimental C executions passed Confirm and could have left their uniquely named test-owned Transactions. They never completed inspect/delete; exact names/IDs were not returned, and no arbitrary ledger cleanup/reset was attempted.

**No validated Defect B production correction retained.** The navigation-Done experiment was reverted because C never passed, despite demonstrated progress through focus. Final C is **FAIL**, furthest final-source checkpoint `3 Manual Entry opened`. Furthest experimental checkpoint was `9 first relaunch completed`; it must not be represented as a final-tree or full lifecycle PASS.

Evidence-access limits: `rork-agent logs runtime --errors --limit 100` returned no runtime logs; `/tmp/rork-swift-test-ios-lumen-finance.log` was absent locally. Current runner responses exposed no downloadable xcresult, exact runtime/Xcode version, destination UDID or numeric exit status. The added issue override still forwards every original issue; it neither suppresses invalid frames nor changes failures to skips. No production logs, test reset seam or screenshot-infrastructure changes were introduced.

### Final retained diff and validation boundary

- **PRODUCTION — DEFECT A:** TransactionForm.swift **+3/-1 lines**, only the finite-size return above; independently validated.
- **PRODUCTION — DEFECT B:** none. Keyboard toolbar restored byte-for-byte to starting implementation.
- **TESTS:** LumenFinanceUITests.swift **+125/-0 lines**: pre-tap geometry/interaction-stage reporting, five isolated unsaved-draft probes, Notes' placeholder-independent value verification, and the additional strict Activity readiness assertion. Original canonical actions and assertions remain; no semantic tap replacement, direct Transaction insertion, skipped Review/Confirm or loosened persistence check. FlowLayout, persistence and domain test sources are unchanged.
- **EVIDENCE:** this appended Run 5 section. Pre-existing history records remain outside the authored diff.
- Production outside TransactionForm, all model/data sources including LedgerWrite, project/scheme, governance and existing non-UI test sources match starting HEAD. Final production diff contains only the FlowLayout correction. Whitespace/protected-path comparisons passed before the evidence append; final static checks are repeated at completion. No manual staging, commit, push, checkout or history rewrite.
- Final matrix: P **20/20**, D **9/9**, F **1/1**, complete non-UI U **30/30**, standalone UI probes **5/5**, canonical UI **0/1**, simulator build **PASS**. These are not an all-UI-target PASS.

### Run 5 disposition and exact next step

**FLOWLAYOUT DEFECT — VALIDATED FIX.**

**PRIMARY UI AMOUNT-FOCUS DEFECT — NOT YET RESOLVED.** Localization improved; full-workflow retention criterion unmet.

**RUNTIME VALIDATION NOT YET COMPLETE.** The UI runtime gate is not cleared.

**PHASE 1A HARDENING CHECKPOINT NOT YET ACCEPTED.** Genuine clean-store initialization, lifecycle certification and authentic pre-hardening compatibility remain unvalidated and intentionally unattempted here. No compatibility capability probe was performed. Migration validation is NOT APPLICABLE; no schema or persisted semantics changed.

**PHASE 1A NOT YET COMPLETE.** No money/status/date migration, cloud work, evidence redesign or Phase 1B work began.

Smallest next diagnostic blocker: obtain a sequence-controlled explanation of the keyboard-toolbar focus transition in which C's amount semantic tap fails while the standalone amount probe succeeds. Keep Defect A and closed Run 3 recovery intact. The experimental first-relaunch onboarding result remains recorded, not silently fixed or certified in this pass.

## Run 6.1 — frozen-production B1/B2 characterization — 2026-09-12

### Starting state and Run 6 interpretation

- Owner-supplied expected GitHub checkpoint: `58f9b5aa13edc03dad758ddeeb98a9f00954d053`. Internal starting HEAD: `e9365f22f2113259592fb582b2fa1eeaaa6b7bba`; working tree initially clean, with no pre-existing modifications.
- Read-only `git ls-remote origin HEAD refs/heads/main` returned `e9365f22f2113259592fb582b2fa1eeaaa6b7bba` for both. This establishes the configured origin's advertised refs, not independent identification of canonical GitHub. Locally cached origin refs initially still pointed at `ea333ab48fa0e08e3a3182acf453e534bcb47bcd`.
- The supplied checkpoint object exists locally. App/tests/docs match it except for the absent generated `LumenFinance/Config.swift` placeholder in the internal snapshot. No complete-tree/SHA equivalence is claimed. Relevant Run 3 recovery, Run 5 FlowLayout correction, retained keyboard toolbar, original canonical test and Run 6 B1-A prefix were present.
- **B1-A EXTRACTION FIDELITY — VALID.** Side-by-side source inspection confirms the literal canonical sequence through Review, without Done, Confirm or relaunch.
- **B1-A BEFORE-FIX REPRODUCTION GATE — NOT SATISFIED IN RUN 6.** The prior unchanged-production PASS did not make the extraction structurally invalid; it made B1-A unsuitable as a guaranteed-red regression at that time.
- Production was frozen throughout Run 6.1. No toolbar, FocusState, AppState, onboarding, LedgerWrite, persisted model/schema/migration, money, duplicate-semantic or architecture change was attempted.

### Baseline and execution surface

All XCTest invocations were individual, sequential `swiftTest` calls with `appPath: "ios-lumen-finance"`. No source edits preceded this baseline:

| Check | Exact selector | Result |
|---|---|---|
| FlowLayout | `LumenFinanceTests/FlowLayoutTests/testFlowLayoutReturnsFiniteMeasuredSize` | 1/1 PASS, 15s |
| Persistence | `LumenFinanceTests/LedgerPersistenceTests` | 20/20 PASS, 12s |
| Domain | `LumenFinanceTests/LumenFinanceTests` | 9/9 PASS, 14s |
| Whole non-UI | `LumenFinanceTests` | 30/30 PASS, 14s |
| Simulator application build | `runChecks({"appPath":"ios-lumen-finance"})` | PASS |

Repository scheme: `LumenFinance`, Debug TestAction, both test targets nonparallelizable. Actual runner command, effective scheme/destination, runtime/Xcode version, device/UDID, container identity and numeric test exit status were not exposed. These repository settings are not independently observed runner metadata. Device/App Store Release validation was not performed.

### Retained passive UI-test instrumentation

- Reuse each strict method's existing Get Started wait result to log the onboarding branch; no duplicate wait. Reuse the existing Add Activity wait result for main-shell telemetry.
- Keep generated merchant identifiers in test-local memory for issue annotation. Add test name and previously observed state to the existing issue record, still forwarding every issue to `super.record`.
- Reuse the unchanged geometry capture and action checkpoints. Store/print a post-test summary and XCTest attachment, without new UI queries.
- No new strict pre-Amount waits, geometry/keyboard queries, focus interactions, navigation, Done taps, sleeps, launch arguments, environment markers or resets. Global `continueAfterFailure = false` remains intact.
- Keyboard before/after Amount: **UNAVAILABLE IN STRICT SEQUENCE**. Explicit initial launch from terminated state: **UNAVAILABLE**; the strict methods do not explicitly terminate first, and runner behavior was not exposed.
- Existing standalone probes were neither changed nor executed. Their pre-existing keyboard queries were not inserted into either strict method.

### Fixed strict B1 matrix

A = `LumenFinanceUITests/LumenFinanceUITests/testB1ACanonicalPrefixReachesReview`.
C = `LumenFinanceUITests/LumenFinanceUITests/testManualReviewSaveRelaunchInspectEditStatusAndDelete`.

| Invocation | Selector | Result | Get Started initially / onboarding completed / main shell | Test-owned merchant |
|---|---|---|---|---|
| 1: B1-A strict #1 | A | 0 passed / 1 failed | YES / YES / YES | Ledger test 99A6985C |
| 2: B1-A strict #2 | A | 0 passed / 1 failed | YES / YES / YES | Ledger test 01632BE7 |
| 3: canonical strict, once only | C | 0 passed / 1 failed | YES / YES / YES | Ledger test D6F399CA |
| 4: B1-A strict #3, post-canonical | A | 0 passed / 1 failed | YES / YES / YES | Ledger test CD079732 |

Every strict response surfaced `Invalid frame dimension (negative or non-finite).`, last completed `3 Manual Entry opened`, diagnostic stage `amount semantic tap requested`. Amount existed, was hittable, finite and positive; semantic tap was requested but the amount-focused checkpoint was not reached. Amount typing, Merchant tap/typing and Review were not reached. This describes strict execution termination, not proof the physical UI was incapable of continuing.

All four returned the same Amount rectangle: x=64.33333333333333, y=240.0, width=297.66666666666663, height=41.0; null=false, empty=false. Merchant and Income geometry were likewise finite, positive and hittable in all four. No duplicate geometry queries were introduced.

State continuity consistent with persistence: **INDETERMINATE** for all four. The first has no preceding Run 6.1 UI observation; each subsequent invocation again showed Get Started despite the preceding onboarding action. No visible carried-forward onboarded state was demonstrated, but container reuse versus reset versus persistence failure cannot be distinguished from these observations.

Observed: B1-A failed in all three strict executions, and C failed at the same boundary. No within-matrix pass/fail instability or method/context split was observed. All failures co-occurred with onboarding completion; without an already-onboarded comparison this is not a discriminating onboarding-state correlation and does not establish causation. Run 6's earlier PASS remains valid evidence. Runtime/state sensitivity and possible timing perturbation from even passive logging remain hypotheses, not established causes. Toolbar involvement remains supported by prior evidence, not proven deterministic by this frozen-production matrix.

### Canonical transaction accounting

Canonical merchant: `Ledger test D6F399CA`. Review/Confirm were not reached; no Transaction was created by this invocation. Normal delete cleanup and final absence assertion were NOT REACHED. No new canonical-test residue is indicated; old possible Run 5 residue was not inspected or cleaned. B1-A #3 ran against the resulting post-canonical state with no normalization or special cleanup.

### Single optional issue-continuation diagnostic

- Authorized by all three strict B1-A reproductions. The actual B1-A selector was invoked once more, separately as a diagnostic, after the fixed strict matrix; the canonical method was not rerun.
- Temporarily enabled `continueAfterFailure` locally inside B1-A with deferred restoration, keeping all existing UI actions through Review and every original issue forwarded. A temporary post-Review zero-issue-count assertion was intended only to expose final progress in the failure summary, not to make this an acceptance test.
- Result: 0 passed / 1 failed, same invalid-frame issue and last reported checkpoint/stage as the strict cases; merchant `Ledger test 0E2FE2C4`, onboarding YES/YES, main shell YES, same valid geometry.
- No later progress or post-Review count assertion was exposed by the response. Actual continuation, tap return, usable focus/keyboard, typing, Merchant interaction and Review completion are **UNAVAILABLE / NOT DEMONSTRATED** in the returned evidence. Do not conclude the physical interaction was impossible merely from the summary, or claim issue/function separability.
- All temporary continuation and terminal-count assertion changes were removed before B2. Strict issue handling was restored byte-for-byte to the pre-diagnostic instrumented source. No strict FAIL was converted to PASS.
- The supplied full-test-log path `/tmp/rork-swift-test-ios-lumen-finance.log` was checked once after strict invocation 1 and was absent locally. No repeated access attempts, xcresult/internal-stack chasing or external research occurred. Post-test attachments/full console output were not exposed to the agent.

### Independent B2 diagnostic

Selector: `LumenFinanceUITests/LumenFinanceUITests/testB2IsolatedOnboardingRelaunch`, invoked once after temporary continuation removal. No fresh-container facility was used or assumed; the actual encountered state was tested. No production reset seam was added.

- Initial Get Started: **YES**. **B2 EVIDENCE LEVEL — FULL**.
- Existing Get Started action returned; main shell/Activity before termination: **YES**.
- Explicit `terminate()` returned: **YES**. Relaunch returned: **YES**.
- Activity after relaunch, following a 10-second wait: **NO**. Get Started after relaunch: **YES**.
- Result: **0 passed / 1 failed**. Exact assertion: `XCTAssertTrue failed - B2 Activity must survive termination/relaunch without repeating onboarding`; last checkpoint `B2 relaunch returned`, source line 230 in the executed UI test.
- Both after-relaunch observations were captured before the strict assertion aborted. The subsequent Get Started absence assertion was not reached; presence is nevertheless independently recorded by the existing B2 observation.
- Financial Transaction mutation: **NO**. Intentional canonical-ledger mutation: **NO**. No Manual Entry, keyboard, Review/Confirm, status/edit/delete or LedgerWrite interaction. Normal production startup/reference initialization remained untouched.
- **B2 — ONBOARDING/RELAUNCH FAILURE REPRODUCED IN ISOLATION.** This separates its reproduction from transaction creation and keyboard behavior. It does not identify an AppState/UserDefaults/framework/runner cause or certify broader lifecycle behavior.

### Final retained state and disposition

- Final simulator application `runChecks`: **PASS** after removal of the temporary diagnostic changes. Lower suites were not repeated: production, project configuration and non-UI infrastructure remained frozen.
- Retained UI-test diff: `LumenFinanceUITests.swift` +85/-4, consisting of passive telemetry and the isolated B2 test. Existing B1-A remains; original strict actions/assertions and canonical continuation remain unchanged. The four replaced lines are the two onboarding branches and two Add Activity wait assertions, now reusing their results for logging.
- Evidence diff: this appended audit section only. Production diff: **zero**. All other docs, governance, non-UI tests, project/scheme and configuration remain unchanged. Protected-path comparison and whitespace checks passed before this append and are repeated at finalization. No manual Git staging, commit, push or history rewrite.
- **FIRECRAWL — NOT USED IN RUN 6.1. EXTERNAL RESEARCH — NOT USED IN RUN 6.1.** No new external question was pursued.
- **B1 — REPRODUCED CONSISTENTLY IN RUN 6.1.** No production correction authorized or attempted; no validated B1 fix claimed. Consistency is bounded to this four-invocation strict matrix, not universal reproducibility.
- **B2 — ONBOARDING/RELAUNCH FAILURE REPRODUCED IN ISOLATION.** Unresolved; no production correction attempted.
- **RUNTIME VALIDATION NOT YET COMPLETE.**
- **PHASE 1A HARDENING CHECKPOINT NOT YET ACCEPTED.**
- **PHASE 1A NOT YET COMPLETE.** No clean-store, full-lifecycle, compatibility, migration or Phase 1B certification/work began.
