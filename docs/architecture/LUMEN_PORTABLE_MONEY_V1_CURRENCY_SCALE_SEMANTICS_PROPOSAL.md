# Lumen PortableMoneyV1 Currency Scale / Minor-Unit Semantics Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C money-domain admission proposal.**

This document does not change production validation, persistence, SwiftData schema, amount-entry behavior, currency formatting, importer/exporter behavior, serializer behavior, or the canonical ledger.

It proposes the readiness semantics that apply **after** an amount already satisfies the independently reviewed PortableMoneyV1 global structural rules:

    10^-9 <= x < 10^15
    p <= 15
    S <= 9

It does not define the complete PortableMoneyV1 admitted-currency registry.

It does not authorize implementation.

---

# 1. Decision Question

The global structural money domain is now accepted at the **PROPOSED-contract** level:

    x = C × 10^E
    p = digits(C)
    S = max(0, -E)

    p <= 15
    x < 10^15
    S <= 9
    E >= -9

Those rules answer:

> Can this exact decimal value participate in PortableMoneyV1's public numeric representation at all?

They intentionally do not answer:

> Is this exact decimal amount ordinary and automatically READY for its stated currency?

The next bounded question is therefore:

> Given a structurally valid exact amount, what should Lumen do when its normalized scale exceeds the ordinary scale associated with the record's currency?

The answer must preserve several existing responsibilities simultaneously:

- exact canonical monetary value must not be silently changed;
- the global nine-place structural ceiling must not be mistaken for a nine-place promise for every currency;
- new/manual and foreign-import confirmation may require more scrutiny than restoration of already-canonical Lumen state;
- currency semantics must be stable and Lumen-owned rather than delegated to whatever metadata the current OS happens to expose;
- cash-specific rounding must not silently become a universal transaction rule;
- source lexical trailing zeros must remain nonsemantic.

---

# 2. Terms

## 2.1 Structural normalized scale

For normalized exact decimal value:

    x = C × 10^E

PortableMoneyV1 defines:

    S = max(0, -E)

The independently reviewed global structural rule is:

    S <= 9

This proposal does not reopen that rule.

## 2.2 Ordinary currency scale

For an admitted currency code c, this proposal defines:

    O(c) = Lumen's versioned ordinary currency scale for general transaction quantities

O(c) answers:

> How many fractional decimal positions are ordinary for a general monetary quantity denominated in currency c?

O(c) is a **currency-semantic reference value**, not a storage limit.

It does not change the exact mathematical amount.

It does not make source lexical zeros semantic.

It does not authorize rounding.

## 2.3 Ordinary-scale and over-ordinary-scale values

For a structurally valid value:

    if S <= O(c):
        ordinary-scale for c

    if O(c) < S <= 9:
        over-ordinary-scale for c

An over-ordinary-scale value remains structurally representable by PortableMoneyV1.

Its workflow readiness depends on context.

---

# 3. Standards Basis for Ordinary Currency Scale

Portable v1 must not derive O(c) at runtime from:

- Foundation or NumberFormatter defaults;
- Locale.commonISOCurrencyCodes;
- device locale;
- host SDK version;
- regional settings;
- a live network lookup.

Instead, the eventual admitted Lumen currency registry must own a stable, versioned ordinary-scale value for each admitted currency to which this policy applies.

## 3.1 CLDR general currency digits are the proposed primary semantic basis

Unicode CLDR 48.2 defines supplemental currency metadata including:

- digits;
- rounding;
- cashDigits;
- cashRounding.

Its `digits` field is the number of decimal digits normally formatted for the currency.

CLDR documents a default of 2 when no currency-specific override is present.

CLDR also states that `digits` is based on the ISO 4217 minor-unit value but may differ where there is compelling evidence for customary practice.

Reference:

https://www.unicode.org/reports/tr35/tr35-numbers.html

The proposed Lumen ordinary-scale concept therefore aligns primarily with stable CLDR `digits` semantics rather than assuming a universal two-decimal rule.

## 3.2 ISO 4217 remains an authoritative source of currency-code and minor-unit facts

SIX Financial Information is the official ISO 4217 Maintenance Agency.

Reference:

https://www.six-group.com/en/products-services/financial-information/market-reference-data/data-standards.html

The eventual Lumen registry should retain a documented relationship to ISO 4217 currency and minor-unit data.

However:

> **ISO minor unit and Lumen ordinary scale must not be treated as definitionally identical if the selected stable standards source deliberately records a customary difference.**

