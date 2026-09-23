
---
id: investigation.phase1c-portable-money-magnitude-characterization
title: Phase 1C PortableMoneyV1 — decimal-exponent / magnitude characterization
kind: investigation
status: resolved
confidence:
  current_create_path_exponent_boundary: high
  durable_bit_preservation_inside_current_create_path: high
  raw_binary64_boundary_sampling: medium
  final_product_portable_envelope: unresolved
created: 2026-09-22
reviewed: 2026-09-22
last_verified: 2026-09-22
platforms:
  - ios-simulator
related:
  - project.knowledge-system
  - investigation.phase1c-portable-money-double-characterization
evidence:
  - phase1c.portable_money_magnitude.run2
revisit_when:
  - the PortableMoneyV1 product exponent/magnitude envelope is admitted
  - Money.magnitude or TransactionDraft amount validation changes
  - Transaction.amount storage changes
---

# Phase 1C PortableMoneyV1 — Decimal-Exponent / Magnitude Characterization

## Summary

This investigation characterizes the next PortableMoneyV1 money gate after normalized decimal precision was closed at the proposed-contract level.

The bounded question was:

> Given the proposed limit of at most 15 normalized significant decimal digits, what decimal-exponent / magnitude range can the current parse → Double → current Transaction validation → durable SwiftData save/reopen → candidate plain-decimal representation path preserve without underflow, overflow, monetary-value change, or current-domain rejection?

The investigation intentionally distinguishes:

    RAW BINARY64 CAPABILITY
    What the Double representation can parse/represent

    CURRENT LUMEN CREATE-PATH CAPABILITY
    What TransactionDraft.canConfirm currently admits

    PRODUCT PORTABLE ENVELOPE
    What Lumen should promise publicly

Those are not the same authority.

The decisive finding is:

> For the tested values with 1–15 normalized significant decimal digits, the current Lumen create path accepted the characterized values exactly when their normalized decimal exponent E was within -128...127.

That boundary was not imposed by raw binary64 magnitude.

It aligned with the current validation dependency:

    TransactionDraft.isValid
            ↓
    Money.magnitude(amount) != nil
            ↓
    Decimal(string: String(abs(amount)))

Apple documents the Foundation decimal representation used by NSDecimalNumber / bridged Decimal as a decimal integer mantissa of up to 38 digits with an exponent from -128 through 127.

The current implementation boundary therefore should not automatically become the PortableMoneyV1 public product envelope.

The public product envelope may legitimately be much narrower.

---

## Scope / Provenance

Branch:

    research/phase1c-portable-money-magnitude-characterization

The branch was created from the precision-complete proposed-contract head:

    de9663a5e594330560ea1e491c2fab170e323800

Successful characterization revision:

    c79db5b0216f7b6290b42c12a648a942f21ff905

GitHub Actions run:

    35809480138

Run conclusion:

    success

Run 1 (35809146162) failed during XCTest compilation before any characterization observation executed. It is a harness failure, not monetary evidence.

The diagnostic changed only an XCTest characterization file and a branch-specific GitHub Actions evidence workflow. It did not change production money storage, validation, schema, importer/exporter behavior, or serializer behavior.

---

## Definitions

The proposed PortableMoney normalized decimal definition remains:

For nonzero positive exact decimal value x:

    x = C × 10^E

where C is a positive integer not divisible by 10, E is the normalized decimal exponent, and normalized significant precision p is the base-10 digit count of C.

For magnitude discussion:

    A = E + p - 1

A is the ordinary scientific-notation power-of-ten position.

The distinction matters because one fixed normalized E range produces different adjusted magnitude ranges for different precisions.

---

## Exact Comparison Oracle

The earlier precision diagnostic used Foundation Decimal as its comparison oracle.

That is inappropriate for discovering exponent limits near raw binary64 boundaries because Foundation Decimal has its own finite exponent domain.

