# Lumen Portable JSON v1 Categoryless Canonical Transaction Compatibility Proposal

## Status

**ACCEPTED AT PROPOSED-CONTRACT LEVEL — Phase 1C categoryless-canonical-Transaction compatibility gate.**

Starts exactly from accepted status checkpoint `2173fb6873c7416b51838909e46f5d299c681609`.

This proposal does not modify production code, tests, SwiftData schema, migrations, importer/exporter implementation, `TransactionDraft`, Category management behavior, or previously accepted Portable v1 semantics.

It does not finalize Category portable identity, Category record schema, general reference reconstruction, CSV category semantics, or unsigned type/direction semantics.

# 1. Decision Question

When a currently canonical `Transaction` has no Category association, what does Portable JSON v1 promise at three distinct layers?

```text
1. REPRESENTABILITY
Can exact canonical absence of Category be represented?
            ↓
2. EXPORT COMPLETENESS
Can an ownership export containing that Transaction
remain complete and truthful?
            ↓
3. RESTORATION READINESS
Can a fresh-store supported Lumen round trip restore
equivalent canonical categoryless state while preserving
the Review/Confirm trust boundary?
```

The gate also distinguishes:

```text
canonical absence of association
!= unresolved portable reference
!= missing referenced Category record
!= parser failure
```

# 2. Current Canonical Model

`Transaction.category` is an optional SwiftData relationship:

```swift
@Relationship var category: Category?
```

The `Transaction` initializer likewise accepts:

```swift
category: Category? = nil
```

and assigns that value directly.

Therefore exact canonical `category == nil` is a state the current persisted model can represent without inventing a placeholder Category.

The relationship declaration does not specify an explicit delete rule or inverse in repository source.

# 3. Ordinary Creation and Confirmation

`TransactionDraft.category` defaults to `nil`.

Draft validity requires:

```swift
category != nil
```

and `TransactionDraft.canConfirm` depends on that validity.

`makeTransaction` therefore cannot create a new categoryless canonical Transaction through ordinary Draft → Review → Confirm.

`ReviewTransactionView` explicitly tells the user to choose a category when the draft cannot confirm.

The Phase 1C responsibility contract already freezes:

> a resolved Category association is required for ordinary canonical confirmation;

and:

> making Category optional in canonical creation is a separate product/domain change and is not authorized merely to make portability easier.

So:

```text
current canonical state
!=
currently creatable state
```

applies on this axis as well.

# 4. Existing-Record Behavior

`TransactionDraft(from:)` copies:

```swift
category = txn.category
```

An existing categoryless canonical Transaction therefore opens into an edit draft with `category == nil`.

However, because `isValid` requires a Category, ordinary edit-save cannot commit that draft until a Category is selected.

The Category picker provides existing Categories but no explicit "None" action. No current repository code path was found that clears an existing Transaction's Category relationship by setting it to `nil`.

At the same time, non-edit Detail behavior can inspect a categoryless record:

- Detail displays Category as `—`;
- row presentation falls back to the transaction-type icon/color/label;
- status controls operate directly on the canonical Transaction rather than requiring category-valid edit confirmation.

Thus an already-categoryless canonical Transaction is inspectable and can remain categoryless while other directly supported canonical operations occur.

# 5. Category Management / Deletion Evidence

Current seed/bootstrap code creates Category reference data but does not create a permanent `Uncategorized` Category.

Repository search found no production path that deletes a `Category` object and no production path assigning `transaction.category = nil`.

There is also no repository test demonstrating that deleting a Category nullifies `Transaction.category`.

Therefore this proposal does **not** claim that current app Category deletion is a demonstrated producer of categoryless canonical state.

The relationship is optional, so categoryless state is structurally permitted. But deletion-induced categorylessness remains **not demonstrated by current repository behavior** and is not required to justify this compatibility gate.

# 6. Demonstrated Persisted Current-Schema Categoryless State

A same-schema URL-backed SwiftData persistence test inserts one Transaction for every `TransactionStatus` case using the `Transaction` initializer without supplying a Category.

Because the initializer default is `category: nil`, those persisted Transactions are categoryless.

The test closes and reopens the store and verifies the full Transaction set survives.

This is direct repository evidence that current-schema `Transaction` objects with `category == nil` can be durably persisted and reopened.

Important evidence qualifier:

> The test itself explicitly says it is a same-schema round-trip and **not** an authentic baseline/historical migration fixture.

