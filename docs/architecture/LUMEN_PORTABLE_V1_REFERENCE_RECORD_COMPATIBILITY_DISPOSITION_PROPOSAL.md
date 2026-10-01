# Lumen Portable v1 Reference-Record Compatibility / Export Disposition Proposal

## Status

**ACCEPTED AT PROPOSED-CONTRACT LEVEL — independently reviewed Phase 1C ordinary reference-record compatibility/export-disposition gate.**

Starting accepted semantic checkpoint:

`377a2fda1fd41a1f169ed6299de86740c53313ef`

Branch:

`docs/phase1c-portable-v1-reference-record-compatibility-disposition-proposal`

This proposal does not reopen:

- the accepted complete-export set for Category / PaymentMethod / Tag;
- the accepted exact Category / PaymentMethod / Tag schemas;
- lifecycle-timestamp exclusion;
- Portable identity semantics;
- Source / TransactionSource semantics;
- restoration matching / merge / overwrite authority.

It does not authorize production code, tests, persistence/schema changes, migrations, importer/exporter implementation, serializer implementation, or UI.

---

# 1. Decision question

For a requested **complete Portable JSON v1 ownership export**:

> **What must Lumen do when an already-owned durable Category, PaymentMethod, or Tag cannot be represented exactly under the accepted Portable v1 reference-record schema?**

The gate decides operation-level compatibility disposition.

It does not redesign the schema to make incompatible state fit.

---

# 2. Accepted prerequisites

This gate consumes three previously admitted assemblies.

## 2.1 Owned set

For complete Portable JSON ownership export:

```text
every durable Category
→ categories[]

every durable PaymentMethod
→ payment_methods[]

every durable Tag
→ tags[]
```

Membership is independent of Transaction reachability, guessed creation provenance, default-like appearance, `PaymentMethod.is_active`, display-name similarity, or expected destination bootstrap.

Therefore:

```text
owned
!= optional merely because awkward to serialize
```

## 2.2 Exact schemas

Accepted known-field schemas are:

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

Accepted schema semantics include:

- exact CategoryGroup token set;
- exact PaymentMethodType token set;
- exact string preservation for admitted string fields;
- explicit null semantics for nullable PaymentMethod fields;
- non-null `last_four` means exactly four ASCII decimal digits of a non-secret payment-instrument identifier used for display/disambiguation;
- unknown future group/type tokens do not coerce to `custom` / `other`;
- owned-but-unrepresentable records remain owned.

## 2.3 Complete ownership meaning

Portable JSON v1 is the normative, highest-fidelity ownership representation for durable state explicitly admitted to the current portability contract.

A complete ownership artifact cannot truthfully claim completeness after silently dropping an admitted owned object.

---

# 3. First-principles boundary

The problem is not:

> Can Lumen produce syntactically valid JSON somehow?

The problem is:

> Can Lumen produce a Portable JSON v1 artifact that truthfully represents the complete admitted owned reference state?

Preserve:

```text
serializable somehow
!=
representable under accepted v1 semantics

owned
!=
necessarily representable

unrepresentable
!=
permission to omit

unrepresentable
!=
permission to mutate canonical state
```

---

# 4. Current repository evidence

## 4.1 Category

Current canonical Category persists:

- `name: String`;
- `group: CategoryGroup`;
- `color: String`;
- `icon: String`;
- `is_default: Bool`.

The current `CategoryGroup` enum cases exactly match the six accepted v1 group tokens.

Current Category strings and booleans introduce no additional accepted lexical rejection.

Therefore no concrete current Category field-domain incompatibility is demonstrated in the present model.

A future canonical enum case outside the v1 set would create a compatibility case for an exporter still claiming Portable v1.

## 4.2 PaymentMethod

Current canonical PaymentMethod persists:

- `name: String`;
- `method_type: PaymentMethodType`;
- `institution_name: String?`;
- `last_four: String?`;
- `notes: String?`;
- `is_active: Bool`.

The current `PaymentMethodType` enum cases exactly match the eight accepted v1 tokens.

The model does **not** validate `last_four` lexically.

Therefore current storage is broader than the accepted v1 `last_four` domain.

Example technically permitted by the current initializer/model:

```text
last_four = "AB12"
```

or:

```text
last_four = "4111111111111111"
```

The repository does not establish that ordinary current UI creates those values.

The evidence class is:

```text
technically persistable under current model
!=
demonstrated authentic production/user state
```

That is sufficient to require a truthful compatibility rule if encountered.

## 4.3 Tag

Current canonical Tag persists:

- `name: String`;
- `color: String`.

