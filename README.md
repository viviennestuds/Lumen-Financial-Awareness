# Lumen

Lumen is a local-first financial-awareness application built around user-controlled financial truth, durable ownership, and calm reflection rather than restrictive budgeting.

This repository is Lumen's **durable system of record**.

Authority is determined by the **status, role, and precedence of documents within the repository**—not merely by a file existing here.

Preserve:

```text
repository residency
!=
substantive authority
```

Chats, prompts, generated summaries, external planning discussions, and agent responses may be useful reasoning inputs. They are not project authority.

---

# Start Here

A capable human or agent should orient itself from repository governance before making material changes.

For substantial work, read the applicable sources in this order:

1. `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
2. `docs/ROADMAP.md`
3. `docs/NON_GOALS.md`
4. `docs/architecture/LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`
5. applicable accepted ADR / responsibility contract / capability admission
6. applicable implementation plan or release checklist
7. relevant knowledge, investigations, audits, and executable evidence

This list combines two different concerns:

```text
SUBSTANTIVE GOVERNANCE
→ what Lumen is allowed / required to do

METHODOLOGY
→ how material decisions should be reasoned about

EVIDENCE
→ what the repository currently establishes
```

On this proposal branch, the Engineering Reasoning Framework is **proposed** as Lumen's living canonical methodology. It does not override substantive governance, and it should not be treated as adopted until independent review accepts the governance change.

---

# Substantive Authority

The repository already defines a substantive authority hierarchy.

A typical path is:

```text
Architecture Contract
        ↓
Roadmap
        ↓
Non-Goals
        ↓
accepted ADR / responsibility contract
        ↓
exact admission
        ↓
implementation plan
        ↓
code / tests
```

Use the exact applicable governing document for the work at hand.

Do not infer authority from filename, recency, branch position, or repository residency alone.

Examples:

```text
proposal awaiting review
!=
accepted contract

knowledge note
!=
architecture decision

characterization test
!=
implementation authorization

future-domain vision
!=
active roadmap scope

newer chat summary
!=
newer repository authority
```

---

# Repository Map

## `docs/architecture/`

Architectural contracts, ADRs, responsibility boundaries, exact admissions, public-format proposals, and future-domain architecture/vision documents.

Important distinction:

- a file under `docs/architecture/` is not automatically accepted;
- inspect its status and governing relationships.

Start with:

- `LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`

## `docs/ROADMAP.md`

Canonical implementation roadmap.

Answers:

> What are we building, in what order, and what counts as complete?

The active phase is defined there.

## `docs/NON_GOALS.md`

Canonical scope-control document.

Answers:

> What must not become an implementation requirement merely because it is possible or interesting?

## `docs/implementation/`

Implementation plans and release/validation checklists derived from admitted capabilities.

Implementation plans do not outrank the contract/admission that authorized them.

## `docs/knowledge/`

Current technical understanding, investigations, platform research, and reusable testing methodology.

Knowledge informs decisions.

It does not create a competing governance hierarchy.

Read:

- `docs/knowledge/README.md`

before treating a knowledge note as evidence or guidance.

## `ios-lumen-finance/`

Current native iOS application and tests.

Code and executable evidence matter, but current implementation shape does not automatically define the intended architecture.

## `.github/workflows/`

Repository automation and validation workflows.

A workflow proves only what its contract and test role establish.

---

# How Lumen Makes Material Decisions

For architectural, product-semantic, persistence, privacy/authority, public-format, migration, or major subsystem work, use:

`docs/architecture/LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`

Its core reasoning flow is:

```text
First Principles
        ↓
Repository Evidence
        ↓
Minimum Sufficient Contract
        ↓
Assembly Map
        ↓
Authority Budget
        ↓
Assembly Debt
        ↓
Assembly Pressure
        ↓
Counterexample Test
        ↓
Irreversible Commitments
        ↓
Proposal / Admission
        ↓
Independent Review
        ↓
Implementation / Validation
```

The framework is intentionally lightweight.

Material work should answer the applicable questions without mechanically filling irrelevant headings.

---

# Before Changing the Repository

For consequential work:

1. establish the correct governing documents;
2. establish the correct branch/base from repository history;
3. do not assume the most recent proposal branch is the canonical integration baseline;
4. inspect current implementation/evidence where the decision depends on it;
5. identify unresolved lower-level contracts before designing higher-level behavior;
6. distinguish proposal from acceptance and acceptance from implementation authority;
7. keep production/schema changes separate from docs-only contract work unless explicitly admitted.

Preserve:

```text
latest branch
!=
correct base

newest proposal
!=
canonical integration line

accepted concept
!=
implementation authorization
```

---

# Branch and Proposal Discipline

Lumen frequently uses narrow research/proposal branches.

A proposal branch may contain valuable accepted-at-proposed-contract-level reasoning without being merged to the canonical integration branch.

Before repository-wide governance or implementation work:

- identify the default/canonical integration line;
- compare relevant branches;
- establish the merge base;
- avoid inheriting unrelated stacked proposal work accidentally.

Repository-wide methodology, tooling, or unrelated architecture work should not acquire **assembly debt** on an unrelated proposal chain merely because that branch is newer.

---

# Human and Agent Handoff

This README is the universal entry point for:

- the project owner;
- human contributors;
- reviewers;
- ChatGPT repository threads;
- Rork or other app-building agents;
- future coding/research agents;
- future maintainers revisiting Lumen without prior chat context.

The goal is **not** to create AI-specific authority.

It is to make the repository self-orienting for any capable reader.

Accordingly, there is intentionally no separate `AI_CONTEXT.md` or `AGENTS.md` at this time.

Add tool-specific integration files only when an actual tool or workflow demonstrates that they provide retrieval/execution value that the root README cannot provide.

If such a file is added later, it should normally route back to repository governance rather than duplicate project truth.

---

# Stateless Development Principle

Lumen should remain workable even if any individual chat, reviewer, agent, or developer disappears.

A new capable reader should be able to recover from the repository:

```text
What is Lumen?

What must remain true?

What are we building now?

What is explicitly not authorized?

What evidence exists?

How are material decisions expected to be reasoned about?

What review/admission boundary applies before implementation?
```

The repository should preserve the answers.

Chats should help reason about them—not become the only place they exist.

---

# Current Product Principle

Lumen's guiding principle is:

**Financial Awareness over Financial Restriction.**

For the full canonical product and engineering invariants, read:

`docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
