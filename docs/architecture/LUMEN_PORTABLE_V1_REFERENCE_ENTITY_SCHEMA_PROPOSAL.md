# Lumen Portable v1 Exact Category / PaymentMethod / Tag Record Schemas

## Status

**ACCEPTED AT PROPOSED-CONTRACT LEVEL — independently reviewed Phase 1C exact ordinary reference-entity record schemas.**

This document governs the accepted-at-proposed-contract-level Portable JSON v1 record fields and value semantics for:

- `Category`;
- `PaymentMethod`;
- `Tag`.

It does not reopen:

- which durable records belong in the complete owned set;
- ordinary lifecycle timestamp disposition;
- Portable document-local identity semantics.

It does **not** accept the full Portable JSON / CSV v1 contract and does not authorize implementation.

Starting proposal-development baseline:

`c7dd2ea639df6db0e98f942f5d906b522d28cf30`

That baseline is composition-only. Its merge ancestry does not create semantic authority.

Branch:

`docs/phase1c-portable-v1-reference-entity-schema-proposal`

---

# 1. Decision question

For each already-owned ordinary reference entity:

> **What exact Portable JSON v1 fields constitute its portable semantic record, which fields are required versus nullable versus omitted, what token/value semantics apply, and what current durable states become representability problems under that exact schema?**

The gate answers record shape.

It does not answer restoration matching.

Preserve:

```text
owned object set
!=
exact object representation

exact object representation
!=
restoration / merge authority
```

---

# 2. Accepted prerequisites

This proposal consumes without reopening:

## 2.1 Complete-export set semantics

For complete Portable JSON v1:

```text
every durable Category
→ categories[]

every durable PaymentMethod
→ payment_methods[]

every durable Tag
→ tags[]
```

Membership is independent of reachability, default/active-like state, guessed provenance, name similarity, or expected destination bootstrap.

Therefore an awkward record cannot be filtered merely because its field values are inconvenient.

## 2.2 Lifecycle-timestamp exclusion

Accepted ordinary lifecycle disposition excludes:

- `Category.created_at`;
- `PaymentMethod.created_at`;
- `Tag.created_at`.

Those fields do not appear in these exact schemas.

## 2.3 Portable identity

Every record receives one required document-local `portable_id` under the accepted global namespace and grammar.

The native SwiftData `id` is not exported.

Portable identity grants same-document reference resolution only.

## 2.4 Relationship direction

Transactions own portable references:

- `category_ref`;
- `payment_method_ref`;
- `tag_refs`.

Reference records do not need transaction back-reference arrays.

---

# 3. First-principles schema rule

Portable JSON is not a blind SwiftData dump.

But once a durable object is admitted to the complete owned set, every omitted field needs a reason.

For ordinary non-temporal reference state, use this test:

```text
durable field
+
field carries current domain/display state of the owned object
+
no stronger privacy / machine-state / provenance reason for exclusion
        ↓
include it exactly

durable field
+
responsibility already owned elsewhere
or
accepted exclusion exists
        ↓
omit it
```

Do not manufacture new validation merely because a prettier schema is possible.

Preserve:

```text
canonical String field
!=
permission to trim

display metadata
!=
identity

enum case named "custom" or "other"
!=
fallback authority for unknown tokens

nullable
!=
omittable without semantics
```

---

# 4. Repository evidence

## 4.1 Category model

Current canonical `Category` stores:

- `id: String`;
- `name: String`;
- `group: CategoryGroup`;
- `color: String`;
- `icon: String`;
- `is_default: Bool`;
- `created_at: Date`.

Current UI/analytics consume:

- `name` for selection/display;
- `group` for grouping and analytics;
- `color` for rendering/analytics;
- `icon` for Category glyph rendering.

`is_default` is canonical durable state even though the previous ownership gate established:

```text
is_default == true
!=
proof of bootstrap provenance
```

`created_at` is already excluded by the accepted lifecycle gate.

The native `id` is replaced in Portable documents by `portable_id`.

Computed `tint` is not stored canonical state and is not a Portable field.

## 4.2 CategoryGroup enum

Current canonical cases are exactly:

- `fixed_costs`;
- `investments`;
- `savings_goals`;
- `guilt_free_spending`;
- `income`;
- `custom`.

The enum raw values already use the candidate Portable spelling.

`custom` is a real canonical group.

It is not authority to coerce an unknown future token.

## 4.3 PaymentMethod model

Current canonical `PaymentMethod` stores:

- `id: String`;
- `name: String`;
- `method_type: PaymentMethodType`;
- `institution_name: String?`;
- `last_four: String?`;
- `notes: String?`;
- `is_active: Bool`;
- `created_at: Date`.

Current Transaction workflows bind PaymentMethod relationships and display `name`.

Current seed state demonstrates non-null:

- `institution_name`;
- `last_four`.

Current seed `last_four` examples are four ASCII decimal digits.

Current persistence does **not** enforce a lexical validator for `last_four`. Therefore the stored model establishes `String?` plus current examples; it does not itself prove a decimal-only public format domain. Any narrower Portable v1 domain must be admitted explicitly as a Lumen product/format semantic.

`is_active` is durable state. The accepted export-set gate already established:

```text
inactive
!=
deleted
!=
safe to omit the record
```

The lifecycle gate excludes `created_at`.

Native `id` is replaced by document-local `portable_id`.

## 4.4 PaymentMethodType enum

Current canonical cases are exactly:

- `cash`;
- `debit_card`;
- `credit_card`;
- `bank_transfer`;
- `hsa`;
- `fsa`;
- `gift_card`;
- `other`.

`other` is an exact canonical token.

It is not permission to normalize an unknown future token.

## 4.5 Tag model

Current canonical `Tag` stores:

- `id: String`;
- `name: String`;
- `color: String`;
- `created_at: Date`;
- inverse `transactions` relationship.

Current UI consumes:

- `name`;
- `color`.

`created_at` is already excluded.

Native `id` is replaced by `portable_id`.

The inverse `transactions` collection is relationship machinery. Portable Transactions already carry `tag_refs`, so serializing the inverse again would duplicate relationship authority.

---

# 5. String preservation rule

Except where this proposal explicitly defines a narrower field domain, string-valued reference fields are preserved as exact JSON strings.

That means no Portable-v1 normalization of:

- leading/trailing whitespace;
- capitalization;
- Unicode normalization;
- empty versus non-empty spelling;
- display-name similarity;
- color spelling;
- SF Symbol/icon spelling.

This gate does not claim every spelling renders attractively.

It claims that the canonical record owns the spelling.

For example:

```text
Category.color = "#2F6B57"
Category.color = "2F6B57"
Category.color = "not-a-valid-color"
```

are all structurally representable strings under this schema.

Current rendering helpers may interpret those values differently.

Rendering success is not a Portable identity or schema-admission test.

Likewise:

```text
name = "Food"
name = " food "
```

remain distinct exact strings.

