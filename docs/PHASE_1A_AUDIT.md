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
