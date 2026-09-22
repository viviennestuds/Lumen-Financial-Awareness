# Payment Instruments, Rewards & Benefits — Future Domain Vision

## Status

**Future-domain vision. Not current production scope.**

This document preserves a product and architecture direction that emerged from real Lumen use: reusable financial context is being lost because generic payment-method values are too coarse, forcing recurring structured meaning into free-text Notes.

A concrete example is a transaction recorded only as `Debit Card` while Notes carry information such as `2% cash back`. That context is useful enough to compare, filter, aggregate, explain, and eventually automate. It therefore deserves a deliberate future-domain model rather than repeated free text.

This document is subordinate to:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/ROADMAP.md`
- `docs/NON_GOALS.md`

It does not change the active phase or authorize implementation.

> **The conceptual entities in this document describe responsibilities. They do not authorize new persisted SwiftData models or a schema migration.**

The active production phase is Phase 1C — Ownership, Portability & Data Management.

---

## Purpose

Preserve the future responsibility boundaries for:

- specific payment instruments;
- reward and other program context;
- effective-dated rules;
- derived reward or eligibility evaluations;
- confirmed or realized outcomes;
- HSA/FSA reimbursement context;
- EBT/SNAP-related context;
- downstream financial-awareness experiences.

The goal is not to turn Lumen into a payment wallet, issuer database, tax authority, or generalized automation engine.

The goal is to let Lumen understand reusable financial context that is currently flattened into generic payment-method classifications or repeated Notes while preserving uncertainty, provenance, historical context, and user authority.

---

# Future-Domain Invariants

The following principles are mature enough to preserve now. They constrain future design without defining a persisted schema.

## 1. Generic Payment Type Is Not a Specific Payment Instrument

A generic type remains useful:

- Credit Card;
- Debit Card;
- Cash;
- Bank Transfer;
- HSA-related instrument;
- FSA-related instrument;
- EBT-related instrument;
- other future funding types.

But:

`Credit Card`

is not equivalent to:

`Fidelity Visa Signature`

and:

`Debit Card`

is not equivalent to:

`Upgrade Rewards Debit`.

A future transaction may therefore know both:

```text
Payment type:       Credit Card
Payment instrument: Fidelity Visa Signature
```

The current generic payment-method model remains valid as classification. This vision does not require replacing it now.

---

## 2. Ordinary Program Changes Are Effective-Dated and Non-Retroactive

Changing today's program rule must not silently rewrite the rule that applied to historical transactions.

Example:

```text
Reward rule v1
2%
effective Jan 1, 2026 through Feb 28, 2027

Reward rule v2
1%
effective Mar 1, 2027 onward
```

A September 2026 transaction remains evaluated against the first recorded rule context. An April 2027 transaction uses the second.

A different operation is an explicit correction of previously wrong historical knowledge.

Example:

```text
Recorded Sep 2026:
3% rewards, believed effective Jan 1

Corrected Dec 2026:
3% actually became effective Mar 1
```

That is a **historical-knowledge correction**, not a December program change.

Therefore:

> **Ordinary rule changes are effective-dated and non-retroactive. Retroactive changes require an explicit historical correction rather than silently editing the current rule.**

A historical correction may legitimately change later derived evaluations for the affected period because Lumen's recorded understanding of that period was corrected.

---

## 3. Recorded Program Context, Derived Evaluation, Realized Outcome, and Awareness Are Separate

A future Lumen domain must not collapse these responsibilities.

```text
Recorded program context
2% eligible-purchase rule
        ↓
Derived evaluation
Estimated reward eligibility: $2.00
        ↓
Realized outcome
Issuer actually awarded: $1.50
        ↓