A future reference-management workflow may impose stronger creation validation without rewriting restoration semantics for already canonical state.

---

# 6. Required known-key rule

For the canonical v1 exporter and validation of known v1 fields, every field admitted by an entity schema is a required JSON object key.

Fields whose canonical value may be absent use explicit JSON `null`.

Therefore:

```json
{
  "institution_name": null,
  "last_four": null,
  "notes": null
}
```

means exact canonical absence for those PaymentMethod fields.

Omitting one of those keys is not treated as equivalent to null in a valid v1 record.

This provides:

- deterministic structural validation;
- exact null semantics;
- no ambiguity between absent schema field and canonical nil.

This rule freezes the presence semantics of **known v1 keys only**.

It does **not** decide what a v1 parser must do when an input object contains additional unrecognized keys. Whether such keys are rejected, ignored, preserved, or trigger version/evolution handling remains reserved for the downstream unknown-field/evolution gate.

---

# 7. Exact Category record

## 7.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000001",
  "name": "Example Category",
  "group": "custom",
  "color": "#2F6B57",
  "icon": "tag",
  "is_default": false
}
```

## 7.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical Category name |
| `group` | required | six admitted CategoryGroup tokens | exact canonical group |
| `color` | required | JSON string | exact canonical display-color metadata |
| `icon` | required | JSON string | exact canonical display-icon metadata |
| `is_default` | required | JSON boolean | exact canonical default-like classification flag |

## 7.3 Omitted Category state

Portable v1 does not serialize:

- native `Category.id`;
- `Category.created_at`;
- computed `Category.tint`;
- Transaction back-references.

## 7.4 is_default authority boundary

`is_default` is preserved because it is canonical state.

But:

```text
is_default == true
!=
proof the record came from Seed.bootstrapIfNeeded()

is_default
!=
cross-installation built-in identity

is_default
!=
merge authority
```

Restoration/conflict logic must not reinterpret this field as provenance.

---

# 8. Category group tokens

Portable v1 proposes these exact tokens:

```text
fixed_costs
investments
savings_goals
guilt_free_spending
income
custom
```

Rules:

- exact lowercase ASCII spelling;
- no case folding;
- no aliases;
- no label spelling such as `"Fixed Costs"`;
- `custom` means the canonical `.custom` group only.

Unknown token:

```text
"future_group"
!=
"custom"
```

An unknown token is not representable as a v1 Category group and must receive future-version/evolution handling rather than silent coercion.

---

# 9. Exact PaymentMethod record

## 9.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000002",
  "name": "Example Card",
  "method_type": "credit_card",
  "institution_name": "Example Institution",
  "last_four": "1234",
  "notes": null,
  "is_active": true
}
```

## 9.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical PaymentMethod name |
| `method_type` | required | eight admitted PaymentMethodType tokens | exact canonical method classification |
| `institution_name` | required, nullable | JSON string or null | exact institution display metadata or exact absence |
| `last_four` | required, nullable | exactly four ASCII decimal digits or null | final four digits of a non-secret payment-instrument identifier for display/disambiguation, or exact absence |
| `notes` | required, nullable | JSON string or null | exact canonical PaymentMethod descriptive note or exact absence |
| `is_active` | required | JSON boolean | exact canonical active/inactive flag |

## 9.3 Omitted PaymentMethod state

Portable v1 does not serialize:

- native `PaymentMethod.id`;
- `PaymentMethod.created_at`;
- credentials not represented by the admitted schema.

---

# 10. PaymentMethod type tokens

Portable v1 proposes these exact tokens:

```text
cash
debit_card
credit_card
bank_transfer
hsa
fsa
gift_card
other
```

Rules:

- exact lowercase ASCII spelling;
- no case folding;
- no display-label aliases;
- `other` means the exact canonical `.other` case.

Unknown token:

```text
"crypto_wallet"
!=
"other"
```

Unknown future types require evolution/compatibility handling.

They must not silently become `other`.

---

# 11. PaymentMethod last_four boundary

`last_four` is deliberately narrower than the other free-form string fields.

## 11.1 Repository evidence versus proposed product semantic

Current repository evidence establishes:

- canonical persistence stores `last_four` as `String?`;
- current seed examples are `"4821"` and `"9023"`;
- no model-level lexical validator currently constrains the field;
- the field is intended as a limited payment-method suffix rather than a full credential container.

That evidence does **not** independently prove that every canonical value already satisfies a decimal-only alphabet.

Therefore the following rule is an **explicit proposed Lumen Portable v1 semantic**, not an inference that current persistence already enforces it:

> A non-null Portable v1 `last_four` is the final four ASCII decimal digits of a **non-secret payment-instrument identifier**, carried only for display/disambiguation.

If non-null, v1 therefore requires:

```text
^[0-9]{4}$
```

using ASCII digits only.

A PaymentMethod that has no meaningful numeric identifier suffix uses canonical `null` for this portable field. `method_type` does not imply that every PaymentMethod must have a non-null `last_four`.

Examples:

```text
"4821"
→ representable numeric identifier suffix

null
→ representable exact absence

"821"
"•••• 4821"
"12345"
"4111111111111111"
"AB12"
"ABCD"
""
→ not representable as Portable v1 last_four
```

## 11.2 Why v1 chooses decimal digits instead of a generic four-character suffix

The credential-safety boundary supports rejecting arbitrary full credential strings, but **does not by itself prove the decimal alphabet**.

The decimal alphabet is proposed as a deliberate Minimum Sufficient Contract because:

- Lumen's current `last_four` name and seed usage are consistent with the familiar final-four-digits payment-instrument meaning;
- v1 currently has no admitted product requirement for alphanumeric or arbitrary-Unicode payment-instrument suffixes;
- broadening the field to generic four-character display metadata would invent a new semantic domain, including unresolved character-counting/Unicode questions, rather than preserve an established canonical contract;
- types such as `cash`, `gift_card`, `other`, or future instruments are not forced to fabricate a suffix; canonical absence remains `null`;
- a future version may admit a broader identifier-suffix representation if product evidence earns it.

Therefore:

```text
canonical non-null last_four outside four ASCII digits
        ↓
owned PaymentMethod remains owned
        ↓
schema representability / compatibility problem
```

The rule does **not** authorize:

- truncation;
- automatically taking the last four characters or digits from a longer source value;
- masking;
- substitution with null;
- moving the value into notes;
- interpreting a PIN, CVV, authentication code, or other secret as `last_four`;
- omitting the PaymentMethod.

The later reference compatibility gate must decide the complete-export disposition for such a record.

The already accepted owned-set rule guarantees that the record itself still belongs to the complete owned set.

---

# 12. PaymentMethod credential boundary

This schema admits only descriptive reference metadata.

It does not authorize portability of:

- full payment-card numbers;
- bank account credentials;
- authentication tokens;
- CVV/CVC values;
- PINs;
- cryptographic secrets;
- account-login state.