Both are accepted as exact strings.

Therefore no concrete current Tag field-domain incompatibility is demonstrated in the present model.

## 4.4 Portable identity is not the compatibility axis here

Every admitted reference record requires a document-local `portable_id`.

Exporter-owned Portable-ID generation, capacity, allocation order, and deterministic assignment remain governed by the identity / deterministic-ordering line.

This proposal does **not** classify a hypothetical ID-allocation failure as a canonical reference-record field incompatibility.

---

# 5. Evidence classes

## Class 1 — demonstrated representable current state

Examples include:

- all current seeded Categories;
- all current seeded Tags;
- seeded PaymentMethods with `last_four == null`;
- seeded numeric examples such as `"4821"` and `"9023"`.

## Class 2 — current model/storage permits state outside accepted v1 schema

The concrete present example is:

- non-null PaymentMethod `last_four` outside `^[0-9]{4}$`.

This does not require manufacturing a fixture to prove the model accepts arbitrary `String?`.

## Class 3 — future canonical evolution incompatible with v1

Examples include a future:

- `CategoryGroup` token outside the six admitted v1 tokens;
- `PaymentMethodType` token outside the eight admitted v1 tokens.

Such values do not exist in the present enum definitions.

The compatibility contract may define how v1 behaves if future canonical state exceeds the old v1 domain, without claiming that state exists today.

---

# 6. Compatibility taxonomy

## A. PaymentMethod last_four incompatibility

A durable owned PaymentMethod is v1-incompatible on this axis when:

```text
last_four != null
and
last_four does not match ^[0-9]{4}$
```

The record remains owned.

The incompatible value is not rewritten.

## B. Category group-token incompatibility

If canonical state can contain a Category group outside the six v1 tokens, that record is incompatible with Portable JSON v1.

No fallback to `custom` is authorized.

## C. PaymentMethod type-token incompatibility

If canonical state can contain a PaymentMethod type outside the eight v1 tokens, that record is incompatible with Portable JSON v1.

No fallback to `other` is authorized.

## D. Other accepted-schema incompatibility

A future implementation may expose another canonical known-field state that violates an accepted v1 known-field domain.

That requires explicit classification rather than coercion.

This catch-all does not authorize a new field domain.

---

# 7. Non-loss invariants

```text
reference-schema incompatibility
!= permission to omit the owned record
!= permission to normalize the field
!= permission to truncate
!= permission to mask
!= permission to substitute null
!= permission to move data into another field
!= permission to rewrite Transaction references
!= permission to fabricate a different reference object
```

For `last_four` specifically:

```text
incompatible credential-like source value
!= permission to echo that raw value into diagnostics
```

The compatibility mechanism must not become a credential-exfiltration surface.

---

# 8. Separate claims

## 8.1 Valid Portable JSON serialization

A Portable JSON v1 artifact is structurally/semantically valid only when each included record satisfies the applicable accepted v1 record schema.

## 8.2 Complete ownership export

A complete Portable JSON v1 ownership export claims that every in-scope owned durable object in the selected coherent snapshot is represented according to the admitted v1 contract.

Therefore:

```text
owned reference record omitted because incompatible
→ artifact may not claim complete ownership
```

## 8.3 Supported-state round trip

A supported round trip requires that the artifact contain the admitted state it claims to restore.

An owned object that never entered the artifact has no valid complete-round-trip claim.

These claims remain distinct.

---

# 9. Export preflight

Before claiming successful completion of a **complete Portable JSON v1 ownership export**, Lumen must preflight every owned durable:

- Category;
- PaymentMethod;
- Tag;

in the selected coherent snapshot against the accepted exact v1 known-field schema.

Preflight must be non-mutating.

It must not repair canonical state merely to make export pass.

The operation may also have other independent preflight axes, including already accepted monetary/currency compatibility.

This proposal does not define one implementation architecture for combining those checks.

It does establish:

```text
any independently blocking complete-export incompatibility
→ complete Portable JSON ownership success cannot be claimed
```

---

# 10. Minimum deterministic diagnostics

For each incompatible owned reference record, preflight must be able to provide:

- entity family: Category / PaymentMethod / Tag;
- deterministic association sufficient to identify the source canonical object for that export attempt;
- one or more stable incompatibility reason semantics;
- the incompatible known-field axis;
- enough safe context for a user/system to understand what requires attention.

Candidate reason semantics:

```text
reference_category_group_not_in_v1
reference_payment_method_type_not_in_v1
reference_payment_method_last_four_out_of_domain
reference_other_known_field_schema_incompatibility
```