Awareness
Explain the difference or surface a pattern
```

These facts may disagree without erasing one another.

A recorded rule can remain historically meaningful even when an individual transaction receives a different realized outcome because of an issuer classification, exclusion, cap, posting rule, promotion, or other program behavior.

Likewise, a derived estimate is not canonical Transaction truth merely because it is deterministic from currently recorded inputs.

If evaluations are ever persisted for auditability or performance, their provenance should identify the rule/context used rather than masquerading as fields intrinsic to `Transaction`.

---

## 4. Lumen Classifications Must Not Masquerade as External Program Classifications

A Lumen category such as:

`Groceries`

is a user/product classification.

It does not automatically mean that a card issuer, network, merchant-category-code system, HSA/FSA program, EBT/SNAP program, or other external authority classifies the same transaction in the same way.

A future result may therefore say:

> Likely eligible based on your Lumen category and saved program rule.

when external classification is not known.

Lumen must not silently turn its own category taxonomy into authoritative issuer/network/program classification.

---

## 5. Payment Instrument and Benefit / Program Eligibility Are Independent Dimensions

Using a particular instrument does not establish eligibility under a benefit program.

Examples:

```text
Paid with: Fidelity Visa Signature
Potential benefit: HSA reimbursement
```

is valid.

Therefore:

`HSA card used` ≠ `HSA eligible`

and:

`EBT instrument used` ≠ `item-level SNAP eligibility`.

HSA, FSA, EBT/SNAP, and future programs are not assumed to share one future persisted `BenefitContext` type. This document uses **Benefit / Program Context** as a responsibility label only.

The future design must remain capable of representing funding, eligibility, reimbursement, and program participation as related but non-identical facts.

---

## 6. Lumen Identifies Instruments for Analysis; It Does Not Store Payment Credentials

A future instrument identity may reasonably include data such as:

- display name;
- user nickname;
- generic instrument type;
- issuer;
- network;
- optional last four digits;
- active/archive status;
- non-secret program metadata.

Lumen must not become a payment credential store merely because it understands financial instruments.

Out of bounds for this future domain include:

- full primary account number / full card number;
- CVV/CVC;
- PIN;
- online-banking password;
- payment authorization secrets;
- authentication tokens whose possession enables payment use;
- credentials required to transact with the instrument.

The security boundary is:

> **Lumen may know enough to identify and analyze a financial instrument, but not enough to function as the payment instrument.**

---

# Conceptual Domain Shape

This diagram communicates responsibilities, not a proposed object graph:

```text
                         Transaction
                        /           \
                       /             \
          Payment Instrument     Benefit / Program Context
                  |                 /              \
       Program Context /       HSA / FSA        EBT / SNAP
        Reward Rules          reimbursement       context
                  |                 |
          Reward Evaluation    Eligibility candidates
                    \             /
                     \           /
                    Realized outcomes
                           ↓
                       Awareness
```

A second view emphasizes the future reward/program path:

```text
Specific Payment Instruments
            ↓
Effective-Dated Program Context / Rules
            ↓
Derived Reward & Benefit Evaluations
            ↓
Confirmed / Realized Outcomes
            ↓
Awareness
```

These are conceptual layers. They do not imply that each box becomes one Swift type, one SwiftData model, one table, one module, or one service.

---

# Temporal Semantics

Future program context has at least two conceptual clocks.

## Financial Applicability

When the recorded rule or program condition applies financially:

```text
effectiveFrom
effectiveUntil
```

## Lumen Knowledge History

When Lumen learned, recorded, or corrected that information:

```text
recordedAt
updatedAt
```

These are different questions.

A rule may have been financially effective in March but not recorded in Lumen until September. Lumen may then correct its understanding in December.

This distinction does **not** authorize or require a general bitemporal database architecture.

It exists to prevent future implementation from conflating:

- when something was true in the financial/program domain;
- when Lumen learned or changed its representation of that fact.

---

# Reward Evaluation Semantics

A bounded future reward domain may eventually evaluate a transaction against recorded program context.

Conceptually:

```text
Transaction
$22.00
Upgrade Rewards Debit

+

Recorded reward rule
2% on qualifying purchases

=