`institution_name` and `notes` remain descriptive strings, not credential fields.

This proposal does not create heuristic secret scanning or redaction behavior.

If future repository evidence demonstrates canonical credential material in an admitted descriptive field, that creates a separate safety/compatibility issue rather than authority to silently rewrite the value.

---

# 13. Exact Tag record

## 13.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000003",
  "name": "Example Tag",
  "color": "#2F6B57"
}
```

## 13.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical Tag name |
| `color` | required | JSON string | exact canonical display-color metadata |

## 13.3 Omitted Tag state

Portable v1 does not serialize:

- native `Tag.id`;
- `Tag.created_at`;
- inverse `Tag.transactions`.

The Transaction-side `tag_refs` relationship remains authoritative for same-document Tag associations.

---

# 14. Relationship role

Reference record content never establishes relationship identity.

Examples:

```text
Category.name equality
!=
same Category identity

PaymentMethod name + last_four equality
!=
same PaymentMethod identity

Tag name equality
!=
same Tag identity
```

Transactions resolve relationships through accepted document-local refs.

These schemas grant no automatic:

- merge;
- overwrite;
- deduplication;
- replacement;
- receiving-store match.

Reference matching/conflict semantics remain downstream.

---

# 15. Native IDs are excluded

Current canonical `id` values remain installation-local object identifiers.

Portable v1 does not emit them in these records.

The exporter may consume native IDs privately when allocating document-local `portable_id` handles under the accepted identity contract.

Preserve:

```text
native id used internally
!=
native id exported
!=
cross-installation public identity
```

---

# 16. Representability matrix

## 16.1 Category

A currently loaded Category is field-schema representable when:

- exporter can assign a valid document-local `portable_id`;
- `group` is one of the six v1 tokens.

Its string and boolean fields introduce no additional lexical rejection in this gate.

Therefore current canonical Category strings—including unusual/empty display strings—remain exactly representable.

## 16.2 PaymentMethod

A currently loaded PaymentMethod is field-schema representable when:

- exporter can assign a valid `portable_id`;
- `method_type` is one of the eight v1 tokens;
- `last_four` is null or exactly four ASCII decimal digits.

All other admitted string/nullable-string values remain exact JSON strings/null.

## 16.3 Tag

A currently loaded Tag is field-schema representable when:

- exporter can assign a valid `portable_id`.

Its name/color strings introduce no additional lexical rejection in this gate.

## 16.4 Future enum values

If a future canonical model adds:

- Category group token outside the six v1 tokens; or
- PaymentMethod type outside the eight v1 tokens;

that new canonical state is not silently representable by an old v1 token.

No fallback normalization is authorized.

Unknown-field/evolution policy remains downstream.

---

# 17. Owned but unrepresentable

The accepted export-set gate already establishes:

```text
owned
!=
necessarily representable under a later exact schema
```

This proposal supplies concrete possible representability boundaries.

Example:

```text
durable PaymentMethod
last_four = "4111111111111111"
        ↓
record still belongs in payment_methods[]
        ↓
v1 exact schema cannot represent that last_four value
        ↓
explicit compatibility/disposition required
```

What is forbidden:

```text
unrepresentable
        ↓
silently omit PaymentMethod
        ↓
rewrite Transaction.payment_method_ref
        ↓
