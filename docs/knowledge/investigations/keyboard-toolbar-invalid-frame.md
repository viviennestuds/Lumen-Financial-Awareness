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
reviewed: 2026-09-15
last_verified: 2026-09-15
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
  - phase1a.physical_device_2026_09_14
revisit_when:
  - B1 is characterized in a stable already-onboarded or independently controlled automation environment
  - hosted runtime metadata becomes observable
  - new product evidence contradicts the current non-blocking disposition
---

# SwiftUI Keyboard Toolbar Invalid-Frame Investigation

## Summary

Lumen's canonical Manual Entry UI workflow repeatedly surfaced `Invalid frame dimension (negative or non-finite)` during the hosted XCTest semantic tap/focus path for the Amount field while production source retained a SwiftUI keyboard toolbar and `FocusState`-managed fields.

The hosted mechanism remains unresolved and environment-sensitive. Standalone interaction probes passed, one literal canonical-prefix run passed on unchanged production, a later frozen-production matrix failed consistently, and a temporary toolbar-relocation experiment materially changed canonical progress without producing a complete passing workflow.

Physical product evidence now materially constrains the interpretation: on the sideloaded physical-iPhone build, ordinary human interaction successfully exercised Amount, Merchant, Notes, the keyboard Done toolbar, Review, Save, navigation, filtering, and subsequent ledger inspection without reproducing the hosted invalid-frame failure.

**Current product disposition:** B1 remains a useful unresolved hosted characterization, but current evidence does not support treating it as a Phase 1A product blocker or authorizing a production keyboard/focus correction.

## Scope / Environment

### Observed

- Rork-hosted iOS/XCTest execution against the SwiftUI Manual Entry flow.
- `TransactionFormFields` uses `@FocusState` and a `ToolbarItemGroup(placement: .keyboard)` with a Done action.
- Canonical tests use semantic `XCUIElement.tap()` on the Amount field.
- Pre-tap Amount geometry was repeatedly finite, positive, present, and hittable in the recorded failing runs.
- Standalone semantic/coordinate focus probes and manual simulator interaction provide comparison evidence.
- Physical-iPhone product validation on 2026-09-14 used an unsigned canonical device build installed without production source modifications. Ordinary Amount/Merchant/Notes entry, keyboard-toolbar interaction, Review, Save, navigation, filters, Insights, Settings, and transaction inspection completed without the hosted invalid-frame failure.

### Not yet established

- The precise SwiftUI phase at which the hosted invalid-frame issue is generated.
- Whether the issue is caused by keyboard accessory layout, focus transition, safe-area recomputation, runner instrumentation, sequence state, or a combination.
- Whether the warning/failure can be reproduced through independently controlled automation on a physical device.
- Whether a stable already-onboarded hosted state changes B1 behavior.
- Whether the broader hosted preferences/lifecycle anomaly demonstrated in Run 6.2 is causally related to B1.
- Whether hosted runtime/Xcode differences account for some of the observed variation.

## Current Understanding

**Observation:** the retained production form uses `@FocusState private var focusedField: String?`, focuses Amount/Merchant fields through that state, and installs a `.keyboard` `ToolbarItemGroup` containing Spacer + Done.

**Observation:** Run 5 canonical execution failed during the Amount semantic tap after Manual Entry opened, while captured pre-tap Amount geometry was finite, positive, present, and hittable.

**Observation:** Run 5 standalone probes showed that Amount semantic tap, Amount coordinate tap, Merchant semantic tap, Notes semantic tap in the final retained invocation, and the non-text Income control could complete independently.

**Observation:** a temporary Run 5 production experiment moved the existing Done action away from `.keyboard` placement while preserving focus handling. The canonical workflow then advanced beyond the original Amount boundary through fields, Review, Confirm, terminate, and relaunch before failing at repeated onboarding. Restoring the keyboard toolbar restored the original canonical Amount-tap failure. The experiment was reverted because the full workflow never passed.

**Inference:** keyboard-toolbar presentation is materially implicated in the failing hosted sequence, but that experiment does not isolate the exact responsible element or prove deterministic causality.

**Observation:** Run 6 introduced a literal canonical-prefix test through Review. The Run 6.1 audit records that the prior unchanged-production Run 6 execution passed, so the extraction was not a guaranteed-red reproducer.

