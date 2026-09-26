# Lumen Portable JSON / CSV v1 Format Contract

## Status

**PROPOSED FOR REVIEW — Phase 1C public portable-domain format contract.**

- **Proposal date:** 2026-09-22
- **Canonical repository baseline reviewed:** `2dd3ec9310554bc12d8c4f71076af9603a501c34`
- **Governing phase:** Phase 1C — Ownership, Portability & Data Management
- **Responsibility authority:** `docs/architecture/PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`
- **Format disposition:** Proposed. This document intentionally contains explicit evidence/research gates that must be resolved before the format is accepted as final.
- **Implementation disposition:** This document does **not** authorize importer implementation, workspace persistence, promotion-control persistence, SwiftData schema changes, migrations, production services, or implementation-pass sequencing.
- **Characterization disposition:** The bounded money characterization has been completed and incorporated as evidence. It does **not** by itself accept this format contract, authorize implementation, or close unrelated format gates.

This document is subordinate to:

- `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
- `docs/ROADMAP.md`
- `docs/NON_GOALS.md`
- `docs/architecture/ADR-001-source-of-truth-and-ingestion.md`
- `docs/architecture/PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`

If this proposal conflicts with those accepted sources, the higher-authority source wins.

---

# 1. Purpose

This contract defines the public interchange semantics Lumen intends to own for Phase 1C.

It answers a narrower question than the Phase 1C responsibility contract:

> **What exact structured representation may another implementation produce or consume without knowing anything about Lumen's SwiftData object graph or private import-workspace representation?**

The intended layers are:

```text
LUMEN PORTABLE JSON v1
normative, highest-fidelity public portable-domain representation

LUMEN CSV v1
deliberately narrower public tabular projection

IMPORT WORKSPACE REPRESENTATION
private, resumable, noncanonical implementation concern
NOT defined by either public format
```

This contract defines format semantics.

It does not define:

- importer UX;
- foreign-file inference cleverness;
- bank/provider adapters;
- workspace autosave representation;
- promotion receipts/idempotency storage;
- reconciliation;
- schema migrations;
- FX valuation.

---

# 2. Contract Maturity Markers

This proposal uses four explicit maturity markers.

## PROPOSED

The design is sufficiently supported to include in the candidate v1 contract but is not canonical until this document is accepted.

## EVIDENCE GATED

The surrounding responsibility is established, but the exact rule must be chosen from bounded empirical characterization before final acceptance.

## RESEARCH / ADMISSION REQUIRED

The format needs a stable rule, but current evidence is insufficient to choose it safely.

## OUT OF SCOPE

The capability is deliberately not part of Portable v1.

Open gates are not invitations to fill blanks through intuition. They record the exact evidence still required.

---

# 3. Three Different Validity Questions

Structured ingestion must preserve three different questions.

```text
SOURCE VALIDITY
Can the source be parsed as the structure it claims to be?
        ↓
MAPPING / INTERPRETATION
Are its source values assigned unambiguous Lumen meanings?
        ↓
CANONICAL READINESS
Are all meanings required by Lumen confirmation resolved?
```

These stages are not synonyms.

A foreign file can be valid CSV while omitting Currency or Category.

A source row can be parseable while its amount direction, date meaning, status, currency, or Category is unresolved.

A proposal can have valid portable syntax while still being outside the current canonical Transaction domain.

> **Missing required canonical semantics make a proposal unresolved; they do not retroactively make the source file malformed.**

The accepted Phase 1C readiness model remains:

- READY;
- NEEDS RESOLUTION;
- INVALID / UNSUPPORTED.

This format contract does not redefine that model.

---

# 4. Source Availability Does Not Create Canonical Ownership

A foreign source may expose information that Lumen does not own canonically.

> **Source availability does not create canonical ownership.**

Examples include:

- rewards/points values;
- running account balances;
- cardholder/account-holder labels;
- institution-specific status vocabulary;
- provider-specific type vocabulary;
- raw statement descriptions;
- account/reference identifiers.

Those values may later inform mapping, provenance, rewards, account, payment-instrument, or reconciliation domains.

Their presence in a source file does not authorize:

- new `Transaction` fields;
- new SwiftData models;
- a broader Lumen CSV schema;
- provider-specific behavior;
- automatic semantic assignment.

Format Survey Evidence 001 records a real example of this boundary in:

`docs/knowledge/investigations/phase1c-format-survey-001-structured-financial-csv.md`

---

# 5. Foreign Formats vs Lumen-Owned Formats

The format boundary is:

```text
FOREIGN STRUCTURED DATA
flexible / provider-specific / potentially incomplete
        ↓
parse + map + resolve
        ↓
LUMEN PORTABLE-DOMAIN SEMANTICS
strict / normalized / versioned
        ↓
Review / Confirm
        ↓