Derived evaluation
Estimated eligible reward: $0.44
```

The evaluation should remain explainable from its inputs.

A future UI should prefer language such as:

> Estimated reward eligibility based on your saved rules.

rather than claiming an issuer has awarded a reward when that outcome has not been confirmed.

A later issuer statement, import, or explicit user confirmation may establish a realized outcome separately.

---

# Benefit / Reimbursement Semantics

Benefit eligibility and reimbursement are separate from how the original transaction was paid.

Example:

```text
Walgreens — $70
Payment instrument: Fidelity Visa Signature

Reward context:
2% purchase candidate

Benefit / program context:
Potential HSA reimbursement

Reimbursement state:
Not yet reimbursed
```

Later evidence/item understanding might support a narrower candidate subtotal:

```text
Medication              $24   potential HSA candidate
First-aid supplies      $11   potential HSA candidate
Cosmetics               $35   no HSA designation

Potential candidate subtotal  $35
```

Lumen should remain conservative about regulated or tax-sensitive eligibility language. OCR, barcode, merchant, or product data may support **candidates** and user review; they do not automatically establish authoritative HSA/FSA/EBT/SNAP eligibility.

---

# Evidence & Provenance Connection

This future domain illustrates why Phase 1B's completed evidence/provenance contracts were designed to remain general enough to support financial knowledge beyond OCR-derived Transactions.

Possible future flows include:

```text
Issuer rewards statement
        ↓
EvidenceArtifact
        ↓
Observation
"Rewards earned: $38.42"
        ↓
association / candidate
        ↓
resolution
        ↓
Reward outcome
```

```text
Card-program terms
        ↓
EvidenceArtifact
        ↓
Observation
"2% on eligible purchases"
        ↓
Rule candidate
        ↓
review / resolution
        ↓
Recorded program context
```

```text
Walgreens receipt
        ↓
EvidenceArtifact
        ↓
item observations
        ↓
HSA/FSA eligibility candidates
        ↓
resolution
        ↓
