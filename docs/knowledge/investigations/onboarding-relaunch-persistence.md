---
id: investigation.onboarding-relaunch-persistence
title: Onboarding and preferences across hosted UI-test relaunch
kind: investigation
status: unresolved
confidence:
  reproduction: high
  root_cause: low
  broader_defaults_lifecycle_hypothesis: medium
  physical_product_persistence: high
created: 2026-09-13
reviewed: 2026-09-15
last_verified: 2026-09-15
platforms:
  - ios
frameworks:
  - Foundation
  - SwiftUI
  - XCTest
apis:
  - UserDefaults
  - XCUIApplication.terminate
  - XCUIApplication.launch
related:
  - investigation.swiftui.keyboard-toolbar-invalid-frame
  - platform.apple.foundation.userdefaults
  - testing.ios-runtime-validation
evidence:
  - phase1a.run6_1
  - phase1a.run6_2
  - phase1a.physical_device_2026_09_14
  - phase1a.existing_store_compatibility_2026_09_15
revisit_when:
  - hosted app-container/defaults continuity becomes directly observable
  - the original hosted environment exposes enough metadata to isolate domain/container behavior
  - new product evidence contradicts the current physical-device persistence result
---

# Onboarding and Preferences Across Hosted UI-Test Relaunch

## Summary

In Rork's hosted UI-test environment, Lumen repeatedly lost changed `UserDefaults.standard`-backed preference state across the tested `XCUIApplication.terminate()` to `launch()` boundary. Run 6.2 broadened the observation from onboarding alone to a second independent preference: both `lumen_has_onboarded` and a test-owned currency change failed to survive relaunch, while a same-process compiled `AppState`/`UserDefaults` probe passed.

The product-scope question is now answered separately. On 2026-09-14, ordinary physical-iPhone force-close/reopen of the same installed Lumen application preserved onboarding completion, the changed reporting/default currency preference, SwiftData financial state, and transaction/status state. The application was not reinstalled, re-signed, or moved to a different bundle identity between the before/after checks.

A separate GitHub Actions historical-store compatibility workflow on 2026-09-15 also demonstrated SwiftData continuity through its own simulator/XCTest validation path. That evidence strengthens confidence in hardened ledger persistence, but it does **not** explain or retroactively resolve the earlier Rork-hosted `UserDefaults` behavior.

**Current product disposition:** the hosted preferences lifecycle mechanism remains unresolved, but current evidence does not support a production persistence defect or a Phase 1A blocker. No production persistence correction is warranted.

## Scope / Environment

### Observed

- Rork-hosted iOS/XCTest execution.
- UI-app lifecycle driven by `XCUIApplication.terminate()` and `launch()`.
- Production `AppState` using `UserDefaults.standard`.
- `lumen_has_onboarded` and `lumen_currency` as independent preference keys.
- A same-process unit-test probe of the compiled `AppState` read/write path.
- One strict immediate relaunch characterization, one 2-second-settle probe, and one independent currency-control probe.
- Physical-iPhone product validation on 2026-09-14 using the same installed application across ordinary force-close/reopen.
- Physical validation preserved onboarding completion, changed reporting/default currency preference, SwiftData transactions, transaction source state, and a Pending → Posted state change.
- GitHub Actions run `34933858277` on 2026-09-15 validated historical SwiftData store continuity through a separately characterized XCTest harness and candidate terminate/relaunch flow.

### Not yet established

- Effective Rork-hosted preferences domain identity across the original failing relaunch boundary.
- Effective Rork-hosted application-container continuity across the original failing B2 relaunch boundary.
- Exact hosted Xcode/iOS runtime behavior responsible for the original preference observation.
- Whether SwiftData would survive the **same original Rork-hosted B2 runner boundary** while `UserDefaults` values reset; the later GitHub Actions compatibility workflow used a different, explicitly characterized environment.
- Whether TestFlight-installed behavior differs materially from the successful sideloaded physical-device result.

## Current Understanding

**Observation:** production reads and writes onboarding with the same key, `lumen_has_onboarded`, through `UserDefaults.standard`.

**Observation:** source audit found one production onboarding writer, no second writer, no reset/remove path, no startup overwrite/default registration, and no source-configured test launch behavior that explains the reset.

**Observation:** the compiled same-process AppState probe passed: absent key to false AppState; set `hasOnboarded = true` to immediate same-process defaults read true; second AppState to true; original test-process preference restored.

