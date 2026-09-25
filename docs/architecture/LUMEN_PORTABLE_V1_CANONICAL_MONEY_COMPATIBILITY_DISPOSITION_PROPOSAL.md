# Lumen Portable v1 Canonical Monetary Compatibility / Export Disposition Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C compatibility/disposition contract.**

This proposal starts from accepted checkpoint `b41fb9a6c45909318f4806e9645338a1d79caa9c`.

It does **not** expand PortableMoneyV1 or `lumen-currency-v1`, and does not authorize production code, tests, persistence/schema, importer/exporter implementation, serializer implementation, migrations, or workspace/promotion changes.

# 1. Decision Question

When an existing canonical `Transaction` contains exact monetary state that cannot be represented under the admitted PortableMoneyV1 + `lumen-currency-v1` domain, what explicit export and round-trip disposition does Portable v1 provide?

```text
CANONICAL TRANSACTION
        ↓
Can exact monetary state be represented by
PortableMoneyV1 + lumen-currency-v1?
        │
   ┌────┴────┐
  yes        no
   │          │
normal       compatibility disposition required
portable      ├─ amount outside structural domain
path          └─ currency outside registry
```

This is a compatibility/disposition question, not permission to widen the accepted domains.

# 2. Boundaries Not Reopened

```text
10^-9 <= x < 10^15
p <= 15
S <= 9
```

and the immutable proposed `lumen-currency-v1` 155-code membership + exact `O(c)` mapping remain unchanged.

# 3. Repository Evidence

## 3.1 Ownership contract

The accepted Phase 1C responsibility contract defines Portable JSON as the normative, highest-fidelity representation of durable state **explicitly admitted** to the portability contract, not a lossless image of the application container. Supported fields/entities have defined round-trip guarantees; state outside the admitted portable contract must be explicitly excluded rather than silently implied. Export must represent coherent durable state, and round-trip equivalence is measured against admitted semantics.

## 3.2 Current canonical storage is broader

Current SwiftData `Transaction` persists `amount: Double` and `currency: String`. The model initializer accepts those values directly and does not encode the PortableMoneyV1 structural predicates or `lumen-currency-v1` membership.

The ordinary draft/confirmation path is narrower: finite positive amount, `Money.magnitude(amount) != nil`, and Foundation `Locale.commonISOCurrencyCodes` recognition. Existing-edit behavior preserves the original `Double` when amount text is unchanged.

## 3.3 Demonstrated evidence

A repository test preserves `12.345678901 KWD` exactly through an unrelated edit. This value is inside global `S <= 9` but atypical relative to KWD ordinary scale; it demonstrates exact already-canonical preservation, not an out-of-domain amount or out-of-registry currency.

The bounded money characterization also created/persisted/reopened broad diagnostic values. Probes included powers through `10^18`, integer/scale matrices through 18 integer digits, precision through 17 significant digits, subunit scales through 12, and tiny values through scale 18. The recorded investigation reports passing examples outside later conservative PortableMoneyV1 policy axes. These are diagnostic test-store records, not evidence of user production data, but they prove current durable capability and the accepted portable domain are not identical.

## 3.4 Evidence classes

**Class 1 — demonstrated in repository fixtures/tests:** exact atypical-scale preservation; diagnostic persistence/reopen of values outside later PortableMoneyV1 policy axes.

**Class 2 — model/storage-permitted but not demonstrated as real user canonical state:** finite `Double` amounts outside final portable structural admission; arbitrary persisted currency strings including historical/withdrawn/fund/unit/special/non-registry values; compatibility records produced by a path whose validation differs from today's draft UI.

**Class 3 — impossible as exact current canonical storage:** monetary values not representable as Swift `Double`; decimal distinctions already collapsed before canonical persistence into the same `Double`. Portable v1 cannot recover information canonical storage itself does not possess.

# 4. Incompatibility Taxonomy

## A. Amount-domain incompatibility

