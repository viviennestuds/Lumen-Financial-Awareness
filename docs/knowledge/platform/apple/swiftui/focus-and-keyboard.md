---
id: platform.apple.swiftui.focus-and-keyboard
title: SwiftUI focus and keyboard behavior relevant to Lumen
kind: platform
status: active
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
frameworks:
  - SwiftUI
apis:
  - FocusState
  - ToolbarItemGroup
  - ToolbarItemPlacement.keyboard
related:
  - investigation.swiftui.keyboard-toolbar-invalid-frame
  - testing.ios-runtime-validation
  - platform.apple
---

# SwiftUI Focus and Keyboard Behavior Relevant to Lumen

## Purpose

This note preserves reusable Lumen-specific understanding around SwiftUI focus state and keyboard toolbar presentation. It is not a general SwiftUI keyboard guide and does not claim a comprehensive current Apple documentation review.

## Current Lumen Usage

Current production `TransactionFormFields` in `ios-lumen-finance/LumenFinance/Views/TransactionForm.swift`:

- declares `@FocusState private var focusedField: String?`;
- associates Amount with `focusedField == "amount"`;
- associates Merchant with `focusedField == "merchant"`;
- uses the same focus state for editable transaction fields;
- adds a `ToolbarItemGroup(placement: .keyboard)`;
- places a `Spacer()` and a Done button inside that group;
- dismisses focus by setting `focusedField = nil` from Done.

These are source observations about Lumen, not statements about universal SwiftUI behavior.

## Current Platform-Contract Coverage

A comprehensive review of Apple's current `FocusState`, `ToolbarItemGroup`, or `.keyboard` placement documentation has not been completed for this knowledge note.

This note therefore does not currently assert an Apple-guaranteed keyboard accessory layout algorithm, a documented ordering of focus acquisition versus keyboard presentation, or an Apple-confirmed cause for Lumen's invalid-frame behavior.

When official Apple documentation is directly reviewed for those questions, add the source and a short paraphrased contract summary here.

## Lumen Runtime Observations

The detailed project-specific history lives in `docs/knowledge/investigations/keyboard-toolbar-invalid-frame.md`.

Reusable observations currently include:

- Hosted canonical UI execution can stop during Amount semantic focus while the element's pre-tap geometry is finite, positive, present, and hittable.
- Standalone focus probes can succeed on the same production source.
- A temporary experiment that moved the existing Done action away from `.keyboard` placement materially changed canonical progress, but did not produce a passing full workflow and was reverted.
- A later unchanged-production literal canonical-prefix run passed, while a subsequent frozen-production matrix failed repeatedly.
- Manual simulator interaction has been reported as normal for Amount/Merchant keyboard usage.

These observations support continued investigation. They do not establish the underlying SwiftUI mechanism.

## External Technical Evidence

The B1 investigation note preserves the exact community-source provenance recorded by the Phase 1A Run 5 audit. Those sources are comparison evidence only; the audit does not treat them as Apple confirmation or proof of the hosted runner's internals.

Their live content was not independently revalidated during this bootstrap. If reused in a future investigation, re-check the source and record a reviewed date.

## Lumen Implications

**Observation:** Lumen has evidence that keyboard-toolbar placement changes the hosted canonical sequence's behavior.

**Inference:** keyboard accessory presentation is a reasonable investigation boundary.

**Current interpretation:** exact causality remains unresolved, so production should not be rewritten solely to eliminate the hosted behavior or conform to a community workaround.

The corresponding investigation's current guardrail remains the active operating constraint for B1 work.

## Caveats

- Hosted XCTest behavior is not equivalent to ordinary physical-device human interaction unless demonstrated.
- Manual success does not invalidate automated evidence.
- Automated failure does not by itself prove user-facing breakage.
- Community reproduction does not define an Apple platform contract.
- A future Apple documentation review may clarify intended behavior without explaining the hosted runtime observation.

## Revisit Triggers

Revisit this platform note when:

- current Apple documentation for `.keyboard` toolbar placement or `FocusState` is directly reviewed;
- physical-device focus/keyboard behavior is characterized;
- a new iOS/Xcode runtime materially changes B1 behavior;
- the B1 investigation reaches a validated production correction or disposition.
