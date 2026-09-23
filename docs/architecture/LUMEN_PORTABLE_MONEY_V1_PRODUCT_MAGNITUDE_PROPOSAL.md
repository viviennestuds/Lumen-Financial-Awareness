# Lumen PortableMoneyV1 Product Magnitude Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C product-domain admission proposal.**

This document does not change production validation, persistence, SwiftData schema, importer behavior, serializer behavior, or the canonical ledger.

It proposes only the **public upper magnitude ceiling** for PortableMoneyV1.

The lower/tiny-value side of the monetary envelope is intentionally not admitted here because the lower normalized exponent is inseparable from the still-open maximum-scale and currency-specific-scale contracts.

---

# 1. Decision Question

The completed magnitude characterization established that the current Lumen create/save/reopen path is technically capable of a decimal range far larger than any ordinary personal-finance product needs.

The remaining product question is therefore not:

> What is the largest value the current implementation can technically represent?

It is:

> What upper monetary magnitude should Lumen intentionally promise as part of its public PortableMoneyV1 contract?

The answer should be:

- simple to validate;
- simple to explain;
- large enough not to surprise ordinary or high-value personal-finance use;
- independent of one implementation helper's extreme numeric range;
- friendly to JSON/CSV interchange;
- compatible with the already-proposed <=15 normalized-significant-digit precision rule;
- conservative enough to keep pathological values outside the guaranteed v1 domain.

---

# 2. Existing Technical Evidence

The accepted technical characterization records:

- normalized significant decimal precision `p <= 15` as the proposed conservative precision class;
- current create/save/reopen compatibility for sampled values with normalized exponent `E = -128...127`;
- a precision-independent adjusted-exponent all-pass intersection of `A = -114...127`;
- raw binary64 capability materially wider than the product needs.

Definitions:

```text
x = C × 10^E

p = number of base-10 digits in C

A = E + p - 1
```

The technical evidence is a ceiling on what current behavior can support.

It is not product policy.

---

# 3. Proposed Public Upper Magnitude

## 3.1 Proposed rule

PortableMoneyV1 should admit only monetary values satisfying:

```text
x < 10^15
```

Equivalently:

```text
adjusted decimal exponent A <= 14
```

This is proposed in addition to, not instead of:

```text
normalized significant decimal precision p <= 15
```

The resulting upper-domain rule is therefore:

```text
0 < x < 10^15
AND
p <= 15
```

subject independently to the remaining currency, scale, serializer, and Transaction-domain requirements.

The upper magnitude ceiling is **currency-unit agnostic**. It limits the numeric amount expressed in the record's native currency; it does not define FX value, reporting currency, or cross-currency comparability.

---

# 4. Why 10^15

## 4.1 It aligns naturally with the 15-digit precision contract

The precision contract already defines a conservative maximum of 15 normalized significant decimal digits.

An upper magnitude of less than `10^15` means the whole-unit portion of an amount never needs more than 15 decimal positions before the decimal point.

That gives v1 a coherent relationship between:

- precision;
- magnitude;
- human-readable plain-decimal representation.

It avoids creating a public range whose ordinary integer spelling is dramatically larger than the precision class Lumen otherwise promises.

## 4.2 It leaves enormous product headroom

A value immediately below `10^15` is just under one quadrillion native currency units.

That is far beyond ordinary personal spending, income, account activity, budgets, purchases, reimbursements, transfers, and most high-value personal financial records.

The proposal therefore leaves substantial headroom without making implementation extremes part of the product contract.

## 4.3 It remains radically below the current technical ceiling

The current characterization found a current create-path normalized exponent capability extending to `E = 127`.

The proposed public upper bound ends at adjusted exponent `A = 14`.

Portable v1 would therefore intentionally expose only a tiny fraction of the technically available high-magnitude space.

That is desirable.

A portability contract should optimize for useful, reviewable financial data rather than maximum numeric reach.

## 4.4 It keeps plain-decimal interchange manageable

PortableMoneyV1 deliberately forbids exponent notation in the public amount grammar.

A product ceiling below `10^15` keeps the integer side of canonical plain-decimal output bounded and easy to inspect in:

- JSON;
- CSV;
- spreadsheets;
- logs;
- import review;
- human debugging.

The exact canonical serializer remains a separate open gate.

This proposal only makes its future output domain more manageable.

---

# 5. Why Not Use the Technical Maximum

The following must not become the public rule merely because they exist:

- `Double.greatestFiniteMagnitude`;
- Foundation Decimal's exponent range;
- the observed current-create `E = -128...127` envelope;
- the `A = -114...127` all-precision technical intersection.

Those values answer implementation-capability questions.

They do not answer what a personal-finance interchange contract should promise.

A public format gains little practical value from accepting hundred-digit-looking plain-decimal magnitudes while increasing:

- validation complexity;
- accidental-value risk;
- interoperability burden;
- review difficulty;
- future implementation obligations.

---

# 6. Why Not Choose a Much Smaller Ceiling Yet

A smaller ceiling such as `10^9` or `10^12` could cover most ordinary consumer activity.

However, those limits would create more product-specific exclusions without a demonstrated portability benefit.

Portable v1 must remain useful for:

- unusually high-value asset transactions;
- high-denomination native currencies;
- inherited/imported historical records;
- legitimate records whose scale is atypical but still understandable.

The proposed `10^15` ceiling is therefore intentionally generous while remaining simple and far below technical extremes.

If later product evidence shows that a smaller ceiling materially improves safety or interoperability, that would be a contract revision rather than an implementation accident.

---

# 7. The Lower Side Is Not Admitted Here

This proposal does **not** define a minimum positive PortableMoneyV1 magnitude.

For normalized value:

```text
x = C × 10^E
```

a lower bound on `E` directly constrains how many fractional decimal places a normalized value may contain.

That overlaps the still-open questions:

- global maximum scale;
- currency-specific scale;
- treatment of values beyond ordinary currency minor units.

Therefore this proposal intentionally does not claim:

```text
E >= some product minimum
```

The eventual lower monetary bound must be admitted together with, or consistently derived from, the scale contract.

This preserves the existing separation:

```text
UPPER MAGNITUDE
How large may the monetary value be?

SCALE / LOWER MAGNITUDE
How finely may the native currency amount be subdivided?
```

---

# 8. Interaction With Precision

The proposed upper magnitude and precision rules are independent predicates.

Examples:

```text
999999999999999
→ magnitude inside proposed ceiling
→ precision 15
→ eligible for the money-domain checks that remain

999999999999999.9
→ magnitude inside proposed ceiling
→ precision 16
→ outside proposed precision limit

1000000000000000
→ precision 1
→ but magnitude equals 10^15
→ outside proposed magnitude ceiling
```

This is intentional.

Precision answers how much decimal information the value carries.

Magnitude answers how large the monetary value is.

Neither substitutes for the other.

---

# 9. Interaction With Existing Canonical State

The already-admitted compatibility guardrail remains unchanged.

If a current or historical canonical Transaction contains an amount at or above the eventual public PortableMoneyV1 ceiling, export must not silently:

- round it;
- clamp it;
- replace it;
- coerce it;
- omit the Transaction.

The exact out-of-domain export/round-trip disposition remains a separate open gate.

This proposal does not authorize destructive normalization of existing canonical state.

---

# 10. Interaction With Currency

The ceiling is expressed in **native currency units**.

It does not imply that:

- one unit of every currency has equal economic value;
- cross-currency amounts can be compared directly;
- values should be converted before validation;
- FX belongs in PortableMoneyV1.

Portable v1 still records native denomination only.

A high-denomination currency may legitimately use more whole-number digits than another currency.

The generous `10^15` ceiling is partly intended to avoid making the public amount domain depend on one country's denomination scale.

Currency registry membership and currency-specific scale remain separate gates.

---

# 11. Alternatives Considered

## Alternative A — inherit current technical exponent capability

Example:

```text
E = -128...127
```

Disposition:

**Reject as product policy.**

Reason:

This is an implementation compatibility fact, not a useful personal-finance contract.

## Alternative B — use the common technical adjusted-exponent interval

Example:

```text
A = -114...127
```

Disposition:

**Reject as product policy.**

Reason:

It is still derived from implementation extremes and would allow enormous plain-decimal values with no demonstrated product benefit.

## Alternative C — upper bound below 10^12

Disposition:

**Defer / not preferred for v1 proposal.**

Reason:

It is plausible for ordinary consumer finance but creates unnecessary exclusions for atypical high-value or high-denomination records without a demonstrated interoperability benefit.

## Alternative D — admit values below 10^15

Disposition:

**PROPOSED.**

Reason:

It aligns with the 15-digit precision contract, remains human-manageable, offers enormous legitimate headroom, and stays radically below the current technical ceiling.

---

# 12. Proposed Contract Language

The PortableMoneyV1 contract should state:

> **PortableMoneyV1 uses a product upper magnitude ceiling of less than 10^15 native currency units, equivalent to adjusted decimal exponent A <= 14. This ceiling is independent of the <=15 normalized-significant-digit precision rule and remains subject to scale, currency, serializer, and ordinary Transaction-domain requirements.**

It should also state:

> **The current technical exponent envelope is compatibility evidence only and is not the public product range.**

And:

> **The lower/minimum positive monetary bound remains unresolved until the maximum-scale and currency-specific-scale contracts are admitted.**

---

# 13. What This Proposal Does Not Resolve

Still open:

- maximum scale;
- minimum positive portable magnitude;
- currency-specific scale semantics;
- admitted currency registry;
- exact canonical plain-decimal serializer;
- historical/current out-of-domain export disposition;
- transaction-type directional semantics;
- other non-money Portable v1 gates.

This proposal does not authorize implementation.

---

# 14. Review Questions

Independent review should answer:

1. Is `x < 10^15` sufficiently generous for a native-currency personal-finance interchange contract?
2. Is the alignment with the 15-digit precision limit a good reason to prefer `10^15` over a smaller arbitrary ceiling?
3. Should the public rule be expressed normatively as `x < 10^15`, `A <= 14`, or both?
4. Is it correct to leave the lower/minimum magnitude unresolved until the scale contract is admitted?
5. Does any existing canonical-state or currency-denomination concern require a different ceiling before this becomes normative?

Until that review is complete, the product upper magnitude ceiling remains **PROPOSED**, not accepted.
