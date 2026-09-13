---
id: platform.apple.foundation.userdefaults
title: UserDefaults usage and lifecycle observations in Lumen
kind: platform
status: active
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
frameworks:
  - Foundation
apis:
  - UserDefaults
related:
  - investigation.onboarding-relaunch-persistence
  - testing.ios-runtime-validation
  - platform.apple
---

# UserDefaults Usage and Lifecycle Observations in Lumen

## Purpose

This note records what Lumen currently does with `UserDefaults` and what the project has observed around hosted relaunch behavior.

It is intentionally not a general Foundation reference and does not claim a comprehensive review of Apple's current `UserDefaults` contract.

## Current Lumen Usage

`ios-lumen-finance/LumenFinance/Data/AppState.swift` currently persists three values through `UserDefaults.standard`: onboarding state, currency code, and `timezoneIdentifier`.

- `lumen_has_onboarded` through `AppState.hasOnboarded`;
- `lumen_currency` through `AppState.currencyCode`;
- `lumen_timezone` through `AppState.timezoneIdentifier`.

Onboarding and currency currently participate directly in user-facing application state. `timezoneIdentifier` remains persisted in `AppState`, while the current Settings UI displays the device timezone rather than exposing that stored value as a configurable preference.

The same `AppState` initializer reads those keys from `UserDefaults.standard` when a new instance is created.

Current fallback behavior in source:

- absent onboarding key → `false` through `bool(forKey:)`;
- absent currency key → `"USD"`;
- absent timezone key → `TimeZone.current.identifier`.

These are Lumen source observations, not claims about platform-wide persistence guarantees.

## Current Platform-Contract Coverage

A comprehensive direct review of Apple's current `UserDefaults` documentation has not been completed for this bootstrap note.

This note therefore does not currently assert:

- a platform guarantee about flush timing under forced process termination;
- a guarantee that a hosted XCTest app process retains the same effective defaults domain/container across `terminate()` and `launch()`;
- a guarantee that a unit-test host and UI-app process use equivalent `UserDefaults.standard` domains;
- an explanation for Rork-hosted lifecycle behavior.

Official documentation should be reviewed directly if one of those contract questions becomes necessary to resolve a future work item.

## Lumen Executable Observations

### Same-process AppState probe

`ios-lumen-finance/LumenFinanceTests/AppStatePersistenceTests.swift` contains:

`testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference`

Primary role: **probe**.

Run 6.2 recorded that this probe passed after:

- preserving the original test-process onboarding preference;
- removing the key;
- verifying a new `AppState` reads not-onboarded;
- setting `hasOnboarded = true`;
- verifying the same `UserDefaults.standard` environment immediately reads true;
- creating a second `AppState` and verifying it reads true;
- restoring the original preference.

**Observation:** the compiled `AppState` read/write path behaves coherently within the unit-test execution environment used by that probe.

**Not established:** UI-app process-relaunch durability, effective domain equivalence, or hosted container continuity.

### Hosted UI relaunch observations

Run 6.2 retained three relevant UI diagnostics in `ios-lumen-finance/LumenFinanceUITests/LumenFinanceUITests.swift`:

- `testB2IsolatedOnboardingRelaunch` — **characterization**;
- `testB2SettledOnboardingRelaunchDiagnostic` — **probe**;
- `testB2CurrencyPreferenceRelaunchControl` — **probe**.

The first two observed onboarding reappearance after hosted `XCUIApplication.terminate()` / `launch()`; the second added one fixed 2.0-second pre-termination settle period and did not change the result.

The currency probe changed the visible preference from USD to EUR before termination, then observed USD after relaunch while onboarding also reappeared.

**Inference:** because two separate `UserDefaults.standard`-backed values exhibited the hosted relaunch loss, an onboarding-key-specific explanation is less compelling.

**Current interpretation:** broader defaults-domain / hosted-lifecycle behavior is plausible, but the exact mechanism and production relevance remain unresolved. Application-container scope has not yet been characterized.

## Environment Boundary

The Phase 1A audit records static project identities for the app/unit/UI-test targets, but effective runtime defaults-domain and container equivalence were not established.

Do not infer runtime domain identity solely from bundle identifiers or target-host configuration.

The B2 investigation separates three unresolved scopes:

1. **Preferences scope** — why changed defaults-backed values disappear in the hosted lifecycle.
2. **Container scope** — whether SwiftData survives the same boundary.
3. **Product scope** — whether an ordinarily installed physical-iPhone build reproduces the behavior.

## Lumen Implications

Do not replace direct `UserDefaults` access with `@AppStorage`, add synchronization calls, or introduce timing delays solely because the hosted diagnostics are red.

Such changes require their own evidence-backed production cause.

A future physical-device PASS may establish that a product-facing persistence defect is not reproduced while leaving the hosted preferences characterization unresolved.

## Revisit Triggers

Revisit this note when:

- current Apple `UserDefaults` documentation is directly reviewed for a concrete lifecycle question;
- physical-device onboarding/currency persistence is tested without reinstalling the app;
- hosted SwiftData persistence is characterized across the same terminate/relaunch boundary;
- hosted runtime process/domain/container metadata becomes observable;
- production source changes the preference storage mechanism.
