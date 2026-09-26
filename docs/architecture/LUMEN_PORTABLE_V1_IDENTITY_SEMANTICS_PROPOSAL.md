# Lumen Portable v1 Identity Semantics Proposal

**Status:** PROPOSED FOR REVIEW

**Gate:** Phase 1C Portable identity semantics

**Base checkpoint:** `docs/phase1c-portable-v1-transaction-type-direction-proposal @ db75dc05f7bfc103acc16b4c5635a920a994c1ce`

This is a docs/evidence proposal only. It does not modify production code, tests, SwiftData schema, model identifiers, importer/exporter implementation, migrations, promotion machinery, deterministic array ordering, or previously accepted Portable-v1 semantics.

---

# 1. Decision Question

The first question is not which UUID spelling Portable v1 should use.

It is:

> **What identity does `portable_id` establish in Portable JSON v1, what is its required scope/lifetime, and what authority does that identity explicitly not carry?**

The proposed answer is deliberately narrower than a durable external object identity:

> **Portable JSON v1 `portable_id` is a document-local, globally unique relationship handle. Its identity lifetime is one Portable JSON document. It reconstructs relationships inside that document and carries no cross-document sameness or mutation authority.**

Therefore Portable v1 proposes **document-local identity (Model A)** rather than same-store durable export identity or round-trip durable portable identity.

The proposal does **not** claim that two equal `portable_id` strings in two different Portable JSON documents identify the same logical object.

---

# 2. Repository Evidence

## 2.1 Persisted model IDs exist, but are not one uniform public identity contract

`ios-lumen-finance/LumenFinance/Models/Models.swift` defines String IDs for current persisted models.

Relevant current forms are:

```swift
Category.id: String = UUID().uuidString
PaymentMethod.id: String = UUID().uuidString
Tag.id: String = UUID().uuidString
TransactionSource.id: String = UUID().uuidString
Transaction.id: String = UUID().uuidString
```

The model file describes these names as mirroring planned schema IDs/foreign keys, but current SwiftData relationships are object relationships rather than a Portable public-ID contract.

Important evidence boundaries:

- the fields are mutable `String` properties;
- UUID text is the default constructor behavior, not a universal persisted grammar guarantee;
- current model declarations shown here do not schema-enforce one cross-entity global ID namespace;
- current code does not define these values as public Portable API;
- no current persisted `portable_id` field exists.

The Phase 1C ownership contract already freezes:

```text
SwiftData/local persistence identity
!=
permanent public portable identity
!=
overwrite authority on import
```

## 2.2 Category, PaymentMethod, and Tag IDs are current local relationship-selection keys

`TransactionDraft` keeps Category and PaymentMethod as object references and Tag selection as `Set<String>` of current `Tag.id` values.

On edit:

```swift
category = txn.category
payment_method = txn.payment_method
tagIDs = Set(txn.tags.map(\.id))
```

On confirmation:

```swift
category: category
payment_method: payment_method
tags: allTags.filter { tagIDs.contains($0.id) }
```

This establishes that current IDs participate in local application identity/selection behavior.

It does not establish that they are suitable permanent public identifiers.

## 2.3 Transaction ID is distinct from duplicate/content identity

Current duplicate characterization uses `Transaction.id` only to exclude the transaction being edited from a similarity search.

The duplicate matcher separately compares financial semantics.

Therefore:

```text
same financial content
!=
same Transaction identity
```

and:

```text
Transaction.id
!=
duplicate fingerprint / duplicate decision
```

Two distinct Transactions may legitimately have identical amount/date/merchant/type/category content.

Portable identity must not be generated from mutable financial content equality.

## 2.4 Default reference data does not have installation-independent IDs

`Seed.seedCategories()`, `seedPaymentMethods()`, and `seedTags()` construct current reference entities without supplying IDs.

Their IDs therefore come from fresh `UUID().uuidString` defaults.

Consequences:

- a default category such as “Dining” can have different native IDs in two installations;
- same name/group/type does not prove same canonical object identity;
- a fresh-store restoration may resolve/create a semantically corresponding reference entity without inheriting the exporting installation's native ID;
- display/content similarity must remain separate from Portable identity.

