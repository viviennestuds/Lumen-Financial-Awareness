# Lumen Portable v1 Category / PaymentMethod / Tag Complete-Export Set Semantics

## Status

**PROPOSED FOR REVIEW — Phase 1C ownership/export-set proposal.**

This document proposes only which durable `Category`, `PaymentMethod`, and `Tag` records belong in a **complete Portable JSON v1 ownership snapshot**.

It does **not** accept the full Portable JSON / CSV v1 contract and does not authorize production implementation.

Starting proposal-development baseline:

`67620ddc5773745db3dfed24d80a50aed4a60a16`

Branch:

gdocs/phase1c-portable-v1-reference-entity-export-set-proposal`

---

# 1. Decision question

For a complete Portable JSON ownership snapshot:

> **What exact set of durable Category, PaymentMethod, and Tag records belongs in the exported reference-data set independent of current Transaction reachability, how should seeded/default-like versus user-created state be treated where durable creation provenance is incomplete, and what exclusions—if any—are justified by Lumen's ownership contract rather than implementation convenience?**

This gate answers **record-set membership**.

It does not yet answer:

 - exact Category field schema;
- exact PaymentMethod field schema;
- exact Tag field schema;
- `created_at` inclusion/restoration semantics;
- exact lifecycle-timestamp spelling;
- importer conflict matching;
- overwrite/update authority;
- portable-ID allocation algorithm;
- emitted array ordering;
- `TransactionSource` export-set semantics;
- Source/provenance fields;
- schema or migration changes;
- production exporter/importer implementation.

---

# 2. Governing sources

This proposal is subordinate to:

1. `LUMEN_ARCHITECTURE_CONTRACT_V1.md`;
2. `PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`;
3. accepted Phase 1C Portable component contracts;
4. `LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`.

The Phase 1C responsibility contract defines Portable JSON as:

 > the normative, highest-fidelity portable representation of the durable state explicitly admitted to the current portability contract.

It also requires:

- included entities/fields to be documented;
- supported fields/entities to have defined round-trip guarantees;
- relationships within an export to remain resolvable;
- semantic similarity not to silently establish reference identity;
- coherent durable state to be exported.

The accepted Portable identity contract separately establishes:

```text
same display/content semantics
!!=
same portable identity

portable_id
!=
overwrite / update / deduplication authority
```

Those boundaries control this proposal.

---

# 3. First-principles statement

The irreducible ownership question is not:

> Which reference records happen to be reachable from a Transaction?

It is:

> Which durable reference records has Lumen admitted as part of the user's portable reference-data state?

A reachability graph can answer:

> Which Category / PaymentMethod / Tag is required to decode this Transaction?

It cannot by itself answer:

 ~ Which durable reference data belongs to a complete ownership snapshot? ~

Those are different responsibilities.

Preserve:

```text
relationship closure
!=
complete ownership scope
```

and:

```text
durable
!=
user-created
!0=
seeded/default-like
!=
referenced
!=
portable
```

The portability contract must decide the final predicate explicitly.

---

# 4. Repository evidence

## 4.1 Current durable models

Current SwiftData models define three ordinary reference families.

### Category

Current durable fields include:

- `id`;
- `name`;
- `group`;
- `color`;
- `icon`;
- `is_default`;
- `created_at`.

The initializer defaults:

```text
id = UUID().uuidString
is_default = true
created_at = .now
```

Therefore:

```text
Category.is_default == true
!=
proof of bootstrap provenance
```

The field may express a current product classification, but the initializer itself does not establish a seed-origin certificate.

### PaymentMethod

Current durable fields include:

- `id`;
- `name`;
- `method_type`;
- `institution_name`;
- `last_four`;
- `notes`;
- `is_active`;
- `created_at`.

The model has **no durable seed/user-origin field*.

### Tag

Current durable fields include:

- `id`;
- `name`;
- `color`;
- `created_at`.

The model has **no durable seed/user-origin field*.

Tags have an inverse relationship to Transactions, but a Tag can exist durably with zero Transactions.

## 4.2 Bootstrap behavior

`Seed.bootstrapIfNeeded()` independently checks whether each family is empty:

```text
Category count == 0
→
seed Categories