Benefit / reimbursement context
```

These examples are future compatibility scenarios only.

**They do not authorize reopening or expanding the completed Phase 1B implementation into rewards, payment instruments, benefits, or generalized rules.**

---

# Potential Awareness Experiences

Structured instrument and program context could eventually support awareness such as:

- "70% of your Guilt-Free Spending used your Robinhood Gold Card.";
- "Your Fidelity Visa was your most-used grocery payment instrument this month.";
- "Based on the rules recorded for those purchase dates, $846 of spending was estimated rewards-eligible.";
- "An estimated $24.86 of grocery spending matched your saved Fidelity reward rules.";
- "Three purchases remain marked as potential HSA reimbursement candidates.";
- "Four purchases matched a higher saved reward rate on another instrument.".

The tone should remain awareness-oriented rather than punitive.

Preferred:

> You had another saved card with a higher estimated reward rate for four purchases.

Avoid:

> You used the wrong card four times.

The user decides how much optimization they want from this context.

---

# Roadmap Placement

This vision deliberately does not assign the full subsystem to one production phase.

A plausible future progression is:

- **Phase 1B** — evidence/provenance foundations only; no instrument/reward/benefit implementation;
- **Phase 1C** — potential evolution from generic payment-method reference values toward user-managed specific payment-instrument identity/management where warranted, including safe ownership/export/import semantics;
- **later domain work** — effective-dated program context, reward evaluation, benefit/reimbursement context, and realized outcomes;
- **Phase 4 or other downstream awareness work** — behavioral insights derived from those domains.

This is direction, not a delivery promise.

The canonical Roadmap controls actual production scope.

---

# Future Constraints / Open Design Questions

The following are important constraints but are **not frozen implementation decisions**.

## Rule Applicability Basis

Do not assume `Transaction.transactionDate` universally selects the applicable program rule.

A future program may depend on:

- purchase date;
- authorization date;
- posted date;
- statement period;
- program-specific events.

The correct applicability basis remains domain-specific and undecided.

## Rule Conflict Resolution

Overlapping exclusions, category bonuses, merchant overrides, promotions, caps, and base rules may conflict.

Future conflict resolution must be deterministic and explainable.

No precedence hierarchy is frozen here.

## Exact Money, Rounding, Caps, and Period Semantics

Specific payment-instrument identity does not by itself require migrating the current monetary representation.

A serious reward-accounting subsystem must reassess:

- exact monetary arithmetic;
- rounding rules;
- whether rounding occurs per transaction or per statement;
- caps and thresholds;
- statement-cycle accumulation;
- points versus cash values;
- conversion rates;
- promotional multipliers.

Phase 1A's decision not to perform a speculative money migration remains valid.

## External Classification

Future reward or benefit evaluation may need issuer/network/program classification that differs from Lumen's own category system.

How external classification is represented and sourced remains open.

## Provenance Quality

A user-entered rule, an issuer document, an imported statement, and a provider-supplied program record have different provenance.

Future design should preserve that difference rather than flattening every recorded rule into identical certainty.

## Persisted Evaluation Snapshots

Whether derived reward/benefit evaluations should be recomputed on demand or sometimes persisted with provenance remains open.

If persisted, a snapshot must not become canonical Transaction truth merely because it is stored.

## Realized Outcome Lifecycle

The exact lifecycle for confirmed rewards, reimbursements, redemptions, reversals, or adjustments remains undefined.

Do not freeze states prematurely.

## Shared Rule Infrastructure

Reward rules, reimbursement rules, merchant rules, and awareness rules may eventually reveal reusable primitives.

This document does **not** authorize or imply a generalized rules engine.

Shared infrastructure should be extracted only after repeated domain behavior demonstrates real commonality.

---

# Explicit Current-Phase Non-Goals

This vision is not automatically Phase 1C implementation scope.

Phase 1C does **not** automatically implement:

- the full specific-payment-instrument subsystem;
- a wallet/payment-accounts UI;
- reward calculation;
- reward-rule versioning;
- card-program automation;
- realized reward accounting;
- HSA/FSA eligibility logic;
- reimbursement automation;
- EBT/SNAP eligibility logic;
- generalized financial rules;
- issuer/network program classification;
- a persisted schema corresponding to the conceptual diagrams above.

The Roadmap permits Phase 1C to consider specific payment-instrument identity/management only where a concrete ownership, management, export, or import requirement earns that scope. The broader rewards/benefits/program domain remains later work.

Phase 1B evidence/provenance contracts remain frozen dependencies and may be consumed by later domains without being opportunistically redesigned.

---

# Open Product Questions

Questions intentionally deferred include:

- What user-facing term is clearest: Wallet, Payment Instruments, Accounts & Cards, Funding Sources, or another label?
- Which instrument attributes are valuable enough to justify durable storage?
- Should reward programs be instrument-owned, account-owned, issuer-owned, or modeled differently?
- How should archived/replaced instruments remain associated with historical transactions?
- Which kinds of realized outcomes are worth tracking manually before statement/import support exists?
- How much reward optimization belongs in Lumen before it stops feeling like awareness and starts feeling like a prescriptive optimization product?
- Which benefit/program contexts are sufficiently similar to share UI or domain behavior without falsely treating HSA/FSA/EBT/SNAP as identical systems?
- What evidence should support recorded program context before Lumen presents it with stronger confidence?

These questions should be answered when implementation pressure makes them concrete.

---

# Product Motivation to Preserve

The originating product observation is more important than any proposed type name:

> **Reusable financial context is being lost because today's generic payment-method values are too coarse, forcing recurring structured meaning into free-text Notes.**

The future opportunity is not merely "build a cashback engine."

It is to let Lumen represent reusable financial instruments, temporal program context, benefit/reimbursement context, and realized outcomes in ways that can later produce richer, explainable financial awareness without contaminating canonical Transaction truth.

Consistent with the discipline used to complete Phase 1B:

> **Earn abstractions through demonstrated domain behavior. Do not create persisted complexity merely because the conceptual model is cleaner.**