Includes canonical monetary values failing the accepted structural domain:

- `p > 15`;
- `S > 9`;
- positive magnitude below `10^-9`;
- magnitude `>= 10^15`;
- another final PortableMoneyV1 structural failure.

## B. Currency-registry incompatibility

Includes canonical currency strings outside `lumen-currency-v1`, including where applicable historical/withdrawn codes, current canonical codes not admitted by registry v1, excluded fund/unit/special/metal codes, and other persisted non-registry strings.

Platform recognition does not override registry membership.

## C. Combined incompatibility

A Transaction may fail both axes. Deterministic preflight should be able to report all materially applicable reasons rather than concealing a second failure behind the first.

# 5. Non-Loss Invariants

```text
incompatibility
!= permission to round
!= permission to truncate
!= permission to clamp
!= permission to coerce
!= permission to substitute currency
!= permission to silently omit
```

# 6. Separate Claims

**Successful Portable v1 serialization** means every record the artifact claims to contain satisfies applicable Portable v1 semantics.

**Complete ownership export** means an export operation claims to represent all durable state within its selected/export-contract scope. A Portable v1 artifact excluding an incompatible in-scope canonical Transaction is not by itself a complete ownership export.

**Full supported-state round trip** means admitted state can be exported, imported through the required workflow, and restored with the promised semantics.

A partial artifact may be valid while not being a complete ownership export.

# 7. Export Preflight

Before claiming successful completion, the export operation must preflight one coherent selected canonical snapshot against the requested export product.

For Portable JSON v1 monetary compatibility, every in-scope canonical Transaction must be classified against:

```text
PortableMoneyV1 + selected admitted currency registry
```

Preflight is an observable contract responsibility. Query strategy, batching, UI, and persistence are implementation matters.

# 8. Minimum Deterministic Diagnostics

For each incompatible in-scope Transaction, preflight must be able to report:

- a deterministic reference sufficient to associate the diagnostic with the source canonical record during that export attempt;
- one or more stable incompatibility reason codes;
- the failed domain/registry axis;
- enough non-mutating context to explain the incompatibility without substituting another monetary value.

Candidate reason semantics:

```text
money_precision_out_of_domain
money_scale_out_of_domain
money_magnitude_below_domain
money_magnitude_above_or_equal_domain
money_other_structural_incompatibility
currency_not_in_registry
```

This proposal does not freeze diagnostic wire shape, portable IDs, UI wording, ordering, persistence, or exact decimal spelling.

# 9. Alternatives

## A — Atomic refusal of a complete Portable v1 ownership export

If any in-scope canonical Transaction is incompatible, the requested **complete Portable v1 ownership export** does not complete successfully. Preflight reports incompatibilities before success is claimed.

Strengths: no silent loss; strict v1 semantics; clear completeness claim; no second wire contract; deterministic.

Cost: one incompatible record blocks a complete Portable v1 ownership export.

## B — Explicitly partial Portable v1 export

Export compatible records with explicit machine-readable/user-visible exclusion reporting.

Benefit: usable supported subset.

Risk: the artifact must remain unmistakably partial; detached data must not later masquerade as a complete ownership export; excluded state has no round-trip claim. This can be a separately named operation, but should not be the default meaning of complete export.

## C — Separately identified compatibility representation

A separately admitted representation could preserve exact canonical monetary state outside PortableMoneyV1 without claiming those values are PortableMoneyV1.

Benefit: potentially broader whole-state portability.

Cost: a new public semantic domain, recognition/version rules, representation/restoration rules, and long-term maintenance. Current evidence does not establish that this is necessary for Portable v1 acceptance.

## D — Widen/normalize PortableMoneyV1

Rejected. It would reopen independently reviewed boundaries and/or misrepresent canonical truth.

## E — Silent omission

Rejected. A valid-looking artifact could falsely appear complete.

# 10. Recommended Proposed Disposition