**Observation:** Run 6.1 then executed three B1-A strict invocations plus the full canonical test. All four failed at the Amount semantic-tap boundary with the same valid pre-tap geometry and all four completed onboarding in that invocation.

**Observation:** owner-reported manual simulator testing completed ordinary Amount/Merchant keyboard interaction, Review/save, navigation, filtering, and derived views without a user-visible keyboard/focus abnormality.

**Observation:** Run 6.2 showed that onboarding reappearance is not unique to the B1 workflow: an independently changed currency preference also reverted across the hosted terminate/relaunch boundary.

**Observation:** physical-device product validation on 2026-09-14 successfully exercised Amount, Merchant, Notes, the production keyboard Done toolbar, Review, Save, detail inspection, status changes, filters, and other core flows without a human-facing invalid-frame/focus failure.

**Inference:** the physical-device result materially weakens the proposition that B1 is an ordinary product-facing defect, while leaving the hosted automation mechanism unexplained.

**Current interpretation:** B1 is best treated as an unresolved, state/environment-sensitive hosted keyboard/focus characterization. Toolbar involvement is supported; exact root cause is not established; current user-facing defect evidence is low.

**Current interpretation:** the hosted B1 mechanism does not block the accepted Phase 1A product/governance disposition. Reopening production correction requires new evidence that ties a user-facing or product-runtime failure to a concrete mechanism.

## Evidence Index

| Evidence ID | Role | Repository evidence | Establishes | Does not establish |
|---|---|---|---|---|
| `phase1a.run5` | runtime diagnosis / production hypothesis | `docs/PHASE_1A_AUDIT.md` → `Run 5 — independent FlowLayout fix and functional UI isolation`; current `TransactionForm.swift`; current UI probes/canonical selector | Canonical Amount semantic-tap failure with finite geometry; standalone probes can pass; temporary keyboard-toolbar relocation materially advanced canonical progress; no B1 correction retained | Exact SwiftUI cause; bare Spacer causality; deterministic toolbar causality; user-facing failure |
| `phase1a.run6` | extraction characterization | GitHub commit `58f9b5aa13edc03dad758ddeeb98a9f00954d053` added `testB1ACanonicalPrefixReachesReview`; Run 6.1 audit records the prior unchanged-production PASS | B1-A is a literal canonical prefix through Review and has passed on unchanged production | Global repeatability; proof that B1 is resolved; proof that later Run 6.1 failures were invalid |
| `phase1a.run6_1` | frozen-production characterization | `docs/PHASE_1A_AUDIT.md` → `Run 6.1 — frozen-production B1/B2 characterization`; `testB1ACanonicalPrefixReachesReview`; `testManualReviewSaveRelaunchInspectEditStatusAndDelete` | Three B1-A runs and one canonical run failed at the same Amount semantic-tap boundary with finite/hittable geometry; all four completed onboarding that invocation | Global B1 determinism; onboarding causality; toolbar causality; inability of a human to continue interaction |
| `phase1a.run6_2` | contextual lifecycle diagnosis | `docs/PHASE_1A_AUDIT.md` → `Run 6.2 — B2 preferences/relaunch diagnosis`; B2/currency diagnostics | Repeated onboarding under hosted relaunch is part of a broader observed preferences/lifecycle anomaly; B1 production was not modified | That the B2 mechanism causes B1; that onboarding state is irrelevant to B1; any B1 fix |
| `phase1a.physical_device_2026_09_14` | manual product validation | `docs/PHASE_1A_CLOSURE.md` → B1/B2 disposition and clean-install/product validation; canonical unsigned physical-device build lineage | Ordinary physical-iPhone Amount/Merchant/Notes/keyboard-toolbar/Review/Save interaction completed without the hosted B1 failure; no product-facing blocker was observed | Exact hosted SwiftUI/XCTest cause; proof that every iPhone/runtime can never reproduce the warning; invalidation of the hosted characterization |

Revision context:

- The historical hosted B1/B2 evidence remains preserved by the audit and retained diagnostic tests.
- The physical-device product validation preceded the dedicated compatibility-infrastructure-only commit; the latter changed no production Lumen behavior.
- Phase 1A product behavior was ultimately accepted through validated candidate `8ce3fad0c449c433ca3c2fc7490a1a948c4f504a`; see `docs/PHASE_1A_CLOSURE.md` for closure provenance.