The registry proposal must make any such difference explicit rather than silently inheriting it from the host platform.

## 3.3 Cash metadata is not the default general-Transaction rule

CLDR separately defines:

- `cashDigits`;
- `cashRounding`.

Those fields apply to cash-transaction formatting and rounding contexts.

A Lumen `Transaction` is not inherently a physical-cash transaction.

Therefore PortableMoneyV1 v1 should **not** use cash-specific digits or rounding as the default readiness rule for all Transactions.

A future explicitly cash-aware capability may admit cash-specific semantics separately.

## 3.4 General non-cash rounding increment is separate from O(c)

CLDR also defines general `rounding` separately from `digits`.

The proposed Lumen value:

    O(c)

models **ordinary fractional scale only**.

It does not by itself admit or enforce a general non-cash rounding increment.

If the stable registry metadata selected for an admitted currency contains a nonzero general rounding rule, that increment requires an explicit Lumen disposition before it can affect PortableMoneyV1 readiness, canonical confirmation, display authority, or normalization.

This scale proposal must therefore neither:

- silently enforce a nonzero general rounding increment merely because the standards source publishes one; nor
- silently treat that increment as irrelevant and claim all currency minor-unit semantics are complete.

Until that separate disposition is admitted, `O(c)` answers only the ordinary fractional-scale question.

---

# 4. Proposed Currency-Scale Classification

For an amount that already satisfies:

    10^-9 <= x < 10^15
    p <= 15
    S <= 9

and for a currency c whose ordinary scale O(c) is admitted:

## Ordinary-scale

    S <= O(c)

Result:

    currency-scale axis = READY

This does not bypass other readiness requirements such as Category, status, identity, or other unresolved semantics.

## Over-ordinary-scale

    O(c) < S <= 9

Result depends on workflow authority.

The amount is **not structurally invalid** merely because it exceeds O(c).

The exact amount must remain available for review.

No workflow may silently round it to O(c).

---

# 5. New Manual Confirmation

For a newly entered manual Transaction:

## S <= O(c)

Currency-scale status:

    READY

assuming all other Transaction requirements are resolved.

## O(c) < S <= 9

Currency-scale status:

    NEEDS RESOLUTION

Direct confirmation should not proceed merely because the value is globally structurally valid.

The user must be shown that the exact amount has more normalized fractional precision than is ordinary for the selected currency.

Resolution may result in either:

1. **Edit amount**
   - the user deliberately supplies a different exact amount; or

2. **Keep exact atypical amount**
   - the user explicitly confirms that the exact over-ordinary-scale amount is intended.

The second path is important because an ordinary currency scale is not proof that every legitimate financial record must be truncated to that scale.

This proposal does not authorize automatic rounding before either choice.

After explicit keep-exact resolution, the currency-scale issue is resolved for that confirmation boundary and the exact value may become READY subject to all other requirements.

No new persisted "scale override" field is authorized by this proposal.

---

# 6. Structured Import Review

The same distinction applies to non-Lumen structured sources such as mapped CSV.

## S <= O(c)

The amount is READY on the currency-scale axis if its currency meaning is otherwise resolved.

## O(c) < S <= 9

The proposal is:

    NEEDS RESOLUTION

The imported exact amount must remain intact in the noncanonical workspace.

Lumen must not automatically:

- round it;
- truncate it;
- rewrite it to O(c);
- substitute a formatter-produced value;
- reject the source file as malformed solely for this reason.

The user may resolve the proposal by:

- deliberately editing the exact amount; or
- explicitly keeping the exact atypical amount.

This is a semantic review state, not a source-syntax failure.

---

# 7. Lumen Portable JSON / CSV Round-Trip Restoration

A Lumen-owned portable export represents already-canonical Lumen state, not an untrusted claim that an unknown foreign source should be accepted automatically.

Therefore a structurally valid over-ordinary-scale amount that was canonical in the exporting Lumen state has different restoration authority from a newly proposed foreign amount.

For a supported Lumen Portable v1 record where:

    amount is structurally valid
    currency is admitted for the applicable portable contract
    record represents exported canonical state

an over-ordinary-scale amount should be:

    READY on the currency-scale axis
    with an advisory compatibility indication where useful

It must not be forced through an edit merely because:

    S > O(c)

on the receiving installation.

Review / explicit confirmation remains required by the broader Phase 1C import contract.

But scale alone must not destroy exact round-trip equivalence for already-canonical supported state.