This is direct evidence against treating current default-data IDs as globally meaningful identities.

## 2.5 TransactionSource has stronger Phase 1B semantic identity rules

Phase 1B is an important special case.

`EvidenceIdentity` treats parseable UUID forms of `TransactionSource.id` as semantic evidence identities:

- UUID spellings compare semantically;
- case-varied UUID strings can conflict;
- persisted semantic ownership is counted from saved rows;
- historical non-UUID source IDs remain untouched;
- duplicate semantic owners are an identity conflict.

`RetainedEvidenceLocator` uses:

```text
lumen-evidence://v1/<CANONICAL-UUID>/payload
```

and verifies that the locator UUID matches the owning source's semantic UUID.

This identity belongs to **Confirmed Evidence Retention v1**.

Phase 1C must consume it without redefining it.

The existence of a strong source/evidence UUID therefore does not authorize:

```text
TransactionSource evidence UUID
=
Portable public identity
=
Portable overwrite authority
```

A Portable Source record may be assigned a document-local `portable_id` while Phase 1B source/evidence identity continues to govern retained-evidence semantics independently.

## 2.6 Evidence-operation identity is coordination authority, not Portable identity

`EvidenceOperationCoordinator` leases work by a `sourceID: UUID` plus an in-memory token.

That UUID scopes concurrent evidence operations.

The token/lease does not survive as a Portable record identity and does not establish cross-export object identity.

## 2.7 Draft/source copying preserves source identity for the confirmation workflow

`TransactionDraft.confirmationSource` copies `source.id` when constructing the source used at confirmation.

That behavior preserves the Phase 1B source/evidence association through confirmation.

It is not evidence that every current model `id` should become a public portable identifier.

## 2.8 Repeated import and promotion authority are already separate

The Phase 1C responsibility contract distinguishes:

```text
same interrupted confirmation replay
```

from:

```text
a later user-selected import containing overlapping data
```

Importing the same portable file twice does not automatically grant overwrite/delete authority.

Therefore Portable identity must not become promotion replay authority or later-import mutation authority.

---

# 3. Identity Taxonomy

The repository currently contains several identity concepts that must remain distinct.

| Identity concept | Current evidence | Lifetime / role | Portable authority? |
| --- | --- | --- | --- |
| SwiftData persistence identity | `persistentModelID` | local persistence/object tracking | none |
| model/domain ID | model `id: String` | local durable application identifier/selection key | exporter input only under this proposal |
| Phase 1B evidence semantic identity | parseable UUID `TransactionSource.id` | retained-evidence ownership/association | remains Phase 1B authority only |
| Portable record identity | proposed `portable_id` | one Portable JSON document | relationship resolution only |
| Portable relationship identity | `category_ref`, `payment_method_ref`, `tag_refs`, `source_ref` | points to Portable records in same document | same-document resolution only |
| draft selection identity | e.g. `tagIDs` | transient Review/edit selection | none |
| evidence-operation lease identity | source UUID + lease token | in-process coordination | none |
| promotion/replay identity | separately governed Phase 1C concern | one confirmed operation/recovery | none |
| duplicate-detection identity | financial similarity/fingerprint logic | duplicate awareness | none |
| overwrite/update authority | not granted by current portable contract | explicit future authority if ever admitted | **not granted** |

The central invariant is:

```text
same underlying value shape (for example UUID)
!=
same identity semantics
```

---

# 4. Candidate Lifetime Models

## 4.1 Model A — document-local identity

Definition:

```text
portable_id identifies exactly one Portable record
inside one Portable JSON document

same portable_id spelling in another document
→ no sameness claim
```

Benefits:

- sufficient for Category/PaymentMethod/Tag/Source relationship reconstruction;
- does not externalize a permanent canonical identity;
- does not require a new persisted portable-ID field;
- does not require imported IDs to become native model IDs;
- minimizes cross-artifact correlation;
- cleanly separates repeated import from overwrite/synchronization;
- fresh-store restoration can create normal new canonical IDs.

Costs:

- IDs are not promised stable across separate exports;
- cross-export diffs cannot use `portable_id` as durable object identity;
- export → fresh-store import → re-export can legitimately produce different IDs;
- deterministic identity assignment must be defined per document.