## Lumen Executable Evidence

Current relevant selectors in `ios-lumen-finance/LumenFinanceUITests/LumenFinanceUITests.swift` include:

- `testB1ACanonicalPrefixReachesReview` — primary role: **characterization**.
- `testManualReviewSaveRelaunchInspectEditStatusAndDelete` — primary role: **acceptance** for the broader core ledger workflow; its historical B1 boundary remains evidence rather than an independently established physical-device defect.
- `testProbeAmountSemanticTap` — primary role: **probe**.
- `testProbeMerchantSemanticTap` — primary role: **probe**.
- `testProbeNotesSemanticTap` — primary role: **probe**.
- `testProbeNonTextControlTap` — primary role: **probe**.
- `testProbeAmountCoordinateTap` — primary role: **probe**.

Test role is semantic. A characterization/probe being red is evidence; it is not automatic authorization to change production solely to make the suite green.

## Manual Product Evidence

Manual simulator evidence previously showed ordinary Amount/Merchant keyboard interaction could complete normally.

Physical-device evidence is now stronger for product scope. On 2026-09-14, the same installed sideloaded Lumen application was exercised on a physical iPhone without changing production keyboard/focus behavior. Amount, Merchant, Notes, keyboard Done, Review, Save, subsequent transaction inspection, filters, and status interaction completed without the hosted invalid-frame failure.

This does not explain the hosted automation behavior. It does establish that the hosted failure should not be promoted into a product blocker without contradictory product-runtime evidence.

## External Technical Evidence

The Run 5 audit records two community reports used as supporting research:

- `https://stackoverflow.com/questions/79325386/swiftui-warning-with-toolbar-item-placement-keyboard`
- `https://stackoverflow.com/questions/79728378/swiftui-toolbarplacement-keyboard-not-showing-buttons-on-first-appearance`

The audit characterizes them as comparable community reports, not Apple confirmation and not proof of Lumen's runner internals. Their source content was not independently revalidated during the knowledge-layer bootstrap.

## Evidence Tensions

- Run 6 B1-A passed on unchanged production, while Run 6.1 B1-A failed 3/3 and the canonical test failed at the same boundary.
- Standalone Amount/Merchant/Notes/non-text probes can pass while the canonical hosted sequence fails at Amount focus.
- Temporarily removing keyboard toolbar placement changed canonical progress, yet no complete passing workflow was produced and the correction was reverted.
- Manual simulator interaction appeared normal while hosted strict XCTest execution could stop on the invalid-frame issue.
- Physical-iPhone ordinary human interaction also completed normally, materially lowering product-facing defect evidence without explaining the hosted mechanism.
- External reports indicate comparable warnings can occur in other environments, but they do not establish Lumen's cause.
- All Run 6.1 strict failures completed onboarding in that invocation, but Run 6.2 makes onboarding-specific causality less compelling without proving the broader lifecycle anomaly relevant or irrelevant to B1.

## Current Guardrail

Do not remove or relocate the production keyboard toolbar solely to eliminate the hosted warning/failure.

Do not treat the warning text alone as proof of a user-facing failure.

Do not treat physical/manual success as proof that the hosted characterization is meaningless; preserve it as unresolved runtime knowledge.

**Product disposition:** B1 is non-blocking for the accepted Phase 1A closure. A production correction requires new evidence of a product/runtime failure plus an evidence-backed mechanism and correction.

## Open Questions

- Which SwiftUI transition actually generates the hosted invalid dimension: focus acquisition, keyboard presentation, accessory layout, safe-area recomputation, or another state transition?
- Can B1 be characterized in an already-onboarded state without introducing a production reset/test seam?
- Can independently controlled physical-device automation reproduce the hosted warning even though ordinary human interaction did not?
- Does hosted runtime/Xcode version materially affect reproduction?
- Is the broader hosted defaults/lifecycle anomaly causally related to B1 in any way?

## Revisit When

- A stable already-onboarded B1 comparison becomes available without changing production semantics.
- Hosted runtime/Xcode/container metadata becomes observable enough to isolate the automation boundary.
- Independently controlled device automation produces materially new evidence.
- New physical product evidence contradicts the current non-blocking disposition.
- New official or external evidence materially changes the focus/keyboard interpretation.