This magnitude diagnostic therefore compares exact normalized decimal pairs directly:

    input plain decimal
            ↓
    exact (C, E)
            ↓
    Double parse
            ↓
    candidate plain-decimal serialization
            ↓
    exact (C, E)
            ↓
    pair equality

No Foundation Decimal value is used as the equality oracle.

---

## Method

The diagnostic exercised normalized precision classes:

    1, 2, 5, 10, 15

For each precision it used three deterministic coefficient shapes.

The adjusted-exponent scan included:

- a broad range from approximately -330 through +310;
- dense coverage around raw binary64 lower and upper boundaries;
- dense coverage from -140 through +175 to resolve the current Transaction validation boundary.

Total probes:

    5,715

For each probe the test recorded:

- exact normalized input (C, E);
- parsed Double;
- underflow / overflow;
- test-only plain-decimal reserialization;
- exact normalized-value equivalence before persistence;
- Money.magnitude availability;
- TransactionDraft.canConfirm;
- inserted Double.bitPattern;
- reopened Double.bitPattern;
- exact normalized-value equivalence after reopen.

Create-valid values were committed through the real LedgerWrite / SwiftData disk-backed path and reopened.

---

## Run Result

Run 2 observed:

    total probes                         5,715

    pass                                 3,840
    current Money.magnitude rejected     1,708
    Double monetary-value changed           92
    Double overflow / nonfinite              40
    Double underflow to zero                 35

No successfully persisted probe produced a missing Transaction, a changed Double.bitPattern, or a post-persistence monetary-value change.

Within this bounded run:

> No successful probe showed SwiftData changing the stored binary64 value or the exact normalized decimal value represented by that binary64 value after reopen.

That is an observed result, not a universal persistence theorem.

---

## Raw Binary64 Observations

The raw Double path is much wider than the current Lumen create path.

The test recorded approximately:

    greatest finite     1.7976931348623157 × 10^308
    least normal        2.2250738585072014 × 10^-308
    least nonzero       5 × 10^-324

Near the lower subnormal region the diagnostic produced underflow and decimal monetary-value changes.

At adjusted exponent +308, some sampled coefficient/precision combinations overflowed while others remained finite.

At +309 and above in the tested region, all sampled values overflowed.

This is consistent with the established binary64 range model: DBL_MIN_10_EXP is -307 and DBL_MAX_10_EXP is 308, while the already-adopted DBL_DIG = 15 precision guarantee remains subject to range constraints.

References:

- Swift Double: https://developer.apple.com/documentation/swift/double
- C numeric limits: https://en.cppreference.com/w/c/types/limits
- C++ numeric_limits: https://en.cppreference.com/w/cpp/types/numeric_limits

The product contract should not use Double.greatestFiniteMagnitude as a financial product limit.

---

## Current Lumen Create-Path Boundary

Current validation requires:

    amount.isFinite
    && amount > 0
    && Money.magnitude(amount) != nil

Money.magnitude currently performs:

    Decimal(string: String(abs(amount)), locale: Locale(identifier: "en_US_POSIX"))

Apple documents NSDecimalNumber, which bridges with Swift Decimal, as representing a decimal integer mantissa up to 38 digits with decimal exponent from -128 through 127.

Reference:

https://developer.apple.com/documentation/foundation/nsdecimalnumber

### Observed boundary by normalized precision

| Normalized precision p | Adjusted exponent A all-pass range | Equivalent normalized exponent E |
| ---: | ---: | ---: |
| 1 | -128 ... 127 | -128 ... 127 |
| 2 | -127 ... 128 | -128 ... 127 |
| 5 | -124 ... 131 | -128 ... 127 |
| 10 | -119 ... 136 | -128 ... 127 |
| 15 | -114 ... 141 | -128 ... 127 |

The precision-dependent adjusted ranges collapse exactly to one normalized-exponent rule:

> Within the characterized coefficient/precision set, the current Lumen create/save/reopen path passed when normalized decimal exponent E was within -128...127.