CANONICAL STATE
```

Foreign-format survey evidence may improve later mapping.

It must not expand Lumen Portable v1 by accretion.

The guaranteed formats remain:

- Lumen Portable JSON v1;
- Lumen CSV v1.

Non-Lumen CSV may later map into those semantics.

Arbitrary third-party JSON remains deferred unless a specific adapter is admitted.

---

# 6. Lumen Portable JSON v1 Envelope

## 6.1 Proposed top-level shape — PROPOSED

The candidate top-level document shape is:

```json
{
  "format": "lumen-portable",
  "version": 1,
  "currency_registry": "lumen-currency-v1",
  "exported_at": "2026-09-22T16:00:00Z",
  "categories": [],
  "payment_methods": [],
  "tags": [],
  "sources": [],
  "transactions": []
}
```

The top-level entity arrays are always present, even when empty.

The object is a public portable-domain representation.

It is not a serialization of `ModelContext`, SwiftData metadata, application preferences, filesystem structure, or the private import workspace.

## 6.2 Envelope fields

| Field | Type | Status | Semantics |
| --- | --- | --- | --- |
| `format` | string | PROPOSED | Must equal `"lumen-portable"` for this format family |
| `version` | integer | PROPOSED | Must equal `1` for v1 |
| `currency_registry` | string | PROPOSED | Required immutable Lumen currency-registry identifier; initially `"lumen-currency-v1"` |
| `exported_at` | timestamp string | PROPOSED | Export-generation instant; not a financial transaction date |
| `categories` | array | PROPOSED | Supported Category portable records |
| `payment_methods` | array | PROPOSED | Supported PaymentMethod portable records |
| `tags` | array | PROPOSED | Supported Tag portable records |
| `sources` | array | PROPOSED | Deliberately limited semantic/provenance projection |
| `transactions` | array | PROPOSED | Transaction-bearing portable records |

The exact canonical timestamp spelling for `exported_at` is governed by the timestamp section below.

---

# 7. Encoding, Nullability, and Absence

## 7.1 JSON encoding — PROPOSED

Portable JSON v1 is UTF-8 JSON.

JSON numbers are **not** used for monetary amount values.

User-authored strings are portable content and must not be silently trimmed, Unicode-normalized, title-cased, or otherwise rewritten merely for serialization.

Required enum/token fields use the exact normalized tokens defined by this contract.

## 7.2 Required fields — PROPOSED

A required field must be present.

An absent required field is not equivalent to a null value.

## 7.3 Nullable fields — PROPOSED

For known nullable scalar or reference fields, the candidate v1 rule is:

> **The field remains present and uses JSON `null` when the semantic value is absent.**

This makes absence explicit and reduces ambiguity between "not part of this schema" and "part of this schema with no value."

## 7.4 Arrays — PROPOSED

Known collection fields are present and use an empty array when there are no values.

## 7.5 Unknown-field behavior — RESEARCH / ADMISSION REQUIRED

Before final format acceptance, v1 must define whether an importer:

- rejects unknown fields;
- ignores additive unknown fields;
- or uses another explicit compatibility rule.

The parser must never interpret an unsupported future format version as v1 merely because some field names look familiar.

---

# 8. Portable Entity Scope

The candidate v1 entity scope is:

| Entity/responsibility | JSON v1 | CSV v1 | Current disposition |
| --- | --- | --- | --- |
| Transaction | yes | yes, narrower projection | PROPOSED with explicit status/category round-trip gates |
| Category | yes | referenced by transaction columns | PROPOSED |
| PaymentMethod | yes | optional name projection | PROPOSED |
| Tag | yes | omitted from initial CSV v1 | PROPOSED |
| TransactionSource semantic/provenance projection | limited | no | PROPOSED with field-level gates |
| UserProfile/preferences | no | no | OUT OF SCOPE for initial v1 |
| raw retained evidence bytes | no | no | OUT OF SCOPE for JSON/CSV v1 |
| import workspace state | no | no | OUT OF SCOPE |
| Budgets/CashflowPhases | no | no | OUT OF SCOPE until separately admitted |
| rewards/benefits/account balances | no | no | OUT OF SCOPE |

Exclusion from v1 does not mean a concept is unimportant.

It means its portable semantics are not admitted by this contract.

---

# 9. Portable Identity and References

## 9.1 Public identity is not SwiftData identity — PROPOSED

Portable records use an opaque public relationship key named `portable_id`.

A portable ID:

- identifies a record inside the portable representation;
- supports references between exported portable records;
- must be unique in the relevant portable entity namespace;
- must not be interpreted as overwrite authority on import;
- must not be assumed to equal the corresponding SwiftData model `id`;
- must not be used as promotion replay authority;
- must not replace ordinary duplicate-awareness.

## 9.2 Exact generation and cross-export stability — RESEARCH / ADMISSION REQUIRED

The following remain open:

- exact `portable_id` lexical grammar;
- deterministic generation;
- whether the same canonical entity receives the same portable ID across separate exports;
- whether IDs are document-local or stable across a broader portability lifetime;
- deterministic ordering implications.

These decisions must preserve:

- relationship resolution;
- deterministic export behavior;
- no accidental exposure of local persistence identity as permanent public API;
- no hidden overwrite/delete authority.

No new persisted identifier field is authorized by this proposal.

---

# 10. Portable Transaction Record

## 10.1 Candidate shape — PROPOSED

A candidate transaction record is:

```json
{
  "portable_id": "txn-example",
  "amount": "24.50",
  "currency": "USD",
  "type": "expense",
  "merchant_name": "Example Market",
  "transaction_date": "2026-01-04",
  "posted_date": null,
  "status": "posted",
  "notes": null,
  "category_ref": "cat-example",
  "payment_method_ref": null,
  "tag_refs": [],
  "source_ref": null,
  "created_at": "2026-01-04T15:20:00Z",
  "updated_at": "2026-01-04T15:20:00Z"
}
```

The example is synthetic and demonstrates shape only.

## 10.2 Transaction field dispositions

| Portable field | Required? | Candidate source semantic | Status |
| --- | --- | --- | --- |
| `portable_id` | yes | public relationship key | generation semantics RESEARCH / ADMISSION REQUIRED |
| `amount` | yes | native monetary magnitude | lexical contract PROPOSED; semantic domain EVIDENCE GATED |
| `currency` | yes | native transaction denomination | token grammar PROPOSED; admitted universe RESEARCH / ADMISSION REQUIRED |
| `type` | yes | transaction direction/type | token set PROPOSED; directional sufficiency RESEARCH / ADMISSION REQUIRED |
| `merchant_name` | yes | merchant/counterparty | PROPOSED |
| `transaction_date` | yes | financial transaction calendar date | PROPOSED encoding; conversion from current storage EVIDENCE GATED |
| `posted_date` | nullable | financial posted calendar date | PROPOSED encoding; conversion from current storage EVIDENCE GATED |
| `status` | yes | current canonical transaction status | portability domain partially gated |
| `notes` | nullable | user-authored notes | PROPOSED |
| `category_ref` | nullable in representation | Category association | PROPOSED representation; exact-null categoryless compatibility ACCEPTED AT PROPOSED-CONTRACT LEVEL; non-null reference identity/resolution remains separately gated |
| `payment_method_ref` | nullable | PaymentMethod association | PROPOSED |
| `tag_refs` | array | Tag associations | PROPOSED |
| `source_ref` | nullable | limited source/provenance association | PROPOSED |
| `created_at` | yes | canonical record creation instant | inclusion/restoration semantics RESEARCH / ADMISSION REQUIRED |
| `updated_at` | yes | canonical record update instant | inclusion/restoration semantics RESEARCH / ADMISSION REQUIRED |

## 10.3 Deliberately excluded current Transaction fields

The candidate v1 Transaction projection excludes:

- `user_id`;
- `confidence_score`;
- `duplicate_fingerprint`;
- `cashflow_phase_id`;
- `budget_id`.

Reasons:

- local/user-account identity is not automatically portable transaction identity;
- machine confidence is not canonical financial truth;
- duplicate fingerprint semantics are internal duplicate-awareness/control state, not portable event identity;
- CashflowPhase/Budget portability is not admitted in v1.

This is a portable DTO decision, not a request to remove those fields from current persistence.

---

# 11. Transaction Type

## 11.1 Proposed enum — PROPOSED

Portable v1 transaction type uses the normalized lowercase tokens:

- `expense`;
- `income`;
- `transfer`;
- `refund`.

No additional alias spelling is valid in Lumen-owned Portable v1.

Foreign formats may use other representations upstream.

## 11.2 Type is separate from amount sign — PROPOSED

Portable amount is a positive magnitude.

Transaction direction/type is represented separately.

The following is not a valid PortableMoneyV1 direction encoding:

```json
{
  "amount": "-24.50",
  "currency": "USD"
}
```

A foreign signed amount may participate in mapping, but normalized Lumen portable semantics separate magnitude from transaction type.

## 11.3 Directional sufficiency — RESEARCH / ADMISSION REQUIRED

Because PortableMoneyV1 keeps `amount` unsigned, every admitted `type` token must be sufficient to interpret the transaction's financial flow semantics.

Current repository behavior establishes only a limited implementation fact: `TransactionType.isOutflow` returns `true` for `expense` and `false` for the other current tokens. That implementation fact does **not** by itself establish that `transfer` has one unambiguous portable direction, nor does it freeze the intended portable flow semantics of every token.

Before format acceptance, the contract must define for each admitted type whether its unsigned amount represents an:

- outflow;
- inflow;
- direction-neutral/non-nettable movement;
- or otherwise explicitly defined flow semantic.

If any admitted token cannot uniquely carry the required flow meaning with an unsigned amount, the portable representation must be refined before acceptance.

This gate does not itself authorize an additional direction field or a change to the current `TransactionType` model.

---

# 12. Transaction Status

## 12.1 Persisted domain — ACCEPTED AT PROPOSED-CONTRACT LEVEL

Current persisted `TransactionStatus` values are:

- `pending`;
- `posted`;
- `ignored`;
- `duplicate`;
- `review_needed`.

The status-compatibility proposal in `LUMEN_PORTABLE_V1_TRANSACTION_STATUS_COMPATIBILITY_PROPOSAL.md` proposes that Portable JSON v1 admit all five exact tokens for truthful preservation of current canonical Transaction state.

They are not assigned the same workflow role:

```text
ordinary financial-lifecycle statuses:
pending
posted

canonical compatibility statuses:
ignored
duplicate
review_needed
```

The compatibility label preserves existing canonical truth without declaring the mixed persisted status model to be the preferred long-term architecture.

## 12.2 Representability and complete ownership export — ACCEPTED AT PROPOSED-CONTRACT LEVEL

All five exact tokens are lexically representable.

For a complete Portable JSON v1 ownership export, the proposed rule is:

> **Preserve the exact admitted canonical status token. Do not omit the Transaction, drop its status, or normalize `ignored`, `duplicate`, or `review_needed` to `pending`/`posted`. An admitted compatibility status does not by itself make the export incomplete.**

This is deliberately different from an out-of-domain PortableMoneyV1 value: the status value can be represented exactly, while restoration capability is the narrower open concern.

## 12.3 Restoration readiness — ACCEPTED AT PROPOSED-CONTRACT LEVEL

Current new-Transaction confirmation permits only:

- `pending`;
- `posted`.

Therefore:

```text
pending / posted
→ READY on status-restoration axis through ordinary confirmation

ignored / duplicate / review_needed
→ recognized exact compatibility state
→ NOT READY for canonical promotion through current ordinary confirmation
```

For v1 status round-trip equivalence, the proposal requires restoration of the same admitted status token and its admitted observable semantics unless a future separately accepted migration contract defines another lossless mapping.

Supported fresh-store round trip for the three compatibility statuses therefore requires a specifically admitted compatibility-restoration path **inside explicit Review/Confirm authority**.

Normatively:

```text
restoration authority != creation authority

ordinary creation semantics
!=
supported Lumen round-trip restoration semantics
```

The compatibility-restoration path must be identifiable as restoration of previously canonical state from a supported Lumen round-trip representation. It must not make the compatibility statuses valid choices for ordinary new/manual creation, foreign-source mapping, generic structured import, OCR/extraction proposals, or other non-restoration ingestion.

Review/Confirm must remain meaningful user authority. Restoration may preserve an otherwise non-creatable canonical status, but it must not become a generic confirmation bypass, silently coerce status, or operate as a hidden widening of ordinary `TransactionDraft.canConfirm`.

The exact UI, persisted context representation, importer mechanics, and implementation of that restoration capability are not decided here.

## 12.4 CSV remains separately scoped

Lumen CSV v1 also carries `status` and must not silently normalize shared status meaning. Whether all five compatibility statuses are admitted to CSV's deliberately narrower round-trip/export claim remains separately gated.

These Portable JSON status semantics are **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

Acceptance includes the invariant that restoration authority is distinct from ordinary creation/non-restoration ingestion authority. The three compatibility statuses remain NOT READY for canonical promotion until an admitted restoration capability exists and is validated.

---

# 13. Category Requirement and Historical Nullability

## 13.1 Canonical absence vs reference failure — ACCEPTED AT PROPOSED-CONTRACT LEVEL

Current `Transaction.category` remains nullable at the persistence-model level.

Current `TransactionDraft → Review → Confirm` requires a resolved Category for ordinary creation.

The categoryless-compatibility proposal in `LUMEN_PORTABLE_V1_CATEGORYLESS_TRANSACTION_COMPATIBILITY_PROPOSAL.md` proposes that Portable JSON v1 define:

```text
category_ref == null
→ exact canonical absence of Category association

category_ref non-null + resolvable
→ reconstruct the referenced Category association