claim complete ownership success
```

The later compatibility gate owns the exact operation-level consequence.

---

# 18. Null versus omitted

For PaymentMethod nullable fields:

```json
"institution_name": null
```

means exact canonical nil.

The same applies to:

- `last_four`;
- `notes`.

The valid v1 record still contains the key.

This proposal intentionally rejects treating:

```text
key omitted
==
key present with null
```

inside a valid v1 PaymentMethod record.

Unknown-field/evolution and parser error behavior remain separate gates.

---

# 19. Display metadata is portable state, not portable rendering

`color` and `icon` are preserved because they are canonical display metadata and current Lumen consumes them.

Portable v1 does not guarantee:

- identical rendered pixels;
- continued existence of a particular platform symbol;
- color parser behavior on all future platforms.

The contract guarantees exact field preservation.

Therefore:

```text
exact display metadata
!=
cross-platform rendering guarantee
```

---

# 20. CSV scope

This gate defines complete reference records for Portable JSON v1.

It does not turn CSV into a reference-entity graph format.

Existing CSV Category/PaymentMethod text columns remain a narrower transaction-oriented projection.

Tags remain omitted from initial CSV v1.

Any claim that a CSV column shares one of these field semantics must be admitted explicitly in the CSV contract.

---

# 21. Alternatives considered

## Alternative A — Export every remaining stored field verbatim

Rejected.

That would reintroduce native IDs, lifecycle timestamps, and inverse relationship machinery already owned by other contracts or explicitly excluded.

## Alternative B — Export only names plus portable_id

Rejected.

That loses admitted canonical state:

- Category group/color/icon/is_default;
- PaymentMethod type/institution/last_four/notes/is_active;
- Tag color.

It would not faithfully restore the owned reference object.

## Alternative C — Normalize strings for cleaner interchange

Examples:

- trim names;
- uppercase/lowercase;
- canonicalize colors;
- replace invalid icons;
- collapse empty string to null.

Rejected.

Current canonical persistence does not establish those normalizations as equivalent.

## Alternative D — Omit null PaymentMethod keys

Possible for a looser JSON convention, but rejected for exact v1 schema.

Required nullable keys make canonical absence explicit and distinguish schema omission from nil state.

## Alternative E — Preserve arbitrary PaymentMethod last_four strings

Rejected.

That would turn a field whose admitted purpose is a limited suffix into a potentially unbounded payment credential channel.

## Alternative F — Admit any four-character non-secret suffix

Rejected for v1.

This would avoid decimal-only spelling, but it would create a broader public semantic that current Lumen does not yet require:

- what counts as one character would need a Unicode/code-point/grapheme contract;
- alphanumeric and arbitrary-symbol suffixes would become permanently admitted v1 state;
- the current repository has no accepted product consumer that requires that broader domain.

The narrower four-ASCII-decimal-digit rule is therefore proposed intentionally as a v1 product semantic rather than claimed as a persistence invariant.

---

# 22. Reasoning Framework Check

## First Principles

Required capability:

Represent every admitted ordinary reference object faithfully enough for supported ownership export/restoration without serializing unrelated persistence machinery.

Necessary semantics:

- exact object-local domain/display values;
- exact canonical enum classifications;
- exact nullable absence;
- same-document identity.

Unnecessary stronger guarantees:

- native-ID portability;
- rendering equivalence;
- automatic name normalization;
- bootstrap provenance;
- restoration matching.

## Repository Evidence

Established:

- exact current SwiftData field sets;
- current enum cases/raw values;
- current UI/analytics consumption of Category/Tag display metadata;
- seeded PaymentMethod institution/last-four examples;
- accepted lifecycle exclusion;
- accepted export-set inclusion;
- accepted identity semantics.

Not established:

- a universal color lexical invariant;
- a universal SF Symbol validity invariant;
- trimming/case-folding equivalence;
- cross-installation reference identity from content;
- a persistence-level decimal validator for `PaymentMethod.last_four`;
- safe arbitrary credential export.

Claims are narrowed accordingly.

## Minimum Sufficient Contract

The proposed schemas preserve every current non-temporal domain/display field except responsibilities already excluded or replaced.

They add one narrow, explicit Portable v1 product-semantic rule for `last_four`: when non-null it means the final four ASCII decimal digits of a non-secret payment-instrument identifier used for display/disambiguation. This rule is intentionally **not** presented as an existing SwiftData validation invariant.

No generalized reference-data framework is added.

## Assembly Map

Prerequisites:

- accepted reference owned-set gate;
- accepted lifecycle exclusion;
- accepted Portable identity;
- accepted reference/null distinction.

New subassembly:

Exact Category / PaymentMethod / Tag Portable JSON v1 record shapes.

Consumers:

- reference compatibility disposition;
- reference restoration/conflict semantics;
- deterministic serialization/order;
- final Portable JSON acceptance.

## Authority Budget

Proposed new authority:

- these exact fields define v1 reference record semantics;
- enum token sets are exact;
- PaymentMethod nullable keys use explicit null;
- Portable v1 explicitly defines non-null `last_four` as the final four ASCII decimal digits of a non-secret payment-instrument identifier used only for display/disambiguation.

Explicitly not granted:

- content-based identity;
- merge/overwrite authority;
- string normalization;
- provenance inference;
- creation UI validation;
- migration;
- implementation.

## Assembly Pressure

Common schema patterns are shared only where earned:

- required `portable_id`;
- exact strings;
- explicit null for nullable PaymentMethod fields.

Entity-specific semantics remain entity-specific.

## Counterexamples

The proposal survives:

- duplicate names;
- whitespace/case-distinct names;
- invalid-looking color strings;
- invalid-looking icon strings;
- inactive PaymentMethod;
- null versus empty PaymentMethod metadata;
- future unknown enum tokens;
- non-null overlong/credential-like `last_four`;
- unreferenced owned records.

## Assembly Debt

The record shape itself no longer depends on lifecycle timestamp disposition.

Reference compatibility and restoration remain downstream because they consume these now-proposed shapes.

## Irreversible Commitments

Acceptance would make these fields public v1 semantics.

Removing an admitted field later would require version/evolution handling.

Therefore no additional field is included merely because it exists in SwiftData.

---

# 23. Exact accepted proposed-contract language

The following language is **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

> **Category record.** A Portable JSON v1 Category record defines the following required v1 keys: `portable_id`, `name`, `group`, `color`, `icon`, and `is_default`. `portable_id` follows the accepted document-local identity contract. `name`, `color`, and `icon` preserve their exact canonical string values without trimming, case folding, normalization, or rendering validation. `group` is exactly one of `fixed_costs`, `investments`, `savings_goals`, `guilt_free_spending`, `income`, or `custom`. `is_default` preserves the canonical boolean but does not prove bootstrap provenance or grant merge identity.
>
> **PaymentMethod record.** A Portable JSON v1 PaymentMethod record defines the following required v1 keys: `portable_id`, `name`, `method_type`, `institution_name`, `last_four`, `notes`, and `is_active`. `institution_name`, `last_four`, and `notes` are nullable but their keys are required; JSON null means exact canonical nil. `method_type` is exactly one of `cash`, `debit_card`, `credit_card`, `bank_transfer`, `hsa`, `fsa`, `gift_card`, or `other`. A non-null `last_four` is exactly the final four ASCII decimal digits of a non-secret payment-instrument identifier used only for display/disambiguation. This decimal-only rule is an explicit Portable v1 product semantic accepted by this component gate; it is not claimed as a current persistence validator. `is_active` preserves the canonical boolean and does not mean deletion when false.
>
> **Tag record.** A Portable JSON v1 Tag record defines the following required v1 keys: `portable_id`, `name`, and `color`. `name` and `color` preserve exact canonical strings.
>
> These required-key rules define the known canonical v1 exporter/schema surface. Treatment of **additional unrecognized input keys** remains reserved for the downstream unknown-field/evolution gate; this schema proposal does not decide whether such keys are rejected, ignored, preserved, or require version negotiation.
>
> Native SwiftData `id` values, ordinary `created_at` lifecycle timestamps, computed display helpers, and Tag inverse Transaction relationships are not fields in these v1 records.
>
> Unknown Category group tokens do not normalize to `custom`; unknown PaymentMethod type tokens do not normalize to `other`. Same-name or otherwise content-similar records do not gain identity or restoration-match authority.
>
> If an already-owned durable record cannot satisfy this exact schema, the record remains in the admitted owned set and requires explicit compatibility/disposition handling. The exporter must not silently omit the record, normalize the incompatible field, rewrite referencing Transactions, or claim complete ownership success through omission.

---

# 24. Remaining dependencies

After this proposal, still open:

1. reference-record compatibility/disposition for concrete schema failures;
2. reference restoration/conflict semantics;
3. PortableMoney lexical/governance closure;
4. exact financial-date lexical/year validity;
5. Source/provenance portability;
6. top-level/admitted timestamp lexical rules;
7. deterministic Portable-ID allocation and emitted ordering;
8. unknown-field/evolution policy;
9. full Portable JSON / CSV v1 acceptance.

---

# 25. Independent-review acceptance

Independent review of:

`be59c5d1ecaa6eb6ea09b6909d6666392e97104f`

passes at the proposed-contract level.

Accepted known-field schemas:

```text
Category
├── portable_id
├── name
├── group
├── color
├── icon
└── is_default

PaymentMethod
├── portable_id
├── name
├── method_type
├── institution_name
├── last_four
├── notes
└── is_active

Tag
├── portable_id
├── name
└── color
```

Accepted semantics include:

- all admitted known v1 keys are required as defined;
- `institution_name`, `last_four`, and `notes` are required nullable PaymentMethod keys, with JSON null meaning exact canonical nil;
- treatment of additional unrecognized input keys remains **outside this gate** and reserved for unknown-field/evolution policy;
- Category `group` uses exactly the six admitted tokens and unknown future tokens do not normalize to `custom`;
- PaymentMethod `method_type` uses exactly the eight admitted tokens and unknown future tokens do not normalize to `other`;
- admitted display/domain strings preserve exact canonical spelling without trimming, case folding, normalization, color validation, or symbol validation;
- `is_default` preserves exact state but grants no bootstrap-provenance or merge identity;
- `is_active == false` preserves inactive state and does not mean deletion;
- native SwiftData IDs are not portable identity and ordinary `created_at` lifecycle timestamps remain excluded by the accepted lifecycle gate;
- Tag inverse Transaction relationships remain omitted because portable association is represented through Transaction `tag_refs`;
- an owned record that cannot satisfy an accepted exact schema remains owned and requires explicit compatibility/disposition handling.

Accepted `last_four` semantic:

> A non-null Portable v1 `last_four` is the final four ASCII decimal digits of a non-secret payment-instrument identifier, used only for display/disambiguation.

This is an explicit Portable v1 product-domain decision, **not** a claim that current SwiftData validation already enforces `^[0-9]{4}# Lumen Portable v1 Exact Category / PaymentMethod / Tag Record Schemas