So the repository establishes durable current-schema capability and persisted test state. It does **not** establish that these fixture records became canonical through the governing user-authorized Draft → Review → Confirm boundary, nor that authentic historical/user stores contain categoryless canonical Transactions.

Several ordinary unit-test Transactions are also constructed without Categories for analytics/status behavior, but those in-memory fixtures are weaker evidence than the URL-backed persistence test.

# 7. Evidence Classification

## A. Demonstrated persisted current-schema categoryless Transaction state

**Yes.**

The URL-backed same-schema persistence test persists and reopens categoryless Transactions because Category is omitted from the initializer.

This proves current-schema durability for `category == nil`.

It does not prove that the fixture records were user-confirmed through the governing canonical-ingestion boundary, and it does not prove authentic historical user prevalence.

## B. Categoryless state directly producible by current app behavior

**No ordinary create/clear path demonstrated.**

Current ordinary confirmation rejects Category absence.

The existing edit picker has no "None" action.

No production Category deletion path or explicit relationship-clearing path was found.

However, the current app can inspect an already-categoryless record and preserve the absence while performing direct operations such as status changes.

## C. Technically permitted by persistence but not necessarily user-observed

**Yes.**

The persisted relationship and initializer are explicitly optional.

Code that constructs/inserts a `Transaction(category: nil)` can persist such state.

## D. Impossible under the current canonical model

Exact `category == nil` is **not** impossible; it is expressly representable.

A different concept—a non-null portable reference whose target Category is missing—is not the same canonical state and belongs to reference-integrity handling.

# 8. Derived and Observable Semantics of Category Absence

Category absence is not entirely cosmetic.

## 8.1 Analytics

`Analytics.categoryTotals` groups a nil Category under a derived key:

```text
uncategorized
```

and presents the group name:

```text
Uncategorized
```

with a fallback color.

`Analytics.groupTotals` treats categoryless expenses as if their derived group were `.custom`.

These are derived analytics conventions. They do **not** establish a canonical Category entity named `Uncategorized`.

## 8.2 Insights / Dashboard

Insights renders the category totals, so categoryless expense activity can appear under the derived `Uncategorized` bucket.

Dashboard top-category behavior consumes the same category totals; a categoryless spending group can therefore affect the displayed top-category result.

## 8.3 Transaction row and detail

A categoryless row displays the Transaction type label/icon/color instead of a Category label/icon/color.

Detail shows:

```text
Category: —
```

## 8.4 Search and filtering

Search text contains Category name only when one exists.

The Category filter menu enumerates actual Category records and has no synthetic `Uncategorized` Category option.

A selected concrete Category filter will not match a categoryless Transaction.

Therefore replacing nil with a real or synthetic Category would alter observable grouping/filter/display semantics.

# 9. Canonical Null vs Portable Reference Failure

Portable JSON must preserve three distinct states.

## 9.1 Canonical absence

```json
"category_ref": null
```

means:

> this canonical Transaction has no Category association.

It does not mean the importer failed to resolve a Category.

## 9.2 Present and resolvable reference

```json
"category_ref": "cat-123"
```

with the referenced admitted Category present/resolvable means:

> reconstruct this Category relationship.

## 9.3 Present but unresolved reference

```json
"category_ref": "cat-123"
```

when `cat-123` is unavailable, missing, ambiguous, unsupported, or otherwise unresolved means:

> reference/dataset incompatibility or unresolved relationship state.

It must **not** silently degrade to:

```json
"category_ref": null
```

because doing so would transform a broken association claim into a claim that no association existed canonically.

This proposal does not solve the general portable reference-resolution mechanism; it freezes only this semantic distinction for Category.

# 10. Representability Analysis

The existing candidate field:

```json
"category_ref": null
```

is sufficient to represent exact canonical Category absence.

No synthetic Category record is necessary.

No parser placeholder is necessary.

No Category ID is necessary because the canonical relationship is absent.

Therefore categoryless canonical state is **representable** by Portable JSON v1.

# 11. Complete Ownership Export Analysis

Because exact canonical absence is representable, a categoryless Transaction can participate truthfully in a complete Portable JSON v1 ownership export.

The proposed export rule is:

```text
canonical Transaction.category == nil
        ↓
"category_ref": null
        ↓
truthful complete-export representation
```

The exporter must not:

- omit the Transaction because Category is nil;
- invent a Category reference;
- create a synthetic `Uncategorized` Category;
- select a default Category;
- convert an unresolved non-null Category reference into null.

Therefore the presence of `category_ref: null` does **not by itself** make a complete ownership export incomplete.