category_ref non-null + unresolved
→ reference/dataset incompatibility or unresolved relationship
→ must not silently degrade to null
```

`null` therefore does not mean unknown ID, missing referenced Category record, parser failure, or request to choose a Category.

## 13.2 Representability and complete ownership export — ACCEPTED AT PROPOSED-CONTRACT LEVEL

A canonical Transaction with `category == nil` is exactly representable as:

```json
"category_ref": null
```

The proposed rule is:

> **Exact canonical Category absence is compatible with a complete Portable JSON v1 ownership export. The exporter must preserve `null` and must not omit the Transaction, fabricate a Category, select a default Category, create a synthetic `Uncategorized` entity, or convert an unresolved non-null reference into `null`.**

Derived analytics/presentation behavior such as the display label `Uncategorized` does not itself establish a canonical Category entity.

## 13.3 Restoration readiness — ACCEPTED AT PROPOSED-CONTRACT LEVEL

Current ordinary confirmation still requires a Category.

Therefore ordinary creation semantics remain:

```text
category == nil
→ not READY for ordinary new/manual confirmation
```

For supported Lumen round-trip restoration, the proposal independently applies the already accepted authority distinction:

```text
restoration authority != creation authority
```

The proposed exact category-axis equivalence rule is:

```text
original canonical category == nil
→ restored canonical category == nil
```

Supported restoration of a previously canonical categoryless Transaction may therefore use specifically admitted restoration authority inside meaningful Review/Confirm.

That authority must be identifiable as restoration from a supported Lumen round-trip representation and must not make Category optional for manual creation, foreign-source mapping, generic structured import, OCR/extraction proposals, ordinary new Lumen Transactions, or other non-restoration ingestion.

The exact UI, restoration-context representation, importer mechanics, and general Category-reference reconstruction mechanism are not decided here.

## 13.4 Existing repository evidence

Same-schema URL-backed persistence tests persist and reopen `Transaction` objects whose Category is omitted from the initializer and therefore `nil`. This proves persisted current-schema durability for `category == nil`. It does **not** prove that those fixture records became canonical through the governing user-authorized Draft → Review → Confirm boundary, and it does not prove authentic historical/user-store prevalence.

No current production path was found that creates a new categoryless Transaction through ordinary confirmation, clears an existing Category, or deletes a Category and demonstrates a resulting null relationship. Category-deletion-induced nullability is therefore not claimed as repository-proven behavior.

## 13.5 CSV remains separately scoped

Lumen CSV v1 is narrower. Blank Category compatibility cells already exist in the candidate shape, but exact CSV categoryless round-trip semantics remain separately gated.

These categoryless Portable JSON semantics are **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

Acceptance includes exact-null semantics, complete-export compatibility, `nil → nil` supported-restoration equivalence, and the invariant that restoration authority remains distinct from ordinary creation/non-restoration ingestion authority. General non-null Category reference identity/resolution remains separately gated.

---

# 14. PortableMoneyV1

PortableMoneyV1 represents the native monetary fact.

It does not represent reporting-currency valuation.

## 14.1 Responsibilities

```text
amount
= positive base-10 decimal magnitude

currency
= native denomination

type
= separate transaction direction/type semantic
```

## 14.2 Amount lexical grammar — PROPOSED

A PortableMoneyV1 amount is JSON text / CSV text using:

- ASCII decimal digits `0`–`9`;
- optionally one `.` decimal separator;
- at least one digit before the decimal separator;
- at least one digit after the separator when the separator is present.

Conceptual candidate grammar:

```text
[0-9]+(\.[0-9]+)?
```

The lexical representation does **not** permit:

- `+` or `-` sign;
- currency symbol;
- grouping separator;
- comma decimal separator;
- exponent notation;
- `NaN`;
- `Infinity`;
- leading/trailing whitespace.

Examples:

```text
"52.30"     lexical shape allowed
"5200"      lexical shape allowed
"12.345"    lexical shape allowed
"0"         lexical shape allowed
"0.00"      lexical shape allowed

"-52.30"    invalid lexical shape
"+52.30"    invalid lexical shape
"$52.30"    invalid lexical shape
"1,234.56"  invalid lexical shape
"52,30"     invalid lexical shape
"5.23e1"    invalid lexical shape
"NaN"       invalid lexical shape
```

Lexical validity does not establish Transaction-domain validity.

For example:

```text
"0.00"
→ syntactically parseable decimal text
→ outside the current canonical Transaction amount > 0 domain
```

## 14.3 Leading-zero policy — RESEARCH / ADMISSION REQUIRED

The lexical grammar above deliberately does not yet decide whether:

```text
"052.30"
```

is:

- accepted and normalized;
- rejected as noncanonical input;
- or handled by another explicit rule.

The completed persistence characterization showed that a leading-zero probe can normalize through the current durable amount path without changing its monetary value.

What remains is therefore a public-format policy/admission decision, not an unresolved persistence fact.

The final rule must be deterministic.

## 14.4 Trailing zeros and source scale — PROPOSED

Portable v1 monetary equivalence does **not** preserve arbitrary source lexical scale as transaction provenance.

The characterization observed that:

```text
"52.3"
"52.30"
"52.300"
```

all enter the current durable `Double` representation as the same monetary value.

Therefore those spellings must not be treated as three distinct portable financial facts merely because their source text used different trailing-zero scale.

The exact canonical decimal spelling remains governed by Section 14.8, but the portable semantic is monetary value rather than source trailing-zero preservation.

## 14.5 Product upper magnitude — PROPOSED / lower exponent remains open

Portable v1 has not yet frozen its **product** decimal-exponent / maximum-magnitude envelope.

A dedicated magnitude characterization has now separated raw binary64 capability from the current Lumen create path.

Sanitized evidence is recorded in:

`docs/knowledge/investigations/phase1c-portable-money-magnitude-characterization.md`

### Characterized current create-path envelope

For the tested values with no more than 15 normalized significant decimal digits, the current `TransactionDraft → makeTransaction → LedgerWrite / SwiftData save/reopen` path passed across these precision-dependent adjusted-exponent ranges:

| Normalized precision `p` | Adjusted exponent `A` all-pass range | Equivalent normalized exponent `E` |
| ---: | ---: | ---: |
| 1 | -128 ... 127 | -128 ... 127 |
| 2 | -127 ... 128 | -128 ... 127 |
| 5 | -124 ... 131 | -128 ... 127 |
| 10 | -119 ... 136 | -128 ... 127 |
| 15 | -114 ... 141 | -128 ... 127 |

Those ranges collapse to one current implementation rule:

> **Within the characterized coefficient/precision set, the current Lumen create/save/reopen path passed when normalized decimal exponent `E` was within `-128...127`.**

For a later rule that requires one precision-independent adjusted-exponent interval across the entire proposed `p <= 15` precision class, the intersection of the tested all-pass ranges is:

```text
-114 <= A <= 127
```

That intersection is conservative and intentionally excludes some values that the current create path can handle at particular precisions. The normalized `E` rule remains the cleaner description of current implementation compatibility.

Immediately outside those per-precision boundaries, sampled values were rejected by the current `Money.magnitude` validation dependency even though many remained finite and monetarily equivalent as raw `Double` values.

Current validation includes:

```swift
Money.magnitude(amount) != nil
```

and `Money.magnitude` currently converts `String(Double)` through Foundation `Decimal`.

Apple documents `NSDecimalNumber`, which bridges with Swift `Decimal`, as supporting a decimal integer mantissa up to 38 digits and exponent from -128 through 127:

https://developer.apple.com/documentation/foundation/nsdecimalnumber

The characterization therefore treats `E = -128...127` as a **current implementation compatibility envelope**, not as the public PortableMoneyV1 product promise.

### Raw binary64 is materially wider

The same diagnostic observed that raw `Double` parsing/representation remains viable far outside the current create-path envelope, while the expected underflow/overflow failures appear only near binary64's much wider technical extremes.

Reference points:

- https://developer.apple.com/documentation/swift/double
- https://en.cppreference.com/w/c/types/limits

Portable v1 must not equate `Double.greatestFiniteMagnitude`, Foundation Decimal's current exponent range, or any other implementation maximum with a useful financial product limit.

### Product upper magnitude — PROPOSED

The technical characterization is intentionally much wider than the product contract should promise.

A separate product-domain proposal is recorded in:

`docs/architecture/LUMEN_PORTABLE_MONEY_V1_PRODUCT_MAGNITUDE_PROPOSAL.md`

PortableMoneyV1 proposes the following public **upper** magnitude ceiling:

```text
x < 10^15
```

Equivalently, using adjusted decimal exponent `A = E + p - 1`:

```text
A <= 14
```

This applies independently from the already-proposed precision rule:

```text
p <= 15 normalized significant decimal digits
```

Therefore the current candidate upper money domain is:

```text
0 < x < 10^15
AND
p <= 15
```

subject independently to scale, currency, serializer, and ordinary Transaction-domain requirements.

The `10^15` ceiling is proposed because it:

- aligns naturally with the 15-digit precision contract;
- allows up to 15 whole-number decimal positions before the decimal point;
- leaves enormous headroom for ordinary, high-value, and high-denomination personal-finance records;
- keeps exponent-free JSON/CSV amounts manageable to inspect;
- remains radically below the current technical ceiling.

Values at or above `10^15` are not claimed to be technically unrepresentable. They are simply outside the proposed PortableMoneyV1 public product ceiling.

> **Technical capability is a ceiling, not the product promise.**

### Lower/minimum magnitude remains open

This proposal does **not** set a minimum positive PortableMoneyV1 magnitude.

For normalized value:

```text
x = C × 10^E
```

a lower bound on normalized exponent `E` directly constrains fractional decimal scale.

That overlaps the still-open:

- maximum-scale contract;
- currency-specific scale contract.

The lower/tiny-value side of the monetary domain must therefore be admitted together with, or consistently derived from, those scale semantics rather than being guessed here.

The existing guardrail for current or historical canonical amounts outside the final PortableMoneyV1 admitted domain remains unchanged: export must not silently round, coerce, substitute, or omit those values.

## 14.6 Global normalized scale and lower structural magnitude — PROPOSED / independently reviewed

PortableMoneyV1 defines **normalized scale** from the already-defined normalized decimal form:

```text
x = C × 10^E
```

as:

```text
S = max(0, -E)
```

Normalized scale is a property of the exact mathematical decimal value after nonsemantic trailing zeros are removed.

It is not the number of fractional characters originally supplied.

A separate product-domain proposal is recorded in:

`docs/architecture/LUMEN_PORTABLE_MONEY_V1_SCALE_LOWER_MAGNITUDE_PROPOSAL.md`

### Proposed global structural rule

PortableMoneyV1 proposes:

```text
S <= 9
```

equivalently:

```text
E >= -9
```

This yields a minimum **structurally** admitted positive magnitude of:

```text
10^-9
```

Combined with the already-proposed upper magnitude and precision rules, the global structural money domain becomes:

```text
10^-9 <= x < 10^15
p <= 15 normalized significant decimal digits
S <= 9
```

subject independently to currency-specific scale semantics, admitted currency membership, canonical serialization, Transaction-domain requirements, and historical/out-of-domain disposition.

### Why nine is structural rather than currency-specific

The repository already protects a legacy canonical `KWD` amount with nine fractional digits from being rewritten by an unrelated edit.

A global structural ceiling below nine would immediately classify that known compatibility class outside the portable structural domain.

That fact does **not** make nine fractional digits ordinary KWD semantics.

Unicode CLDR currency metadata illustrates why the responsibilities must stay separate: conventional currency fraction digits vary by currency, including JPY at 0, USD at 2, KWD at 3, and UYW at 4, with a default of 2 when no override is present.

Reference points:

- https://www.unicode.org/reports/tr35/tr35-numbers.html
- https://unicode.org/cldr/charts/latest/supplemental/detailed_territory_currency_information.html

Therefore:

```text
GLOBAL STRUCTURAL SCALE
S <= 9
        ↓
