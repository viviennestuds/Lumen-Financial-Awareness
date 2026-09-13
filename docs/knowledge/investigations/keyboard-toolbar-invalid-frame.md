---
id: investigation.swiftui.keyboard-toolbar-invalid-frame
title: SwiftUI keyboard toolbar invalid-frame investigation
kind: investigation
status: unresolved
confidence:
  reproduction: medium
  toolbar_involvement: medium
  user_facing_defect_evidence: low
  root_cause: low
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
frameworks:
  - SwiftUI
  - XCTest
apis:
  - FocusState
  - ToolbarItemGroup
  - ToolbarItemPlacement.keyboard
related:
  - investigation.onboarding-relaunch-persistence
  - platform.apple.swiftui.focus-and-keyboard
  - testing.ios-runtime-validation
evidence:
  - phase1a.run5
  - phase1a.run6
  - phase1a.run6_1
  - phase1a.run6_2
revisit_when:
  - B2 product-scope lifecycle evidence receives a disposition
  - B1 is characterized in a stable already-onboarded or independent device environment
  - hosted runtime metadata becomes observable
---

# SwiftUI Keyboard Toolbar Invalid-Frame Investigation

## Summary

Lumen's canonical Manual Entry UI workflow has repeatedly surfaced `Invalid frame dimension (negative or non-finite)` during the XCTest semantic tap/focus path for the Amount field while production source retains a SwiftUI keyboard toolbar and `FocusState`-managed fields.

The evidence does not establish that ordinary users are unable to focus or type. Standalone interaction probes have passed, one literal canonical-prefix run passed on unchanged production, a later frozen-production matrix failed consistently, and a manual simulator smoke test reported normal Amount/Merchant keyboard use. A temporary toolbar-relocation experiment materially changed canonical progress but did not produce a passing full workflow and was reverted.

No validated B1 production correction is retained.

## Scope / Environment

### Observed

- Rork-hosted iOS/XCTest execution against the SwiftUI Manual Entry flow.
- `TransactionFormFields` uses `@FocusState` and a `ToolbarItemGroup(placement: .keyboard)` with a Done action.
- Canonical tests use semantic `XCUIElement.tap()` on the Amount field.
- Pre-tap Amount geometry was repeatedly finite, positive, present, and hittable in the recorded failing runs.
- Standalone semantic/coordinate focus probes and a manual simulator interaction provide comparison evidence.

### Not yet established

- Exact Xcode/iOS runtime version for the failing hosted executions.
- The precise SwiftUI phase at which the invalid-frame issue is generated.
- Whether the issue is caused by keyboard accessory layout, focus transition, safe-area recomputation, runner instrumentation, sequence state, or a combination.
- Whether the warning/failure reproduces during ordinary physical-iPhone interaction.
- Whether a stable already-onboarded hosted state changes B1 behavior.
- Whether the broader hosted preferences/lifecycle anomaly demonstrated in Run 6.2 is causally related to B1.

## Current Understanding

**Observation:** the retained production form uses `@FocusState private var focusedField: String?`, focuses Amount/Merchant fields through that state, and installs a `.keyboard` `ToolbarItemGroup` containing Spacer + Done.

**Observation:** Run 5 canonical execution failed during the Amount semantic tap after Manual Entry opened, while captured pre-tap Amount geometry was finite, positive, present, and hittable.

**Observation:** Run 5 standalone probes showed that Amount semantic tap, Amount coordinate tap, Merchant semantic tap, Notes semantic tap in the final retained invocation, and the non-text Income control could complete independently.

**Observation:** a temporary Run 5 production experiment moved the existing Done action away from `.keyboard` placement while preserving focus handling. The canonical workflow then advanced beyond the original Amount boundary through fields, Review, Confirm, terminate, and relaunch before failing at repeated onboarding. Restoring the keyboard toolbar restored the original canonical Amount-tap failure. The experiment was reverted because the full workflow never passed.