## Status

**ACCEPTED AT PROPOSED-CONTRACT LEVEL — independently reviewed Phase 1C exact ordinary reference-entity record schemas.**

This document governs the accepted-at-proposed-contract-level Portable JSON v1 record fields and value semantics for:

- `Category`;
- `PaymentMethod`;
- `Tag`.

It does not reopen:

- which durable records belong in the complete owned set;
- ordinary lifecycle timestamp disposition;
- Portable document-local identity semantics.

It does **not** accept the full Portable JSON / CSV v1 contract and does not authorize implementation.

Starting proposal-development baseline:

`c7dd2ea639df6db0e98f942f5d906b522d28cf30`

That baseline is composition-only. Its merge ancestry does not create semantic authority.

Branch:

`docs/phase1c-portable-v1-reference-entity-schema-proposal`

---

# 1. Decision question

For each already-owned ordinary reference entity:

> **What exact Portable JSON v1 fields constitute its portable semantic record, which fields are required versus nullable versus omitted, what token/value semantics apply, and what current durable states become representability problems under that exact schema?**

The gate answers record shape.

It does not answer restoration matching.

Preserve:

```text
owned object set
!=
exact object representation

exact object representation
!=
restoration / merge authority
```

---

# 2. Accepted prerequisites

This proposal consumes without reopening:

## 2.1 Complete-export set semantics

For complete Portable JSON v1:

```text
every durable Category
→ categories[]

every durable PaymentMethod
→ payment_methods[]

every durable Tag
→ tags[]
```

Membership is independent of reachability, default/active-like state, guessed provenance, name similarity, or expected destination bootstrap.

Therefore an awkward record cannot be filtered merely because its field values are inconvenient.

## 2.2 Lifecycle-timestamp exclusion

Accepted ordinary lifecycle disposition excludes:

- `Category.created_at`;
- `PaymentMethod.created_at`;
- `Tag.created_at`.

Those fields do not appear in these exact schemas.

## 2.3 Portable identity

Every record receives one required document-local `portable_id` under the accepted global namespace and grammar.

The native SwiftData `id` is not exported.

Portable identity grants same-document reference resolution only.

## 2.4 Relationship direction

Transactions own portable references:

- `category_ref`;
- `payment_method_ref`;
- `tag_refs`.

Reference records do not need transaction back-reference arrays.

---

# 3. First-principles schema rule

Portable JSON is not a blind SwiftData dump.

But once a durable object is admitted to the complete owned set, every omitted field needs a reason.

For ordinary non-temporal reference state, use this test:

```text
durable field
+
field carries current domain/display state of the owned object
+
no stronger privacy / machine-state / provenance reason for exclusion
        ↓
include it exactly

durable field
+
responsibility already owned elsewhere
or
accepted exclusion exists
        ↓
omit it
```

Do not manufacture new validation merely because a prettier schema is possible.

Preserve:

```text
canonical String field
!=
permission to trim

display metadata
!=
identity

enum case named "custom" or "other"
!=
fallback authority for unknown tokens

nullable
!=
omittable without semantics
```

---

# 4. Repository evidence

## 4.1 Category model

Current canonical `Category` stores:

- `id: String`;
- `name: String`;
- `group: CategoryGroup`;
- `color: String`;
- `icon: String`;
- `is_default: Bool`;
- `created_at: Date`.

Current UI/analytics consume:

- `name` for selection/display;
- `group` for grouping and analytics;
- `color` for rendering/analytics;
- `icon` for Category glyph rendering.

`is_default` is canonical durable state even though the previous ownership gate established:

```text
is_default == true
!=
proof of bootstrap provenance
```

`created_at` is already excluded by the accepted lifecycle gate.

The native `id` is replaced in Portable documents by `portable_id`.

Computed `tint` is not stored canonical state and is not a Portable field.

## 4.2 CategoryGroup enum

Current canonical cases are exactly:

- `fixed_costs`;
- `investments`;
- `savings_goals`;
- `guilt_free_spending`;
- `income`;
- `custom`.

The enum raw values already use the candidate Portable spelling.

`custom` is a real canonical group.

It is not authority to coerce an unknown future token.

## 4.3 PaymentMethod model

Current canonical `PaymentMethod` stores:

- `id: String`;
- `name: String`;
- `method_type: PaymentMethodType`;
- `institution_name: String?`;
- `last_four: String?`;
- `notes: String?`;
- `is_active: Bool`;
- `created_at: Date`.

Current Transaction workflows bind PaymentMethod relationships and display `name`.

Current seed state demonstrates non-null:

- `institution_name`;
- `last_four`.

Current seed `last_four` examples are four ASCII decimal digits.

Current persistence does **not** enforce a lexical validator for `last_four`. Therefore the stored model establishes `String?` plus current examples; it does not itself prove a decimal-only public format domain. Any narrower Portable v1 domain must be admitted explicitly as a Lumen product/format semantic.

`is_active` is durable state. The accepted export-set gate already established:

```text
inactive
!=
deleted
!=
safe to omit the record
```

The lifecycle gate excludes `created_at`.

Native `id` is replaced by document-local `portable_id`.

## 4.4 PaymentMethodType enum

Current canonical cases are exactly:

- `cash`;
- `debit_card`;
- `credit_card`;
- `bank_transfer`;
- `hsa`;
- `fsa`;
- `gift_card`;
- `other`.

`other` is an exact canonical token.

It is not permission to normalize an unknown future token.

## 4.5 Tag model

Current canonical `Tag` stores:

- `id: String`;
- `name: String`;
- `color: String`;
- `created_at: Date`;
- inverse `transactions` relationship.

Current UI consumes:

- `name`;
- `color`.

`created_at` is already excluded.

Native `id` is replaced by `portable_id`.

The inverse `transactions` collection is relationship machinery. Portable Transactions already carry `tag_refs`, so serializing the inverse again would duplicate relationship authority.

---

# 5. String preservation rule

Except where this proposal explicitly defines a narrower field domain, string-valued reference fields are preserved as exact JSON strings.

That means no Portable-v1 normalization of:

- leading/trailing whitespace;
- capitalization;
- Unicode normalization;
- empty versus non-empty spelling;
- display-name similarity;
- color spelling;
- SF Symbol/icon spelling.

This gate does not claim every spelling renders attractively.

It claims that the canonical record owns the spelling.

