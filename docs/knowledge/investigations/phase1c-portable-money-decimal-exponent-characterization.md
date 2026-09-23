---
id: investigation.phase1c-portable-money-decimal-exponent-characterization
title: Phase 1C PortableMoneyV1 — decimal exponent / magnitude characterization
kind: investigation
status: resolved
confidence:
  bounded_characterization: high
  binary64_range_interpretation: high
  current_lumen_path_envelope: high
  product_portable_envelope: unresolved
created: 2026-09-23
reviewed: 2026-09-23
last_verified: 2026-09-23
platforms:
  - ios-simulator
related:
  - project.knowledge-system
  - investigation.phase1c-portable-money-double-characterization
evidence:
  - phase1c.portable_money_magnitude.run2
revisit_when:
  - the PortableMoneyV1 product decimal-exponent / magnitude envelope is admitted
  - Money.magnitude or TransactionDraft amount validation changes
  - Transaction.amount storage changes
  - the exact canonical serializer changes
---

# Phase 1C PortableMoneyV1 — Decimal Exponent / Magnitude Characterization

## Summary

This investigation characterizes the decimal-exponent / magnitude dimension of the proposed PortableMoneyV1 domain **after** closing the precision question at a proposed conservative limit of at most 15 normalized significant decimal digits.

It deliberately separates:

```text
TECHNICAL REPRESENTATION ENVELOPE
What can binary64 parse/round-trip without overflow, underflow,
or monetary-value change?

CURRENT LUMEN CREATION ENVELOPE
What subset can today's TransactionDraft validation actually admit?

PRODUCT PORTABLE ENVELOPE
What conservative subset should Lumen promise publicly?
```

The third question is a product/admission decision and is **not** answered by this characterization.

The bounded diagnostic found:

```text
5,715 total probes

3,840   full current-path durable passes
1,708   rejected by current Money.magnitude / Decimal validation
92      decimal monetary-value changes during decimal -> Double conversion
40      Double overflow / non-finite parse results
35      Double underflow to zero
0       durable monetary-value changes after a create-valid save/reopen
0       persisted Double bit-pattern changes after a create-valid save/reopen
```

The most consequential result is that **binary64 is not the binding range constraint for current Lumen transaction creation**.

Current `TransactionDraft.isValid` requires:

```swift
Money.magnitude(amount) != nil
```

and current `Money.magnitude` converts the already-parsed `Double` through Foundation `Decimal`.

Foundation documents the bridged `NSDecimalNumber` representation as a decimal integer mantissa of up to 38 digits multiplied by `10^exponent`, with exponent from **-128 through 127**.

Given PortableMoneyV1's proposed precision limit of at most 15 normalized significant digits, that produces a conservative **all-precision current-path technical interval** in terms of adjusted decimal exponent:

```text
-114 <= A <= 127
```

where `A` is the adjusted decimal exponent defined below.

The characterization independently observed **all 15 sampled coefficient/precision probes passing at every densely tested adjusted exponent from -114 through 127**, with only partial current-path acceptance immediately outside that interval.

This technical interval is **not** the product PortableMoneyV1 public range.

Lumen may deliberately choose a much smaller product envelope.

---

## Decimal Exponent Terminology

The precision reconciliation defines a nonzero positive exact decimal value as:

```text
x = C × 10^E
```

where:

- `C` is a positive integer not divisible by 10;
- `E` is the normalized decimal exponent;
- `p = digits(C)` is normalized significant decimal precision.

For magnitude/range reasoning, this investigation additionally defines:

```text
A = E + p - 1
```

as the **adjusted decimal exponent**.

`A` is the base-10 exponent of the value's most significant decimal digit.

Examples:

```text
52.3
= 523 × 10^-1
p = 3
E = -1
A = 1

0.0000523
= 523 × 10^-7
p = 3
E = -7
A = -5

1200000000000000
= 12 × 10^14
p = 2
E = 14
A = 15
```

Adjusted exponent is useful because it separates overall order of magnitude from coefficient precision.

It does **not** replace scale.

---

## Scope / Environment

### Repository provenance

The magnitude-characterization branch was created from the precision-closed proposed-contract head:

`de9663a5e594330560ea1e491c2fab170e323800`

Branch:

`research/phase1c-portable-money-magnitude-characterization`

No production Swift source, SwiftData model, or migration was changed.

The executable diagnostic exists only in the XCTest target.

### Run 1 — harness-only failure

Revision:

`45ea75ba09667122c2bc76e4307a1e1b3460fa96`

GitHub Actions run:

`35809146162`

The XCTest target failed to compile because a test-only nested value type did not satisfy a declared `Hashable` conformance.

No magnitude probes executed.

Run 1 is not monetary evidence.

### Run 2 — successful magnitude characterization

Revision:

`c79db5b0216f7b6290b42c12a648a942f21ff905`

GitHub Actions run:

`35809480138`

Environment:

- runner image: `macos26`;
- runner image version: `20260907.0351.1`;
- macOS: `26.6.2`;
- Xcode: `26.6`, build `17F113`;
- iPhone Simulator SDK: `26.5`.

---

