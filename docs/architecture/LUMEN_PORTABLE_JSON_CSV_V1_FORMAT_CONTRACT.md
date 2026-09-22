# Lumen Portable JSON / CSV v1 Format Contract

## Status

**PROPOSED FOR REVIEW — Phase 1C public portable-domain format contract.**

- **Proposal date:** 2026-09-22
- **Canonical repository baseline reviewed:** `2dd3ec9310554bc12d8c4f71076af9603a501c34`
- **Governing phase:** Phase 1C — Ownership, Portability & Data Management
- **Responsibility authority:** `docs/architecture/PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`
- **Format disposition:** Proposed. This document intentionally contains explicit evidence/research gates that must be resolved before the format is accepted as final.
- **Implementation disposition:** This document does **not** authorize importer implementation, workspace persistence, promotion-control persistence, SwiftData schema changes, migrations, production services, or implementation-pass sequencing.
- **Characterization disposition:** The later bounded money characterization is defined here only far enough to establish its falsifiable question. The characterization has **not** been run by this proposal.

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
| `type` | yes | transaction direction/type | PROPOSED |
| `merchant_name` | yes | merchant/counterparty | PROPOSED |
| `transaction_date` | yes | financial transaction calendar date | PROPOSED encoding; conversion from current storage EVIDENCE GATED |
| `posted_date` | nullable | financial posted calendar date | PROPOSED encoding; conversion from current storage EVIDENCE GATED |
| `status` | yes | current canonical transaction status | portability domain partially gated |
| `notes` | nullable | user-authored notes | PROPOSED |
| `category_ref` | nullable in representation | Category association | PROPOSED representation; categoryless round-trip EVIDENCE GATED |
| `payment_method_ref` | nullable | PaymentMethod association | PROPOSED |
| `tag_refs` | array | Tag associations | PROPOSED |
| `source_ref` | nullable | limited source/provenance association | PROPOSED |
| `created_at` | yes | canonical record creation instant | PROPOSED timestamp semantic |
| `updated_at` | yes | canonical record update instant | PROPOSED timestamp semantic |

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

---

# 12. Transaction Status

Current persisted `TransactionStatus` values are:

- `pending`;
- `posted`;
- `ignored`;
- `duplicate`;
- `review_needed`.

Current new-Transaction confirmation permits only:

- `pending`;
- `posted`.

Therefore the exact Portable v1 status domain is **RESEARCH / ADMISSION REQUIRED** before final acceptance.

The contract must not silently:

- drop existing compatibility-bearing status values;
- coerce them to `posted`;
- claim round-trip equivalence that the current confirmation path cannot reproduce.

The minimum established rule is:

> **Portable import must never convert a status with no admitted canonical mapping into another canonical status merely to make the row confirmable.**

The final format review must decide whether non-creatable persisted statuses are:

- part of Portable JSON v1 with a separately admitted restoration path;
- excluded with an explicit non-round-trip guarantee;
- reclassified outside portable Transaction status;
- or otherwise handled without bypassing Review/Confirm.

This is a real format gate.

---

# 13. Category Requirement and Historical Nullability

Current `Transaction.category` remains nullable at the persistence-model level.

Current `TransactionDraft → Review → Confirm` requires a resolved Category.

Therefore the candidate representation keeps `category_ref` nullable so it can truthfully describe current durable state without inventing a Category.

On import:

```text
category_ref present and resolvable
→ Category meaning may be resolved

category_ref == null
→ structurally valid portable record
→ not READY under current confirmation contract
→ Category must be resolved before confirmation
```

The exact round-trip guarantee for any existing categoryless canonical Transaction is **EVIDENCE GATED**.

The format must not:

- fabricate a Category during export;
- silently assign a default Category during import;
- make Category optional in canonical creation as a side effect of portability.

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

## 14.3 Leading-zero policy — EVIDENCE GATED

The lexical grammar above deliberately does not yet decide whether:

```text
"052.30"
```

is:

- accepted and normalized;
- rejected as noncanonical input;
- or handled by another explicit rule.

The final rule must be deterministic.

## 14.4 Trailing zeros and source scale — EVIDENCE GATED

The contract does not yet assume that the textual spellings:

```text
"52.3"
"52.30"
"52.300"
```

represent different financial facts.

The likely portable responsibility is monetary value, not preservation of arbitrary source lexical scale, but that is not frozen until characterization establishes a defensible canonical serialization rule.

## 14.5 Maximum magnitude — EVIDENCE GATED

Portable v1 has not yet frozen its maximum admitted magnitude.

The final limit must be supported by durable round-trip evidence through the current canonical representation or by a separately admitted persistence change.

## 14.6 Maximum scale — EVIDENCE GATED

Portable v1 has not yet frozen:

- global maximum decimal scale;
- currency-specific accepted scale;
- whether scale beyond a currency's ordinary minor unit is rejected or resolved;
- how historical/current Lumen values outside a candidate scale rule are exported.

These are characterization and standards-research questions.

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

## 14.8 Canonical decimal serialization — EVIDENCE GATED

Portable v1 must eventually define one deterministic decimal spelling for canonical export.

The format must **not** canonize:

```swift
String(transaction.amount)
```

merely because it is current implementation behavior.

The exact serializer must be chosen from the bounded characterization described later in this contract.

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

## 15.3 Complete registry membership — RESEARCH / ADMISSION REQUIRED

The final registry must classify rather than blindly copy every code available from a standards/platform list.

Research must consider at least:

- ordinary currently circulating currencies;
- historical/withdrawn codes;
- precious-metal codes;
- fund/unit-of-account codes;
- testing codes;
- "no currency" or similar special codes.

USD, EUR, JPY, and KWD are representation probes.

They are **not** a four-currency whitelist.

## 15.4 Registry identifier in each document — RESEARCH / ADMISSION REQUIRED

The responsibility for stable currency semantics is established.

This proposal does not yet require a field such as:

```json
"currency_registry": "lumen-iso4217-v1"
```

Whether a registry identifier must travel in every document depends on the final version-evolution design.

---

# 16. Candidate Money Characterization Invariant

The later characterization must answer one bounded question.

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
999999999999.99
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
        ├─ yes → freeze that admitted domain
        └─ no / materially inadequate
                ↓
          separate money-persistence admission
```

A failed characterization is evidence.

It is not automatic authorization to migrate away from `Double`.

This proposal does not run the characterization.

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

## 19.3 Conflict behavior is not identity

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

## 20.3 Credential boundary

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
transaction_date,posted_date,amount,currency,type,status,merchant_name,category_name,category_group,payment_method_name,notes
```

The blank downloadable template must eventually derive from this exact admitted header definition.

## 24.2 CSV field meanings

| Column | Required text? | Semantic |
| --- | --- | --- |
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

An empty cell is **not** valid for a required portable semantic such as amount/currency/type/merchant/date.

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

and:

```text
amount,currency,type
52.30,USD,expense
```

represent the same candidate PortableMoneyV1 + type meaning.

CSV must not invent:

- different currency aliases;
- signed-direction semantics;
- locale-specific decimal interpretation;
- different date semantics;
- different enum tokens.

CSV is narrower in field coverage, not looser in the meaning of fields it shares with JSON.

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
- portable identity generation/stability sufficient for relationship reconstruction.

Those are explicit contract gates, not implementation surprises.

---

# 29. Version Handling

## 29.1 Exact v1 recognition — PROPOSED

A Lumen Portable JSON v1 document requires:

```text
format == "lumen-portable"
version == 1
```

A document with a different version must not be parsed as v1 by guesswork.

## 29.2 Future versions — PROPOSED

A future Lumen version may:

- continue to read v1;
- provide an explicit version adapter/migration;
- reject a newer unsupported version with a clear unsupported-version result.

It must not silently reinterpret incompatible future semantics through v1 rules.

## 29.3 Currency-definition evolution — RESEARCH / ADMISSION REQUIRED

The final contract must decide how currency-registry evolution relates to the top-level format version and whether any registry identifier travels with the document.

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

- lexically well-formed currency token not admitted by the Portable v1 currency definition;
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

- canonical leading-zero rule — EVIDENCE GATED;
- canonical trailing-zero / decimal spelling — EVIDENCE GATED;
- maximum admitted magnitude — EVIDENCE GATED;
- maximum admitted scale — EVIDENCE GATED;
- currency-specific scale semantics — EVIDENCE GATED;
- exact Double → portable-decimal serializer — EVIDENCE GATED.

## Currency

- complete admitted-currency membership — RESEARCH / ADMISSION REQUIRED;
- treatment of historical/special ISO codes — RESEARCH / ADMISSION REQUIRED;
- registry/version evolution mechanism — RESEARCH / ADMISSION REQUIRED.

## Dates

- current `Date` → financial calendar-date conversion and timezone rule — EVIDENCE GATED;
- canonical fractional-second timestamp spelling — RESEARCH / ADMISSION REQUIRED.

## Identity / ordering

- portable ID grammar/generation — RESEARCH / ADMISSION REQUIRED;
- cross-export stability — RESEARCH / ADMISSION REQUIRED;
- deterministic array ordering tied to identity — EVIDENCE GATED.

## Transaction compatibility

- portability/restoration of `ignored`, `duplicate`, and `review_needed` persisted statuses — RESEARCH / ADMISSION REQUIRED;
- round-trip disposition for categoryless current/historical canonical Transactions — EVIDENCE GATED.

## Provenance

- whether `original_filename`, `uploaded_at`, `captured_at`, or `source_timezone` enter v1 — RESEARCH / ADMISSION REQUIRED.

## Parser evolution

- unknown-field policy inside v1 — RESEARCH / ADMISSION REQUIRED.

These gates must be closed before this document moves from proposed to accepted/canonical status.

---

# 33. Next Evidence Step

The next evidence step for money is **not** a production importer and not a migration.

It is a bounded characterization designed against the candidate PortableMoneyV1 invariant in Section 16.

The characterization should be represented as:

- a diagnostic/probe or characterization role;
- non-production;
- no schema change;
- no canonical format acceptance implied by the test merely existing.

Its result must feed this document.

A useful safe domain may allow this format contract to freeze PortableMoneyV1 without any storage migration.

An inadequate result may justify a **separate** money-persistence admission.

---

# 34. Next Design Step After This Proposal

This proposal should receive independent review before characterization is built.

The intended progression is:

```text
PROPOSED Portable JSON / CSV v1 contract
        ↓
review candidate invariants and explicit gates
        ↓
design/run bounded money characterization
        ↓
resolve money gates from evidence
        ↓
resolve remaining format gates
        ↓
accept/canonicalize Portable JSON / CSV v1 contract
        ↓
exact capability/persistence admission where required
        ↓
only then implementation
```

This document deliberately stops before importer implementation, workspace persistence, promotion-control persistence, schema changes, or implementation-pass decomposition.