**Inference:** keyboard-toolbar presentation is materially implicated in the failing hosted sequence, but that experiment does not isolate the exact responsible element or prove deterministic causality.

**Observation:** Run 6 introduced a literal canonical-prefix test through Review. The current Run 6.1 audit records that the prior unchanged-production Run 6 execution passed, so the extraction was not a guaranteed-red reproducer.

**Observation:** Run 6.1 then executed three B1-A strict invocations plus the full canonical test. All four failed at the Amount semantic-tap boundary with the same valid pre-tap geometry and all four completed onboarding in that invocation.

**Observation:** owner-reported manual simulator testing later completed ordinary Amount/Merchant keyboard interaction, Review/save, navigation, filtering, and derived views without a user-visible keyboard/focus abnormality.

**Observation:** Run 6.2 showed that onboarding reappearance is not unique to the B1 workflow: an independently changed currency preference also reverted across the hosted terminate/relaunch boundary.

**Inference:** Run 6.2 makes an onboarding-specific explanation for B1 less compelling because repeated onboarding sits within a broader hosted preferences/lifecycle phenomenon.

**Current interpretation:** B1 is best treated as a state/environment-sensitive hosted keyboard/focus characterization with toolbar involvement supported but exact root cause and user-facing impact unresolved.

**Current interpretation:** Run 6.2 does not establish that the broader defaults/lifecycle phenomenon causes B1, and it does not establish that the phenomenon is irrelevant to B1.

## Evidence Index

| Evidence ID | Role | Repository evidence | Establishes | Does not establish |
|---|---|---|---|---|
| `phase1a.run5` | runtime diagnosis / production hypothesis | `docs/PHASE_1A_AUDIT.md` → `Run 5 — independent FlowLayout fix and functional UI isolation`; current `TransactionForm.swift`; current UI probes/canonical selector | Canonical Amount semantic-tap failure with finite geometry; standalone probes can pass; temporary keyboard-toolbar relocation materially advanced canonical progress; no B1 correction retained | Exact SwiftUI cause; bare Spacer causality; deterministic toolbar causality; user-facing failure |
| `phase1a.run6` | extraction characterization | GitHub commit `58f9b5aa13edc03dad758ddeeb98a9f00954d053` added `testB1ACanonicalPrefixReachesReview`; Run 6.1 audit records the prior unchanged-production PASS | B1-A is a literal canonical prefix through Review and has passed on unchanged production | Global repeatability; proof that B1 is resolved; proof that later Run 6.1 failures were invalid |
| `phase1a.run6_1` | frozen-production characterization | `docs/PHASE_1A_AUDIT.md` → `Run 6.1 — frozen-production B1/B2 characterization`; `testB1ACanonicalPrefixReachesReview`; `testManualReviewSaveRelaunchInspectEditStatusAndDelete` | Three B1-A runs and one canonical run failed at the same Amount semantic-tap boundary with finite/hittable geometry; all four completed onboarding that invocation | Global B1 determinism; onboarding causality; toolbar causality; inability of a human to continue interaction |
| `phase1a.run6_2` | contextual lifecycle diagnosis | `docs/PHASE_1A_AUDIT.md` → `Run 6.2 — B2 preferences/relaunch diagnosis`; B2/currency diagnostics | Repeated onboarding under hosted relaunch is part of a broader observed preferences/lifecycle anomaly; B1 production was not modified | That the B2 mechanism causes B1; that onboarding state is irrelevant to B1; any B1 fix |

Revision context:

- Canonical GitHub state currently retaining the summarized B1/B2 evidence: `66663d6bff208299d0849b5cd276382e53881711`.
- Run 6's B1-A source addition is directly inspectable at `58f9b5aa13edc03dad758ddeeb98a9f00954d053`.
- Run 6.1 and Run 6.2 audit sections separately record their internal execution HEADs and source-identity limitations. Do not treat those internal runner snapshots as automatically identical to the canonical GitHub revisions that later retained the evidence.

