# Lumen Engineering Reasoning Framework

## Status

**PROPOSED FOR REVIEW — intended living canonical development-methodology document.**

This document defines the reasoning disciplines Lumen uses to decompose, propose, sequence, evaluate, review, and admit architectural and product-semantic changes.

It does **not** override substantive repository governance, including:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`;
- `docs/ROADMAP.md`;
- `docs/NON_GOALS.md`;
- accepted ADRs and responsibility contracts;
- exact capability admissions;
- accepted implementation plans.

Where this methodology conflicts with a governing architectural or product rule, the governing rule wins.

Once accepted, this framework governs **how decisions are reasoned about**. It does not itself authorize implementation, migration, persistence, scope expansion, or product behavior.

Changes to this framework govern future reasoning and work that is explicitly reopened for review. They do **not** retroactively invalidate accepted substantive decisions merely because the methodology later evolves. Reopening an accepted architectural, product, admission, or implementation decision requires the authority and review appropriate to that decision.

The framework exists to improve reasoning quality, not to substitute process for engineering judgment. Use the smallest amount of framework necessary to expose assumptions, dependencies, authority changes, and irreversible commitments.

---

# 1. Role in Lumen Governance

Lumen separates three concerns.

## 1.1 Substantive governance

Substantive governance answers:

> What is Lumen allowed, required, or currently scoped to do?

The existing authority hierarchy remains authoritative.

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

The exact applicable path depends on the work.

## 1.2 Methodology

This framework answers:

> How should Lumen reason toward architectural and product-semantic decisions?

It is a methodology overlay, not another substantive rung inserted into the hierarchy above.

## 1.3 Evidence

Repository evidence answers:

> What does the current system, implementation, platform, or investigation actually establish?

Evidence may include:

- executable tests;
- audits;
- accepted characterization;
- knowledge notes;
- repository inspection;
- official platform documentation;
- retained historical observations;
- focused external research.

Evidence informs decisions. It does not automatically acquire decision authority merely by existing.

---

# 2. Assembly-Informed Scope Note

“Assembly-informed” in this framework is an engineering reasoning metaphor.

Lumen does **not** claim to apply Assembly Theory as a quantitative scientific measure of software complexity, quality, or correctness.

The useful ideas here are:

- compositional dependency;
- reusable semantic subassemblies;
- dependency ordering;
- generalization pressure;
- unresolved dependency debt;
- unnecessary assembly;
- cost of irreversible commitments.

Terms such as **Assembly Map**, **Assembly Pressure**, and **Assembly Debt** are Lumen engineering vocabulary informed by this compositional mental model.

They are not claims that these are formal scientific metrics.

---

# 3. Core Reasoning Flow

For material architectural or product-semantic work, reason in roughly this order:

```text
FIRST PRINCIPLES
What must become possible?
        ↓
REPOSITORY EVIDENCE
What is actually established?
        ↓
MINIMUM SUFFICIENT CONTRACT
What is the smallest commitment that solves the requirement?
        ↓
ASSEMBLY MAP
What accepted pieces does this consume?
What later work consumes this piece?
        ↓
AUTHORITY BUDGET
What authority is created?
What earns it?
        ↓
ASSEMBLY DEBT
What unresolved lower-level dependency remains?
        ↓
ASSEMBLY PRESSURE
Is a repeated pattern ready to generalize?
        ↓
COUNTEREXAMPLE TEST
Where does this reasoning stop applying?
        ↓
IRREVERSIBLE COMMITMENTS
What becomes expensive to change?
        ↓
PROPOSAL / ADMISSION
Exact contract language
        ↓
INDEPENDENT REVIEW
        ↓
IMPLEMENTATION / VALIDATION
only when separately authorized
```

This is a reasoning order, not a mandatory document outline.

Material proposals must address the **applicable** disciplines. They do not need ceremonial headings for questions that genuinely do not apply.

---

# 4. First-Principles Lens

Start from the actual product or system requirement rather than inherited implementation shape.

Ask:

- What user or product capability are we trying to enable?
- What must be true for that capability to exist?
- What information does Lumen actually possess?
- What authority already exists?
- What facts are established?
- What assumptions are merely inherited from prior implementation, naming, convention, or intuition?
- What stronger behavior would require facts or authority Lumen does not currently possess?
- What can be removed while still satisfying the requirement?

Prefer questions such as:

```text
necessary?
rather than
possible?

earned?
rather than
convenient?

truthful?
rather than
richer?
```

A more feature-rich or theoretically complete model is not automatically more correct if Lumen does not own the required facts.

---

# 5. Repository-Evidence Discipline

Repository evidence comes before architectural certainty.

For each material claim, distinguish:

- **established repository fact**;
- **observed behavior**;
- **accepted contract**;
- **inference**;
- **current interpretation**;
- **open question**.

Do not strengthen evidence through wording.

Examples:

```text
persisted same-schema fixture
!=
authentic historical user state