This rule protects cases such as the existing repository compatibility fixture:

    12.345678901 KWD

which is structurally valid at:

    S = 9

while remaining atypical relative to ordinary KWD scale.

---

# 8. Existing Canonical State: Edit and Export

Existing canonical state has already crossed Lumen's canonical authority boundary.

## 8.1 Existing-canonical edit semantics

An unrelated edit must not convert an already-canonical atypical monetary value back into an unresolved proposal solely because its scale exceeds the current ordinary scale.

If an edit leaves the canonical pair unchanged:

    (amount, currency) before edit
    ==
    (amount, currency) after edit

then an existing over-ordinary-scale amount:

    O(c) < S <= 9

must preserve its exact value and must **not** require renewed currency-scale resolution merely because another field changed.

This rule is value-and-currency based, not text-field based. Nonsemantic re-rendering of the same exact monetary value does not create a new scale decision.

If either the amount or currency changes, Lumen must evaluate the resulting pair under the current admitted currency-scale semantics.

For the resulting pair:

    S <= O(c)
    → READY on the currency-scale axis

    O(c) < S <= 9
    → NEEDS RESOLUTION
    → deliberately edit the amount or explicitly keep the exact atypical amount

Changing only the currency therefore cannot bypass scale review.

If the resulting currency does not yet have admitted ordinary-scale metadata, readiness remains unresolved under the currency-definition contract; Lumen must not invent `O(c) = 2`.

No new persisted scale-override or acknowledgment field is authorized by this rule.

## 8.2 Current / historical canonical export

For a canonical amount satisfying the final global PortableMoneyV1 structural domain:

    export exact normalized monetary value

even when:

    S > O(c)

Ordinary currency scale is not an export-rounding instruction.

Export must not silently:

- round;
- truncate;
- clamp;
- coerce;
- substitute;
- omit the Transaction

merely because the canonical amount exceeds ordinary currency scale.

If an existing canonical amount falls outside the **global structural** PortableMoneyV1 domain itself, the separately open historical/current out-of-domain disposition still governs.

This proposal does not resolve that separate case.

---

# 9. Display and Formatting

Currency display has a different responsibility from canonical value and portable serialization.

## Ordinary-scale values

For values where:

    S <= O(c)

a conventional currency formatter may be used for user-facing display, provided it does not redefine canonical portable spelling.

## Over-ordinary-scale canonical or review values

For values where:

    O(c) < S <= 9

a display surface that is used to:

- inspect;
- review;
- edit;
- confirm;
- diagnose;
- verify an export

must expose the exact relevant fractional value rather than presenting only a rounded conventional display.

A compact non-authoritative surface may use conventional formatting only if the product still provides an accessible exact representation and does not imply that the rounded rendering is the stored amount.

Formatting must never become a hidden canonicalization step.

---

# 10. Source Lexical Zeros Remain Nonsemantic

Currency-scale classification uses normalized scale S.

Therefore, for USD with ordinary scale O(USD) = 2:

    52.3
    52.30
    52.300000000

all normalize to:

    523 × 10^-1
    S = 1

and are ordinary-scale values.

The lexical presence of additional trailing zeros does not produce an over-ordinary-scale condition.

---

# 11. Worked Examples

The examples below illustrate semantics only.

They are not the complete currency registry.

## USD-style ordinary scale 2

    12.34
    S = 2
    O(USD) = 2
    → ordinary-scale

    12.3400
    normalized S = 2
    → ordinary-scale

    12.345
    S = 3
    → structurally valid
    → over-ordinary-scale
    → NEEDS RESOLUTION for new/manual or generic structured import

## JPY-style ordinary scale 0

    1200
    S = 0
    O(JPY) = 0
    → ordinary-scale

    1200.5
    S = 1
    → structurally valid
    → over-ordinary-scale
    → NEEDS RESOLUTION for new/manual or generic structured import

## KWD-style ordinary scale 3

    12.345
    S = 3
    O(KWD) = 3
    → ordinary-scale

    12.345678901
    S = 9
    → structurally valid
    → over-ordinary-scale

For new/manual or generic structured import:

    NEEDS RESOLUTION

For exact export/restoration of supported already-canonical Lumen state:

    preserve exact value
    READY on currency-scale axis for round-trip restoration

## Four-digit ordinary-scale units

A currency or unit admitted with:

    O(c) = 4

may treat:

    S <= 4

as ordinary-scale while values with:

    4 < S <= 9

remain structurally valid but over-ordinary-scale.

---