If a later product rule wants one precision-independent adjusted-exponent ceiling across the entire proposed p <= 15 precision class, the intersection of the tested all-pass adjusted ranges is:

    -114 <= A <= 127

That adjusted-exponent intersection is conservative: it intentionally excludes some values that the current create path can handle at particular precisions. The normalized E rule remains the cleaner description of current implementation compatibility.

Immediately outside the per-precision boundaries, sampled values were rejected by the current Money.magnitude validation dependency even though many remained finite and monetarily equivalent as raw Double values.

This strongly indicates that the current create-path magnitude envelope is constrained by Foundation decimal conversion rather than raw binary64 range.

---

## Technical Safe Envelope vs Product Portable Envelope

### Technical current-create envelope

For the tested precision classes, the characterized current create/save/reopen envelope is:

    normalized significant precision <= 15

    AND

    normalized decimal exponent E within -128...127

This is an implementation compatibility boundary of the current Lumen path.

It is not a claim that binary64 cannot represent values outside it, and it is not a reason to make Foundation Decimal permanent PortableMoney authority.

### Product PortableMoneyV1 envelope

Still unresolved.

Lumen may intentionally choose a much smaller public financial domain than E = -128...127.

A personal-finance interchange format gains little practical value from promising enormous magnitudes merely because the current implementation can technically validate them.

The final product envelope should optimize for useful financial values, simple validation, predictable plain-decimal serialization, interoperability, manageable text sizes, future implementation portability, and truthful round-trip behavior.

> Technical capability is a ceiling, not the product promise.

No product maximum magnitude or final exponent range is admitted by this investigation.

---

## Existing Canonical State

A current or historical canonical Transaction may theoretically contain an amount outside the eventual PortableMoneyV1 product domain.

This investigation does not authorize export to round it, coerce it, substitute another value, or silently omit the Transaction.

The final out-of-domain export/round-trip disposition remains a separate admission decision.

---

## Contract Consequences

The smallest justified consequences are:

1. Define normalized exponent E as the clean technical axis for the current create-path range.
2. Record E = -128...127 as the characterized current create/save/reopen implementation envelope for the tested <=15-digit precision classes.
3. Do not equate that implementation envelope with the PortableMoneyV1 public product envelope.
4. Treat the final product exponent / maximum-magnitude envelope as a policy/admission decision that may be substantially narrower.
5. Do not infer a need for a storage migration.
6. Keep maximum scale, currency-specific scale, and exact canonical serializer separate.
7. Keep the historical out-of-domain disposition gate open.

---

## Evidence Index

| Evidence ID | Role | Repository / CI evidence | Establishes | Does not establish |
| --- | --- | --- | --- | --- |
| phase1c.portable_money_magnitude.run2 | Decimal-exponent / magnitude characterization | revision c79db5b0..., Actions run 35809480138 | sampled current create/save/reopen exponent boundary; normalized E=-128...127 collapse across tested precision classes; raw Double range materially wider; no persisted bit-pattern changes observed | final public product envelope, maximum scale, currency-specific scale, canonical serializer, currency registry |

Run 1 is excluded from monetary evidence because XCTest failed to compile before observations were produced.

---

## Current Guardrail

Do not turn the current Money.magnitude / Foundation Decimal validation boundary into the PortableMoneyV1 public specification merely because it is observable.

The portable contract owns financial interchange semantics.

Current implementation helpers are compatibility evidence, not permanent format authority.

Do not widen this investigation into maximum scale, currency minor-unit policy, currency registry membership, FX, serializer implementation, production validation changes, or storage migration.

---

## Revisit When

Revisit this investigation when:

- the final PortableMoneyV1 product exponent / maximum-magnitude envelope is proposed;
- current Money.magnitude or TransactionDraft validation changes;
- the language-independent canonical serializer is proposed;
- historical/out-of-domain export behavior is admitted;
- Transaction amount storage changes.

The bounded technical question is now answered well enough to move from numeric characterization to product-domain admission.