## Method

### Exact comparison oracle

The earlier precision characterization used Foundation `Decimal` as a convenient comparison oracle.

That would be inappropriate for this exponent/range investigation because Foundation Decimal's own exponent limits are part of what the current Lumen path is being characterized against.

Instead, this diagnostic compares exact normalized decimal pairs:

```text
(C, E)
```

A serialized value is monetarily equivalent only when it normalizes to the exact same coefficient and decimal exponent.

This lets the diagnostic distinguish:

- decimal -> binary64 information loss;
- binary64 underflow;
- binary64 overflow;
- current Foundation Decimal validation rejection;
- persistence/reopen behavior.

### Precision held constant as an admitted prerequisite

All generated values used normalized precision from:

```text
1, 2, 5, 10, 15 significant decimal digits
```

with three deterministic coefficient shapes per precision.

The investigation does not reopen the precision decision.

### Adjusted-exponent sampling

The diagnostic generated:

- a dense range from adjusted exponent `-140 ... 175`;
- a dense lower binary64-boundary range from `-325 ... -300`;
- a dense upper binary64-boundary range from `300 ... 310`;
- decade samples across the remaining broad range.

Total:

`5,715` probes.

### Current canonical creation path

For each probe the test exercised:

```text
plain decimal
        ↓
TransactionDraft.amountText
        ↓
Double(...)
        ↓
candidate plain-decimal round-trip comparison
        ↓
Money.magnitude(Double)
        ↓
TransactionDraft.canConfirm
        ↓ if admitted
Transaction
        ↓
LedgerWrite / SwiftData disk save
        ↓
container release + reopen
        ↓
same Double bit pattern?
        ↓
same normalized decimal value?
```

The serializer remained test-only evidence machinery.

No production serializer was implemented.

---

## Results

## Overall classifications

Run 2 produced:

| Classification | Count |
| --- | ---: |
| full durable pass | 3,840 |
| current `Money.magnitude` rejection | 1,708 |
| decimal -> Double monetary-value change | 92 |
| Double overflow / non-finite | 40 |
| Double underflow to zero | 35 |
| persistence bit-pattern change | 0 |
| post-reopen monetary-value change | 0 |

For every probe that was admitted by current creation and persisted:

```text
inserted Double.bitPattern
==
reopened Double.bitPattern
```

and the test-only canonical plain-decimal representation remained monetarily equivalent after reopen.

This extends the earlier persistence observation into the exponent/magnitude envelope actually reached by current creation.

It is still bounded evidence, not a universal theorem over every binary64 value.

---

## Binary64 Technical Context

The diagnostic recorded:

```text
Double.greatestFiniteMagnitude
≈ 1.7976931348623157 × 10^308

Double.leastNormalMagnitude
≈ 2.2250738585072014 × 10^-308

Double.leastNonzeroMagnitude
≈ 5 × 10^-324
```

Swift documents subnormal values as carrying less precision than normal values.

The observed lower boundary reflects that loss:

- sufficiently tiny values underflowed to zero;
- in the subnormal region, some <=15-digit decimal values changed monetary value;
- some sampled subnormal values still happened to round-trip exactly.

Therefore:

> **Subnormal representability is not the same thing as the conservative 15-digit decimal guarantee.**

At the upper edge:

- adjusted exponent 307 produced no sampled binary64 overflow/value-change observation;
- at adjusted exponent 308, 10 of 15 sampled probes overflowed to non-finite `Double`;
- at adjusted exponent 309 and above, the sampled probes overflowed.

Likewise, some lower adjusted exponents below the conservative normal-range boundary happened to survive.

Those successes do not enlarge the general PortableMoney guarantee.

The conservative binary64 precision/range reasoning remains distinct from the narrower current Lumen creation constraint described next.

References:

- Apple Swift `Double.greatestFiniteMagnitude`: https://developer.apple.com/documentation/swift/double/greatestfinitemagnitude
- Apple Swift `Double.leastNormalMagnitude`: https://developer.apple.com/documentation/swift/double/leastnormalmagnitude
- Apple Swift `Double.leastNonzeroMagnitude`: https://developer.apple.com/documentation/swift/double/leastnonzeromagnitude
- C++ numeric-limit terminology: https://en.cppreference.com/w/cpp/types/numeric_limits

---

## Current Lumen Creation Envelope

Current `TransactionDraft.isValid` requires:

```swift
amount.isFinite
&& amount > 0
&& Money.magnitude(amount) != nil
...
```

and current `Money.magnitude` is:

```swift
Decimal(
    string: String(abs(amount)),
    locale: Locale(identifier: "en_US_POSIX")
)
```

Foundation documents the `NSDecimalNumber` representation bridged by Swift `Decimal` as:

```text
mantissa × 10^exponent
```

with:

- a decimal integer mantissa up to 38 digits;
- decimal exponent from `-128` through `127`.

Reference:

https://developer.apple.com/documentation/foundation/nsdecimalnumber

For normalized PortableMoney:

```text
x = C × 10^E
p = digits(C)
A = E + p - 1
```

and:

```text
1 <= p <= 15
```

