# Lumen PortableMoneyV1 Scale and Lower-Magnitude Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C money-domain admission proposal.**

This document does not change production validation, persistence, SwiftData schema, amount-entry behavior, currency formatting, importer behavior, serializer behavior, or the canonical ledger.

It proposes:

- a global **normalized structural scale ceiling** for PortableMoneyV1;
- the minimum positive magnitude implied by that structural ceiling;
- the boundary between global structural scale and still-open currency-specific scale semantics.

It does **not** admit per-currency minor-unit rules.

---

# 1. Decision Question

The previously accepted product proposal now gives PortableMoneyV1 a proposed public upper monetary magnitude:

    0 < x < 10^15

with:

    normalized significant decimal precision p <= 15

The lower/tiny-value side remains open because a lower normalized decimal exponent is a scale decision in disguise.

The next product question is therefore:

> How many normalized fractional decimal places should PortableMoneyV1 permit structurally before currency-specific semantics are considered?

The answer should:

- preserve a useful compatibility envelope for existing canonical state;
- remain independent from one currency's ordinary minor unit;
- keep plain-decimal JSON/CSV representation bounded;
- avoid implying that source lexical trailing zeros are semantic;
- leave exact currency-specific acceptance/readiness policy for the currency contract;
- compose mechanically with the existing normalized `(C, E)` representation.

---

# 2. Definitions

PortableMoneyV1 already defines every nonzero positive exact decimal value as:

    x = C × 10^E

where:

- `C` is a positive integer;
- `C` is not divisible by 10;
- `E` is the normalized decimal exponent;
- `p = digits(C)` is normalized significant decimal precision.

This proposal defines **normalized scale**:

    S = max(0, -E)

Examples:

    52.300
    → 523 × 10^-1
    → E = -1
    → normalized scale S = 1

    0.00100
    → 1 × 10^-3
    → E = -3
    → normalized scale S = 3

    1200000000000000
    → 12 × 10^14
    → E = 14
    → normalized scale S = 0

Normalized scale is a property of the exact mathematical decimal value after nonsemantic trailing zeros are removed.

It is **not** the number of fractional digit characters originally supplied.

---

# 3. Proposed Global Structural Scale

PortableMoneyV1 should use:

    normalized scale S <= 9

Equivalently:

    normalized decimal exponent E >= -9

for the global structural money-domain rule.

This proposal combines with the already-proposed upper magnitude and precision rules:

    0 < x < 10^15
    p <= 15
    S <= 9

or equivalently:

    0 < x < 10^15
    p <= 15
    E >= -9

subject independently to:

- currency-specific scale semantics;
- admitted currency membership;
- exact canonical plain-decimal serialization;
- Transaction-domain requirements;
- historical/out-of-domain disposition.

---

# 4. Implied Minimum Positive Magnitude

Given:

    C >= 1
    E >= -9

the smallest structurally admitted positive value is:

    1 × 10^-9

Therefore the proposed global structural money domain has:

    10^-9 <= x < 10^15

before currency-specific constraints are applied.

This is a structural PortableMoneyV1 boundary.

It does **not** mean every admitted currency is economically divisible into 10^-9 units.

---

# 5. Why Scale 9

## 5.1 It preserves a known repository compatibility class

The current Phase 1A test suite deliberately verifies that an unrelated edit preserves a legacy canonical amount:

    12.345678901 KWD

without rewriting its amount.

That value has:

    normalized scale = 9

The test exists to protect existing canonical precision from accidental normalization during unrelated edits.

A global structural ceiling below 9 would therefore classify a known repository compatibility case as outside the portable structural domain immediately.

That would be possible, but it would require a stronger product reason than currently exists.

Choosing 9 avoids creating that exclusion at the global structural layer.

This does **not** claim that nine fractional digits are ordinary KWD currency semantics.

## 5.2 It is deliberately wider than ordinary currency fraction conventions

Unicode CLDR publishes currency-fraction metadata used by major software platforms.

Current examples include:

- JPY: 0 fraction digits;
- USD: 2;
- KWD: 3;
- UYW: 4.

CLDR specifies a default currency fraction-digit count of 2 when a currency has no specific override.

References:

- Unicode LDML currency data: https://www.unicode.org/reports/tr35/tr35-numbers.html
- Unicode detailed currency information: https://unicode.org/cldr/charts/latest/supplemental/detailed_territory_currency_information.html

A structural ceiling of 9 is therefore intentionally **not** a statement about ordinary minor units.

It provides compatibility headroom above conventional currency formatting while preserving a bounded public decimal domain.

## 5.3 It remains easy to serialize and review

At most nine normalized fractional positions is small enough that canonical plain-decimal representations remain straightforward in JSON, CSV, spreadsheets, import review, debugging, and future cross-language implementations.

The exact serializer is still open.

This proposal only bounds the representation it will eventually need to produce.

## 5.4 It stays far inside the characterized technical envelope

The technical magnitude investigation observed current create/save/reopen compatibility for normalized exponent:

    E = -128...127

across the characterized precision classes.

The proposed lower structural exponent:

    E >= -9

is therefore radically more conservative than the current implementation's technical lower exponent capability.

This is a product choice, not a storage limitation.

---

# 6. Why This Is Not a Currency Minor-Unit Rule

The global structural rule answers:

> Can this decimal amount participate in PortableMoneyV1's public numeric representation at all?

It does not answer:

> Is this amount semantically ordinary or READY for this particular currency?

Those responsibilities must remain separate.

Conceptually:

    GLOBAL STRUCTURAL SCALE
    S <= 9
            ↓
    CURRENCY-SPECIFIC SEMANTICS
    still to be admitted
            ↓
    canonical readiness / import behavior
    still to be admitted