## Lumen Executable Evidence

Current relevant selectors in `ios-lumen-finance/LumenFinanceUITests/LumenFinanceUITests.swift`:

- `testB1ACanonicalPrefixReachesReview` — primary role: **characterization**.
- `testManualReviewSaveRelaunchInspectEditStatusAndDelete` — primary role: **acceptance** for the broader core ledger workflow; its B1 failure remains one boundary within that larger contract.
- `testProbeAmountSemanticTap` — primary role: **probe**.
- `testProbeMerchantSemanticTap` — primary role: **probe**.
- `testProbeNotesSemanticTap` — primary role: **probe**.
- `testProbeNonTextControlTap` — primary role: **probe**.
- `testProbeAmountCoordinateTap` — primary role: **probe**.

Test role is semantic. A characterization/probe being red is evidence; it is not automatic authorization to change production solely to make the suite green.

## Manual Product Evidence

The Run 6.2 audit preserves owner-reported manual simulator evidence: ordinary Amount/Merchant keyboard interaction completed normally and Review/save/navigation/filtering/derived views were usable, with no user-visible keyboard/focus abnormality observed.

This is manual product evidence, not proof that the hosted automated failure is invalid and not process-lifecycle persistence evidence.

## External Technical Evidence

The Run 5 audit records two community reports used as supporting research:

- `https://stackoverflow.com/questions/79325386/swiftui-warning-with-toolbar-item-placement-keyboard`
- `https://stackoverflow.com/questions/79728378/swiftui-toolbarplacement-keyboard-not-showing-buttons-on-first-appearance`

The audit characterizes them as comparable community reports, not Apple confirmation and not proof of Lumen's runner internals. Their source content was not independently revalidated during this bootstrap.

## Evidence Tensions

- Run 6 B1-A passed on unchanged production, while Run 6.1 B1-A failed 3/3 and the canonical test failed at the same boundary.
- Standalone Amount/Merchant/Notes/non-text probes can pass while the canonical sequence fails at Amount focus.
- Temporarily removing keyboard toolbar placement changed canonical progress, yet no complete passing workflow was produced and the correction was reverted.
- Manual simulator interaction appears normal while hosted strict XCTest execution can stop on the invalid-frame issue.
- External reports indicate comparable warnings can occur in other environments, but they do not establish Lumen's cause.
- All Run 6.1 strict failures completed onboarding in that invocation, but Run 6.2 makes onboarding-specific causality less compelling without proving the broader lifecycle anomaly relevant or irrelevant to B1.

## Current Guardrail

Do not remove or relocate the production keyboard toolbar solely to eliminate the hosted warning/failure until evidence satisfies a product/runtime acceptance rule.

Do not treat the warning text alone as proof of a user-facing failure.

Do not treat manual success alone as proof that automated characterization is meaningless.

Prefer the next B1 characterization after B2 receives product-scope lifecycle evidence, ideally in an environment where onboarding/persistence state can be understood independently.

## Open Questions

- Does B1 reproduce on a physical iPhone under ordinary human interaction?
- Can B1 be characterized in an already-onboarded state without introducing a production reset/test seam?
- Does the invalid-frame warning occur during a successful manual interaction, or only under hosted automation?
- Which SwiftUI transition actually generates the invalid dimension: focus acquisition, keyboard presentation, accessory layout, safe-area recomputation, or another state transition?
- Does hosted runtime/Xcode version materially affect reproduction?
- Is the broader hosted defaults/lifecycle anomaly causally related to B1 in any way?

## Revisit When

- Physical-device lifecycle and keyboard behavior are observed on the sideloaded build.
- B2 receives a product-scope disposition.
- A stable already-onboarded B1 comparison becomes available without changing production semantics.
- Hosted runtime/Xcode metadata becomes observable.
- New official or external evidence materially changes the focus/keyboard interpretation.
