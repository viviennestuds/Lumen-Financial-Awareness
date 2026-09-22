---
id: investigation.phase1c-portable-money-double-characterization
title: Phase 1C PortableMoneyV1 — current Double persistence characterization
kind: investigation
status: resolved
confidence:
  durable_double_bit_preservation: high
  direct_string_double_unsuitable: high
  sampled_15_digit_candidate_domain: medium
  exact_final_portable_domain: unresolved
created: 2026-09-22
reviewed: 2026-09-22
last_verified: 2026-09-22
platforms:
  - ios-simulator
related:
  - project.knowledge-system
  - investigation.phase1c-format-survey-001
evidence:
  - phase1c.portable_money.run2
  - phase1c.portable_money.run4
revisit_when:
  - PortableMoneyV1 precision/magnitude/scale rules are finalized
  - the canonical Transaction amount storage type changes
  - the canonical decimal serializer changes
---

# Phase 1C PortableMoneyV1 — Current Double Persistence Characterization

## Summary

This investigation characterizes the current durable `Transaction.amount: Double` path against the proposed PortableMoneyV1 monetary-value round-trip invariant.

It is non-production evidence.

It does **not** authorize:

- a `Transaction.amount` storage migration;
- importer/exporter implementation;
- a SwiftData schema change;
- workspace persistence;
- promotion-control persistence;
- format-contract acceptance;
- currency-registry membership;
- currency-specific scale rules;
- FX/valuation semantics.

The bounded question was:

> For candidate PortableMoneyV1 decimal values, does the current durable `Double` path preserve the monetary value required by the proposed portable round-trip contract?

The observed durable path was:

```text
candidate decimal text
        ↓
TransactionDraft amount parsing
        ↓
Transaction.amount: Double
        ↓
LedgerWrite / SwiftData durable save
        ↓
store close / reopen
        ↓
reopened Double
        ↓
candidate plain-decimal serializer
        ↓
Decimal monetary-value comparison
```

The most important findings are:

1. SwiftData did not change the persisted `Double` bit pattern for any create-valid probe observed in the successful characterization runs.
2. Direct `String(Double)` is unsuitable as the public PortableMoneyV1 serializer because it can emit exponent notation outside the proposed lexical grammar.
3. Expanding the shortest-round-trip Double spelling into normalized plain decimal eliminates that lexical problem in the tested domain, but it cannot recover decimal meaning already lost when a higher-precision decimal is converted into `Double`.
4. The refined precision-position sample had **522 / 522 passes for values characterized as 1–15 significant decimal digits**, **34 / 38 passes at 16 digits**, and **3 / 35 passes at 17 digits**.
5. Therefore the evidence supports a **15-significant-decimal-digit candidate safety boundary for further contract review**, but the test is sampled evidence, not an exhaustive proof over every possible decimal spelling.
6. Scale alone is not the storage-safety boundary: very small values through scale 18 passed when their significant precision remained small.
7. Magnitude alone is not the storage-safety boundary: some large values survive exactly while nearby values at the same apparent magnitude/scale do not.
8. Zero remains lexically parseable but is rejected by the current canonical Transaction creation domain.
9. Source lexical scale is not preserved by the current canonical amount representation: equivalent inputs such as `52.3`, `52.30`, and `52.300` collapse to the same durable monetary value.

The evidence demonstrates a useful bounded decimal domain. It does not demonstrate that arbitrary positive finite `Double` values are appropriate PortableMoneyV1 monetary facts.

---

## Scope / Environment

### Repository provenance

The characterization branch was created from the independently reviewed Portable v1 proposal head:

`d874564ed4e858ac63b3e11ac5be13115f842dde`

Branch:

`research/phase1c-portable-money-characterization`

No production Swift source, SwiftData model, or migration was changed for the characterization.

The executable diagnostic lives only in the XCTest target.

### Successful evidence revisions

#### Run 2 — direct String(Double) candidate

Revision:

`cfcf4f8bf5cdbd42062b6c518b5cd4d0d646c0e5`

GitHub Actions run:

`35775523069`

Purpose:

- test the exact durable save/reopen path;
- compare Decimal monetary value before and after persistence;
- intentionally test direct `String(Double)` as a candidate serializer;
- expose whether exponent notation or precision loss makes it unsuitable.

#### Run 4 — normalized plain-decimal candidate

Revision:

`bb247a322233977b2b3e5804148c5c3a9a637d58`

GitHub Actions run:

`35779607064`

Environment recorded by the run:

- runner image: `macos26`;
- runner image version: `20260907.0351.1`;
- macOS: `26.6.2`;
- Xcode: `26.6`, build `17F113`;
- iPhone Simulator SDK: `26.5`.

Purpose:

- retain the same durable path;
- replace direct exponent-bearing `String(Double)` output with a test-only normalized plain-decimal form;
- add very-small-value probes;
- add a significant-precision / decimal-position matrix;
- distinguish precision from scale and magnitude.

### Harness-only failures

Run 1 and Run 3 failed during XCTest compilation before characterization evidence executed.

Those failures were test-harness defects, not monetary counterexamples, and are not used as PortableMoneyV1 evidence.

---

## Method

### Candidate lexical domain

The diagnostic used the proposed lexical shape:

```text
[0-9]+(\.[0-9]+)?
```

with no:

- sign;
- currency symbol;
- grouping separator;
- exponent notation;
- locale comma;
- NaN/Infinity.

Lexical validity and canonical Transaction validity remained separate.

### Current creation path

For each probe, the diagnostic used the actual current `TransactionDraft` amount path rather than assigning directly to `Transaction.amount`.

The draft was supplied with:

- candidate decimal text;
- an admitted current currency context;
- a valid merchant;
- a real Category in the temporary SwiftData store;
- `expense` transaction type;
- `pending` status.

The diagnostic recorded whether `draft.canConfirm` accepted the value.

### Durable write / reopen

Create-valid Transactions were committed through `LedgerWrite.perform` into a temporary disk-backed SwiftData store.

The container was then released and reopened from the same store URL.

The diagnostic compared:

- inserted `Double.bitPattern`;
- reopened `Double.bitPattern`.

Any bit-pattern change would have been classified separately from decimal-conversion loss.

No such change was observed in the successful runs.

### Monetary comparison

The expected portable monetary value was parsed as Foundation `Decimal` using an `en_US_POSIX` locale.

After reopen, the candidate serializer produced decimal text, which was parsed back to `Decimal`.

Success meant:

```text
expected Decimal monetary value
==
serialized/reparsed Decimal monetary value
```

The comparison intentionally did **not** require preservation of source spelling.

### Serializer candidates

#### Run 2

```text
String(reopenedDouble)
```

This was intentionally tested rather than assumed suitable.

#### Run 4

The diagnostic:

1. started from Swift's shortest-round-trip Double spelling;
2. expanded exponent notation to ordinary decimal notation;
3. removed leading integer zeros except the single zero before a fractional amount;
4. removed insignificant trailing fractional zeros;
5. omitted the decimal point when no fractional digits remained.

This was a **test-only serializer candidate**.

The run does not establish Swift-specific formatting behavior as the public cross-implementation Portable v1 algorithm.

---

## Tested Domain

### Required/open-gate probes

The diagnostic included:

```text
0
0.00
0.01
0.001
52.3
52.30
52.300
12.345
987654321098.76
052.30
```

### Currency representation probes

The same structural money representation was exercised with:

- USD;
- EUR;
- JPY;
- KWD.

These are representation probes only.

They do not establish registry membership or currency-specific scale rules.

### Binary / precision boundary probes

The diagnostic included values around the exact-integer binary64 boundary, including:

```text
9007199254740990
9007199254740991
9007199254740992
9007199254740993
9007199254740994
```

and adjacent high-magnitude decimal values.

### Magnitude / integer-digit probes

The diagnostic sampled powers of ten and neighboring all-nine values through very large magnitudes.

### Integer-digit / scale matrix

Run 2 and Run 4 exercised a deterministic matrix spanning:

- integer-digit counts up to 18;
- fractional scales up to 9 where the bounded generator permitted;
- repeated patterned and deterministic generated values.

### Tiny-value probes

Run 4 explicitly included:

```text
0.0000001
0.000000000001
0.000000000000001
0.0000000000000001
0.00000000000000001
0.000000000000000001
```

All six passed the monetary-value comparison with the normalized plain-decimal candidate serializer.

### Precision-position matrix

Run 4 added a separate matrix designed to distinguish significant decimal precision from lexical scale.

It generated candidate values across:

- 1 through 17 significant decimal digits;
- multiple decimal positions ranging from subunit values through large integer magnitudes;
- deterministic variants per precision/position.

The successful run contained:

- **595 precision-position observations**;
- **522 observations at 1–15 significant digits**;
- **38 observations at 16 significant digits**;
- **35 observations at 17 significant digits**.

