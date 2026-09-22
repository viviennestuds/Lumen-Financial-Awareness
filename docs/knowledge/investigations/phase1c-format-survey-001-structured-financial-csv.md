---
id: investigation.phase1c-format-survey-001
title: Phase 1C format survey 001 — structured financial CSV
kind: investigation
status: resolved
confidence:
  structural_observations: high
  generic_mapping_implications: medium
created: 2026-09-22
reviewed: 2026-09-22
last_verified: 2026-09-22
platforms:
  - ios
related:
  - project.knowledge-system
evidence:
  - phase1c.format_survey_001
revisit_when:
  - a later foreign-CSV design claims assumptions contradicted by this survey
  - new format samples introduce materially different structural dimensions
---

# Phase 1C Format Survey 001 — Structured Financial CSV

## Summary

A private user-provided structured financial CSV was reviewed as Phase 1C format-survey evidence.

The original file contains personal financial information and is intentionally **not** committed, reproduced, transformed into a repository fixture, or treated as a provider-support specification.

The useful result is structural:

- a valid structured financial export can omit Currency;
- a valid structured financial export can omit Category;
- one signed Amount column can coexist with an independent transaction Type column;
- source Status vocabulary can contain values with no direct mapping to Lumen's current creatable canonical status domain;
- Date and Time may be separate source fields;
- a source can expose useful metadata that Lumen does not currently own as canonical Transaction semantics;
- blank/optional cells may coexist with otherwise parseable rows.

The survey supports the existing Phase 1C distinction:

```text
SOURCE VALIDITY
Can the source be parsed as the structure it claims to be?
        ↓
MAPPING / INTERPRETATION
Are the source values assigned unambiguous Lumen meanings?
        ↓
CANONICAL READINESS
Are all meanings required by Lumen confirmation resolved?
```

A "yes" at the first stage does not imply a "yes" at the later stages.

This survey did **not** reveal a need to reopen the accepted Phase 1C responsibility contract.

---

## Scope / Environment

### Observed

The reviewed source was a small CSV export from a financial account/card context.

Its header shape contained ten source columns:

- Date;
- Time;
- Cardholder;
- Amount;
- Points;
- Balance;
- Status;
- Type;
- Merchant;
- Description.

Across the reviewed rows:

- Amount values included both positive and negative signs;
- Status included more than one external state, including a successful/posted state and a declined state;
- Type included more than one external transaction kind, including purchase-like and payment-like values;
- Currency was absent as a column;
- Category was absent as a column;
- Balance could be absent on a row;
- Description could be absent on a row.

No personal row value is repository evidence.

### Not yet established

This survey does **not** establish:

- support for the source provider;
- a provider-specific adapter contract;
- a universal interpretation of source amount sign;
- a universal interpretation of external Payment, Purchase, Declined, or any other source value;
- that Points belongs in Lumen's canonical Transaction model;
- that Balance belongs in Lumen's canonical Transaction model;
- that Cardholder establishes PaymentMethod or payment-instrument identity;
- that Description maps to user-authored Notes;
- that foreign Date + Time should dictate the Lumen Portable v1 date shape;
- the correct generic mapping policy for unsupported external statuses;
- the PortableMoneyV1 magnitude, scale, or canonical-serialization domain;
- any requirement to add a SwiftData field or migration.

---

## Current Understanding

**Observation:** the source is structurally parseable while omitting semantics currently required for canonical Lumen confirmation.

**Current interpretation:** source validity, mapping interpretation, and canonical readiness must remain separate states. A row may be structurally valid while still requiring file-, column-, group-, or row-level resolution before it can become a READY Lumen transaction proposal.

**Observation:** Currency is absent from the source schema.

**Current interpretation:** a foreign structured import may legitimately need a file-level currency resolution. Lumen must not infer currency merely from device locale, provider identity, or another unstated assumption.

Conceptually:

```text
parseable rows
        ↓
Currency unresolved for the file
        ↓
one file-level user resolution
        ↓
affected proposals reevaluated
```

**Observation:** Category is absent from the source schema.

**Current interpretation:** absence of a source Category field does not make the CSV malformed. Under the current Lumen confirmation contract, Category remains a required canonical association and must be resolved upstream of confirmation.

> **Required canonical semantic does not imply required source-file column.**

**Observation:** signed Amount values coexist with an independent source Type field.

**Current interpretation:** source sign is evidence used during interpretation, not generic authority for Lumen transaction direction.

The mapping problem is closer to:

```text
source Amount
+ source Type
+ source Status
+ file/account semantics where established
        ↓
interpretation
        ↓
Lumen positive native magnitude
+ Lumen transaction type
+ Lumen canonical status
```

This survey does not define the interpretation rules.

**Observation:** an external status exists for which current Lumen transaction creation has no direct canonical status mapping.

**Current interpretation:** lack of a direct mapping must not be hidden by silently coercing the source event into `posted` or another creatable Lumen status.

This survey does not decide whether a later mapper should classify such a row as unsupported, exclude it, request explicit resolution, or handle it through another admitted capability.

**Observation:** the source provides Points, Balance, Cardholder, and raw Description context in addition to core transaction-like fields.

**Current interpretation:**

> **Source availability does not create canonical ownership.**

A source field can be useful without earning a field on canonical `Transaction`.

Examples of deliberately unearned conclusions include:

```text
Points
≠ automatically Transaction reward state

Balance
≠ automatically canonical account balance

Cardholder
≠ automatically PaymentMethod/payment-instrument identity

Description
≠ automatically user-authored Notes
```

Those domains require their own admitted semantics.

**Observation:** Date and Time are separate source columns.

**Current interpretation:** foreign temporal representation and Lumen portable temporal semantics must remain separate. A future mapper may need to interpret Date-only, Date + Time, dated posting fields, timestamps, settlement dates, or other provider concepts. The existence of one foreign shape does not define the guaranteed Lumen format.

---

## Evidence Index

| Evidence ID | Role | Evidence | Establishes | Does not establish |
| --- | --- | --- | --- | --- |
| `phase1c.format_survey_001` | Private structured-format survey | User-supplied CSV reviewed on 2026-09-22; original intentionally excluded from repository | The structural observations recorded in this note | Provider support, generic mapping behavior, canonical field additions, or PortableMoneyV1 precision/scale rules |

The private original is intentionally not a repository artifact.

This sanitized note is a distillation of structural observations, not a replacement copy of the source data.

---

## Evidence Tensions

No contradiction with the accepted Phase 1C responsibility contract was found.

The survey instead exposes expected tension between three valid facts:

1. the source can be structurally valid;
2. the source can omit semantics Lumen currently requires for confirmation;
3. Lumen must not invent those semantics merely to make an import succeed.

That tension is resolved through mapping/resolution and readiness, not through schema accretion.

A separate tension exists between useful source metadata and canonical ownership:

```text
source contains useful information
        ≠
Lumen currently owns a canonical semantic for it
```

The current guardrail is to preserve the information as survey evidence without promoting it into the portable or canonical schema merely because it is available.

---

## Current Guardrail

Format Survey Evidence 001 is **descriptive evidence only**.

It must not be used as authority for:

- provider-specific compatibility;
- a Robinhood or other named-provider adapter;
- required support for Points, Balance, Cardholder, Payment, Purchase, Declined, or any other surveyed source field/value;
- a new canonical Transaction property;
- a new PaymentMethod/payment-instrument identity rule;
- an importer implementation;
- a synthetic executable fixture unless a later test need actually earns one.

If a fixture is later required, construct it independently from the structural characteristics in this note. Do not redact, perturb, transform, or derive rows from the private source file.

Foreign-format survey evidence and PortableMoneyV1 characterization remain separate research tracks:

```text
FORMAT SURVEY
real foreign structured files
→ what ambiguity/messiness must future mapping tolerate?

PORTABLE-MONEY CHARACTERIZATION
controlled/generated probes
→ what exact monetary semantics can Lumen guarantee?
```

---

## Open Questions

- Which new structural dimensions will materially extend the foreign-format survey matrix?
- How should future mapping contracts classify external statuses with no direct creatable Lumen status?
- Which source concepts, if any, later earn canonical account, reward, payment-instrument, or provenance semantics?
- Which temporal source concepts are common enough to require reusable mapping responsibilities?
- When executable foreign-mapping tests are admitted, which minimal synthetic archetypes are justified?

These are not blockers for the proposed Lumen Portable JSON / CSV v1 format contract.

---

## Revisit When

Revisit this note when:

- a new real-world structured format introduces a materially different shape, such as Debit/Credit columns, per-row Currency, Transaction Date + Posted Date, description-only rows, account identifiers, or materially different quoting/encoding behavior;
- a foreign-CSV mapping contract is proposed;
- an implementation plan proposes an executable synthetic fixture;
- a proposed canonical field is justified primarily by "the source exports it."

Until then, this survey's role is complete: it challenged the Phase 1C abstractions with a real structured export and did not establish a need to redesign them.