CURRENCY-SPECIFIC SCALE / MINOR-UNIT SEMANTICS
PROPOSED / independent review required
```

A structurally valid value is not automatically semantically ordinary or READY for every currency.

### Currency-specific readiness semantics — PROPOSED / independently reviewed

A separate proposal is recorded in:

`docs/architecture/LUMEN_PORTABLE_MONEY_V1_CURRENCY_SCALE_SEMANTICS_PROPOSAL.md`

For an admitted currency `c`, that proposal defines:

```text
O(c) = Lumen-owned, versioned ordinary currency scale
```

and classifies a structurally valid exact amount as:

```text
S <= O(c)
→ ordinary-scale
→ READY on the currency-scale axis

O(c) < S <= 9
→ over-ordinary-scale
→ workflow-specific readiness
```

The proposed workflow rule is:

- new manual confirmation: over-ordinary-scale is **NEEDS RESOLUTION**;
- generic structured import: over-ordinary-scale is **NEEDS RESOLUTION**;
- existing canonical edit with unchanged exact `(amount, currency)`: preserve the exact pair without renewed scale resolution solely because another field changed;
- existing canonical edit with changed amount or currency: evaluate the resulting pair; an over-ordinary-scale result is **NEEDS RESOLUTION**;
- existing canonical export: preserve and export the exact structurally admitted value without scale rounding;
- supported Lumen portable round-trip restoration: preserve the exact canonical value and treat scale as READY for restoration, with an advisory indication where useful;
- display/review surfaces must not conceal an exact atypical value behind only a rounded conventional rendering.

Resolution for new/manual, changed canonical monetary pairs, or generic structured import may deliberately edit the amount or explicitly keep the exact atypical value.

No automatic rounding, truncation, clamping, coercion, substitution, or omission is admitted.

The ordinary-scale proposal uses stable CLDR general currency `digits` semantics as its primary standards basis, with ISO 4217 Maintenance Agency data retained as authoritative currency-code/minor-unit evidence.

`O(c)` models ordinary fractional scale only. CLDR's separate general `rounding` increment is not silently enforced or discarded by this rule; any nonzero general rounding increment in the selected registry metadata requires a separate explicit Lumen disposition.

Cash-specific `cashDigits` / `cashRounding` do not become general Transaction readiness rules.

Complete registry membership and registry/version semantics remain a separate gate from ordinary-scale readiness and are now proposed in `docs/architecture/LUMEN_PORTABLE_MONEY_V1_CURRENCY_REGISTRY_PROPOSAL.md`. Historical/current canonical compatibility remains separately open.

Current manual entry and Foundation display formatting remain implementation behavior, not portable authority.

The completed technical characterization demonstrated that much smaller values are representable by the current numeric path; the `S <= 9` rule remains a product-domain boundary rather than a storage limitation.

The existing structural out-of-domain guardrail remains unchanged: export must not silently round, truncate, coerce, substitute, or omit a canonical amount merely to satisfy a PortableMoneyV1 boundary.

## 14.7 Precision, scale, value, and spelling are distinct

For a representation such as:

```text
123.450
```

the format review must distinguish:

- mathematical monetary value;
- decimal scale;
- decimal precision;
- supplied lexical spelling.

Those concepts must not be used interchangeably.

### Normalized significant decimal precision — PROPOSED

For a nonzero positive exact decimal value `x`, PortableMoneyV1 defines its normalized decimal form as the unique pair `(C, E)` such that:

```text
x = C × 10^E
```

where:

- `C` is a positive integer;
- `C` is not divisible by 10;
- `E` is an integer decimal exponent.

The **normalized significant decimal precision** of `x` is the number of base-10 digits in `C`.

Examples:

```text
52.300
→ 523 × 10^-1
→ precision 3

0.000052300
→ 523 × 10^-7
→ precision 3

1200000000000000
→ 12 × 10^14
→ precision 2

1000.01
→ 100001 × 10^-2
→ precision 6

0.00100
→ 1 × 10^-3
→ precision 1
```

Zero is not assigned normalized significant precision for the current Portable Transaction domain because current canonical creation requires `amount > 0`. Zero may remain lexically valid decimal text while being inadmissible as a Transaction amount.

### Conservative v1 precision limit — PROPOSED

PortableMoneyV1 uses a conservative precision limit of:

> **at most 15 normalized significant decimal digits**

This proposal is supported by both:

- the bounded durable characterization, which observed 522 / 522 passes for sampled 1–15 digit values and direct monetary-value counterexamples beginning in the 16-digit sample; and
- the established binary64 `digits10` / `DBL_DIG = 15` decimal text → double → decimal text round-trip guarantee, subject to representable-range constraints.

Reference points:

- Swift `Double` is a double-precision (64-bit) floating-point type: https://developer.apple.com/documentation/swift/double
- Swift's decimal-string `Double` initializer documents IEEE 754 round-to-nearest, ties-to-even behavior plus underflow/overflow behavior: https://developer.apple.com/documentation/swift/double/init%28_%3A%29-5wmm8
- `DBL_DIG` / `digits10` for IEEE `double` is 15: https://en.cppreference.com/w/c/types/limits and https://en.cppreference.com/w/cpp/types/numeric_limits/digits10

Values exceeding 15 normalized significant decimal digits are **not** declared inherently unrepresentable. Some such values are exactly representable by binary64. PortableMoneyV1 simply provides no general precision guarantee for values above the conservative 15-digit v1 limit.

The precision rule is **not sufficient by itself** for PortableMoneyV1 admission.

A candidate amount must still satisfy independently admitted rules for:

- decimal exponent / maximum magnitude;
- maximum scale;
- currency-specific scale semantics;
- admitted currency;
- canonical plain-decimal serialization;
- ordinary Transaction-domain requirements.

The completed characterization is sampled evidence, not exhaustive enumeration of every <=15-digit decimal across every exponent.

## 14.8 Canonical decimal serialization — RESEARCH / ADMISSION REQUIRED

Portable v1 must define one deterministic plain-decimal spelling for canonical export.

The completed characterization rejects direct:

```swift
String(transaction.amount)
```

as the public serializer because sufficiently large values can be emitted in exponent notation, which is outside the PortableMoneyV1 lexical grammar.

A test-only candidate that:

1. starts from a shortest-round-trip binary64 decimal spelling;
2. expands exponent notation into ordinary decimal notation;
3. removes insignificant leading integer zeros;
4. removes insignificant trailing fractional zeros;

produced lexically valid plain-decimal output for every create-valid probe in the refined run.

That demonstrates feasibility without a storage migration.

It does **not** yet define the language-independent Portable v1 canonicalization algorithm. The final contract must specify that algorithm without making Swift's `String(Double)` implementation itself the public standard.

---

# 15. Currency Tokens and Admitted Currency Universe

## 15.1 Currency-token grammar — PROPOSED

Portable v1 currency values use exactly three uppercase ASCII letters:

```text
[A-Z]{3}
```

Examples:

```text
USD  lexically well formed
EUR  lexically well formed
JPY  lexically well formed
KWD  lexically well formed

usd  noncanonical token
Usd  noncanonical token
$    invalid token shape
```

Lexical shape does not establish that a token is admitted.

## 15.2 Stable Lumen-owned admitted-currency definition — PROPOSED RESPONSIBILITY

Portable currency validity must not depend on:

- `Locale.commonISOCurrencyCodes`;
- the host iOS/macOS SDK;
- device locale;
- current regional settings;
- a platform list that may evolve independently of the portable specification.

The candidate governing rule is:

> **Lumen Portable v1 currency values must be uppercase three-letter codes admitted by the stable Lumen Portable v1 currency definition.**

That definition may be derived from ISO 4217 semantics, but Lumen must deliberately decide what is valid as a denomination for canonical Transactions.

## 15.3 Ordinary currency scale and readiness — PROPOSED

For each admitted currency to which ordinary fractional-scale semantics apply, Portable v1 proposes a Lumen-owned, versioned value:

```text
O(c) = ordinary currency scale
```

This value must not be fetched implicitly from the runtime OS.

The proposed primary standards basis is stable Unicode CLDR general currency `digits` metadata.

CLDR defines `digits` as the normal decimal digits for currency formatting, uses a default of 2 when no currency-specific override exists, and bases the value on ISO 4217 minor-unit information while permitting documented customary differences.

ISO 4217 Maintenance Agency data remains authoritative evidence for currency-code and minor-unit facts.

The proposed readiness rule for a structurally admitted amount is:

```text
S <= O(c)
→ READY on currency-scale axis