Exact diagnostic wire format, UI wording, ordering, persistence, and Portable-ID usage remain downstream.

## 10.1 Credential-safe diagnostics

A `last_four` incompatibility diagnostic must not require reproducing the raw incompatible value.

For example, if canonical persistence contains a longer credential-like string, the compatibility result can identify:

```text
PaymentMethod
field = last_four
reason = reference_payment_method_last_four_out_of_domain
```

without exporting or logging the full string merely to explain failure.

Whether a trusted local UI may display some source value under a separately designed privacy contract is not decided here.

---

# 11. Alternatives considered

## Alternative A — Atomic refusal of complete Portable JSON ownership export

Rule:

If any owned Category / PaymentMethod / Tag in the coherent snapshot cannot satisfy the accepted v1 schema, the requested **complete Portable JSON v1 ownership export** does not complete successfully.

Preflight returns deterministic incompatibility diagnostics.

Advantages:

- truthful completeness;
- no silent data loss;
- preserves accepted schema authority;
- preserves accepted owned-set authority;
- avoids inventing a second wire representation;
- does not mutate canonical state.

Cost:

- one incompatible owned reference record can block a complete ownership export.

Disposition:

**RECOMMENDED.**

## Alternative B — Explicitly partial Portable JSON export

A future operation could export only a supported subset.

This is not admitted here.

Reference data makes partialness especially consequential because omission can break relationship closure.

For example:

```text
Transaction.payment_method_ref
→ owned PaymentMethod
→ PaymentMethod incompatible and omitted
```

A future partial-export contract would need to define whether dependent Transactions are also excluded, references are otherwise represented, or another explicit compatibility mechanism applies.

This gate does not invent those semantics.

Any future partial artifact must not masquerade as a complete ownership export.

## Alternative C — Separate compatibility representation

A future separately named/versioned representation could preserve exact incompatible canonical reference state without pretending it satisfies the Portable v1 exact schema.

This could be useful if real compatibility pressure earns it.

It would require separate:

- recognition/versioning;
- field semantics;
- privacy rules;
- relationship behavior;
- restoration behavior.

Not admitted here.

## Alternative D — Emit the incompatible value anyway

Rejected.

That silently widens the accepted v1 schema.

## Alternative E — Normalize or coerce

Rejected.

Examples include:

- `AB12` → `null`;
- `4111111111111111` → `1111`;
- future group → `custom`;
- future method type → `other`.

Those transformations invent or lose canonical meaning.

## Alternative F — Omit the incompatible object

Rejected for complete ownership export.

The owned-set gate already establishes that the object belongs in the complete snapshot.

---

# 12. Recommended proposed disposition

> **A complete Portable JSON v1 ownership export is all-or-nothing with respect to accepted Category / PaymentMethod / Tag record-schema compatibility. If any owned durable record in those admitted families cannot be represented exactly under the accepted v1 known-field schema, the operation must not claim successful completion as a complete Portable JSON v1 ownership export.**

> **Preflight must identify incompatible records deterministically and report stable incompatibility reason semantics without mutating canonical state.**

> **A `last_four` incompatibility diagnostic must not require disclosure of the raw incompatible value.**

This is independently justified by the accepted owned-set and exact-schema contracts.

The monetary compatibility gate is precedent for separating valid serialization, complete ownership, and partial export; it is not the source of authority for this reference disposition.

---

# 13. User resolution versus exporter mutation

An export incompatibility may later be resolved if the canonical reference record is deliberately edited under ordinary authorized product behavior and the resulting state satisfies the v1 schema.

That would be a new canonical state decision.

It is not permission for export preflight itself to edit the record.

Preserve:

```text
user-authorized canonical edit
!=
exporter normalization
```

This gate does not define a PaymentMethod editing UI or resolution workflow.

---

# 14. Composition with monetary compatibility

A complete ownership export may have multiple independent compatibility axes.

Conceptually:

```text
Transaction monetary compatibility
AND
ordinary reference-record schema compatibility
AND
other eventually admitted complete-export predicates
        ↓
all must pass
before complete Portable JSON ownership success
```

One failed axis does not erase diagnostics from another.

The implementation may eventually aggregate all materially applicable preflight findings.

This proposal does not freeze that aggregate diagnostic transport.

---

# 15. CSV boundary

This gate governs **complete Portable JSON v1 ownership export**.

Lumen CSV v1 remains intentionally narrower and is not promoted to a complete reference-graph ownership artifact.

This proposal does not define a CSV reference-record compatibility operation because Category / PaymentMethod / Tag full records are not represented by CSV as a complete entity graph.