For example:

```text
Category.color = "#2F6B57"
Category.color = "2F6B57"
Category.color = "not-a-valid-color"
```

are all structurally representable strings under this schema.

Current rendering helpers may interpret those values differently.

Rendering success is not a Portable identity or schema-admission test.

Likewise:

```text
name = "Food"
name = " food "
```

remain distinct exact strings.

A future reference-management workflow may impose stronger creation validation without rewriting restoration semantics for already canonical state.

---

# 6. Required known-key rule

For the canonical v1 exporter and validation of known v1 fields, every field admitted by an entity schema is a required JSON object key.

Fields whose canonical value may be absent use explicit JSON `null`.

Therefore:

```json
{
  "institution_name": null,
  "last_four": null,
  "notes": null
}
```

means exact canonical absence for those PaymentMethod fields.

Omitting one of those keys is not treated as equivalent to null in a valid v1 record.

This provides:

- deterministic structural validation;
- exact null semantics;
- no ambiguity between absent schema field and canonical nil.

This rule freezes the presence semantics of **known v1 keys only**.

It does **not** decide what a v1 parser must do when an input object contains additional unrecognized keys. Whether such keys are rejected, ignored, preserved, or trigger version/evolution handling remains reserved for the downstream unknown-field/evolution gate.

---

# 7. Exact Category record

## 7.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000001",
  "name": "Example Category",
  "group": "custom",
  "color": "#2F6B57",
  "icon": "tag",
  "is_default": false
}
```

## 7.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical Category name |
| `group` | required | six admitted CategoryGroup tokens | exact canonical group |
| `color` | required | JSON string | exact canonical display-color metadata |
| `icon` | required | JSON string | exact canonical display-icon metadata |
| `is_default` | required | JSON boolean | exact canonical default-like classification flag |

## 7.3 Omitted Category state

Portable v1 does not serialize:

- native `Category.id`;
- `Category.created_at`;
- computed `Category.tint`;
- Transaction back-references.

## 7.4 is_default authority boundary

`is_default` is preserved because it is canonical state.

But:

```text
is_default == true
!=
proof the record came from Seed.bootstrapIfNeeded()

is_default
!=
cross-installation built-in identity

is_default
!=
merge authority
```

Restoration/conflict logic must not reinterpret this field as provenance.

---

# 8. Category group tokens

Portable v1 proposes these exact tokens:

```text
fixed_costs
investments
savings_goals
guilt_free_spending
income
custom
```

Rules:

- exact lowercase ASCII spelling;
- no case folding;
- no aliases;
- no label spelling such as `"Fixed Costs"`;
- `custom` means the canonical `.custom` group only.

Unknown token:

```text
"future_group"
!=
"custom"
```

An unknown token is not representable as a v1 Category group and must receive future-version/evolution handling rather than silent coercion.

---

# 9. Exact PaymentMethod record

## 9.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000002",
  "name": "Example Card",
  "method_type": "credit_card",
  "institution_name": "Example Institution",
  "last_four": "1234",
  "notes": null,
  "is_active": true
}
```

## 9.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical PaymentMethod name |
| `method_type` | required | eight admitted PaymentMethodType tokens | exact canonical method classification |
| `institution_name` | required, nullable | JSON string or null | exact institution display metadata or exact absence |
| `last_four` | required, nullable | exactly four ASCII decimal digits or null | final four digits of a non-secret payment-instrument identifier for display/disambiguation, or exact absence |
| `notes` | required, nullable | JSON string or null | exact canonical PaymentMethod descriptive note or exact absence |
| `is_active` | required | JSON boolean | exact canonical active/inactive flag |

## 9.3 Omitted PaymentMethod state

Portable v1 does not serialize:

- native `PaymentMethod.id`;
- `PaymentMethod.created_at`;
- credentials not represented by the admitted schema.

---

# 10. PaymentMethod type tokens

Portable v1 proposes these exact tokens:

```text
cash
debit_card
credit_card
bank_transfer
hsa
fsa
gift_card
other
```

Rules:

- exact lowercase ASCII spelling;
- no case folding;
- no display-label aliases;
- `other` means the exact canonical `.other` case.

Unknown token:

```text
"crypto_wallet"
!=
"other"
```

Unknown future types require evolution/compatibility handling.

They must not silently become `other`.

---

# 11. PaymentMethod last_four boundary

`last_four` is deliberately narrower than the other free-form string fields.

## 11.1 Repository evidence versus proposed product semantic

Current repository evidence establishes:

- canonical persistence stores `last_four` as `String?`;
- current seed examples are `"4821"` and `"9023"`;
- no model-level lexical validator currently constrains the field;
- the field is intended as a limited payment-method suffix rather than a full credential container.

That evidence does **not** independently prove that every canonical value already satisfies a decimal-only alphabet.

Therefore the following rule is an **explicit proposed Lumen Portable v1 semantic**, not an inference that current persistence already enforces it:

> A non-null Portable v1 `last_four` is the final four ASCII decimal digits of a **non-secret payment-instrument identifier**, carried only for display/disambiguation.

If non-null, v1 therefore requires:

```text
^[0-9]{4}$
```

using ASCII digits only.

A PaymentMethod that has no meaningful numeric identifier suffix uses canonical `null` for this portable field. `method_type` does not imply that every PaymentMethod must have a non-null `last_four`.

Examples:

```text
"4821"
→ representable numeric identifier suffix

null
→ representable exact absence

"821"
"•••• 4821"
"12345"
"4111111111111111"
"AB12"
"ABCD"
""
→ not representable as Portable v1 last_four
```

## 11.2 Why v1 chooses decimal digits instead of a generic four-character suffix

The credential-safety boundary supports rejecting arbitrary full credential strings, but **does not by itself prove the decimal alphabet**.

The decimal alphabet is proposed as a deliberate Minimum Sufficient Contract because:

- Lumen's current `last_four` name and seed usage are consistent with the familiar final-four-digits payment-instrument meaning;
- v1 currently has no admitted product requirement for alphanumeric or arbitrary-Unicode payment-instrument suffixes;
- broadening the field to generic four-character display metadata would invent a new semantic domain, including unresolved character-counting/Unicode questions, rather than preserve an established canonical contract;
- types such as `cash`, `gift_card`, `other`, or future instruments are not forced to fabricate a suffix; canonical absence remains `null`;
- a future version may admit a broader identifier-suffix representation if product evidence earns it.

Therefore:

```text
canonical non-null last_four outside four ASCII digits
        ↓
owned PaymentMethod remains owned
        ↓
schema representability / compatibility problem
```

The rule does **not** authorize:

- truncation;
- automatically taking the last four characters or digits from a longer source value;
- masking;
- substitution with null;
- moving the value into notes;
- interpreting a PIN, CVV, authentication code, or other secret as `last_four`;
- omitting the PaymentMethod.

The later reference compatibility gate must decide the complete-export disposition for such a record.