**Observation:** B2-A immediate terminate/relaunch failed with FULL evidence: Activity was available before termination; after relaunch Activity was absent and Get Started was present.

**Observation:** B2-B repeated the sequence with a fixed 2.0-second pre-termination settle period and failed the same way.

**Inference:** a simple short write-flush latency explanation became less compelling after B2-B, but was not eliminated.

**Observation:** the independent currency control visibly changed USD to EUR before termination, then after relaunch observed Get Started again and currency USD. The changed EUR value did not survive the tested boundary.

**Inference:** the currency result weakens an onboarding-key-specific explanation because a second `UserDefaults.standard`-backed preference exhibited the same hosted relaunch loss.

**Observation:** on the physical iPhone on 2026-09-14, the same installed application was force-closed/swiped away and reopened without reinstalling, re-signing, or changing bundle identity. Onboarding did not reappear, EUR remained the reporting/default currency preference, SwiftData transactions remained present, source/provenance state remained present, and a Pending → Posted state transition remained durable.

**Inference:** the physical result strongly weakens the proposition that the original hosted B2 observation represents ordinary installed-product persistence behavior.

**Observation:** Phase 1A existing-store compatibility run `34933858277` independently characterized its exact XCTest path, demonstrated app-data sentinel continuity, installed the hardened candidate over an authentic historical producer store without changing the prelaunch store bytes, opened the inherited ledger, performed a current Pending → Posted mutation, terminated/relaunched, and read the mutation back successfully.

**Inference:** the compatibility workflow establishes robust SwiftData continuity in that GitHub Actions/XCTest environment. It does not establish why the earlier Rork-hosted `UserDefaults` values reset.

**Current interpretation:** broader defaults-domain / hosted-lifecycle behavior remains more plausible than an onboarding-specific production defect. The exact original hosted mechanism remains unknown.

**Current interpretation:** product-scope persistence is validated strongly enough that B2 is non-blocking for Phase 1A. The unresolved question is now primarily a hosted-runtime knowledge question rather than a production-correction question.

## Evidence Index

| Evidence ID | Role | Repository evidence | Establishes | Does not establish |
|---|---|---|---|---|
| `phase1a.run6_1` | runtime characterization | `docs/PHASE_1A_AUDIT.md` → `Run 6.1 — frozen-production B1/B2 characterization`; `LumenFinanceUITests.testB2IsolatedOnboardingRelaunch` | Isolated hosted terminate/relaunch reproduced onboarding reappearance independently of Manual Entry, keyboard, transaction creation, or ledger mutation | AppState/UserDefaults/framework/runner cause; broader preference scope; physical-device behavior |
| `phase1a.run6_2` | runtime diagnosis | `docs/PHASE_1A_AUDIT.md` → `Run 6.2 — B2 preferences/relaunch diagnosis`; `AppStatePersistenceTests.testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference`; B2-A/B2-B/currency selectors in `LumenFinanceUITests.swift` | Same-process AppState/defaults probe passed; immediate and 2-second-settled hosted relaunch lost onboarding; independent changed currency also failed to persist; no concrete production cause found | Cause of reset; whole-container reset; original Rork-hosted SwiftData behavior; ordinary installed-device behavior; a Rork defect |
| `phase1a.physical_device_2026_09_14` | manual product lifecycle validation | `docs/PHASE_1A_CLOSURE.md` → B1/B2 disposition and clean-install/product validation; physical unsigned-device build lineage | Same installed physical-iPhone app preserved onboarding, changed default/reporting currency, SwiftData financial history, source state, and status mutation across ordinary force-close/reopen | Exact Rork-hosted reset mechanism; TestFlight behavior; proof that all future OS/runtime combinations behave identically |
| `phase1a.existing_store_compatibility_2026_09_15` | acceptance / compatibility validation | `.github/workflows/phase1a-existing-store-compatibility.yml`; `scripts/phase1a-existing-store-compatibility.sh`; `LumenExistingStoreCompatibilityUITests.swift`; GitHub run `34933858277`; `docs/PHASE_1A_CLOSURE.md` | Characterized XCTest path preserved app data; authentic historical SwiftData store survived candidate installation; candidate read inherited graph, mutated Pending → Posted, and preserved mutation across relaunch | Cause of original Rork-hosted UserDefaults resets; equivalence of GitHub Actions runner to the earlier Rork runner |

Revision context:

- The historical Rork-hosted B2 evidence remains preserved in `docs/PHASE_1A_AUDIT.md` and the retained characterization/probe tests.
- Physical product validation was performed against the canonical production lineage before the compatibility-infrastructure-only commit.
- Phase 1A product behavior was ultimately accepted through validated candidate `8ce3fad0c449c433ca3c2fc7490a1a948c4f504a`; see `docs/PHASE_1A_CLOSURE.md`.

## Lumen Executable Evidence

The retained diagnostic surface includes:

- `LumenFinanceTests/AppStatePersistenceTests.swift` → `testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference` — primary role: **probe**.
- `LumenFinanceUITests/LumenFinanceUITests.swift` → `testB2IsolatedOnboardingRelaunch` — primary role: **characterization**.
- `LumenFinanceUITests/LumenFinanceUITests.swift` → `testB2SettledOnboardingRelaunchDiagnostic` — primary role: **probe**.
- `LumenFinanceUITests/LumenFinanceUITests.swift` → `testB2CurrencyPreferenceRelaunchControl` — primary role: **probe**.
- `LumenFinanceUITests/LumenExistingStoreCompatibilityUITests.swift` → `testHistoricalStoreCompatibility` — primary role: **acceptance** for the dedicated historical SwiftData compatibility gate, not for the original hosted UserDefaults question.

The hosted B2 UI diagnostics are intentionally useful while red. Their failures remain evidence about the original hosted lifecycle boundary; they are not, by themselves, authorization to modify production.

## Manual Product Evidence

On 2026-09-14, the same sideloaded physical-iPhone Lumen installation was exercised before and after ordinary force-close/reopen without reinstalling, re-signing, or changing bundle identity.

Observed after reopen:

- onboarding completion remained effective;
- the changed reporting/default currency remained EUR;
- SwiftData transactions remained present;
- transaction source/provenance state remained present;
- a Pending → Posted transaction state remained Posted.

This answers the original product-scope lifecycle question positively for the tested physical-device environment.

The physical result does not explain why the earlier hosted runner lost `UserDefaults` values.

## Evidence Tensions

- Same-process compiled AppState/defaults behavior passes, while the original Rork-hosted UI-app relaunch loses changed preference state.
- A 2-second pre-termination settle period does not change the hosted result, weakening but not eliminating simple short flush-latency explanations.
- Two independent `UserDefaults.standard`-backed values reset, weakening an onboarding-only explanation.
- Production source audit does not reveal a reset/remove/overwrite path, while the hosted observation remains repeatable.
- Physical ordinary force-close/reopen preserves the same classes of preference state that the hosted characterization lost.
- Physical SwiftData state also persists, and a separate GitHub Actions compatibility/XCTest environment independently demonstrates SwiftData historical-store continuity and relaunch durability.
- Those later successes constrain product interpretation but do not reveal the original Rork-hosted defaults-domain/container mechanism.

## Current Guardrail

Do not make persistence-layer changes solely to satisfy the original hosted relaunch diagnostics.

Do not add production timing workarounds, `synchronize()` calls, alternate defaults domains, persistence rewrites, or container-reset accommodations without a demonstrated production-side mechanism.

Preserve the original red hosted characterization as knowledge. Do not reinterpret it as invalid merely because physical product scope passed.

**Product disposition:** B2 is non-blocking for the accepted Phase 1A closure. Physical product persistence is validated; the hosted `UserDefaults` lifecycle mechanism remains unresolved; no production persistence correction is warranted by current evidence.

## Open Questions

### 1. Hosted preferences scope

Why did changed `UserDefaults.standard`-backed values disappear across the original Rork-hosted terminate/relaunch boundary?

### 2. Hosted container scope

What application-container/defaults-domain continuity did the original Rork-hosted UI-test environment actually provide? Would SwiftData have survived that exact original boundary?

### 3. Runner scope

Which runner/runtime/install behavior differs between the original Rork-hosted characterization and the later physical-device/GitHub Actions evidence?

### 4. Independent distribution scope

Would TestFlight or another independently signed/installed build produce materially different lifecycle behavior from the successful sideloaded physical-device result?

## Revisit When

- The original hosted runner exposes effective process/defaults-domain/container metadata.
- A reproducible mechanism is identified that explains the hosted reset.
- TestFlight or another independent installation environment provides materially different product-lifecycle evidence.
- New physical product evidence contradicts the current persistence result.
- A future platform/runtime change makes the hosted behavior relevant to an actual product acceptance decision again.