Shared fields still may not be silently normalized under CSV merely because CSV is narrower, but exact CSV compatibility semantics remain separately governed.

---

# 16. Restoration boundary

This proposal decides what artifacts the complete exporter may truthfully claim to produce.

It does not decide what happens when a valid admitted reference record meets destination state such as:

- same display name;
- similar semantic content;
- locally bootstrapped defaults;
- a distinct existing local record;
- ambiguous candidates.

Those remain reference restoration / matching / merge / conflict questions.

Preserve:

```text
export compatibility
!=
destination match authority
```

---

# 17. Unknown-field / evolution boundary

This proposal concerns **canonical source state that cannot satisfy accepted known v1 field domains**.

It does not decide how a v1 parser handles additional unrecognized input keys.

Preserve:

```text
source canonical field incompatibility
!=
unknown input-field evolution policy
```

Future enum expansion may create v1 field-domain incompatibility because an accepted known field carries a token outside v1.

That is distinct from an input object merely containing an additional unknown key.

---

# 18. Reasoning Framework Check

## First Principles

Capability:

Produce a truthful complete ownership artifact for admitted durable reference state.

Established facts:

- every durable Category / PaymentMethod / Tag belongs to the complete owned set;
- exact v1 schemas are accepted;
- `PaymentMethod.last_four` persistence is broader than the accepted v1 domain;
- schema acceptance forbids silent normalization/omission.

Minimum sufficient contract:

Block the **complete ownership success claim** when any owned ordinary reference record is unrepresentable.

Do not create a second compatibility format or partial-export system without a demonstrated need.

## Repository Evidence

Current concrete incompatibility:

- non-null `PaymentMethod.last_four` outside four ASCII decimal digits is technically persistable.

Current enums do not demonstrate unknown tokens.

The proposal therefore does not pretend future enum incompatibility already exists.

## Assembly Map

Prerequisites:

- accepted reference complete-export set;
- accepted exact reference schemas;
- accepted Portable identity boundary;
- Phase 1C complete-ownership contract.

New subassembly:

Reference-record complete-export compatibility disposition.

Consumers:

- complete-export preflight;
- future reference compatibility diagnostics;
- later restoration only after a valid artifact exists.

Unresolved downstream work:

- destination matching/conflict;
- diagnostic wire representation;
- exact serializer/order;
- implementation.

## Authority Budget

New normative authority proposed:

Lumen may refuse to claim successful **complete Portable JSON v1 ownership export** when an owned admitted reference record cannot satisfy the accepted exact schema.

Governing basis if accepted:

this independently reviewed compatibility gate composed with the accepted owned-set and schema gates.

Evidence:

current model/schema mismatch on `last_four`; accepted schema boundaries; complete-ownership semantics.

Authority explicitly not granted:

- mutate canonical state;
- omit records while claiming complete export;
- normalize incompatible fields;
- rewrite references;
- merge destination records;
- expose raw credential-like incompatible values;
- create partial-export semantics;
- create a new compatibility format.

## Assembly Debt

None in the strict semantic sense.

The owned set and exact schemas are already established.

Restoration matching remains downstream because it requires a valid artifact first.

## Assembly Pressure

Money compatibility independently uses the same broad pattern:

```text
owned admitted state
+
public representation cannot express it exactly
→ explicit compatibility disposition
```

This recurrence supports the pattern but does not justify a universal generic compatibility framework yet.

Different domains may still have different operation-level consequences.

## Counterexamples

- unreferenced incompatible PaymentMethod still blocks complete export because unreferenced does not mean unowned;
- a referenced incompatible PaymentMethod cannot be omitted without breaking ownership and potentially reference closure;
- a future enum token cannot be mapped to `custom` / `other`;
- a credential-like `last_four` cannot be echoed merely because diagnostics need explanation;
- a valid partial artifact, if ever admitted, is not a complete ownership artifact.

## Irreversible commitments

If accepted, Portable v1 complete-export semantics will promise that reference-schema incompatibility blocks complete success rather than silently degrading the artifact.

Future partial/compatibility modes must remain explicitly distinct.

---

# 19. Exact accepted proposed-contract language

The following language is **ACCEPTED AT PROPOSED-CONTRACT LEVEL**.