property is optional
!=
ordinary product flow produces nil

UUID-shaped value
!=
one universal identity concept

current helper behavior
!=
complete domain semantic contract
```

When evidence is insufficient, narrow the claim rather than filling the gap with architecture.

External research may resolve a specific knowledge gap, but it does not replace Lumen-owned product semantics.

---

# 6. Minimum Sufficient Contract

For every public, persistent, architectural, or product-semantic commitment, ask:

> What is the smallest externally meaningful contract that satisfies the actual admitted requirement without inventing future obligations?

Test subtraction explicitly.

```text
Can this stronger guarantee be removed
while the required capability still works?
        ↓
yes
→ do not admit it yet

no
→ identify the requirement that earns it
```

This principle protects Lumen from confusing:

- more general with more correct;
- more durable with more authoritative;
- more reusable with more necessary;
- more expressive with more truthful.

A stronger future contract may always be admitted later when a real consumer earns it.

---

# 7. Assembly Map

A material proposal should identify its assembly relationships.

## 7.1 Prerequisite assemblies

What accepted semantic components does the proposal rely upon?

Do not silently redefine them.

## 7.2 New subassembly

What exact reusable capability or semantic contract is being introduced?

Name the smallest stable unit.

## 7.3 Consumers

Which later systems or features need this subassembly?

A consumer should justify the capability it actually needs, not hypothetical future machinery.

## 7.4 Unresolved dependencies

Which lower-level contracts remain unresolved?

A proposal may be blocked, provisional, or deliberately narrower because of them.

## 7.5 Irreversible commitments

What becomes harder to change after adoption?

Examples include:

- public file formats;
- persisted schema;
- external identifiers;
- migration semantics;
- privacy expectations;
- source-of-truth rules;
- destructive authority;
- interoperability guarantees.

## 7.6 Unused complexity

What machinery would this design introduce that no admitted consumer currently needs?

Unused complexity is not free merely because it might be useful someday.

---

# 8. Authority Budget

Every material proposal should ask:

> What new authority does this component gain, and what evidence or admitted contract earns that authority?

Core invariant:

> **No representation, identifier, inference, compatibility mechanism, restoration path, or implementation convenience gains authority beyond the evidence or admitted product contract that created it.**

Authority must be traceable to the evidence or governing contract that grants it.

Authority does **not** transfer automatically to intermediate or downstream components merely because they receive data from an authoritative source or context.

Preserve:

```text
possessing data
!=
inheriting the authority of its source
```

Examples of the intended discipline include:

```text
machine observation
!=
canonical financial authority

foreign provider convention
!=
Lumen-owned semantic authority

durable storage
!=
canonical financial authority

identifier equality
!=
overwrite/delete authority

restoration-specific authority
!=
ordinary creation authority

derived presentation
!=
domain-entity authority
```

If a proposal creates no new authority, say so.

If it creates new authority, identify the exact source that earns it.

---

# 9. Assembly Debt

**Assembly debt** exists when higher-level work depends on a lower-level semantic contract that has not actually been established.

Operational rule:

```text
Capability B depends on semantic component A
+
A remains unresolved
        ↓
B may be researched
but must not silently define A
through implementation accident
```

Typical warning patterns include:

- reconstructing relationships before identity semantics are defined;
- claiming deterministic serialization before lexical/order rules exist;
- designing synchronization before mutation/conflict authority exists;
- building advanced insights before canonical financial semantics are trustworthy;
- assigning machine confidence authority before the Draft/Review trust boundary is established.

Assembly debt should affect sequencing.

It is not automatically a reason to stop all research.

---

# 10. Assembly Pressure

Do not generalize a pattern after its first appearance.

A candidate reusable principle gains **assembly pressure** when:

```text
pattern appears independently
        ↓
appears again in another domain
        ↓
survives relevant counterexamples
        ↓