# 12. Unknown, Historical, Special, Fund, Metal, and Unit Codes

This proposal does not freeze complete registry membership.

Therefore it must not invent an ordinary scale for a token merely because:

- the token matches `[A-Z]{3}`;
- Foundation recognizes it;
- CLDR has a default;
- ISO has assigned the code;
- the code historically existed.

The eventual Lumen registry must deliberately classify admitted codes and the scale metadata that applies to them.

Where the applicable Lumen registry does not establish O(c):

> **The product must not silently assume O(c) = 2 for canonical-readiness purposes.**

New/manual and foreign-import readiness remains unresolved until the currency definition supplies the needed semantics.

Existing canonical export and historical compatibility remain governed by their separate protection rules.

---

# 13. Currency-Definition Evolution

Ordinary currency scale can evolve in external standards or customary practice.

Portable v1 must not let such evolution retroactively rewrite canonical values.

A future registry/version proposal must define:

- how Lumen pins or versions currency metadata;
- how registry revisions are identified;
- how a receiving implementation handles older portable state;
- whether a registry identifier travels in the portable document;
- how scale changes affect new confirmation versus restoration of existing canonical values.

At minimum:

> **A later ordinary-scale change must not silently mutate or make unexportable an exact value that was already canonical under Lumen's earlier accepted state.**

The exact registry-version mechanism remains open.

---

# 14. Why Over-Ordinary-Scale Is NEEDS RESOLUTION Rather Than INVALID

An over-ordinary-scale amount inside:

    S <= 9

has already passed the global numeric-format contract.

Treating it as structurally INVALID would collapse two distinct questions:

    Can PortableMoneyV1 represent the exact value?
    vs.
    Is the exact value ordinary for this currency?

The repository's existing nine-place KWD compatibility case demonstrates why that collapse would be harmful.

Conversely, making every structurally valid amount automatically READY would erase meaningful currency semantics.

Therefore:

    structurally valid + ordinary-scale
        → READY on scale axis

    structurally valid + over-ordinary-scale
        → NEEDS RESOLUTION for new/manual and generic foreign import
        → exact compatibility preservation for existing canonical / Lumen round trip

is the proposed middle boundary.

---

# 15. Why Explicit Keep-Exact Resolution Is Admitted

Ordinary-scale metadata is a strong expectation, not proof that a higher-scale exact record is false.

Potential legitimate sources include:

- imported historical records;
- institution-generated calculations;
- allocations;
- accrued amounts;
- legacy application state;
- deliberately precise user records.

Portable v1 should not invent a rounded value on the user's behalf.

Therefore the proposed resolution contract allows the user to say, in effect:

> The atypical exact amount is intentional; preserve it.

That is a materially different authority event from silently accepting or silently rounding the value.

This proposal does not prescribe UI wording or require a persisted acknowledgment field.

---

# 16. Cash Rounding Is Separate

Cash-specific rounding may legitimately differ from general transaction scale.

Examples in CLDR use separate cash metadata precisely because:

    general monetary quantity
    !=
    physical-cash settlement rule

PortableMoneyV1 v1 does not infer that a Transaction is cash solely from its currency.

Therefore:

- `cashDigits` does not replace O(c);
- `cashRounding` does not modify stored amounts automatically;
- cash-specific confirmation behavior requires a separate explicit product capability if Lumen later needs it.

---

# 17. Interaction With Precision and Structural Scale

Currency ordinary scale is evaluated only after structural admission.

Examples:

    0.0000000001
    S = 10
    → outside global structural ceiling
    → currency ordinary scale is irrelevant

    123456789012345.1
    p = 16
    → outside precision ceiling
    → currency ordinary scale is irrelevant

    12.345 USD
    p = 5
    S = 3
    x < 10^15
    → structurally valid
    → then evaluate O(USD)

The precedence is:

    GLOBAL NUMERIC STRUCTURE
        ↓
    admitted currency identity / metadata
        ↓
    ordinary currency-scale classification
        ↓
    workflow-specific readiness

A lower-level currency-scale observation must not conceal a higher-level structural or currency-admission failure.

---

# 18. Proposed Workflow Matrix