O(c) < S <= 9
→ over-ordinary-scale
```

For **new manual confirmation** and **generic structured import**, over-ordinary-scale means:

```text
NEEDS RESOLUTION
```

The exact amount must remain intact. Resolution may deliberately edit the amount or explicitly keep the exact atypical amount.

For an **existing canonical edit**, an unchanged exact `(amount, currency)` pair does not require renewed scale resolution solely because another field changed. If amount or currency changes, the resulting pair is evaluated again; an over-ordinary-scale result requires explicit resolution.

For **existing canonical export** and **supported Lumen portable round-trip restoration**, an over-ordinary-scale value inside the global structural domain must remain exact; ordinary currency scale is not a rounding instruction.

`O(c)` models ordinary fractional scale only. CLDR general `rounding` is a separate increment axis. If the selected stable registry metadata contains a nonzero general rounding rule, that rule requires a separate explicit Lumen disposition and is neither silently enforced nor silently declared irrelevant by this scale contract.

Cash-specific CLDR `cashDigits` and `cashRounding` are not the default readiness rules for a general Lumen Transaction.

The complete decision record is:

`docs/architecture/LUMEN_PORTABLE_MONEY_V1_CURRENCY_SCALE_SEMANTICS_PROPOSAL.md`

These ordinary-scale/readiness semantics are **PROPOSED / independently reviewed**.

## 15.4 Currency registry membership — PROPOSED

A separate registry proposal is recorded in:

`docs/architecture/LUMEN_PORTABLE_MONEY_V1_CURRENCY_REGISTRY_PROPOSAL.md`

The first proposed immutable registry identifier is:

```text
lumen-currency-v1
```

Its pinned source evidence is:

- SIX ISO 4217 List One XML published `2026-09-17`;
- Unicode CLDR 48.2, pinned to the `release-48-2` source snapshot.

A code enters `lumen-currency-v1` only when the pinned SIX List One entry has:

```text
Ccy matching [A-Z]{3}
CcyNm IsFund != true
numeric CcyMnrUnts
```

Duplicate territory rows collapse to one code and must agree on the relevant code metadata.

That construction yields exactly:

```text
155 admitted codes
```

The proposal explicitly excludes from the first registry:

- current List One entries marked `IsFund="true"`;
- precious-metal and other special codes with N.A. minor units;
- SDR;
- bond-market units;
- testing;
- the no-currency code;
- historical/withdrawn List Three codes.

Those exclusions are Portable v1 registry-membership decisions.

They do not authorize mutation or omission of existing canonical state; historical/current compatibility remains a separate gate.

For each admitted code, the immutable `O(c)` value is taken from pinned CLDR 48.2 general `digits`, using its pinned `DEFAULT digits = 2` when no currency-specific override exists.

The complete 155-code membership and `O(c)` grouping are normative in the registry proposal.

These registry semantics are **PROPOSED / independently reviewed**.

## 15.5 Registry identity and evolution — PROPOSED

Portable currency semantics must carry an explicit immutable registry identifier.

For the initial candidate contract:

```text
lumen-currency-v1
```

is the only supported value.

The identifier is Lumen-owned rather than named after ISO alone because its semantics combine pinned ISO 4217 / SIX membership evidence with pinned CLDR ordinary-scale evidence.

Once accepted, a registry identifier is immutable.

Its:

- admitted member set;
- `O(c)` mapping;
- pinned source-snapshot identity

must not change in place.

A changed membership or changed `O(c)` mapping requires a different registry identifier.

Portable JSON v1 carries the registry identifier once in the top-level `currency_registry` field.

Lumen CSV v1 carries it in the required `currency_registry` column, whose value must be identical across all data rows.

A receiving implementation must not substitute:

- its current OS currency list;
- its current CLDR version;
- the latest known Lumen registry;
- an inferred registry based on export date.

An unknown registry identifier is a well-formed but unsupported portable semantic.

Registry evolution is independently versioned from the public schema. A later registry identifier may be supported with Portable format version 1 only through an explicit later admission; this proposal does not pre-admit any future registry.

---

# 16. Candidate Money Characterization Invariant

The bounded characterization has now been executed against this candidate invariant.

Its governing question was:

For a precisely defined candidate PortableMoneyV1 domain:

> **Does the current durable `Transaction.amount: Double` path preserve the monetary-value equivalence required by Portable v1?**

The candidate test path is:

```text
candidate portable decimal
        ↓
candidate strict parser
        ↓
current canonical Double
        ↓
SwiftData durable save
        ↓
store close / reopen
        ↓
reopened Double
        ↓
candidate canonical portable serializer
        ↓
portable decimal
        ↓
compare contractual monetary value
```

Success does **not** require IEEE-754 binary exactness.

Success requires the final portable value to be contractually monetarily equivalent to the admitted input value.

Textual equality is not automatically required.

## 16.1 Required human-readable probes

At minimum, the characterization design must cover cases in these families:

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

These are design probes, not pre-approved v1 values.

## 16.2 Required systematic coverage

The characterization must also generate values around the candidate:

- magnitude boundaries;
- scale boundaries;
- precision boundaries;
- transition cases likely to expose decimal-to-binary-to-decimal changes.

It must test currency contexts sufficient to detect accidental fixed-two-decimal assumptions, including representation probes for:

- USD;
- EUR or GBP;
- JPY;
- KWD.

## 16.3 Evidence output

The characterization must preserve:

- tested domain/envelope;
- generation strategy;
- candidate value;
- currency/context;
- parsed Double;
- reopened Double;
- serialized result;
- expected monetary value;
- observed monetary value;
- pass/failure classification;
- counterexamples.

"Many tests passed" without the tested envelope is insufficient architectural evidence.

## 16.4 Characterization result does not authorize migration

The decision tree remains:

```text
characterization
        ↓
useful safe PortableMoneyV1 domain demonstrated?
        ├─ yes → continue format admission against that bounded domain
        └─ no / materially inadequate
                ↓
          separate money-persistence admission