PaymentMethod count == 0
→
*seed PaymentMethods

Tag count == 0
→
seed Tags
```

The families are checked independently.

Current seed content includes approximately:

- 23 Categories;
- 7 PaymentMethods;
- 4 Tags.

The seed constructors use ordinary model initializers with installation-local UUID defaults.

Therefore two installations can independently produce:

```text
Store A
Tag("recurring")
id = UUID-A
Store B
Tag("recurring")
id = UID-B
```

The same is true for Categories and PaymentMethods.

Preserve:

```text
same seed name
!=
same object identity
```

## 4.3 Bootstrap happens during normal ledger open

`LumenFinanceApp.openLedger()` performs:

```text
LedgerStore.open()
        Ↄ
Seed.bootstrapIfNeeded(mainContext)
        Ↄ
application container becomes available
```

So a fresh ordinary installation is normally populated with reference defaults before ordinary user work.

A receiving installation may therefore already contain independently created, semantically similar reference records before a future Portable restoration workflow begins.

This is a downstream restoration/conflict fact.

It does **not** change what an exported object's identity means.

## 4.4 Zero-reference durable records are demonstrated current state

Reference seeding occurs even when there are zero Transactions.

gLedgerPersistenceTests.testSeedIdempotencyAndFailureRetryWithoutSamples()` verifies successful bootstrap while Transaction count remains zero.

The same test establishes:

- bootstrap is idempotent after successful seed;
- PaymentMethod count becomes 7;
- Tag count becomes 4;
- no sample Transactions are created.

Therefore:

 > **A durable Category / PaymentMethod / Tag with zero Transaction references is normal current Lumen state, not merely a hypothetical compatibility case.**

Transaction deletion tests also demonstrate that deleting a Transaction does not imply deleting the durable Tag familiy.

## 4.5 Current Transaction workflows consume reference records

Manual Entry, Review, and Transaction Detail query Categories, PaymentMethods, and Tags from SwiftData and attach them to Transaction drafts/records.

Current Transaction creation requires a Category.

PaymentMethod and Tags remain optional.

This establishes that reference records are durable reusable state independent of an individual Transaction.

## 4.6 Current production creation provenance is limited

No current ordinary reference-management surface was found in the inspected production paths for:

- creating a new Category;
- creating a new PaymentMethod;
- creating a new Tag;
- deleting these reference records;
- changing `PaymentMethod.is_active`.

The current app primarily consumes the bootstrap-created records.

Tests and model constructors demonstrate that custom model instances are structurally possible, and the Phase 1C responsibility contract explicitly allows future supported reference-entity creation after preview/confirmation.

Therefore classify evidence carefully:

```text
current production seeded durable records
→
demonstrated

zero-reference durable records
→
*demonstrated

custom/user-created records in ordinary current UI
➩
not demonstrated

edited seeded records in ordinary current UI
→
not demonstrated

inactive PaymentMethod in ordinary current UI
➩
not demonstrated

model-level ability to represent such states
→
demonstrated / structurally possible
```

This proposal must not fabricate present-day user-creation provenance merely because future Phase 1C workflows may admit it.

## 4.7 Empty-family behavior

A zero-count family is structurally possible in a store before bootstrap or after lower-level manipulation.

However normal app opening immediately calls `bootstrapIfNeeded()`, and an empty family is reseeded.

Therefore:

```text
durable family count == 0
```
is a meaningful format state that needs exact semantics, but it is not currently demonstrated as a stable ordinary post-bootstrap production condition.

The Portable contract should define the meaning of an empty array independently of whether current startup policy tends to repopulate that family.

---

# 5. Evidence taxonomy

## A. Demonstrated current durable production state

- seeded Categories;
- seeded PaymentMethods;
- seeded Tags;
- many zero-reference reference records;
- references from Transactions to some subset of those records;
- installation-local UUID identity;
- bootstrap when a family count is zero.

## B. Demonstrated durable/test state or structurally representable state

- custom Category/Tag objects created in tests;
- mutable Category / PaymentMethod / Tag fields;
- inactive PaymentMethod representation;
- duplicate/similar display names absent uniqueness constraints;
- zero-count family before bootstrap.

## C. Future-admitted responsibility but not current ordinary-production behavior