The generator is deterministic and bounded.

This is sampled characterization evidence, not exhaustive enumeration of the entire decimal space.

---

## Results

## Run 2 — Direct String(Double) Is Not the Portable Serializer

Run 2 observed:

```text
total probes                         1122
pass                                  815
monetary value changed                225
serializer emitted nonportable text    80
current create rejected                 2
```

The 80 nonportable lexical results came from exponent-bearing `String(Double)` output at sufficiently large magnitudes.

Therefore:

> **Direct `String(Transaction.amount)` must not be admitted as the PortableMoneyV1 canonical serializer.**

This closes that candidate.

It does not imply that `Double` storage itself is unusable.

---

## Run 4 — Normalized Plain-Decimal Candidate

Run 4 observed:

```text
total probes                1723
pass                         1385
monetary value changed        336
current create rejected         2
nonportable lexical output      0
```

The normalized plain-decimal candidate eliminated the exponent-notation lexical failures observed in Run 2.

The remaining failures were monetary-value changes caused before or during decimal-to-`Double` conversion, not SwiftData persistence changes.

### Durable bit preservation

For every create-valid probe that reached durable persistence:

```text
inserted Double.bitPattern
==
reopened Double.bitPattern
```

No persistence bit-pattern counterexample was observed.

This supports the narrower statement:

> **Within the tested envelope, SwiftData preserved the exact stored binary64 value across save, container release, and reopen.**

It does not establish that the stored binary64 value always equals the originally supplied decimal monetary value.

---

## Precision Result

Run 4 precision-position results were:

| Significant decimal digits | Pass | Monetary-value change | Total |
| ---: | ---: | ---: | ---: |
| 1–15 combined | 522 | 0 | 522 |
| 16 | 34 | 4 | 38 |
| 17 | 3 | 32 | 35 |

The first sampled precision band with direct counterexamples is therefore 16 significant decimal digits.

This supports a **candidate** Portable v1 storage-safety rule centered on no more than 15 significant decimal digits.

It does **not** by itself constitute an exhaustive mathematical proof that every possible <=15-digit decimal in every possible exponent position is safe.

Before final format acceptance, the contract must either:

- support the 15-digit bound with sufficient standards/reasoning evidence in addition to this characterization;
- define a stricter bounded magnitude/scale subset that is directly justified;
- or use another explicit admission rule that rejects values whose monetary meaning cannot survive the current storage path.

What the characterization does establish is that Portable v1 must **not** infer safety for arbitrary 16- or 17-digit decimal values merely because some individual values happen to survive.

---

## Counterexamples / Failure Boundaries

### Zero is outside current canonical creation

```text
"0"
"0.00"
```

were lexically parseable but rejected by current `TransactionDraft.canConfirm`.

This supports keeping lexical validity separate from Portable Transaction-domain validity.

### Source scale is not preserved

These inputs:

```text
52.3
52.30
52.300
```

all reached the same durable monetary value and the normalized candidate serializer emitted:

```text
52.3
```

Therefore current `Double` persistence cannot support a v1 promise that arbitrary source trailing-zero scale is preserved as transaction provenance.

### Leading zeros are not a persistence boundary

```text
052.30
```

was accepted by the current amount parser and normalized to the same monetary value as `52.3`.

This does **not** decide whether the public Portable v1 lexical contract should accept or reject leading zeros.

That remains a format-policy question.

### 2^53 boundary

The exact-integer sequence demonstrated the expected binary64 boundary behavior.

```text
9007199254740992
```

preserved its monetary value.

The adjacent value:

```text
9007199254740993
```

was parsed/stored/serialized as:

```text
9007199254740992
```

and was classified as a monetary-value change.

This is direct evidence that "positive finite Double" is much broader than a safe PortableMoneyV1 decimal domain.

### Same magnitude/scale can have different outcomes

The characterization also found nearby high-magnitude decimal values with the same apparent scale where one value survived and another changed.

That means:

> **Magnitude and scale alone do not fully characterize decimal-to-binary64 monetary preservation.**

Significant decimal precision is a more useful candidate axis, while magnitude and currency-specific scale still need their own product/format rules.

### Very small scale is not automatically unsafe

The explicit tiny probes through scale 18 passed with the normalized plain-decimal candidate serializer.

Therefore this characterization does not justify a storage-driven rule such as:

```text
maximum scale = 2
```

or:

```text
maximum scale = 3
```

Currency-specific minor-unit/scale policy remains separate research/admission work.