becomes candidate reusable principle
```

Formal rule:

> **Generalize only when multiple independent assemblies require the same substructure and the proposed abstraction survives relevant counterexamples.**

This protects Lumen from both premature abstraction and duplicated architecture.

A repeated implementation shape is not enough by itself. The underlying semantic requirement must also repeat.

---

# 11. Counterexample Test

Every proposed principle should ask:

> Where does this model fail?

A useful abstraction has a boundary.

Counterexamples help distinguish:

```text
reusable principle
from
universal rule
```

If a principle works for two domains but fails for a third, preserve the narrower boundary rather than forcing the third domain to fit.

A counterexample may strengthen a design by proving where it should stop.

---

# 12. Irreversible Commitments

Before accepting a public or durable contract, identify what becomes difficult to change.

Pay particular attention to:

- public lexical grammars;
- external identifiers;
- cross-version compatibility;
- data migrations;
- destructive behavior;
- source-of-truth rules;
- privacy/correlation surfaces;
- synchronization/update authority;
- cloud or provider dependencies;
- persisted user-state meaning.

The more irreversible the commitment, the stronger the evidence and review should be.

Prefer reversible internal choices until an irreversible public commitment is earned.

---

# 13. Independent Review and Admission Boundary

Reasoning quality does not authorize implementation.

A proposal may be:

- well reasoned;
- independently reviewed;
- accepted at a proposed-contract level;

while production implementation remains separately unauthorized.

Preserve the repository's existing distinctions among:

- research;
- proposal;
- accepted responsibility;
- exact admission;
- implementation plan;
- production implementation;
- validation/release acceptance.

If implementation discovers a contradiction with an admitted contract, return to the appropriate review boundary rather than silently widening the contract in code.

---

# 14. Methodology Evolution

Once accepted, this framework is intentionally living.

Lumen may refine its accepted reasoning methodology as the project learns.

However:

```text
methodology evolution
!=
automatic reopening of accepted decisions
```

A later framework revision governs:

- future proposals;
- future reviews;
- future admissions;
- work explicitly reopened for reconsideration.

It does not retroactively invalidate accepted architectural, product, admission, or implementation decisions.

Reopening substantive state requires the governing process appropriate to that state.

---

# 15. Anti-Ceremony Rule

The framework exists to expose reasoning, not to create completed forms.

Material work is deficient when it ignores an applicable question.

It is **not** deficient merely because an irrelevant heading is absent.

Avoid:

- empty `N/A` sections;
- numerical architecture scores;
- synthetic “assembly indices”;
- rote restatement of principles;
- adding governance files without demonstrated retrieval or maintenance value.

If parts of this framework become ritual rather than useful reasoning, simplify them.

---

# 16. When to Apply the Framework

Use the framework deliberately for work such as:

- architectural gates;
- new public contracts;
- source-of-truth changes;
- persisted-model or migration changes;
- major ingestion semantics;
- restoration authority;
- privacy/security authority;
- external file formats;
- durable identifiers;
- destructive behavior;
- phase transitions;
- major product subsystems;
- exact capability admissions.

Use lighter treatment for:

- typo fixes;
- routine implementation details already governed by an accepted contract;
- mechanical refactors with no semantic change;
- documentation maintenance that introduces no new authority or commitment.

---

# 17. Reasoning Framework Check

Material proposals should address the applicable questions below.

They need not reproduce every heading literally.

## First Principles

- User/product capability:
- Established facts:
- Assumptions/inferences:
- Minimum sufficient contract:
- Stronger behavior intentionally not admitted:

## Assembly Map

- Prerequisite assemblies:
- New subassembly:
- Known consumers:
- Unresolved dependencies:
- Irreversible commitments:
- Unused complexity intentionally excluded:

## Authority Budget

- New authority introduced:
- Evidence or contract that earns it:
- Authorities explicitly not granted:
- Does any authority risk transferring transitively through an intermediate component?

## Assembly Pressure

- Related prior patterns:
- Evidence for reuse:
- Reasons to keep this domain-specific:

## Counterexamples

- Cases where this reasoning does not apply:
- What those cases teach about the boundary:

## Assembly Debt

- Lower-level dependencies still unresolved:
- Higher-level work that must remain blocked or provisional:

---

# 18. Repository-First Handoff Principle

Lumen should remain understandable without requiring continuity from any particular chat, reviewer, agent, or developer.

Chats, prompts, generated summaries, and external discussions may be useful reasoning inputs.

They are not durable project authority.

Durable project understanding should be recoverable from the repository through:

- governing contracts;
- roadmap/scope documents;
- accepted decisions/admissions;
- implementation plans;
- executable evidence;
- knowledge synthesis;
- explicit proposal status.

A capable new reader should be able to determine:

```text
What must remain true?

What are we building now?

What is not currently authorized?

What evidence exists?

How should a new material decision be reasoned about?

What review/admission boundary applies before implementation?
```

That is the target for stateless, replaceable human and agent participation.

---

# 19. Framework Evaluation

The framework should be evaluated by use, not by elegance.

After material proposals use it, ask:

- Did it expose an assumption that would otherwise have remained hidden?
- Did it eliminate unnecessary complexity?
- Did it clarify authority?
- Did it reveal assembly debt?
- Did it improve sequencing or independent review?
- Did it create unreasonable ceremony?

Keep the parts that improve decisions.

Simplify the parts that become ritual.


---

# 20. Proposal Disposition

This document remains **PROPOSED FOR REVIEW**.

Independent review should decide whether it should be adopted as Lumen's living canonical development methodology and whether the linked README/Roadmap/knowledge routing changes are appropriately narrow.

No product invariant, Roadmap phase scope, implementation admission, production behavior, schema change, or code/test change is authorized by this proposal.
