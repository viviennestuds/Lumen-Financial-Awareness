---
id: platform.apple
title: Apple platform knowledge for Lumen
kind: platform
status: active
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
related:
  - platform.apple.swiftui.focus-and-keyboard
  - platform.apple.foundation.userdefaults
---

# Apple Platform Knowledge for Lumen

This directory contains Lumen-specific, reusable understanding of Apple frameworks and APIs that materially affect the product.

It is not an Apple documentation mirror and should not become one.

## Scope

At bootstrap, this namespace intentionally contains only subjects for which Lumen has concrete project evidence worth preserving:

- SwiftUI focus/keyboard behavior relevant to the current B1 investigation.
- Foundation `UserDefaults` usage relevant to the current B2 investigation.

No empty Vision, SwiftData, compatibility, OCR, or other future taxonomy is created here. Those areas should appear only when the project has real knowledge to preserve.

## Platform Knowledge Rules

Platform notes follow `docs/knowledge/README.md`.

In particular:

- Do not reconstruct Apple contracts from model memory.
- Distinguish official platform documentation from Lumen observations and external technical reports.
- A Lumen runtime observation does not silently redefine Apple's intended API contract.
- An Apple contract does not silently invalidate contradictory Lumen executable evidence.
- Record source provenance when official or external documentation is actually reviewed.
- Prefer short paraphrased synthesis over copied source text.

## Current Official-Documentation Coverage

The knowledge bootstrap does **not** claim that a comprehensive current Apple documentation review has been completed for the topics in this directory.

The initial notes are therefore deliberately conservative:

- `swiftui/focus-and-keyboard.md` records Lumen source/runtime observations and previously retained external technical evidence. It does not present an Apple-confirmed explanation for B1.
- `foundation/userdefaults.md` records how Lumen currently uses `UserDefaults` and what Runs 6.1/6.2 observed. It does not present a comprehensive Apple `UserDefaults` durability contract.

When current Apple documentation is later reviewed directly—through official web documentation, an Apple-specialist retrieval service, or another approved source—the applicable note should add source provenance and update `reviewed` / `last_verified` according to the knowledge-layer conventions.

## Acquisition Workflow

For an Apple-platform question:

1. Read applicable Lumen governance.
2. Read existing `docs/knowledge/` notes.
3. Inspect Lumen source/tests when the question concerns observed project behavior.
4. Identify the exact missing platform-contract question.
5. Retrieve official Apple documentation for that gap when appropriate.
6. Use community/external evidence only as comparison or implementation experience, not as an Apple guarantee.
7. Update the note only when the project's understanding materially changes.

Live Apple retrieval is a knowledge-acquisition mechanism. The durable Lumen synthesis belongs here.