**Proposed.**

## 4.2 Model B — same-store cross-export identity

Definition:

```text
same canonical object in one store
→ same portable_id on later exports
```

Potential benefits:

- stronger diffability;
- stable relationship handles across exports from one store;
- easier cross-export correlation.

Costs:

- creates a persistent public correlation surface;
- encourages consumers to infer update/sync authority;
- requires a durable stable generation input;
- current model IDs would either need to be exposed or deterministically transformed;
- duplicate/noncanonical ID cases would need stronger public disposition;
- does not by itself solve fresh-store re-export continuity.

The repository does not currently require this lifetime for ownership round trip.

**Not proposed for v1.**

## 4.3 Model C — round-trip durable portable identity

Definition:

```text
Store A object
→ export P1
→ fresh Store B import
→ later Store B export
→ P1 again
```

This is materially stronger.

It would require at least one of:

- making the imported Portable identity the new canonical model ID;
- persisting Portable identity separately;
- preserving an equivalent durable mapping.

That would make Portable identity part of Lumen's durable data model and could require schema/persistence admission.

No such requirement is currently established.

**Rejected for v1 absent a separate future admission.**

## 4.4 Model D — canonical/domain public identity

Definition:

```text
portable_id is the durable external identity
of the canonical object itself
```

This most strongly conflates portability with synchronization/domain identity.

It is not earned by current evidence and would create authority ambiguity.

**Rejected for v1.**

---

# 5. Proposed Identity Lifetime

Portable JSON v1 proposes:

> **`portable_id` is document-local. Its semantic lifetime begins with one coherent Portable JSON document and ends at that document boundary.**

A Portable importer may retain an in-memory/import-workspace map while processing that document:

```text
portable_id
→ resolved/created canonical object
```

but Portable v1 does not require that mapping to become durable canonical state.

Therefore:

```text
same-store export A portable_id
may differ from
same-store export B portable_id
```

and:

```text
Store A export portable_id
may differ from
Store B re-export portable_id
after successful round trip
```

Neither difference violates semantic round-trip ownership.

The round-trip guarantee is restoration of admitted canonical semantics and relationships, not preservation of document-local handles.

---

# 6. Fresh-Store Restoration

Consider:

```text
Store A
Transaction native ID = A1
Portable document handle = P1
        ↓
export
        ↓
fresh Store B import
        ↓
Transaction native ID = B7
```

Under the proposed model:

- P1 resolves relationships while importing that document;
- P1 does not have to become B7;
- P1 does not have to be stored durably;
- a later Store B export may assign another document-local handle P9;
- round-trip equivalence is not broken merely because P1 != P9.

This avoids smuggling a new persisted Portable identity field into the public contract.

It also avoids requiring seeded/default reference entities in Store B to adopt Store A's local IDs.

---

# 7. Privacy and Cross-Artifact Correlation

Stable cross-export IDs reveal that two separately shared artifacts contain the same logical record even when mutable fields change.

Document-local IDs deliberately avoid promising that correlation channel.

This does not make separate exports unlinkable: financial content itself can be identifying or correlatable.

The narrower claim is:

> **Portable v1 does not add a durable cross-artifact record correlator merely to reconstruct relationships inside one artifact.**

This is a privacy and authority-minimization property, not an anonymity guarantee.

---

# 8. Namespace Model

Portable JSON v1 proposes **one global `portable_id` namespace per document**.

Therefore all Portable records across:

- Transactions;
- Categories;
- PaymentMethods;
- Tags;
- Sources;

must have distinct `portable_id` values in the same document.

This is stricter than entity-scoped uniqueness.

Example:

```text
Transaction portable_id = p1-000000000123
Category portable_id    = p1-000000000123
→ invalid document: duplicate portable_id
```

Rationale:

- one lookup table can classify every reference target;
- duplicate diagnostics are unambiguous;
- wrong-entity-type references can be distinguished from unresolved references;
- future generic relationship tooling does not need to infer an entity namespace from string reuse;
- global uniqueness costs little for document-local handles.

The identifier itself remains opaque; entity type is established by the record collection in which the target occurs, not encoded as business meaning in the identifier.

---

# 9. Relationship Resolution