The already accepted owned-set rule guarantees that the record itself still belongs to the complete owned set.

---

# 12. PaymentMethod credential boundary

This schema admits only descriptive reference metadata.

It does not authorize portability of:

- full payment-card numbers;
- bank account credentials;
- authentication tokens;
- CVV/CVC values;
- PINs;
- cryptographic secrets;
- account-login state.

`institution_name` and `notes` remain descriptive strings, not credential fields.

This proposal does not create heuristic secret scanning or redaction behavior.

If future repository evidence demonstrates canonical credential material in an admitted descriptive field, that creates a separate safety/compatibility issue rather than authority to silently rewrite the value.

---

# 13. Exact Tag record

## 13.1 Proposed JSON shape

```json
{
  "portable_id": "p1-000000000003",
  "name": "Example Tag",
  "color": "#2F6B57"
}
```

## 13.2 Field contract

| Field | Presence | Type/domain | Portable meaning |
| --- | --- | --- | --- |
| `portable_id` | required | accepted Portable-ID grammar | one-document relationship identity |
| `name` | required | JSON string | exact canonical Tag name |
| `color` | required | JSON string | exact canonical display-color metadata |

## 13.3 Omitted Tag state

Portable v1 does not serialize:

- native `Tag.id`;
- `Tag.created_at`;
- inverse `Tag.transactions`.

The Transaction-side `tag_refs` relationship remains authoritative for same-document Tag associations.

---

# 14. Relationship role

Reference record content never establishes relationship identity.

Examples:

```text
Category.name equality
!=
same Category identity

PaymentMethod name + last_four equality
!=
same PaymentMethod identity

Tag name equality
!=
same Tag identity
```

Transactions resolve relationships through accepted document-local refs.

These schemas grant no automatic:

- merge;
- overwrite;
- deduplication;
- replacement;
- receiving-store match.

Reference matching/conflict semantics remain downstream.

---

# 15. Native IDs are excluded

Current canonical `id` values remain installation-local object identifiers.

Portable v1 does not emit them in these records.

The exporter may consume native IDs privately when allocating document-local `portable_id` handles under the accepted identity contract.

Preserve:

```text
native id used internally
!=
native id exported
!=
cross-installation public identity
```

---

# 16. Representability matrix

## 16.1 Category

A currently loaded Category is field-schema representable when:

- exporter can assign a valid document-local `portable_id`;
- `group` is one of the six v1 tokens.

Its string and boolean fields introduce no additional lexical rejection in this gate.

Therefore current canonical Category strings—including unusual/empty display strings—remain exactly representable.

## 16.2 PaymentMethod

A currently loaded PaymentMethod is field-schema representable when:

- exporter can assign a valid `portable_id`;
- `method_type` is one of the eight v1 tokens;
- `last_four` is null or exactly four ASCII decimal digits.

All other admitted string/nullable-string values remain exact JSON strings/null.

## 16.3 Tag

A currently loaded Tag is field-schema representable when:

- exporter can assign a valid `portable_id`.

Its name/color strings introduce no additional lexical rejection in this gate.

## 16.4 Future enum values

If a future canonical model adds:

- Category group token outside the six v1 tokens; or
- PaymentMethod type outside the eight v1 tokens;

that new canonical state is not silently representable by an old v1 token.

No fallback normalization is authorized.

Unknown-field/evolution policy remains downstream.

---

# 17. Owned but unrepresentable

The accepted export-set gate already establishes:

```text
owned
!=
necessarily representable under a later exact schema
```

This proposal supplies concrete possible representability boundaries.

Example:

```text
durable PaymentMethod
last_four = "4111111111111111"
        ↓
record still belongs in payment_methods[]
        ↓
v1 exact schema cannot represent that last_four value
        ↓
explicit compatibility/disposition required
```

What is forbidden:

```text
unrepresentable
        ↓
silently omit PaymentMethod
        ↓
rewrite Transaction.payment_method_ref
        ↓
claim complete ownership success
```

The later compatibility gate owns the exact operation-level consequence.

---

# 18. Null versus omitted

For PaymentMethod nullable fields:

```json
"institution_name": null
```

means exact canonical nil.

The same applies to:

- `last_four`;
- `notes`.

The valid v1 record still contains the key.

This proposal intentionally rejects treating:

```text
key omitted
==
key present with null
```

inside a valid v1 PaymentMethod record.

Unknown-field/evolution and parser error behavior remain separate gates.

---

# 19. Display metadata is portable state, not portable rendering

`color` and `icon` are preserved because they are canonical display metadata and current Lumen consumes them.

Portable v1 does not guarantee:

- identical rendered pixels;
- continued existence of a particular platform symbol;
- color parser behavior on all future platforms.

The contract guarantees exact field preservation.

Therefore:

```text
exact display metadata
!=
cross-platform rendering guarantee
```

---

# 20. CSV scope

This gate defines complete reference records for Portable JSON v1.

It does not turn CSV into a reference-entity graph format.

Existing CSV Category/PaymentMethod text columns remain a narrower transaction-oriented projection.

Tags remain omitted from initial CSV v1.

Any claim that a CSV column shares one of these field semantics must be admitted explicitly in the CSV contract.

---

# 21. Alternatives considered

## Alternative A — Export every remaining stored field verbatim

Rejected.

That would reintroduce native IDs, lifecycle timestamps, and inverse relationship machinery already owned by other contracts or explicitly excluded.

## Alternative B — Export only names plus portable_id

Rejected.

That loses admitted canonical state:

- Category group/color/icon/is_default;
- PaymentMethod type/institution/last_four/notes/is_active;
- Tag color.

It would not faithfully restore the owned reference object.

## Alternative C — Normalize strings for cleaner interchange

Examples:

- trim names;
- uppercase/lowercase;
- canonicalize colors;
- replace invalid icons;
- collapse empty string to null.

Rejected.

Current canonical persistence does not establish those normalizations as equivalent.

## Alternative D — Omit null PaymentMethod keys

Possible for a looser JSON convention, but rejected for exact v1 schema.

Required nullable keys make canonical absence explicit and distinguish schema omission from nil state.

## Alternative E — Preserve arbitrary PaymentMethod last_four strings

Rejected.

That would turn a field whose admitted purpose is a limited suffix into a potentially unbounded payment credential channel.

## Alternative F — Admit any four-character non-secret suffix

Rejected for v1.

This would avoid decimal-only spelling, but it would create a broader public semantic that current Lumen does not yet require:

- what counts as one character would need a Unicode/code-point/grapheme contract;
- alphanumeric and arbitrary-symbol suffixes would become permanently admitted v1 state;
- the current repository has no accepted product consumer that requires that broader domain.

The narrower four-ASCII-decimal-digit rule is therefore proposed intentionally as a v1 product semantic rather than claimed as a persistence invariant.

---

# 22. Reasoning Framework Check

## First Principles

Required capability:

Represent every admitted ordinary reference object faithfully enough for supported ownership export/restoration without serializing unrelated persistence machinery.

Necessary semantics:

- exact object-local domain/display values;
- exact canonical enum classifications;
- exact nullable absence;
- same-document identity.

Unnecessary stronger guarantees:

- native-ID portability;
- rendering equivalence;
- automatic name normalization;
- bootstrap provenance;
- restoration matching.

## Repository Evidence

Established:

- exact current SwiftData field sets;
- current enum cases/raw values;
- current UI/analytics consumption of Category/Tag display metadata;
- seeded PaymentMethod institution/last-four examples;
- accepted lifecycle exclusion;
- accepted export-set inclusion;
- accepted identity semantics.

Not established:

- a universal color lexical invariant;
- a universal SF Symbol validity invariant;
- trimming/case-folding equivalence;
- cross-installation reference identity from content;
- a persistence-level decimal validator for `PaymentMethod.last_four`;
- safe arbitrary credential export.

Claims are narrowed accordingly.

## Minimum Sufficient Contract

The proposed schemas preserve every current non-temporal domain/display field except responsibilities already excluded or replaced.

They add one narrow, explicit Portable v1 product-semantic rule for `last_four`: when non-null it means the final four ASCII decimal digits of a non-secret payment-instrument identifier used for display/disambiguation. This rule is intentionally **not** presented as an existing SwiftData validation invariant.

No generalized reference-data framework is added.

## Assembly Map

Prerequisites:

- accepted reference owned-set gate;
- accepted lifecycle exclusion;
- accepted Portable identity;
- accepted reference/null distinction.

New subassembly:

Exact Category / PaymentMethod / Tag Portable JSON v1 record shapes.

Consumers:

- reference compatibility disposition;
- reference restoration/conflict semantics;
- deterministic serialization/order;
- final Portable JSON acceptance.

## Authority Budget

Proposed new authority:

- these exact fields define v1 reference record semantics;
- enum token sets are exact;
- PaymentMethod nullable keys use explicit null;
- Portable v1 explicitly defines non-null `last_four` as the final four ASCII decimal digits of a non-secret payment-instrument identifier used only for display/disambiguation.

Explicitly not granted:

- content-based identity;
- merge/overwrite authority;
- string normalization;
- provenance inference;
- creation UI validation;
- migration;
- implementation.

## Assembly Pressure

Common schema patterns are shared only where earned:

- required `portable_id`;
- exact strings;
- explicit null for nullable PaymentMethod fields.

Entity-specific semantics remain entity-specific.

## Counterexamples

The proposal survives:

- duplicate names;
- whitespace/case-distinct names;
- invalid-looking color strings;
- invalid-looking icon strings;
- inactive PaymentMethod;
- null versus empty PaymentMethod metadata;
- future unknown enum tokens;
- non-null overlong/credential-like `last_four`;
- unreferenced owned records.

## Assembly Debt

The record shape itself no longer depends on lifecycle timestamp disposition.

Reference compatibility and restoration remain downstream because they consume these now-proposed shapes.

## Irreversible Commitments

Acceptance would make these fields public v1 semantics.

Removing an admitted field later would require version/evolution handling.

Therefore no additional field is included merely because it exists in SwiftData.

---

# 23. Exact accepted proposed-contract language

The following language is **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

> **Category record.** A Portable JSON v1 Category record defines the following required v1 keys: `portable_id`, `name`, `group`, `color`, `icon`, and `is_default`. `portable_id` follows the accepted document-local identity contract. `name`, `color`, and `icon` preserve their exact canonical string values without trimming, case folding, normalization, or rendering validation. `group` is exactly one of `fixed_costs`, `investments`, `savings_goals`, `guilt_free_spending`, `income`, or `custom`. `is_default` preserves the canonical boolean but does not prove bootstrap provenance or grant merge identity.
>
> **PaymentMethod record.** A Portable JSON v1 PaymentMethod record defines the following required v1 keys: `portable_id`, `name`, `method_type`, `institution_name`, `last_four`, `notes`, and `is_active`. `institution_name`, `last_four`, and `notes` are nullable but their keys are required; JSON null means exact canonical nil. `method_type` is exactly one of `cash`, `debit_card`, `credit_card`, `bank_transfer`, `hsa`, `fsa`, `gift_card`, or `other`. A non-null `last_four` is exactly the final four ASCII decimal digits of a non-secret payment-instrument identifier used only for display/disambiguation. This decimal-only rule is an explicit Portable v1 product semantic accepted by this component gate; it is not claimed as a current persistence validator. `is_active` preserves the canonical boolean and does not mean deletion when false.
>
> **Tag record.** A Portable JSON v1 Tag record defines the following required v1 keys: `portable_id`, `name`, and `color`. `name` and `color` preserve exact canonical strings.
>
> These required-key rules define the known canonical v1 exporter/schema surface. Treatment of **additional unrecognized input keys** remains reserved for the downstream unknown-field/evolution gate; this schema proposal does not decide whether such keys are rejected, ignored, preserved, or require version negotiation.
>
> Native SwiftData `id` values, ordinary `created_at` lifecycle timestamps, computed display helpers, and Tag inverse Transaction relationships are not fields in these v1 records.
>
> Unknown Category group tokens do not normalize to `custom`; unknown PaymentMethod type tokens do not normalize to `other`. Same-name or otherwise content-similar records do not gain identity or restoration-match authority.
>
> If an already-owned durable record cannot satisfy this exact schema, the record remains in the admitted owned set and requires explicit compatibility/disposition handling. The exporter must not silently omit the record, normalize the incompatible field, rewrite referencing Transactions, or claim complete ownership success through omission.

---

# 24. Remaining dependencies

After this proposal, still open:

1. reference-record compatibility/disposition for concrete schema failures;
2. reference restoration/conflict semantics;
3. PortableMoney lexical/governance closure;
4. exact financial-date lexical/year validity;
5. Source/provenance portability;
6. top-level/admitted timestamp lexical rules;
7. deterministic Portable-ID allocation and emitted ordering;
8. unknown-field/evolution policy;
9. full Portable JSON / CSV v1 acceptance.

---

.

Canonical values outside that admitted domain remain owned-but-unrepresentable compatibility cases. This gate grants no authority to truncate, extract a suffix automatically, mask, substitute null, move the value into another field, omit the PaymentMethod, or rewrite references.

This acceptance does **not** decide:

- treatment of additional unknown input keys;
- reference restoration/matching/merge/conflict behavior;
- concrete operation-level compatibility disposition;
- Source/provenance;
- deterministic Portable-ID allocation or emitted ordering;
- migrations;
- production implementation;
- full Portable JSON / CSV v1 acceptance.

---

# 26. Review boundary

This gate is closed at **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

Do not open reference compatibility/restoration, Source/provenance, deterministic-ordering, or another Phase 1C gate from this checkpoint without separate authorization.
