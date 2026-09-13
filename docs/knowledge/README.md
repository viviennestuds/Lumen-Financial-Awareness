---
id: project.knowledge-system
title: Lumen internal knowledge layer
kind: project
status: active
created: 2026-09-13
reviewed: 2026-09-13
last_verified: 2026-09-13
platforms:
  - ios
related:
  - investigation.swiftui.keyboard-toolbar-invalid-frame
  - investigation.onboarding-relaunch-persistence
  - platform.apple
  - testing.ios-runtime-validation
---

# Lumen Internal Knowledge Layer

Lumen's knowledge layer preserves the project's current technical understanding without replacing governance, tests, or the chronological audit.

> **Audit records what happened. Knowledge records what we currently understand. Tests prove what we can reproduce. ADRs record what we decided. Live research fills identified knowledge gaps.**

## Authority and Purpose

Knowledge follows Lumen's existing repository governance. It does **not** define a competing authority hierarchy.

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md` defines canonical product and engineering invariants.
- Accepted ADRs record explicit architectural decisions.
- `docs/ROADMAP.md`, `docs/NON_GOALS.md`, and applicable phase acceptance criteria govern implementation scope and sequencing.
- Knowledge notes distill understanding that helps apply those governing sources.

If a knowledge note appears to conflict with governing material, flag the conflict and defer to the governing source. Do not silently treat the knowledge note as newer authority.

Knowledge notes are **distillations, not transcripts**. Prefer current understanding, decisive observations, important limitations, open questions, and provenance. Link to the audit and tests instead of copying long logs.

## Note Kinds and Statuses

Use only these kinds until a real need proves another category necessary:

- `platform` — reusable understanding of an external platform, framework, or API.
- `investigation` — a specific unresolved or resolved Lumen behavior or technical question.
- `testing` — reusable validation methodology and interpretation rules.
- `project` — reusable Lumen-specific technical knowledge that is not governance or an ADR.

Typical statuses are `draft`, `active`, `unresolved`, `resolved`, `superseded`, and `archived`.

Platform, testing, and project notes commonly use `active`. Investigations commonly use `unresolved` or `resolved`.

If `status: superseded` is used, add `superseded_by` when a current replacement exists.

## Stable IDs

Every note has a lowercase, dot-separated permanent `id`.

Examples:

- `investigation.onboarding-relaunch-persistence`
- `platform.apple.foundation.userdefaults`
- `testing.ios-runtime-validation`

IDs are immutable even if a file is renamed or moved. Never recycle an ID for a different concept, including after the original note is archived or superseded.

Use stable IDs in `related` rather than filesystem-relative identifiers.

## Metadata Normalization

Keep front matter small and retrieval-friendly.

- Platform identifiers use lowercase canonical tokens, such as `ios`.
- Framework names use official casing, such as `SwiftUI`, `Foundation`, and `XCTest`.
- API symbols use code spelling, such as `UserDefaults` or `XCUIApplication.terminate`.
- Confidence values are only `low`, `medium`, or `high`.
- Confidence dimensions may vary by investigation; do not invent numeric precision.
- `superseded_by` is optional and used only when applicable.

Do not add environment, test-role, evidence paths, sources, or commit SHAs to front matter until repeated use demonstrates that they belong there. Those details currently have clearer homes in note bodies.

## Date Semantics

- `created` — when the note was first established.
- `reviewed` — when someone last substantively assessed whether the synthesis still represents current understanding. Typo, formatting, link, or path-only edits do not require a bump.
- `last_verified` — the most recent date on which the material claims supporting the note's current synthesis were collectively rechecked against underlying evidence.

`last_verified` may be older than `reviewed`.

For mixed-source notes, do not advance `last_verified` merely because one source category was refreshed. Individual official or external sources may carry their own reviewed dates in the body.

## Evidence Model

Evidence is question-relative.

- Official platform documentation defines intended platform contracts.
- Lumen executable evidence defines observed Lumen behavior.
- Manual product evidence records observed interactive behavior.
- External technical evidence supplies comparison, corroboration, or competing observations.
- Inference connects evidence but must remain labeled as inference or current interpretation.

No evidence category silently substitutes for another.

Every causal statement should be distinguishable as **observation**, **inference**, or **current interpretation**.

Never rewrite a historical observation merely because the current interpretation changed. Change the interpretation; preserve the evidence.

Do not normalize contradictory evidence away. Investigation notes should use `## Evidence Tensions` when important observations coexist without a single established explanation.