For every non-null Portable reference:

```text
category_ref
payment_method_ref
tag_refs[]
source_ref
```

the importer must distinguish at least:

## 9.1 Null / absent relationship

Example:

```json
"category_ref": null
```

Meaning:

> the exporting canonical Transaction had no Category association.

This preserves the already accepted categoryless contract.

## 9.2 Valid resolved reference

Exactly one record with that `portable_id` exists in the document and it is in the required target entity collection.

Result:

> relationship may be reconstructed subject to the separately admitted entity restoration/Review rules.

## 9.3 Unknown/unresolved non-null reference

No record in the document owns that `portable_id`.

Result:

> reference/dataset incompatibility.

It must not silently become null.

## 9.4 Duplicate portable ID

More than one record in the document owns the same `portable_id`.

Result:

> invalid Portable JSON document / identity conflict.

No first-record-wins or last-record-wins behavior is permitted.

## 9.5 Wrong-entity-type reference

A record owns the referenced `portable_id`, but in the wrong entity collection.

Example:

```text
category_ref = P7
P7 identifies a Tag
```

Result:

> wrong-target-type reference failure.

It is not a missing Category and must not degrade to null or semantic-name matching.

## 9.6 Duplicate references in a set-like relationship

`tag_refs` represents associations.

Repeated use of the same `portable_id` inside one Transaction's `tag_refs` does not create multiple Tag identities.

The exact parser disposition for duplicate array entries remains a parser/representation detail, but it must not create duplicate canonical relationships.

---

# 10. Explicit Non-Authorities

Portable v1 freezes:

```text
portable_id
!= overwrite authority
!= delete authority
!= automatic deduplication identity
!= promotion replay identity
!= synchronization authority
!= SwiftData persistentModelID
!= proof of semantic similarity
```

A later import carrying the same spelling does not gain mutation authority because, under this proposal, equality across documents has no identity meaning at all.

Even within one document, `portable_id` answers:

> “Which exported record does this reference target?”

It does not answer:

> “Which existing local record may this import overwrite?”

Reference-entity matching/conflict rules remain separate.

---

# 11. Same Financial Content Does Not Establish Identity

Portable identity must not be generated from mutable financial content such as:

- amount;
- currency;
- merchant;
- transaction date;
- status;
- Category name;
- Transaction type;
- notes.

Two distinct canonical Transactions can have identical business fields.

Likewise:

```text
Category A deleted
new Category named "Food" created later
```

does not establish that the new Category is the same object.

Name/content similarity may support a future match proposal.

It does not establish Portable identity.

---

# 12. Generation Authority

## 12.1 Authority

The **export operation** owns document-local `portable_id` assignment.

Neither the canonical model nor the importer is required to persist that handle.

## 12.2 Internal identity input is not public identity

The exporter may use current canonical model IDs as internal deterministic ordering/allocation inputs because those IDs already distinguish local objects in ordinary repository behavior.

That use does **not** make the native ID part of the Portable payload or grant it public authority.

Preserve:

```text
canonical/local ID used as exporter-private input
!=
portable_id is canonical/local ID
```

For `TransactionSource`, Phase 1B semantic UUID comparison remains authoritative when deciding whether source identity itself is internally ambiguous. Portable v1 does not weaken that rule.

## 12.3 Duplicate internal identity inputs

Before deterministic document-local allocation, the exporter must not silently treat two distinct same-entity canonical records with the same exporter identity input as one record.

Where current identity evidence establishes an ambiguity/conflict, export must diagnose it rather than merge records by ID or content.

The exact complete-export consequence for a newly discovered non-Source native-ID conflict is an implementation/admission detail only if such a state is demonstrated; this proposal does not manufacture historical fixtures.

## 12.4 No mutable business fields in generation

Merchant, amount, Category name, dates, type, status, and other mutable business values must not be embedded in or used as the semantic basis of `portable_id`.

---

# 13. Proposed Grammar

Grammar follows the semantic model rather than defining it.

Portable JSON v1 proposes the document-local lexical form:

```text
p1-<12 decimal digits>
```

Examples:

```text
p1-000000000001
p1-000000000002
p1-000000000003
```

Normative properties:

- ASCII only;
- lowercase literal prefix `p1-`;
- exactly 12 ASCII decimal digits;
- no whitespace;
- no Unicode normalization issue;
- no embedded entity name, merchant, date, amount, currency, Category name, or native ID;
- comparison is exact byte/code-point equality;
- no case folding;
- no numeric normalization;
- `p1-1` is not equivalent to `p1-000000000001`.

The prefix identifies the Portable-ID grammar generation, not the entity type.

The 12-digit space is intentionally much larger than any realistic v1 document and allows deterministic validation without exposing UUID/native-ID spelling.

If a document would require more than 999,999,999,999 Portable records, it is outside this grammar and cannot be represented as Portable JSON v1 without a future contract revision.

---

# 14. Deterministic Allocation Without Cross-Export Identity Promise

The exporter assigns handles deterministically **within the selected coherent snapshot**.

The proposed allocation concept is:

```text
selected coherent snapshot
        ↓
establish exporter-private deterministic record sequence
        ↓
assign global ordinals 1...N
        ↓
encode ordinal as p1-<12 digits>
        ↓
build same-document reference map
```

The allocator may use stable local canonical identity inputs to make the sequence reproducible for the same selected store state.

However:

> **The ordinal is not a durable identity promise.**

Adding/deleting/recreating records, restoring into another store, or any other change that affects the allocation sequence may change Portable IDs.

This gate deliberately does **not** freeze the final emitted JSON array ordering.

Identity allocation sequence and emitted array order are separable concerns.

The later deterministic-ordering gate may consume the now-defined document-local identity semantics, but it must not reinterpret the ordinal as cross-document identity.

---

# 15. Deterministic Ordering Implications

This proposal rejects the inference:

```text
deterministic ordering desired
→ portable_id must be globally permanent
```

What identity provides is narrower:

- every record in one document has one globally unique handle;
- references are unambiguous;
- an exporter can create a deterministic per-snapshot handle map.

The later ordering gate still must define:

- entity-array ordering;
- Transaction ordering;
- Tag-reference ordering if order is nonsemantic;
- tie-breaking;
- interaction with equivalent snapshots.

Because `exported_at` and document-local identity choices may differ across separate exports, Portable v1 round-trip does not promise byte-for-byte identical artifacts.

---

# 16. Deletion, Recreation, and Editing

## Editing

Ordinary mutation of merchant/name/amount/date/type/status or other business fields does not itself establish a new canonical object.

Because Portable IDs are document-local, Portable v1 does not need to promise that the edited object keeps the same handle in a later document.

## Deletion and recreation

A deleted object and a later newly created object are not inferred to be the same merely because their business fields match.

A later document may coincidentally reuse the same document-local `portable_id` spelling for an unrelated object.

That coincidence has no cross-document semantic meaning.

This is an intentional consequence of document-local identity.

---

# 17. Fresh-Store Re-export Stability

Portable v1 explicitly does **not** promise:

```text
Store A P1
→ fresh-store import
→ Store B re-export
→ P1
```

Instead:

```text
Store A P1
→ fresh-store import maps P1 to restored object B7
→ admitted relationships and semantics restored
→ later Store B export creates a new document-local identity map
→ handle may be P9
```

This is sufficient for the current Phase 1C ownership objective because supported-state equivalence is semantic, not portable-handle equality.

A future backup/synchronization format may choose a stronger identity lifetime.

That would be a separate contract.

---

# 18. Alternatives Considered

## Alternative 1 — expose native model IDs directly

Rejected.

Although current models have `id: String`, direct exposure would turn an internal durable identifier into public API without an established need.

It would also inherit historical/non-UUID and duplicate-identity questions into the wire grammar.

## Alternative 2 — deterministic hash of native ID for same-store stability

Rejected for v1.

This hides the raw ID spelling but still creates a stable cross-artifact correlator and a same-store identity promise.

It also does not solve fresh-store re-export continuity unless the original identity input is preserved.

## Alternative 3 — preserve imported portable ID durably

Rejected for v1.

This would require new durable semantics, a mapping, or reuse of native IDs and would move Portable identity into the persisted data model.

That is not earned by the current ownership requirement.

## Alternative 4 — derive identity from financial/reference content