> **A complete Portable JSON v1 ownership export is all-or-nothing with respect to monetary/currency compatibility of the in-scope canonical Transaction snapshot. If any in-scope canonical Transaction cannot be represented exactly under PortableMoneyV1 + the selected admitted currency registry, the operation must not claim successful completion as a complete Portable v1 ownership export. Preflight must return deterministic incompatibility diagnostics.**

This does **not** require every export-like operation to fail.

A separately requested partial Portable v1 export may be admitted later only if it cannot be represented/presented as complete, exclusions remain deterministically reported, partialness cannot be detached such that the artifact masquerades as complete, and no round-trip claim is made for excluded state.

A separately versioned compatibility representation may likewise be admitted later if evidence justifies it.

# 11. Rationale Against Phase 1C Principles

- **Ownership:** a lossy subset is not labeled complete.
- **Truth:** canonical state remains authoritative.
- **No silent loss:** incompatible records cannot disappear behind complete-export success.
- **Determinism:** same coherent snapshot + same domain/registry yields the same compatibility classification.
- **Strict semantics:** OS/Foundation recognition cannot widen v1.
- **Restoration:** a successful complete Portable v1 ownership export contains only state v1 claims to represent.
- **Authority separation:** canonical truth and portability representation remain distinct.

# 12. Exact Proposed Contract Language

> **Before claiming successful completion of a complete Portable JSON v1 ownership export, Lumen must evaluate every in-scope canonical Transaction in one coherent export snapshot against PortableMoneyV1 and the selected admitted currency registry.**

> **If any in-scope canonical Transaction contains exact monetary state that cannot be represented under those semantics, the operation must not claim successful completion as a complete Portable v1 ownership export.**

> **Incompatibility never authorizes rounding, truncation, clamping, coercion, currency substitution, registry fallback, or silent omission of canonical monetary state.**

> **Export preflight must produce deterministic diagnostics that associate each incompatible canonical Transaction with all materially applicable incompatibility reasons. Exact diagnostic wire shape, UI, persistence, and ordering remain implementation or later-format concerns unless separately admitted.**

> **A valid partial Portable v1 artifact and a complete ownership export are different claims. Any future partial-export operation must be explicitly identified as partial and must not claim round-trip restoration of excluded canonical state.**

> **A future compatibility representation may preserve state outside PortableMoneyV1 or the selected registry only under a separately identified and admitted contract. It must not silently broaden PortableMoneyV1.**

# 13. Not Decided Here

This proposal does not decide exact plain-decimal serialization, leading-zero policy, `portable_id`, deterministic artifact ordering, diagnostic file/manifest schema, export UI, diagnostic persistence, status/category/type compatibility, general non-cash rounding, cash-specific rounding, or implementation mechanics.

# 14. Remaining Dependencies

Full Portable JSON / CSV v1 acceptance still requires the remaining gate inventory: status/category/type compatibility; portable identity/ordering; entity field exactness; date/timestamp semantics; canonical decimal serializer/leading-zero policy; parser unknown-field policy; and other explicitly listed gates.

This proposal may provide a reusable pattern for later canonical-state incompatibilities, but those gates require their own evidence/admission.

# 15. Review Questions

Independent review should evaluate:

1. all-or-nothing complete Portable JSON v1 ownership export for monetary/currency incompatibility;
2. partial export as a distinct possible operation rather than the meaning of complete export;
3. compatibility representation as separately versioned/admitted rather than widening PortableMoneyV1;
4. the demonstrated/permitted/impossible evidence classification;
5. whether preflight diagnostics are strong enough without prematurely designing serializer/UI/persistence;
6. separation of successful serialization, complete ownership export, and full supported-state round trip;
7. preservation of accepted PortableMoneyV1 and `lumen-currency-v1` boundaries.

Until independent review is complete, these compatibility/disposition semantics remain **PROPOSED**, not accepted.