## Evidence IDs and Evidence Indexes

Stable evidence labels such as `phase1a.run6_1` may be used in front matter, but they are not self-resolving references.

**Evidence IDs identify observations, not interpretations.**

Every investigation using evidence IDs must resolve them in a body-level `## Evidence Index`. Each entry should state:

- the evidence ID;
- its role;
- navigable repository evidence, such as an audit section and test selector;
- what the evidence establishes;
- what it does **not** establish;
- the observed repository revision when that historical source state materially matters and can be stated accurately.

Revision information is optional, not ceremonial. Use it when later source evolution could otherwise make historical evidence ambiguous.

## Investigation Contract

Mandatory investigation sections:

1. `# Title`
2. `## Summary`
3. `## Scope / Environment` with `### Observed` and `### Not yet established`
4. `## Current Understanding`
5. `## Evidence Index`
6. `## Evidence Tensions`
7. `## Current Guardrail`
8. `## Open Questions`
9. `## Revisit When`

Optional sections should appear only when earned:

- `## Lumen Executable Evidence`
- `## Manual Product Evidence`
- `## Official Platform Evidence`
- `## External Technical Evidence`
- `## Sources`

Avoid empty ceremonial sections.

Use **Current Guardrail**, not `Decision`, for evidence-driven operating constraints. Durable architectural decisions belong in ADRs.

## Platform Note Contract

Platform notes should emphasize what platform behavior has actually been reviewed or verified, what remains unverified, Lumen-specific implications, environment caveats, and source provenance.

Do not manufacture a platform contract from model memory. If current Apple documentation has not been directly reviewed for a claim, say so. Sparse-but-honest notes are preferred over authoritative-looking synthetic documentation.

External reports may be retained when provenance is available, but they must not be rewritten as Apple guarantees.

## Test Roles

Runtime evidence uses four semantic test roles:

- **acceptance** — required product/runtime contract; red blocks the applicable acceptance decision.
- **regression** — protects previously validated behavior; red indicates a known contract regressed.
- **characterization** — records behavior whose desirability or cause may still be unresolved; red is evidence, not automatic authorization to change production.
- **probe** — bounded diagnostic experiment intended to answer one technical question; a failure may itself answer the question.

Each test should have one current primary role. Roles may change later as the contract becomes clearer.

Test role is semantic, not determined by pass/fail state.

A known-red characterization or probe is **not automatically a product acceptance failure** and is not authorization to weaken production merely to make a suite green.

If automated gating is introduced later, intentionally known-red characterizations/probes must be isolated from the green acceptance gate or handled by an explicit expected-disposition mechanism.

## Knowledge Acquisition Workflow

1. Read applicable governance.
2. Search existing Lumen knowledge.
3. Inspect executable evidence when needed.
4. Identify the actual remaining knowledge gap.
5. Use live retrieval only for that gap: official documentation, an Apple-specialist MCP, Firecrawl, GitHub, or another appropriate source.
6. Compare new evidence with the current synthesis.
7. Update knowledge only if understanding materially changed.
8. Preserve contradictory historical observations.
9. Change code/tests only under the applicable work order or accepted decision process.

Live retrieval is a knowledge-acquisition mechanism, not a replacement for durable project understanding.

## Size and Maintenance Discipline

As a soft design target, ordinary knowledge notes should usually remain around 150–250 lines or less. This is not a mechanical limit. A much larger note is a signal to check whether audit transcripts or raw research are leaking into the knowledge layer.

Do not create empty future taxonomies. Add new notes/directories when Lumen has real knowledge worth preserving.

Do not wholesale mirror Apple or third-party documentation.