# 12. Restoration-Readiness Analysis

The tension appears at restoration, not representation.

Current ordinary creation semantics say:

```text
category == nil
→ draft invalid
→ cannot confirm
```

But current canonical persistence can hold and reopen exact `category == nil`.

The accepted status gate established a narrower precedent:

```text
restoration authority != creation authority
```

This proposal independently tests that principle here.

## 12.1 What exact equivalence requires

Category absence has observable consequences in analytics, display, filtering, and edit readiness.

No repository evidence establishes that assigning any concrete Category is semantically equivalent to nil.

Therefore proposed category-axis round-trip equivalence is:

```text
original canonical category == nil
→ restored canonical category == nil
```

for a supported exact categoryless restoration.

## 12.2 Ordinary confirmation is not sufficient

Ordinary `TransactionDraft.canConfirm` cannot produce that state.

Requiring the user to select a Category before promotion would turn a truthful exported absence into different canonical state.

That could be a valid generic-import resolution rule, but it would not be exact supported-Lumen round-trip restoration.

## 12.3 Proposed compatibility restoration

The recommended disposition is:

> **Portable JSON v1 admits exact canonical Category absence and supported Lumen round-trip restoration may reproduce `category == nil` under specifically admitted restoration authority inside meaningful Review/Confirm.**

As with status compatibility:

```text
restoring previously canonical category == nil
!=
allowing ordinary new Transactions to omit Category
```

The restoration context must be identifiable as restoration of previously canonical Lumen state from a supported Lumen round-trip representation.

It must not make Category optional for:

- manual creation;
- foreign structured imports;
- generic structured import;
- OCR/extraction proposals;
- ordinary new Lumen Transactions;
- other non-restoration ingestion.

Review/Confirm must remain meaningful user authority. Restoration-specific permission to reproduce nil must not become a hidden generic bypass around Category readiness.

This proposal does not define UI, add a restoration flag, change `TransactionDraft`, or specify importer mechanics.

# 13. Alternatives Considered

## Alternative A — Exact categoryless compatibility restoration

```text
category_ref: null
→ recognized supported-Lumen restoration context
→ Review / explicit confirmation
→ canonical category == nil
```

**Recommended.**

Strengths:

- exact ownership round trip;
- no invented classification;
- preserves current observable nil semantics;
- keeps ordinary creation requirements intact;
- aligns with canonical storage capability.

Cost:

- requires a restoration-specific authority/capability distinct from ordinary draft confirmation.

## Alternative B — Require Category resolution before promotion

```text
category_ref: null
→ NEEDS RESOLUTION
→ choose Category
→ canonical categorized Transaction
```

This is appropriate for ordinary/generic ingestion when required canonical meaning is absent.

It is **not recommended as the supported-Lumen round-trip rule**, because it changes previously canonical state and fails exact category-axis equivalence.

## Alternative C — Represent/export categoryless state but permanently exclude it from supported round trip

Not recommended.

It preserves ownership visibility but unnecessarily abandons restoration of a state the current canonical model can already persist.

## Alternative D — Map nil to default/first/synthetic Uncategorized Category

Rejected.

The repository contains no canonical `Uncategorized` entity, and current `Uncategorized` behavior is derived analytics presentation.

Such mapping would invent durable classification and alter semantics.

## Alternative E — Treat null as unresolved reference

Rejected.

Canonical absence and failed reference resolution carry different ownership claims.

# 14. Recommended Narrow Portable JSON v1 Disposition

Portable JSON v1 should define:

```text
category_ref == null
→ exact canonical absence of Category association
→ valid representable Transaction state
→ compatible with complete ownership export
```

For supported Lumen round-trip restoration:

```text
category_ref == null
→ recognized as restoration of previously canonical categoryless state
→ explicit Review / Confirm authority
→ exact canonical category == nil
```

This is restoration-only compatibility authority.

It does not loosen Category requirements for ordinary creation or non-restoration ingestion.

A non-null unresolved `category_ref` remains a separate reference-integrity problem and must never be normalized to null.

# 15. Exact Proposed Contract Language

> **Portable JSON v1 defines `"category_ref": null` as exact canonical absence of a Category association on the Transaction. It does not mean an unknown Category, unresolved Category, missing referenced Category record, parser failure, or request to choose a Category.**

> **A non-null `category_ref` whose referenced Category cannot be resolved must remain a distinct reference-integrity or resolution failure and must not silently degrade to `null`.**