> **Reference-record complete-export compatibility.** Before claiming successful completion of a complete Portable JSON v1 ownership export, Lumen must evaluate every durably owned Category, PaymentMethod, and Tag in the selected coherent export snapshot against the accepted Portable v1 known-field schema for that entity family.
>
> **If any owned record cannot be represented exactly under the accepted v1 schema, the operation must not claim successful completion as a complete Portable JSON v1 ownership export.**
>
> Reference-schema incompatibility does not authorize omission of the owned record, normalization/coercion of the incompatible field, substitution with null, movement of data into another field, fabrication of a replacement object, or rewriting of Transaction references.
>
> Export preflight must provide deterministic association to each incompatible source object and stable incompatibility reason semantics. Exact diagnostic wire format, UI, persistence, and ordering remain downstream.
>
> For a `PaymentMethod.last_four` incompatibility, diagnostics must not require disclosure of the raw incompatible canonical value merely to establish or report incompatibility.
>
> A future partial export or broader compatibility representation may be admitted separately, but neither may silently redefine the accepted exact v1 schemas or masquerade as a complete Portable JSON v1 ownership export.
>
> This compatibility disposition does not grant destination matching, merge, overwrite, deduplication, or conflict-resolution authority.

---

# 20. Remaining dependencies

Still open after this acceptance:

1. reference restoration / matching / merge / conflict semantics;
2. Source/provenance portability;
3. PortableMoney lexical/governance closure;
4. exact financial-date lexical/year validity;
5. top-level/admitted timestamp lexical rules;
6. deterministic Portable-ID allocation and emitted ordering;
7. unknown-field/evolution policy;
8. full Portable JSON / CSV v1 acceptance.

---

# 21. Review questions

Independent review should answer:

1. Is all-or-nothing complete Portable JSON ownership export independently justified for reference-schema incompatibility?
2. Does the accepted owned-set rule make omission incompatible with a truthful complete-export claim even for zero-reference records?
3. Is the current concrete incompatibility evidence correctly limited to technically persistable out-of-domain `PaymentMethod.last_four`?
4. Are future unknown enum tokens correctly treated as forward compatibility rather than current-state evidence?
5. Should diagnostics avoid reproducing a raw incompatible `last_four` value?
6. Are partial export and compatibility representation correctly kept possible but unadmitted?
7. Does this proposal avoid leaking into destination matching/conflict authority?
8. Is Portable-ID assignment correctly kept outside canonical field-schema incompatibility?
9. Does this gate remain JSON-complete-export specific without accidentally upgrading CSV?
10. Does it preserve all accepted schema and ownership semantics without widening them?

---

# 22. Independent-review acceptance and boundary

Independent review of:

`8b1b8cd70459ad51865f05b542f7c65c6ffff2b5`

passes at the proposed-contract level.

Accepted operation-level rule:

```text
durably owned Category / PaymentMethod / Tag
+
accepted exact v1 schema cannot represent the record
        ↓
requested complete Portable JSON v1 ownership export
must not claim successful completion
```

Accepted consequences:

- complete-export compatibility preflight is non-mutating and evaluates every durably owned Category, PaymentMethod, and Tag in the selected coherent snapshot, including owned records with zero Transaction references;
- an incompatible record remains owned;
- schema incompatibility does not authorize omission, normalization, coercion, truncation, masking, null substitution, movement into another field, fabrication of a replacement object, or rewriting of Transaction references;
- preflight must provide deterministic source-object association and stable incompatibility-reason semantics at the semantic level, while exact reason-token spelling, diagnostic wire format, persistence, ordering, UI wording, and Portable-ID use remain downstream;
- for `PaymentMethod.last_four`, incompatibility diagnostics must not require disclosure of the raw incompatible canonical value merely to establish or report the incompatibility;
- the concrete present compatibility case is a technically persistable non-null `last_four` outside `^[0-9]{4}$`; future CategoryGroup or PaymentMethodType expansion is forward-compatibility pressure, not evidence of current incompatible stores;
- independent complete-export compatibility axes remain independently reportable: failure on one axis does not erase materially applicable findings on another, without freezing one aggregation architecture;
- a future explicitly partial export or separately identified compatibility representation remains possible only through separate admission, and neither may masquerade as a complete Portable JSON v1 ownership export.

This acceptance does **not** decide:

- destination matching, merge, overwrite, deduplication, or conflict authority;
- unknown-input-field evolution policy;
- Portable-ID allocation, capacity, or emitted ordering;
- CSV complete-export semantics;
- Source / TransactionSource portability or provenance;
- migrations;
- implementation;
- full Portable JSON / CSV v1 format acceptance.

This component-gate acceptance does not authorize production code, tests, persistence/schema changes, migrations, importer/exporter implementation, serializer implementation, or UI.

Do not open reference restoration/conflict, Source/provenance, deterministic-ordering, or another Phase 1C gate from this checkpoint without separate authorization.