```

A failed characterization is evidence.

It is not automatic authorization to migrate away from `Double`.

The completed runs demonstrate a useful bounded candidate domain, so this evidence does **not** earn a money-storage migration.

## 16.5 Characterization evidence — COMPLETED, FORMAT STILL PROPOSED

Sanitized evidence is recorded in:

`docs/knowledge/investigations/phase1c-portable-money-double-characterization.md`

The refined successful run exercised:

- 1,723 total probes;
- 1,721 values accepted by the current create path and durably persisted;
- 1,385 monetary-equivalence passes;
- 336 monetary-value changes;
- 2 current-domain rejections for zero;
- zero observed SwiftData `Double.bitPattern` changes across save/reopen;
- zero exponent/lexical failures with the normalized plain-decimal candidate serializer.

The decisive precision-position result is:

```text
<=15 significant decimal digits: 522 / 522 sampled passes
16 significant decimal digits:    4 sampled monetary-value failures
17 significant decimal digits:   32 sampled monetary-value failures
```

The characterization therefore narrows, but does not by itself finalize:

- maximum admitted precision;
- maximum magnitude;
- maximum scale;
- currency-specific scale;
- the exact language-independent canonical serializer.

No unrelated currency, date, identity, timestamp, type/direction, provenance, or non-Transaction schema gate is resolved by this evidence.

---

# 17. FX and Reporting-Currency Semantics

**OUT OF SCOPE for Portable v1 transaction facts.**

Portable v1 records native denomination:

```text
native amount
+
native currency
+
transaction type
```

It does not define:

- exchange rates;
- rate providers;
- rate provenance;
- transaction-date vs posting-date vs current FX selection;
- reporting currency;
- converted amount;
- FX rounding;
- cached valuations;
- cross-currency totals.

Same-currency arithmetic can later be truthful without FX:

```text
USD net
EUR net
JPY net
```

A single aggregate across unlike currencies requires a future valuation contract.

> **Transaction currency records what happened. Reporting currency, if later admitted, describes how a user chooses to value/view it.**

Portable v1 must not rewrite the native transaction fact into the user's preferred reporting currency.

---

# 18. Financial Dates and Timestamps

## 18.1 Financial calendar dates — PROPOSED

Candidate Portable v1 financial-date fields use ISO calendar-date text:

```text
YYYY-MM-DD
```

Candidate fields:

- `transaction_date`;
- `posted_date`.

These fields represent financial calendar-date semantics rather than generic instants.

## 18.2 Conversion from current `Date` storage — EVIDENCE GATED

The current canonical model stores these fields using Foundation `Date`.

The final format must define and test:

- which calendar/timezone context establishes the financial date;
- how current persisted instants map to a portable calendar date;
- how re-import reconstructs equivalent canonical meaning;
- DST/date-boundary behavior.

The format must not simply call a default Date formatter and assume the result is portable truth.

## 18.3 Lifecycle timestamps — PROPOSED

Lifecycle fields such as:

- `exported_at`;
- `created_at`;
- `updated_at`;

represent instants.

They use an RFC 3339 / ISO-8601 offset-aware representation normalized to UTC for canonical export.

Exact fractional-second canonicalization remains **RESEARCH / ADMISSION REQUIRED** before byte-level deterministic serialization is frozen.

Whether lifecycle timestamps are themselves round-trip-preserved portable semantics is also **RESEARCH / ADMISSION REQUIRED**.

Before format acceptance, the contract must decide whether fields such as:

- `Transaction.created_at`;
- `Transaction.updated_at`;
- `Category.created_at`;
- `PaymentMethod.created_at`;
- `Tag.created_at`;
- portable Source `created_at`;

are:

- restored as original portable semantics;
- exported as informational metadata that may legitimately be regenerated on import;
- or excluded from the final portable contract.

The format must not simultaneously admit a timestamp as round-trip-preserved state and silently regenerate a different value during restoration.

## 18.4 Foreign temporal representations do not define Lumen format

Foreign adapters may encounter:

- Date only;
- Date + Time;
- Date + Time + zone;
- Transaction Date + Posted Date;
- statement date;
- settlement date.

Those are mapping inputs.

They do not require Lumen CSV v1 to reproduce each source shape.

---

# 19. Category Portable Record

## 19.1 Candidate shape — PROPOSED

```json
{
  "portable_id": "cat-example",
  "name": "Example Category",
  "group": "custom",
  "color": "#2F6B57",
  "icon": "tag",
  "is_default": false,
  "created_at": "2026-01-01T12:00:00Z"
}
```

## 19.2 Proposed group tokens

Current candidate v1 group values mirror the current canonical enum:

- `fixed_costs`;
- `investments`;
- `savings_goals`;
- `guilt_free_spending`;
- `income`;
- `custom`.

## 19.3 Field exactness

The candidate shape does not yet freeze the required/nullable/omitted disposition of every Category field or the round-trip role of `created_at`. Those decisions remain explicit format-acceptance gates in Section 32.

## 19.4 Conflict behavior is not identity

A matching name/group may support a merge proposal.

It does not automatically establish entity identity or overwrite authority.

Exact reference-entity conflict behavior remains governed by the accepted Phase 1C responsibility contract and later import design.

---

# 20. PaymentMethod Portable Record

## 20.1 Candidate shape — PROPOSED

```json
{
  "portable_id": "pm-example",
  "name": "Example Card",
  "method_type": "credit_card",
  "institution_name": "Example Institution",
  "last_four": "1234",
  "notes": null,
  "is_active": true,
  "created_at": "2026-01-01T12:00:00Z"
}
```

The example is synthetic.

## 20.2 Proposed method-type tokens

- `cash`;
- `debit_card`;
- `credit_card`;
- `bank_transfer`;
- `hsa`;
- `fsa`;
- `gift_card`;
- `other`.

## 20.3 Field exactness

The candidate shape does not yet freeze the required/nullable/omitted disposition of every PaymentMethod field. In particular, `institution_name`, `last_four`, `notes`, and the round-trip role of `created_at` remain explicit format-acceptance gates in Section 32.

## 20.4 Credential boundary

Portable PaymentMethod data must not evolve into credential export by accident.

This contract does not authorize portability of:

- full card numbers;
- banking credentials;
- authentication tokens;
- cryptographic secrets;
- account-login state.

---

# 21. Tag Portable Record

## 21.1 Candidate shape — PROPOSED

```json
{
  "portable_id": "tag-example",
  "name": "Example Tag",
  "color": "#2F6B57",
  "created_at": "2026-01-01T12:00:00Z"
}
```

Tag relationships are represented from Transaction through `tag_refs`.

The candidate shape does not yet freeze the required/nullable/omitted disposition of every Tag field or the round-trip role of `created_at`; those remain explicit format-acceptance gates in Section 32.

Tags are intentionally omitted from initial CSV v1 because they are multi-valued and JSON is the higher-fidelity reference graph.

A later CSV revision may admit a deterministic tag encoding if product value earns it.

---

# 22. TransactionSource / Provenance Projection

The public format must not blindly serialize `TransactionSource`.

Phase 1B established that the current model mixes origin, evidence-storage, processing, and compatibility responsibilities.

## 22.1 Candidate source record — PROPOSED PARTIAL PROJECTION

The initial candidate projection is deliberately small:

```json
{
  "portable_id": "src-example",
  "source_type": "receipt_photo",
  "mime_type": "image/jpeg",
  "file_size_bytes": 123456,
  "created_at": "2026-01-01T12:00:00Z"
}
```

This record does **not** mean that the importing installation possesses the raw evidence payload.

## 22.2 Candidate included source fields

| Field | Status | Portable meaning |
| --- | --- | --- |
| `portable_id` | identity generation gated | portable relationship key |
| `source_type` | PROPOSED | origin/source classification |
| `mime_type` | PROPOSED | recorded supplied representation type when established |
| `file_size_bytes` | PROPOSED | recorded supplied representation size when established |
| `created_at` | PROPOSED | source-record lifecycle instant |

The exact required/nullable/omitted disposition of the candidate Source fields is not yet frozen. In particular, `mime_type`, `file_size_bytes`, and lifecycle timestamp restoration remain explicit format-acceptance gates in Section 32.

The normalized Portable v1 `source_type` token set is **RESEARCH / ADMISSION REQUIRED**. Current implementation enum values are not automatically public portable tokens merely because they exist in Swift code.

## 22.3 Source fields requiring further disposition

The following are **RESEARCH / ADMISSION REQUIRED** before inclusion:

- `original_filename` — useful metadata but potentially sensitive;
- `uploaded_at` — ingestion lifecycle semantics;
- `captured_at` — current semantics/coverage are weak;
- `source_timezone` — current value must not be mistaken for artifact-native timezone.

## 22.4 Explicitly excluded source fields

The candidate v1 JSON/CSV formats do not export:

- `stored_file_uri`;
- `compressed_file_uri`;
- `metadata_json`;
- `raw_extracted_text`;
- `parse_status`;
- `source_hash`.

Reasons include:

- machine-local locator state is not transferable identity;
- processing state is not canonical financial truth;
- opaque metadata may be sensitive/semantically undefined;
- raw extracted text is extraction/observation state;
- legacy `source_hash` has no admitted content-identity contract.

## 22.5 No false evidence availability

A portable source record without payload bytes must never cause the receiving installation to report:

- retained evidence available;
- readable local evidence;
- a valid local `stored_file_uri`;
- a local retained payload merely because the exporting installation once had one.

Raw evidence payload portability requires a separately admitted package/contract.

---

# 23. Deterministic JSON Representation

Portable JSON v1 must eventually have deterministic export rules.

## 23.1 Fixed semantic field names — PROPOSED

The public field names in this proposal are snake_case and must not be inferred from Swift property reflection at runtime.

## 23.2 Object key ordering — PROPOSED

Although JSON object key order is not semantic JSON meaning, the canonical Lumen exporter should emit a fixed documented key order for reproducible fixtures, diffs, and tests.

The order shown in candidate shapes is the proposed order.

## 23.3 Array ordering — EVIDENCE GATED / IDENTITY DEPENDENT

Canonical array ordering must be deterministic.

The exact sort keys cannot be finalized until portable identity generation/stability is resolved.

The final rule must not depend on arbitrary in-memory collection order.

## 23.4 Byte-for-byte identity is not the round-trip guarantee

`exported_at`, identity choices, and canonical serialization metadata can make two exports byte-different even when they represent equivalent supported state.

Round-trip ownership is defined semantically, not as file hash equality.

---

# 24. Lumen CSV v1 Scope

CSV v1 is deliberately narrower than Portable JSON v1.

It is a transaction-oriented interchange projection, not an encoding of the entire portable entity graph.

## 24.1 Proposed exact header — PROPOSED

The candidate v1 header order is:

```text
currency_registry,transaction_date,posted_date,amount,currency,type,status,merchant_name,category_name,category_group,payment_method_name,notes
```

The blank downloadable template must eventually derive from this exact admitted header definition.

## 24.2 CSV field meanings

| Column | Required text? | Semantic |
| --- | --- | --- |
| `currency_registry` | yes | immutable Lumen currency-registry identifier; all rows in one file must match |
| `transaction_date` | yes | financial calendar date |
| `posted_date` | no | optional financial posted date |
| `amount` | yes | PortableMoneyV1 magnitude |
| `currency` | yes | PortableMoneyV1 currency |
| `type` | yes | Lumen transaction type token |
| `status` | yes | Lumen transaction status token; final domain gated as above |
| `merchant_name` | yes | merchant/counterparty |
| `category_name` | may be blank in exported compatibility state | Category mapping input; must be resolved before current canonical confirmation |
| `category_group` | may be blank with absent category | Category disambiguation/mapping context |
| `payment_method_name` | no | optional PaymentMethod mapping input |
| `notes` | no | optional user notes |

## 24.3 Deliberately omitted from CSV v1

Initial CSV v1 does not attempt full fidelity for:

- Tags;
- TransactionSource/provenance;
- Category color/icon/default metadata;
- PaymentMethod type/institution/last-four/notes/active state;
- entity creation/update timestamps;
- portable relationship IDs;
- raw evidence;
- workspace state;
- rewards/points;
- account balances.

Users who require the normative highest-fidelity portable representation use Portable JSON v1.

---

# 25. CSV Text Rules

## 25.1 Encoding — PROPOSED

Lumen CSV v1 uses UTF-8.

## 25.2 Delimiter — PROPOSED

The delimiter is comma (`,`).

## 25.3 Header — PROPOSED

The first row contains the exact v1 header in the exact documented order.

Alternate header aliases belong to foreign-file mapping, not Lumen CSV v1.

This exact ordered header is also the Lumen CSV v1 recognition signature defined in Section 29.2.

## 25.4 Quoting — PROPOSED

Fields containing comma, quote, or line-break characters use conventional CSV double-quote escaping:

- surround field with `"`;
- represent an embedded `"` as `""`.

