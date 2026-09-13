---
id: testing.ios-runtime-validation
title: iOS runtime validation in Lumen
kind: testing
status: active
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
frameworks:
  - XCTest
related:
  - investigation.swiftui.keyboard-toolbar-invalid-frame
  - investigation.onboarding-relaunch-persistence
---

# iOS Runtime Validation in Lumen

## Purpose

This note defines how Lumen interprets iOS runtime evidence, especially when hosted simulator/XCTest behavior, manual product behavior, and future physical-device behavior do not fully agree.

It does not replace phase acceptance criteria. It provides reusable testing semantics so that diagnostic evidence is not accidentally promoted into a production mandate.

## Test Roles

Every retained runtime test should have one current primary semantic role.

### Acceptance

A required product/runtime contract. A failing acceptance test blocks the applicable acceptance decision until the failure receives a justified disposition.

Example current intent:

- `LumenFinanceUITests.testManualReviewSaveRelaunchInspectEditStatusAndDelete` — **acceptance** for the broader canonical ledger workflow.

A failure inside an acceptance test can still expose an environmental or framework question. The acceptance role does not predetermine root cause.

### Regression

Protects behavior that was previously validated and intentionally retained. A failure indicates that an established contract may have regressed.

Example:

- `FlowLayoutTests.testFlowLayoutReturnsFiniteMeasuredSize` protects the validated finite-size layout correction.

### Characterization

Records a repeatable or historically important behavior whose desirability, cause, or product relevance may remain unresolved.

A characterization can intentionally remain red. Red means the characterized condition was observed; it does not automatically authorize a production change.

Example:

- `LumenFinanceUITests.testB2IsolatedOnboardingRelaunch` — **characterization** of the strict hosted immediate terminate/relaunch behavior.
- `LumenFinanceUITests.testB1ACanonicalPrefixReachesReview` — **characterization** of the B1 canonical prefix under hosted automation.

### Probe

A bounded diagnostic experiment intended to answer one technical question. A probe can answer its question by passing or by failing.

Current examples:

- `AppStatePersistenceTests.testOnboardingReadWriteWithinSameProcessRestoresOriginalPreference` — **probe** of same-process AppState/defaults behavior.
- `LumenFinanceUITests.testB2SettledOnboardingRelaunchDiagnostic` — **probe** of one fixed 2.0-second settle hypothesis.
- `LumenFinanceUITests.testB2CurrencyPreferenceRelaunchControl` — **probe** of whether a second defaults-backed preference behaves similarly.
- the standalone Amount/Merchant/Notes/non-text/coordinate focus tests in `LumenFinanceUITests.swift` — **probes** of interaction boundaries.

## Role Rules

- Test role is semantic, not determined by pass/fail state.
- Assign one primary role at a time; avoid compound labels such as `characterization/probe`.
- Roles may change when the product contract becomes clearer.
- A characterization/probe failure is evidence, not an automatic requirement to change production.
- An acceptance failure is a blocker for the applicable decision, but root cause still requires evidence.
- A green diagnostic does not automatically certify a broader product contract than the test actually exercised.

## Known-Red Diagnostics and Future Gating

Lumen currently retains useful known-red hosted diagnostics from Phase 1A.

Future automation must not silently fold intentionally retained known-red characterizations/probes into a generic "all tests must be green" acceptance gate.

If CI or another automated gate is introduced later, known-red diagnostic tests must either:

- be isolated from the green acceptance/regression gate; or
- use an explicit expected-disposition mechanism that preserves their diagnostic meaning.

Do not weaken production solely to make a characterization/probe green.

## Evidence Scope

Runtime evidence must identify the environment it actually exercised.

Important distinctions include:

- same-process unit-test behavior;
- hosted simulator UI-test behavior;
- manual simulator interaction;
- physical-device human interaction;
- physical-device automated testing;
- TestFlight/App Store installed behavior.

Do not silently generalize one environment into another.

For hosted evidence, record runtime/Xcode/device/container metadata only when actually exposed. Unknown metadata should remain unknown rather than inferred from project configuration.

## Pass/Fail Interpretation

When a runtime test reports red, separate at least three questions:

1. **Observation** — what action/checkpoint actually failed or differed?
2. **Cause** — what mechanism is demonstrated to explain it?
3. **Product implication** — what product/runtime contract, if any, is violated?

Those answers can differ.

Example from B2:

- **Observation:** onboarding and changed currency are lost across the tested hosted terminate/relaunch path.
- **Cause:** not established.
- **Product implication:** not yet established for an ordinarily installed iPhone build.

Example from B1:

- **Observation:** hosted strict XCTest execution can stop during Amount semantic focus with an invalid-frame issue.
- **Cause:** keyboard-toolbar involvement is supported, exact mechanism unresolved.
- **Product implication:** manual simulator evidence has not demonstrated a user-facing keyboard failure.

## Fixed Diagnostic Plans

When a diagnostic plan is intentionally bounded:

- run the planned variants rather than rerunning until a preferred red/green outcome appears;
- change one material diagnostic variable at a time when possible;
- preserve negative results when they discriminate hypotheses;
- do not manufacture a production correction merely because a hosted test remains red;
- revert temporary production hypotheses unless independently justified by evidence.

Phase 1A Runs 6.1 and 6.2 are examples of fixed characterization/diagnostic matrices.

## Manual Product Evidence

Manual testing is valid evidence about what a human experienced in the environment tested.

It must not be used to erase contradictory automated evidence, but it can materially change the product-impact interpretation.

Current example: owner-reported manual simulator testing completed Amount/Merchant keyboard interaction and broader Review/save/navigation behavior without a visible keyboard/focus abnormality. That observation does not invalidate B1 hosted failures and does not prove relaunch persistence.

## Physical-Device Validation

Physical-device testing is especially valuable when hosted runtime semantics are uncertain.

For the planned Phase 1A lifecycle experiment, preserve these controls:

- install one known build;
- keep the same bundle identity;
- do not reinstall/re-sign between pre/post lifecycle observations;
- record the exact source/build provenance;
- observe `UserDefaults`-backed onboarding and currency separately from a test-owned SwiftData transaction;
- distinguish background/foreground from force-close/reopen.

A physical-device pass may resolve the product-facing question without resolving the hosted-runner mechanism.

## Evidence Preservation

For consequential runtime work:

- keep the chronological detail in `docs/PHASE_1A_AUDIT.md` or the applicable phase audit;
- keep executable checks in tests when they remain useful;
- keep the distilled current interpretation in `docs/knowledge/`;
- use an ADR only when a durable architectural decision is actually made.

Do not rewrite historical test outcomes when the interpretation later changes.

## Current Phase 1A Boundary

As of the bootstrap evidence:

- lower-layer FlowLayout, persistence, and domain checks have green retained baselines;
- the same-process AppState probe is green;
- B2 hosted relaunch characterization/probes are retained as known-red unresolved evidence;
- B1 hosted focus characterization remains open;
- runtime validation is not complete;
- the Phase 1A hardening checkpoint is not yet accepted.

This note does not change those acceptance states. It only defines how to interpret the evidence supporting them.