A value such as:

    12.345 KWD

may eventually align naturally with a currency-specific three-digit convention.

A value such as:

    12.345678901 KWD

would still be structurally representable under the proposed global ceiling, but this proposal does **not** decide whether future KWD-specific rules accept it directly, require resolution, treat it as historical-only portable state, reject it for new import confirmation, or apply another explicit policy.

That decision belongs to the currency-specific scale gate.

---

# 7. Source Lexical Scale Remains Nonsemantic

These spellings:

    52.3
    52.30
    52.300000000

represent the same normalized value:

    523 × 10^-1

and therefore all have:

    normalized scale = 1

PortableMoneyV1 must not reject or admit a mathematical amount based solely on nonsemantic source trailing zeros.

The eventual canonical serializer may choose one deterministic spelling.

That serializer remains a separate gate.

---

# 8. Interaction With Precision

Scale and precision remain independent predicates.

Examples:

    0.123456789
    → S = 9
    → p = 9
    → inside proposed structural scale and precision ceilings

    0.1234567890
    → same normalized value
    → S = 9
    → p = 9
    → same structural result

    0.1234567891
    → S = 10
    → p = 10
    → outside proposed structural scale ceiling

    123456789012345.1
    → S = 1
    → p = 16
    → scale allowed
    → precision disallowed

    0.000000001
    → S = 9
    → p = 1
    → smallest proposed structurally admitted positive magnitude

    0.0000000001
    → S = 10
    → outside proposed structural scale ceiling

---

# 9. Interaction With Upper Magnitude

The current proposed product money envelope becomes:

    10^-9 <= x < 10^15
    p <= 15

at the global structural level.

This remains a conjunction of distinct rules.

---

# 10. Existing Canonical State

Current production creation does not enforce a nine-place scale rule.

Therefore canonical Transactions may theoretically exist with normalized scale greater than 9.

The existing compatibility guardrail applies unchanged.

Export must not silently round, truncate, clamp, coerce, substitute, or omit an existing canonical amount merely to force it into `S <= 9`.

The final historical/current out-of-domain disposition remains separately open.

---

# 11. Current UI and Display Behavior Are Not Portable Authority

Current manual amount entry parses decimal text into `Double` without a currency-specific scale check.

Current display formatting uses Foundation currency formatting behavior.

Neither implementation detail becomes the public PortableMoneyV1 scale contract automatically.

In particular:

- a keyboard allowing many decimal digits does not make every scale public-format-valid;
- a formatter displaying a currency with fewer digits does not authorize destructive rounding of stored canonical value;
- device/OS currency metadata must not become the unversioned portable authority.

The portable contract must own its scale semantics explicitly.

---

# 12. Alternatives Considered

## Alternative A — global maximum scale 3

Disposition: **Not proposed.**

This covers common 0/2/3-digit currency conventions, including JPY/USD/KWD-style cases, but is too narrow for known four-digit CLDR units and would immediately exclude the repository's preserved nine-place legacy compatibility case.

## Alternative B — global maximum scale 4

Disposition: **Not proposed.**

This better spans current CLDR currency-fraction examples such as UYW and CLF-style four-digit units, but still classifies the repository's explicitly preserved nine-place canonical compatibility case outside the structural domain.

## Alternative C — global maximum scale 9

Disposition: **PROPOSED.**

This preserves the known repository nine-place compatibility class structurally, remains bounded and human-manageable, leaves substantial room above conventional currency fraction digits, and does not pre-decide the currency-specific scale contract.

## Alternative D — no global structural scale ceiling

Disposition: **Reject for Portable v1.**

Without a structural scale ceiling, PortableMoneyV1 would leave its minimum positive magnitude effectively unbounded until raw technical underflow limits, undermining predictable validation and plain-decimal interoperability.

---

# 13. Proposed Contract Language

PortableMoneyV1 should state:

> **PortableMoneyV1 uses a global normalized structural scale ceiling of 9 fractional decimal places. For normalized form `x = C × 10^E`, normalized scale is `S = max(0, -E)`, and the structural rule is `S <= 9`, equivalently `E >= -9`.**

It should also state:

> **The resulting minimum structurally admitted positive magnitude is `10^-9` native currency units. This is a global numeric-format boundary, not a declaration that every admitted currency supports nine fractional units.**

And:

> **Currency-specific scale/minor-unit semantics remain a separate PortableMoneyV1 admission contract and may be stricter than the global structural ceiling.**

---

# 14. What Remains Open

This proposal does not resolve:

- per-currency fraction-digit rules;
- whether exceeding a currency's ordinary scale is INVALID, NEEDS RESOLUTION, historical-only, or otherwise admitted;
- admitted currency registry membership;
- treatment of special/fund/unit currency codes;
- exact canonical plain-decimal serializer;
- historical/current out-of-domain export disposition;
- leading-zero lexical policy;
- transaction-type direction semantics;
- other non-money Portable v1 gates.

---

# 15. Review Questions

Independent review should answer:

1. Is normalized scale `S = max(0, -E)` the correct implementation-independent scale definition?
2. Is a global structural ceiling of `S <= 9` appropriately conservative while preserving known canonical compatibility?
3. Is deriving a structural minimum positive magnitude of `10^-9` correct?
4. Is it sufficiently explicit that nine digits are **not** a per-currency minor-unit promise?
5. Should the known nine-place legacy compatibility case influence the global structural ceiling, or should it instead be handled only through the historical out-of-domain policy?
6. Should the next distinct gate be the currency-specific scale/minor-unit registry policy rather than more numeric characterization?

Until independent review is complete, `S <= 9` / `E >= -9` remains **PROPOSED**, not accepted.