To guarantee Foundation Decimal exponent compatibility for **every admitted precision**:

Lower side:

```text
E >= -128

A = E + p - 1

worst admitted precision p = 15

A >= -128 + 15 - 1
A >= -114
```

Upper side:

```text
E <= 127

worst case for adjusted exponent is p = 1

A <= 127
```

Therefore the conservative current-path all-precision interval is:

```text
-114 <= adjusted decimal exponent A <= 127
```

The dense characterization independently matched that derivation:

- every one of the 15 sampled coefficient/precision probes passed at every adjusted exponent from `-114` through `127`;
- below `-114`, progressively fewer high-precision values passed current `Money.magnitude`;
- above `127`, progressively fewer low-precision values passed;
- by adjusted exponent `142`, all 15 sampled values were rejected by current `Money.magnitude`.

This establishes an important architecture distinction:

```text
binary64 can represent the value
        ≠
current Lumen TransactionDraft can confirm the value
```

---

## Technical Safe Envelope vs Product Portable Envelope

### Current-path technical envelope

For the already-proposed precision class:

```text
1 <= normalized significant precision <= 15
```

the strongest current evidence-supported **common** adjusted-exponent interval that is compatible with:

- decimal -> binary64 monetary-value preservation;
- current `Money.magnitude` validation;
- current `TransactionDraft.canConfirm`;
- durable SwiftData save/reopen;
- the test-only plain-decimal round-trip check;

is:

```text
-114 <= A <= 127
```

This is a technical upper envelope for current behavior.

It is not a recommendation that PortableMoneyV1 expose that entire range.

### Product Portable envelope

**RESEARCH / ADMISSION REQUIRED.**

A personal-finance interchange contract can deliberately choose a much narrower public magnitude envelope.

A narrower range may improve:

- validation clarity;
- human reviewability;
- cross-language implementation simplicity;
- canonical serializer behavior;
- interoperability with other financial systems;
- protection against absurd or accidental values.

Therefore:

> **Technical representability establishes an upper boundary, not product value.**

The final PortableMoneyV1 public range should be selected intentionally rather than inheriting Foundation Decimal or binary64's extreme limits merely because they exist.

---

## Existing Canonical State

The format contract already requires an explicit disposition for current or historical canonical amounts that fall outside the eventual PortableMoneyV1 admitted domain.

This investigation reinforces that requirement.

The eventual product envelope may be much narrower than:

```text
-114 <= A <= 127
```

and historical/directly persisted state may theoretically exist outside it.

Export must not silently round, coerce, substitute, or omit such Transactions merely to force conformance.

The magnitude investigation does not resolve that compatibility policy.

---

## Contract Consequences

The smallest justified consequences are:

1. **Define adjusted decimal exponent** as `A = E + p - 1` for range/magnitude reasoning.
2. **Distinguish binary64 range from current Lumen creation range.**
3. **Record `-114 <= A <= 127` as the evidence-supported conservative all-precision current-path technical envelope under today's `Money.magnitude` validation and proposed `p <= 15` precision rule.**
4. **Do not make that entire technical envelope the public PortableMoneyV1 range automatically.**
5. **Change the final product decimal-exponent / magnitude envelope from an empirical storage question into a product/admission decision bounded by current technical behavior.**
6. **Keep maximum scale separate.**
7. **Keep currency-specific scale separate.**
8. **Keep the exact canonical serializer separate.**
9. **Keep historical out-of-domain disposition separate.**
10. **Do not infer a money-storage migration from this characterization.**

---

## Evidence Index

| Evidence ID | Role | Repository / CI evidence | Establishes | Does not establish |
| --- | --- | --- | --- | --- |
| `phase1c.portable_money_magnitude.run2` | Primary decimal-exponent/magnitude characterization | revision `c79db5b0...`, Actions run `35809480138` | sampled binary64 boundary behavior; current `Money.magnitude` restriction; all sampled variants pass from adjusted exponent -114 through 127; no observed post-save/reopen bit/value change for admitted probes | final product public range, maximum scale, currency scale, serializer algorithm, historical compatibility policy |

Run 1 is excluded from monetary evidence because the XCTest target failed to compile before probes executed.

---

## Current Guardrail

Do not interpret:

```text
-114 <= A <= 127
```

as a product requirement to support financial values anywhere near those extremes.

It is a characterization of the **current implementation's common technical envelope** under the proposed precision class.

Do not widen this investigation into:

- maximum-scale policy;
- currency-specific minor units;
- currency registry;
- FX;
- serializer implementation;
- importer implementation;
- money-storage migration.

---

## Revisit When

Revisit this investigation if:

- the product PortableMoneyV1 decimal-exponent/magnitude envelope is admitted;
- `Money.magnitude` stops using Foundation `Decimal`;
- `TransactionDraft` amount validation changes;
- `Transaction.amount` storage changes;
- a future serializer imposes a stricter magnitude envelope.

Until then, the technical range question is answered well enough to stop testing binary64 extremes.

The next work is a product-format admission decision:

> **What much smaller decimal-exponent / magnitude range should Lumen actually promise as PortableMoneyV1?**