| Context | S <= O(c) | O(c) < S <= 9 |
| --- | --- | --- |
| New manual entry | READY on scale axis | NEEDS RESOLUTION; edit or explicit keep-exact |
| Generic structured import | READY on scale axis | NEEDS RESOLUTION; preserve exact proposal; edit or explicit keep-exact |
| Existing canonical edit with unchanged `(amount, currency)` | preserve exact canonical pair; no renewed scale decision | preserve exact canonical pair; no renewed scale resolution solely for unrelated edit |
| Existing canonical edit with changed amount or currency | evaluate resulting pair; READY if ordinary-scale | NEEDS RESOLUTION for resulting pair; edit or explicit keep-exact |
| Existing canonical export | export exact value | export exact value; no scale rounding |
| Supported Lumen portable round-trip restoration | READY on scale axis | READY on scale axis for exact restoration; advisory allowed |
| Review / transaction detail display | conventional exact/ordinary display | exact atypical fractional value must be inspectable |
| Compact display | conventional formatting allowed | conventional display may be secondary only; exact value must remain accessible |

This matrix addresses currency-scale semantics only.

Other readiness gates still apply independently.

---

# 19. Proposed Contract Language

PortableMoneyV1 should state:

> **For each admitted currency to which ordinary fractional-scale semantics apply, Lumen owns a stable, versioned ordinary currency scale O(c). The ordinary-scale concept is distinct from the global normalized structural scale S and must not be derived from runtime OS formatting metadata.**

It should state:

> **A structurally valid value with S <= O(c) is READY on the currency-scale axis. A structurally valid value with O(c) < S <= 9 is over-ordinary-scale: new/manual and generic structured-import confirmation require explicit resolution, while existing canonical export and supported Lumen portable round-trip restoration preserve the exact value without automatic rounding.**

It should state:

> **For an edit of an existing canonical Transaction, an unchanged exact (amount, currency) pair does not require renewed currency-scale resolution solely because another field changes. If amount or currency changes, the resulting pair is evaluated again; an over-ordinary-scale result requires explicit resolution.**

It should state:

> **Currency-scale resolution must never silently round, truncate, clamp, coerce, substitute, or omit the exact amount.**

It should state:

> **O(c) models ordinary fractional scale only. It does not itself admit or enforce CLDR's general non-cash rounding increment. Any nonzero general rounding rule in the selected stable registry metadata requires a separate explicit Lumen disposition.**

It should state:

> **General Transaction currency-scale semantics use the Lumen-owned ordinary-scale definition, not cash-specific rounding metadata. Cash-specific scale/rounding requires a separate admitted capability.**

---

# 20. What Remains Open

This proposal does not resolve:

- complete admitted-currency registry membership;
- the exact registry representation or identifier;
- historical/withdrawn currency membership;
- precious-metal, fund, unit-of-account, testing, or "no currency" membership;
- exact treatment of a currency whose standards metadata changes between registry versions;
- exact UI copy or controls for atypical-scale resolution;
- general non-cash rounding-increment semantics for any registry entry whose stable metadata publishes a nonzero rounding increment;
- whether any particular foreign provider receives specialized mapping behavior;
- exact language-independent canonical decimal serialization;
- leading-zero lexical policy;
- historical/current canonical amounts outside the global PortableMoneyV1 structural domain;
- production implementation;
- schema changes or persistence of a scale-resolution acknowledgment;
- cash-specific product semantics.

---

# 21. Review Questions

Independent review should answer:

1. Is CLDR general `digits` metadata an appropriate primary basis for Lumen's versioned **ordinary scale**, while retaining ISO 4217 Maintenance Agency data as authoritative code/minor-unit evidence?
2. Is it correct that `O(c)` models ordinary fractional scale only, while any nonzero CLDR general `rounding` increment requires a separate explicit Lumen disposition?
3. Is it correct to keep `cashDigits` / `cashRounding` outside general Transaction readiness?
4. Should `S <= O(c)` be READY on the currency-scale axis?
5. Should `O(c) < S <= 9` be NEEDS RESOLUTION for new/manual and generic structured imports rather than INVALID?
6. Should explicit keep-exact confirmation be an admitted resolution path for structurally valid atypical amounts?
7. Should an unchanged exact canonical `(amount, currency)` pair avoid renewed scale resolution during an unrelated edit, while a changed amount or currency causes the resulting pair to be evaluated again?
8. Should already-canonical Lumen values and supported Lumen portable round trips preserve exact over-ordinary-scale amounts without re-resolution solely because of scale?
9. Is the display rule strong enough to prevent conventional formatting from concealing exact atypical values?
10. Is it sufficiently clear that complete currency-registry membership and general rounding-increment disposition remain separate gates?

Until independent review is complete, these currency-specific readiness semantics remain **PROPOSED**, not accepted.
