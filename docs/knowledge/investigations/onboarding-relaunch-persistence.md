---
id: investigation.onboarding-relaunch-persistence
title: Onboarding and preferences across hosted UI-test relaunch
kind: investigation
status: unresolved
confidence:
  reproduction: high
  root_cause: low
  broader_defaults_lifecycle_involvement: medium
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
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
revisit_when:
  - physical-device lifecycle persistence is tested
  - hosted SwiftData persistence scope is characterized
  - hosted app-container/defaults continuity becomes observable
---

# Onboarding and Preferences Across Hosted UI-Test Relaunch

## Summary

In Rork's hosted UI-test environment, Lumen has repeatedly lost changed `UserDefaults.standard`-backed preference state across the tested `XCUIApplication.terminate()` to `launch()` boundary. Run 6.2 broadened the observation from onboarding alone to a second independent preference: both `lumen_has_onboarded` and a test-owned currency change failed to survive relaunch, while a same-process compiled `AppState`/`UserDefaults` probe passed.

No concrete production-side reset, key/domain mismatch, second writer, startup overwrite, or failing in-process read/write mechanism was established. Production causality was therefore not established and production was not changed.

## Scope / Environment

### Observed

- Rork-hosted iOS/XCTest execution.
- UI-app lifecycle driven by `XCUIApplication.terminate()` and `launch()`.
- Production `AppState` using `UserDefaults.standard`.
- `lumen_has_onboarded` and `lumen_currency` as independent preference keys.
- A same-process unit-test probe of the compiled `AppState` read/write path.
- One strict immediate relaunch characterization, one 2-second-settle probe, and one independent currency-control probe.

### Not yet established

- Effective hosted preferences domain identity across relaunch.
- Effective application-container continuity across relaunch.
- Exact hosted Xcode/iOS runtime behavior responsible for the observation.
- Whether SwiftData survives the same hosted terminate/relaunch boundary.
- Ordinary physical-iPhone force-close/reopen behavior.
- TestFlight-installed behavior.
- Whether the hosted observation represents a product-facing defect at all.

## Current Understanding

**Observation:** production reads and writes onboarding with the same key, `lumen_has_onboarded`, through `UserDefaults.standard`.

**Observation:** source audit found one production onboarding writer, no second writer, no reset/remove path, no startup overwrite/default registration, and no source-configured test launch behavior that explains the reset.

**Observation:** the compiled same-process AppState probe passed: absent key to false AppState; set `hasOnboarded = true` to immediate same-process defaults read true; second AppState to true; original test-process preference restored.

**Observation:** B2-A immediate terminate/relaunch failed with FULL evidence: Activity was available before termination; after relaunch Activity was absent and Get Started was present.

**Observation:** B2-B repeated the sequence with a fixed 2.0-second pre-termination settle period and failed the same way. A short simple write-flush latency explanation became less compelling but was not eliminated.

**Observation:** the independent currency control visibly changed USD to EUR before termination, then after relaunch observed Get Started again and currency USD. The changed EUR value did not survive the tested boundary.

**Current interpretation:** an onboarding-specific production defect is less compelling after the independent currency result. Broader defaults-domain/container/hosted-lifecycle behavior is more plausible, but the exact mechanism remains unknown.

**Current interpretation:** Run 6.2 does not prove that Rork resets the whole app container, that `UserDefaults` itself is defective, or that ordinary iPhone lifecycle persistence fails.

## Evidence Index

| Evidence ID | Role | Repository evidence | Establishes | Does not establish |
|---|---|---|---|---|
| `phase1a.run6_1` | runtime characterization | `docs/PHASE_1A_AUDIT.md` → Run 6.1; `testB2IsolatedOnboardingRelaunch` | Isolated hosted terminate/relaunch reproduced onboarding reappearance independently of Manual Entry, keyboard, transaction creation, or ledger mutation | AppState/UserDefaults/framework/runner cause; broader preference scope; physical-device behavior |
| `phase1a.run6_2` | runtime diagnosis | `docs/PHASE_1A_AUDIT.md` → Run 6.2; `AppStatePersistenceTests.swift`; B2-A/B2-B/currency selectors in `LumenFinanceUITests.swift` | Same-process AppState/defaults probe passed; immediate and 2-second-settled hosted relaunch lost onboarding; independent changed currency also failed to persist; no concrete production cause found | Cause of reset; whole-container reset; SwiftData behavior across the boundary; ordinary installed-device behavior; a Rork defect |

Observed canonical GitHub repository state for the retained Run 6.2 evidence: `66663d6bff208299d0849b5cd276382e53881711`. The audit itself records Rork's internal execution snapshot distinctions; this GitHub SHA identifies the retained evidence now being summarized, not the internal runner HEAD used during execution.

## Lumen Executable Evidence

The retained diagnostic surface includes:

- `AppStatePersistenceTests/testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference` — primary role: **probe**.
- `LumenFinanceUITests/testB2IsolatedOnboardingRelaunch` — primary role: **characterization**.
- `LumenFinanceUITests/testB2SettledOnboardingRelaunchDiagnostic` — primary role: **probe**.
- `LumenFinanceUITests/testB2CurrencyPreferenceRelaunchControl` — primary role: **probe**.

The hosted UI diagnostics are intentionally useful while red. Their failures are evidence about the hosted lifecycle boundary; they are not, by themselves, authorization to modify production.

## Evidence Tensions

- Same-process compiled AppState/defaults behavior passes, while hosted UI-app relaunch loses changed preference state.
- A 2-second pre-termination settle period does not change the hosted result, weakening but not eliminating simple short flush-latency explanations.
- Two independent `UserDefaults.standard`-backed values reset, weakening an onboarding-only explanation.
- Production source audit does not reveal a reset/remove/overwrite path, while the hosted observation remains repeatable.
- Effective runtime domain/container continuity is unknown, so the observation cannot yet be assigned confidently to Lumen production or the hosted runner.
- Manual ordinary product interaction appears healthy, but manual process-lifecycle persistence has not yet been validated.

## Current Guardrail

Do not make persistence-layer changes solely to satisfy the hosted relaunch diagnostics. Do not add production timing workarounds or stylistic persistence rewrites without a demonstrated production-side mechanism.

A production persistence correction requires evidence of a concrete production-side cause or contradictory product-level evidence.

Do not call B2 wholly resolved merely because a future physical-device test passes. Product scope, hosted preferences scope, and hosted container scope are separate questions.

## Open Questions

### 1. Preferences scope

Why do changed `UserDefaults.standard`-backed values disappear across the hosted terminate/relaunch boundary?

### 2. Container scope

Does SwiftData survive the same hosted lifecycle boundary while `UserDefaults` values reset, or is broader application-container state also lost?

### 3. Product scope

On an ordinarily installed physical iPhone, without reinstalling or changing bundle identity, do onboarding, changed currency, and a test-owned SwiftData transaction survive background/foreground and force-close/reopen?

### 4. Runner scope

What process/defaults-domain/container continuity does the hosted test environment actually provide across `XCUIApplication.terminate()` / `launch()`?

## Revisit When

- The sideloaded physical-iPhone lifecycle experiment is completed.
- Hosted SwiftData persistence is characterized under the same lifecycle boundary.
- The hosted runner exposes effective process/domain/container metadata.
- New production evidence identifies a specific reset/write/read mechanism.
- TestFlight or another independently installed build provides materially different lifecycle evidence.