Rejected.

Mutable content is not object identity and distinct records may be content-identical.

## Alternative 5 — entity-scoped Portable namespaces

Not selected.

Typed reference fields make entity-scoped namespaces technically workable, but one global document namespace yields simpler validation and clearer wrong-type diagnostics with little cost.

---

# 19. Interaction with Phase 1B Source Identity

Phase 1B source identity is frozen and remains stronger inside its own domain.

Portable Source projection therefore has two separate concepts:

```text
Phase 1B TransactionSource semantic identity
→ governs retained evidence ownership/association on the local installation

Portable Source portable_id
→ governs references inside one Portable JSON document
```

The Portable Source record does not gain the retained evidence payload merely because it has a `portable_id`.

The local `stored_file_uri` remains nonportable installation-local state.

This proposal does not alter locator grammar, evidence identity, commitment markers, availability, reconciliation, retention, or deletion rules.

---

# 20. Exact Proposed Contract Language

> **Portable JSON v1 `portable_id` is an opaque, document-local relationship identifier. Its semantic scope is one Portable JSON document. Equality of `portable_id` values across separate documents does not establish that the records are the same canonical object.**

> **All Portable records in one document share one global `portable_id` namespace. A `portable_id` must identify exactly one record across the Transaction, Category, PaymentMethod, Tag, and Source collections. Duplicate ownership is an invalid-document identity conflict.**

> **The v1 lexical grammar is `p1-` followed by exactly twelve ASCII decimal digits. Comparison is exact. Portable IDs contain no mutable business information and do not expose native model-ID spelling.**

> **The exporter owns document-local ID assignment for one coherent snapshot. Native/canonical IDs may be used as exporter-private deterministic allocation inputs, but this does not make them public Portable identities or import mutation authority.**

> **A Portable reference is valid only when its non-null `portable_id` resolves to exactly one record of the required target entity type in the same document. Null means true absence where the field admits absence. A non-null unresolved reference, duplicate identifier, or wrong-entity-type target is a distinct failure and must not silently degrade to null or semantic-name matching.**

> **`portable_id` grants relationship-resolution authority only. It does not grant overwrite, update, delete, synchronization, duplicate-deduplication, promotion-replay, or persistence-identity authority.**

> **Portable v1 does not promise same-store cross-export ID stability or fresh-store re-export ID stability. Supported round-trip equivalence requires restoration of admitted canonical semantics and relationships, not preservation of document-local Portable handles.**

> **Same financial/reference content does not establish same Portable identity. Portable IDs must not be derived semantically from merchant, amount, dates, type, status, Category name, or other mutable business fields.**

---

# 21. Unresolved Dependencies

This proposal intentionally leaves open:

- final emitted JSON array ordering;
- exact per-entity array sort keys;
- exact importer conflict/match UX for an already-populated receiving store;
- general duplicate matching;
- synchronization;
- merge/update semantics;
- backup identity;
- cloud/account identity;
- promotion receipts/replay implementation;
- exact non-Transaction record schemas;
- lifecycle timestamp semantics;
- date/timestamp spelling;
- decimal serializer spelling;
- unknown-field/parser evolution;
- CSV identity semantics;
- whether a future stronger portability/backup version introduces durable portable identity.

The later deterministic-ordering gate may use the identity model but must not silently expand its lifetime.

---

# 22. Review Questions

Independent review should decide whether:

1. document-local identity is sufficient for Portable JSON v1 ownership and relationship reconstruction;
2. same-store cross-export stability is intentionally **not** promised;
3. fresh-store re-export stability is intentionally **not** promised;
4. one global namespace per document is preferable to entity-scoped namespaces;
5. exact null / unresolved / duplicate / wrong-type distinctions are sufficient;
6. exporter-private use of native IDs is acceptably separated from public Portable identity;
7. the `p1-<12 digits>` grammar is appropriately opaque/versionable;
8. deterministic per-snapshot allocation can remain separate from the later emitted-array-ordering gate;
9. the explicit non-authority list is complete enough for v1;
10. Phase 1B TransactionSource identity remains correctly isolated from Portable Source relationship identity.

Until independent review passes, these identity semantics remain **PROPOSED FOR REVIEW**.