---

## Currency Probe Result

The USD, EUR, JPY, and KWD representation probes all passed the current durable path.

This establishes only that one structural representation:

```text
positive decimal magnitude
+
separate currency token
+
separate transaction type
```

works across those test contexts.

It does **not** establish:

- the complete Portable v1 currency registry;
- valid scale for any currency;
- minor-unit semantics;
- FX conversion;
- reporting-currency behavior.

---

## Current Interpretation

### What is now strongly established

- SwiftData persistence itself did not alter tested `Double` values.
- Direct `String(Double)` is not an acceptable Portable v1 serializer.
- Plain non-exponent decimal serialization is technically achievable without changing storage.
- Source trailing-zero scale cannot be promised as durable transaction meaning under the current representation.
- Zero remains outside current canonical Transaction creation.
- Arbitrary 16/17-digit decimal values cannot be admitted safely under the current path.
- A useful decimal domain exists without requiring an immediate storage migration.

### What is supported but not yet final

- no more than 15 significant decimal digits is a strong candidate storage-safe PortableMoneyV1 precision bound;
- a canonical serializer can normalize to plain decimal and omit insignificant trailing fractional zeros.

These require final contract review before becoming accepted Portable v1 rules.

### What remains open

The characterization does not settle:

- complete admitted-currency membership;
- currency-specific scale rules;
- maximum product-level magnitude;
- final maximum scale;
- leading-zero input policy;
- exact language-independent shortest-round-trip/plain-decimal serialization algorithm;
- transaction type/direction sufficiency;
- dates;
- identity;
- lifecycle timestamps;
- status compatibility;
- non-Transaction schemas.

---

## Contract Consequences

The smallest justified Portable v1 consequences are:

1. **Reject direct `String(Double)` as the canonical serializer.**
2. **Do not promise preservation of source trailing-zero scale.**
3. **Add significant decimal precision as an explicit monetary-domain axis.**
4. **Treat <=15 significant digits as the evidence-supported candidate bound, not yet an accepted universal guarantee.**
5. **Keep maximum magnitude and maximum scale gates open.**
6. **Keep currency-specific scale semantics open.**
7. **Do not infer a need for a money-storage migration from this evidence alone.**

The useful-domain branch of the responsibility contract's decision tree remains viable:

```text
current Double characterization
        ↓
useful bounded domain demonstrated
        ↓
continue PortableMoneyV1 contract refinement
        ↓
no migration authorized by characterization alone
```

A later review may still choose a narrower v1 domain for simplicity or product reasons.

---

## Evidence Index

| Evidence ID | Role | Repository / CI evidence | Establishes | Does not establish |
| --- | --- | --- | --- | --- |
| `phase1c.portable_money.run2` | Initial durable-money characterization | revision `cfcf4f8b...`, Actions run `35775523069` | SwiftData durable path exercised; direct `String(Double)` produces exponent lexical failures and decimal-value failures at higher precision | final serializer, final precision bound, migration requirement |
| `phase1c.portable_money.run4` | Refined precision characterization | revision `bb247a32...`, Actions run `35779607064` | normalized plain-decimal candidate removes lexical exponent failures; 522/522 sampled <=15-digit precision probes passed; 16/17-digit counterexamples exist; no tested Double bit pattern changed across persistence | exhaustive proof for all <=15-digit decimals, currency scale rules, final Portable v1 acceptance |

Run 1 and Run 3 are intentionally excluded from architectural evidence because the XCTest target failed to compile before observations were produced.

---

## Current Guardrail

Do not turn this characterization into a production money utility by copying the test helper into app code.

The candidate serializer exists to expose contract properties.

Production serialization requires a separately reviewed, language-independent Portable v1 rule.

Do not widen this evidence into:

- FX;
- currency registry decisions;
- calendar/recurrence semantics;
- importer implementation;
- schema migration;
- provider-format mapping.

---

## Revisit When

Revisit this investigation when:

- the proposed PortableMoneyV1 significant-precision rule receives independent review;
- a standards/reasoning pass is used to justify or reject the <=15-digit candidate bound;
- the exact language-independent canonical decimal serializer is proposed;
- a later format decision introduces a magnitude/scale constraint stricter than the storage characterization;
- `Transaction.amount` storage changes.

Until then, the characterization has answered its bounded question: the current `Double` path can support a useful exact portable-money subset without an immediate migration, but the portable format must explicitly bound decimal meaning rather than treating all current create-valid Double inputs as equally safe.