> **A canonical Transaction with `category == nil` is representable in Portable JSON v1 and may participate in a complete ownership export without inventing, substituting, or defaulting Category state. Its presence does not by itself make the complete ownership export incomplete.**

> **For exact category-axis round-trip equivalence, a supported Lumen restoration of a Transaction exported with `category_ref: null` must restore `category == nil` unless a future independently accepted migration contract establishes a genuinely equivalent alternative.**

> **Current ordinary creation continues to require a resolved Category. Supported restoration of previously canonical categoryless state requires distinct restoration authority inside meaningful Review/Confirm. Restoration authority does not imply creation authority.**

> **Categoryless restoration authority must be identifiable as restoration from a supported Lumen round-trip representation and must not make Category optional for manual creation, foreign-source mapping, generic structured import, OCR/extraction proposals, ordinary new Lumen Transactions, or other non-restoration ingestion.**

> **Derived presentation such as the analytics label `Uncategorized`, fallback transaction-type labels/icons, or a custom analytics grouping does not create or imply a canonical Category entity.**

> **This gate does not define Category portable identity, finalize Category record schema, solve general reference reconstruction, change Category management, or authorize schema/model/importer changes.**

# 16. CSV Scope

This proposal decides the normative Portable JSON v1 categoryless compatibility contract.

Lumen CSV v1 has separate narrower Category columns and already permits blank compatibility-state Category cells. Exact CSV categoryless round-trip semantics remain separately gated.

CSV must not silently turn unresolved Category reference semantics into canonical absence merely because CSV lacks JSON reference structure.

# 17. Unresolved Dependencies

This proposal does not resolve:

- Category portable identity grammar/stability;
- exact Category portable record fields;
- general reference reconstruction;
- how a non-null unresolved Category reference is surfaced/resolved;
- CSV categoryless round-trip semantics;
- unsigned type/direction;
- exact importer implementation;
- restoration-context implementation;
- Category deletion/product management behavior;
- whether authentic historical user stores contain categoryless Transactions;
- migrations that could later make Category nonoptional or redesign classification.

Future validation of accepted compatibility restoration would need to prove:

```text
Portable JSON category_ref: null
→ fresh store
→ recognized supported-Lumen restoration context
→ Review / explicit confirmation
→ canonical category == nil
→ expected analytics/display/filter semantics
```

while proving the same nil state remains unavailable to ordinary new/manual/non-restoration ingestion.

# 18. Review Questions

Independent review should decide whether:

1. `category_ref: null` should mean only exact canonical absence;
2. non-null unresolved references must remain distinct and never degrade to null;
3. categoryless canonical state is compatible with a complete Portable JSON ownership export;
4. exact category-axis round trip requires `nil → nil`;
5. supported-Lumen restoration may use restoration-specific authority to reproduce nil;
6. restoration authority remains distinct from ordinary creation/non-restoration ingestion authority;
7. derived `Uncategorized` analytics behavior is correctly treated as presentation rather than a canonical entity;
8. Category deletion behavior is correctly left unclaimed because current repository evidence does not demonstrate it;
9. CSV and general reference machinery remain separately gated.

## Independent-review acceptance

Independent review accepted the categoryless compatibility disposition after the persistence-evidence wording was tightened.

Accepted at the proposed-contract level:

- `"category_ref": null` means exact canonical absence of a Category association;
- null does not mean unknown Category, missing/unresolved referenced Category, parser failure, or a request to choose a Category;
- a non-null unresolved Category reference remains a separate reference-integrity/resolution failure and must never silently degrade to null;
- exact Category absence is representable and does not by itself make a complete Portable JSON v1 ownership export incomplete;
- export must not omit the Transaction, invent/default a Category, synthesize an `Uncategorized` Category, or replace absence with another classification;
- exact Category-axis supported-round-trip equivalence is `nil → nil` absent a future independently accepted lossless migration;
- supported Lumen restoration may reproduce `category == nil` under restoration-specific authority inside meaningful Review/Confirm;
- restoration authority remains distinct from ordinary creation/non-restoration ingestion authority;
- derived `Uncategorized` analytics/presentation does not establish a canonical Category entity;
- CSV Category semantics, general reference reconstruction, Category identity/schema, and Category deletion behavior remain separately gated;
- the persistence fixture proves durable current-schema categoryless Transaction state, not authentic historical/user-confirmed canonical provenance.

No production implementation, schema migration, Category redesign, importer change, or type/direction decision is authorized by this acceptance.