The eventual implementation should validate behavior against a documented CSV parsing/writing contract rather than ad-hoc splitting.

## 25.5 Line endings — PROPOSED

The canonical exporter emits LF line endings.

The guaranteed Lumen importer may accept LF or CRLF without changing field semantics.

## 25.6 Null/empty CSV cells — PROPOSED

CSV has no JSON `null`.

For optional CSV fields, an empty cell represents absence.

For optional textual fields, CSV v1 therefore intentionally collapses the distinction between:

```text
JSON null / semantic absence
and
an intentional zero-length string
```

into CSV absence unless a later field-specific rule explicitly defines another representation.

CSV v1 does **not** promise JSON's null-versus-empty-string fidelity. If a future field requires an intentional empty string to remain semantically distinct from absence, that field needs an explicit CSV encoding rule or must remain JSON-only.

An empty cell is **not** valid for a required portable semantic such as currency_registry/amount/currency/type/merchant/date.

Category fields are the deliberate compatibility exception described above: an exported current record may lack Category, but that row is not READY for new canonical confirmation until Category is resolved.

## 25.7 Money semantics are shared with JSON

CSV does not get a separate money grammar.

Examples of Lumen-owned CSV amount values:

```text
52.30
5200
12.345
```

The guaranteed format does not use:

```text
$52.30
1,234.56
52,30
-52.30
5.23e1
```

Foreign CSV mapping may interpret other source conventions upstream.

---

# 26. JSON / CSV Semantic Equivalence

Where JSON and CSV represent the same admitted Transaction concept, they must use the same normalized semantics.

For example:

```json
{
  "amount": "52.30",
  "currency": "USD",
  "type": "expense"
}
```

and the corresponding fields in a complete Lumen CSV v1 row:

```text
currency_registry,transaction_date,posted_date,amount,currency,type,status,merchant_name,category_name,category_group,payment_method_name,notes
lumen-currency-v1,2026-01-04,,52.30,USD,expense,posted,Example Market,Example Category,custom,,
```

represent the same candidate PortableMoneyV1 + type meaning for the shared fields.

CSV must not invent:

- different currency aliases;
- signed-direction semantics;
- locale-specific decimal interpretation;
- different date semantics;
- different enum tokens.

CSV is narrower in field coverage, not looser in the meaning of fields it shares with JSON, except for explicitly documented representation loss such as the optional-text null/empty-string collapse in Section 25.6.

---

# 27. Template and Example Derivation

The downloadable blank CSV template must not be maintained as an independent interpretation of the format.

Conceptually:

```text
admitted CSV v1 schema
        ├── exporter header/order
        ├── importer expectations
        ├── blank downloadable template
        ├── synthetic example
        └── validation documentation/tests
```

The repository does **not** add a synthetic CSV fixture in this proposal.

A fixture/example should be added only when an executable or product need earns it.

If added later:

- it must be independently synthetic;
- it must not be a redaction/perturbation of private user transactions;
- it must validate against the same admitted CSV schema.

---

# 28. Round-Trip Guarantees

## 28.1 Portable JSON round trip — PROPOSED TARGET

The target remains:

```text
supported canonical state
        ↓
Portable JSON v1
        ↓
fresh/empty store
        ↓
parse / preview / resolution
        ↓
Review / explicit confirmation
        ↓
equivalent supported canonical state
```

Equivalence means preservation of the semantics explicitly admitted by the final v1 field/entity contract.

It does not require:

- same internal SwiftData IDs;
- same filesystem paths;
- same raw evidence payload availability;
- same import workspace representation;
- identical JSON bytes;
- preservation of arbitrary input lexical spelling.

## 28.2 CSV round trip is intentionally narrower

CSV v1 guarantees only the semantics represented by its admitted columns.

It does not promise restoration of JSON-only state such as Tags, source/provenance metadata, or full PaymentMethod/Category reference metadata.

## 28.3 Historical/current compatibility gates

The final v1 round-trip statement cannot be accepted until the format resolves at least:

- persisted statuses that current new-Transaction confirmation cannot directly create;
- current durable Transactions whose Category is nil;
- exact Date → financial calendar-date conversion;
- PortableMoneyV1 safe durable domain;
- round-trip/export disposition for any current or historical canonical Transaction amount that falls outside the final PortableMoneyV1 admitted domain;
- portable identity generation/stability sufficient for relationship reconstruction.

For an existing canonical Transaction whose exact monetary state is outside PortableMoneyV1 or whose currency is outside the selected admitted registry, export/round-trip behavior must be explicit.

The compatibility/disposition proposal in `LUMEN_PORTABLE_V1_CANONICAL_MONEY_COMPATIBILITY_DISPOSITION_PROPOSAL.md` proposes the following distinction:

```text
successful Portable v1 serialization
!= complete ownership export
!= full supported-state round trip
```

For a **complete Portable JSON v1 ownership export**, the independently reviewed proposed-contract rule is:

> **Preflight the coherent in-scope canonical snapshot. If any in-scope canonical Transaction cannot be represented exactly under PortableMoneyV1 + the selected admitted currency registry, the operation must not claim successful completion as a complete Portable v1 ownership export.**

This complete ownership-export guarantee belongs to **Portable JSON v1**, the normative highest-fidelity representation. Lumen CSV v1 remains deliberately narrower and is not thereby defined as a complete ownership export. Its narrower scope does not authorize monetary/currency rounding, truncation, clamping, coercion, substitution, registry fallback, or silent omission merely because the requested representation is CSV. The exact completeness/partial-export semantics of a future CSV export operation remain separately gated.

Preflight must be able to associate each incompatible Transaction with deterministic reason semantics covering all materially applicable monetary/currency incompatibility axes.

The exporter/import path must **not** silently:

- round or truncate the canonical monetary value;
- clamp it into the admitted domain;
- coerce it into the admitted domain;
- substitute another monetary value or currency;
- fall back to platform/current registry semantics;
- or omit the Transaction merely to make a complete export conform.

An explicitly partial Portable v1 export remains conceptually distinct from a complete ownership export and is **not admitted by this proposal**. If admitted later, it must be explicitly identified as partial and cannot claim round-trip restoration of excluded canonical state.

A separately identified compatibility representation may also be considered later, but it must not silently broaden PortableMoneyV1 or `lumen-currency-v1`.

These compatibility/disposition semantics are **PROPOSED / independently reviewed — accepted at the proposed-contract level**. Full Portable JSON / CSV v1 format acceptance remains open.

---

# 29. Version Handling

## 29.1 Portable JSON v1 recognition and semantic validity — PROPOSED

Portable JSON v1 **recognition** is established by:

```text
format == "lumen-portable"
version == 1
```

Those two fields identify the document as belonging to the Lumen Portable JSON v1 format family.

Recognition is distinct from full semantic validity.

A recognized Portable JSON v1 document is semantically valid only if all required v1 fields are present and valid, including a nonempty:

```text
currency_registry
```

For the initially supported registry semantic:

```text
currency_registry == "lumen-currency-v1"
```

A recognized Portable JSON v1 document with an unknown nonempty `currency_registry` remains recognizable as Portable JSON v1, but contains an **unsupported registry semantic**.

It must not be reinterpreted using the receiver's current platform metadata, current Lumen registry, or a guessed registry.

A document with a different `format` or `version` must not be parsed as v1 by guesswork.

## 29.2 Lumen CSV v1 recognition — PROPOSED

The exact ordered header defined in Section 24.1 is the recognition signature for Lumen CSV v1:

```text
currency_registry,transaction_date,posted_date,amount,currency,type,status,merchant_name,category_name,category_group,payment_method_name,notes
```

A CSV with a different header or different column order must not be silently interpreted as another Lumen CSV version.

Alternate names, aliases, additional provider columns, missing columns, or different ordering belong to the foreign-CSV mapping path unless a future Lumen CSV version explicitly admits them.

A later format revision may introduce another explicit version-recognition mechanism, but v1 does not infer version from approximate header similarity.

## 29.3 Future versions — PROPOSED

A future Lumen version may:

- continue to read v1;
- provide an explicit version adapter/migration;
- reject a newer unsupported version with a clear unsupported-version result.

It must not silently reinterpret incompatible future semantics through v1 rules.

## 29.4 Currency-registry identity and evolution — PROPOSED

Portable v1 carries currency-registry identity explicitly rather than inferring it only from the top-level format version.

For Portable JSON v1, `format == "lumen-portable"` plus `version == 1` performs format recognition as defined in Section 29.1.

Semantic validity additionally requires a nonempty `currency_registry`.

For the initially supported registry semantic:

```text
currency_registry == "lumen-currency-v1"
```

An unknown nonempty registry identifier does not erase format recognition; it produces a recognized Portable JSON v1 document with an unsupported registry semantic.

For Lumen CSV v1, every data row carries the same value in the required `currency_registry` column.

The registry identifier is immutable semantic version state.

A future registry requires a different identifier and explicit admission.

An implementation encountering an unknown registry identifier must report an unsupported registry semantic rather than applying its own current currency metadata.

The registry version may evolve independently from the Portable schema version, but no future registry/format combination is accepted implicitly.

---

# 30. Validation / Error Taxonomy

The format should distinguish at least:

## Malformed portable syntax

Examples:

- invalid JSON/CSV structure;
- malformed decimal lexical representation;
- missing required field;
- invalid enum token shape.

## Well-formed but unsupported portable semantic

Examples:

- lexically well-formed currency token not admitted by the selected Portable currency registry;
- unknown or unsupported `currency_registry` identifier;
- amount outside the finally admitted safe domain;
- unsupported future format version.

## Valid portable record needing resolution

Examples:

- Category absent under current confirmation contract;
- a reference cannot be unambiguously matched;
- a deliberately admitted import decision remains unresolved.

## Foreign-source mapping ambiguity

Examples:

- source currency absent;
- signed amount + provider-specific type requires interpretation;
- source status has no direct Lumen mapping;
- source date meaning is unclear.

These categories must not collapse into one generic "invalid import" outcome.

---

# 31. Explicit Portable v1 Non-Goals

This format contract does not define or authorize:

- arbitrary bank/provider CSV compatibility;
- provider-specific adapters;
- OCR;
- visual extraction;
- import-workspace serialization;
- workspace filesystem layout;
- promotion receipts;
- idempotency persistence;
- canonical promotion implementation;
- SwiftData migrations;
- change from `Double` to another money storage type;
- FX valuation;
- reporting-currency conversion;
- cross-currency aggregation;
- reward/points portability;
- account-balance portability;
- payment credentials;
- raw evidence payload packaging;
- cloud sync/backups;
- universal JSON ETL.

---

# 32. Remaining Gates Before Format Acceptance

The first proposal intentionally leaves these questions open.

## PortableMoneyV1

- canonical leading-zero input rule — RESEARCH / ADMISSION REQUIRED;
- normalized significant decimal precision definition — PROPOSED;
- <=15 normalized significant decimal digits as the conservative PortableMoneyV1 precision limit — PROPOSED;
- product upper magnitude ceiling `x < 10^15` / adjusted exponent `A <= 14` — PROPOSED / independently reviewed;
- normalized scale definition `S = max(0, -E)` — PROPOSED / independently reviewed;
- global structural scale ceiling `S <= 9` / `E >= -9`, implying minimum structural magnitude `10^-9` — PROPOSED / independently reviewed;
- currency-specific ordinary-scale definition and workflow readiness semantics — PROPOSED / independently reviewed;
- round-trip/export disposition for current or historical canonical Transaction monetary state outside PortableMoneyV1 or the selected admitted currency registry — PROPOSED / independently reviewed;
- exact language-independent plain-decimal canonical serializer — RESEARCH / ADMISSION REQUIRED.

## Currency

- exact `lumen-currency-v1` admitted membership — PROPOSED;
- pinned `lumen-currency-v1` ordinary-scale mapping — PROPOSED;
- registry identifier transport in Portable JSON / CSV — PROPOSED;
- immutable registry/version-evolution semantics — PROPOSED;
- historical/withdrawn and special/fund/metal/unit codes excluded from `lumen-currency-v1`; existing canonical compatibility for such values is covered by the canonical monetary compatibility/disposition proposal — PROPOSED / independently reviewed;
- general non-cash rounding-increment disposition for any admitted registry entry with a nonzero standards-backed rounding rule — RESEARCH / ADMISSION REQUIRED.

## Dates

- current `Date` → financial calendar-date conversion and timezone rule — EVIDENCE GATED;
- canonical fractional-second timestamp spelling — RESEARCH / ADMISSION REQUIRED.

## Identity / ordering

- portable ID grammar/generation — RESEARCH / ADMISSION REQUIRED;
- cross-export stability — RESEARCH / ADMISSION REQUIRED;
- deterministic array ordering tied to identity — EVIDENCE GATED.

## Transaction compatibility

- portability/restoration of `ignored`, `duplicate`, and `review_needed` persisted statuses — ACCEPTED AT PROPOSED-CONTRACT LEVEL;
- round-trip disposition for categoryless current-schema / compatibility-bearing Transactions — ACCEPTED AT PROPOSED-CONTRACT LEVEL; authentic historical prevalence remains unproven;
- directional/flow sufficiency of each unsigned-amount `type` token, especially `transfer` — RESEARCH / ADMISSION REQUIRED.

## Lifecycle timestamps

- inclusion versus informational-only versus exclusion semantics for entity/source lifecycle timestamps — RESEARCH / ADMISSION REQUIRED;
- if included as round-trip state, exact restoration requirements for original timestamp values — RESEARCH / ADMISSION REQUIRED.

## Non-Transaction record schemas

- exact required/nullable/omitted disposition for Category fields — RESEARCH / ADMISSION REQUIRED;
- exact required/nullable/omitted disposition for PaymentMethod fields, including `institution_name`, `last_four`, and `notes` — RESEARCH / ADMISSION REQUIRED;
- exact required/nullable/omitted disposition for Tag fields — RESEARCH / ADMISSION REQUIRED;
- exact required/nullable/omitted disposition for Source fields, including `mime_type` and `file_size_bytes` — RESEARCH / ADMISSION REQUIRED;
- normalized Portable v1 `source_type` token set — RESEARCH / ADMISSION REQUIRED.

## Provenance

- whether `original_filename`, `uploaded_at`, `captured_at`, or `source_timezone` enter v1 — RESEARCH / ADMISSION REQUIRED.

## Parser evolution

- unknown-field policy inside v1 — RESEARCH / ADMISSION REQUIRED.

These gates must be closed before this document moves from proposed to accepted/canonical status.

---

# 33. Status-Consistency Audit and Updated Dependency Inventory

The independently reviewed proposed-contract checkpoints are now:

```text
PortableMoneyV1 normalized precision <= 15
        ↓
product upper magnitude x < 10^15 / A <= 14
        ↓
global normalized scale S <= 9 / E >= -9 / minimum 10^-9
        ↓
currency ordinary-scale/readiness semantics
        ↓
lumen-currency-v1 membership + immutable/versioned semantics
        ↓
canonical monetary compatibility/export disposition
```

The last checkpoint establishes the following only for the monetary/currency compatibility gate:

```text
representability
        ↓
complete Portable JSON v1 ownership-export claim
        ↓
restoration / supported-state round-trip claim
```

It must not be generalized mechanically to other Transaction fields.

## 33.1 Status consistency

The earlier transition narrative that called the currency registry the "next product-domain proposal" is stale and is superseded by this inventory.

The registry proposal and canonical monetary compatibility/disposition proposal have both passed independent review at the **PROPOSED-contract** level.

No production implementation is authorized.

## 33.2 Remaining Transaction-compatibility cluster

Three nearby gates remain materially distinct:

### Persisted status compatibility — accepted at proposed-contract level

Portable JSON v1 now admits all five exact current canonical status tokens. `pending`/`posted` are ordinary financial-lifecycle statuses; `ignored`/`duplicate`/`review_needed` are canonical compatibility statuses. Restoration authority remains distinct from ordinary creation authority.

### Categoryless canonical Transactions — accepted at proposed-contract level

`Transaction.category` is nullable in the current persisted Transaction model, and same-schema persistence tests demonstrate durable current-schema categoryless Transaction state. Those fixtures do not establish authentic historical/user-confirmed canonical provenance. Current ordinary confirmation still requires a Category.

The active proposal distinguishes exact canonical `category_ref: null` from a non-null unresolved reference, treats canonical null as representable and complete-export compatible, and proposes exact `nil → nil` supported-Lumen restoration under restoration-specific Review/Confirm authority.

### Unsigned type/direction sufficiency

PortableMoneyV1 amount remains unsigned. Current `TransactionType` includes `expense`, `income`, `transfer`, and `refund`, while current implementation's `isOutflow` predicate treats only `expense` as outflow.

Before type tokens can be accepted as portable flow semantics, the contract must determine whether each token—especially `transfer`—carries sufficient direction/flow meaning without inventing an implementation-driven interpretation.

This is primarily a representational semantic question before it is a restoration-readiness question.

## 33.3 Recommended next single gate

Persisted Transaction status compatibility is **accepted at the proposed-contract level**.

The authorized current gate is **categoryless canonical Transaction compatibility**. The separate proposal evaluates canonical Category absence across representability, complete-export truthfulness, and restoration readiness while keeping non-null unresolved references distinct.

Unsigned type/direction remains separate and is not solved by this proposal.


---

# 34. Next Design Step After This Proposal

The current progression is now:

The latest accepted compatibility proposal is:

> **Categoryless canonical Transaction compatibility — ACCEPTED AT PROPOSED-CONTRACT LEVEL**

The previously accepted status gate established that restoration authority can differ from ordinary creation authority without widening ordinary ingestion. This categoryless proposal independently tests whether the same distinction is justified for an exact absent Category association, while keeping canonical null separate from unresolved non-null references.

```text
PROPOSED Portable JSON / CSV v1 contract
        ↓
bounded Double precision characterization
        ↓ complete
standards-backed precision reconciliation
        ↓ complete at PROPOSED-contract level
decimal-exponent / magnitude technical characterization
        ↓ complete
PRODUCT upper magnitude proposal: x < 10^15 / A <= 14
        ↓ independently reviewed at PROPOSED-contract level
global normalized scale proposal: S <= 9 / E >= -9 / minimum 10^-9
        ↓ independently reviewed at PROPOSED-contract level
currency-specific scale / minor-unit semantics proposal
        ↓ independently reviewed at PROPOSED-contract level
currency-registry membership + version semantics
        ↓ independently reviewed at PROPOSED-contract level
read-only remaining-gate inventory
        ↓ complete
persisted Transaction status compatibility
        ↓ accepted at PROPOSED-contract level
categoryless canonical Transaction compatibility
        ↓ accepted at PROPOSED-contract level
read-only remaining-gate reassessment
        ↓
accept/canonicalize Portable JSON / CSV v1 contract
        ↓
exact capability/persistence admission where required
        ↓
only then implementation
```

This document remains **PROPOSED FOR REVIEW**.

The completed technical money characterizations do not accept the full format contract and do not authorize importer implementation, workspace persistence, promotion-control persistence, schema changes, serializer implementation, production validation changes, or implementation-pass decomposition.
