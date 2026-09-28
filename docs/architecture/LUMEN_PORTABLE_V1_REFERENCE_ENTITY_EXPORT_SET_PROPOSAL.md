# Lumen Portable v1 Category / PaymentMethod / Tag Complete-Export Set Semantics

## Status

**PROPOSED FOR REVIEW — Phase 1C ownership/export-set proposal.**

This document proposes only which durable `Category`, `PaymentMethod`, and `Tag` records belong in a **complete Portable JSON v1 ownership snapshot**.

It does **not** accept the full Portable JSON / CSV v1 contract and does not authorize production implementation.

Starting proposal-development baseline:

`67620ddc5773745db3dfed24d80a50aed4a60a16`

Branch:

`docs/phase1c-portable-v1-reference-entity-export-set-proposal`

---

# 1. Decision question

For a complete Portable JSON ownership snapshot:

> **What exact set of durable Category, PaymentMethod, and Tag records belongs in the exported reference-data set independent of current Transaction reachability, how should seeded/default-like versus user-created state be treated where durable creation provenance is incomplete, and what exclusions—if any—are justified by Lumen's ownership contract rather than implementation convenience?**

This gate answers **record-set membership**.

It does not yet answer:

 - exact Category field schema;
- exact PaymentMethod field schema;
- exact Tag field schema;
- `created_at` inclusion/restoration semantics;
- exact lifecycle-timestamp spelling;
- importer conflict matching;
- overwrite/update authority;
- portable-ID allocation algorithm;
- emitted array ordering;
- `TransactionSource` export-set semantics;
- Source/provenance fields;
- schema or migration changes;
- production exporter/importer implementation.

---

# 2. Governing sources

This proposal is subordinate to:

1. `LUMEN_ARCHITECTURE_CONTRACT_V1.md`;
2. `PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`;
3. accepted Phase 1C Portable component contracts;
4. `LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`.

The Phase 1C responsibility contract defines Portable JSON as:

 > the normative, highest-fidelity portable representation of the durable state explicitly admitted to the current portability contract.

It also requires:

- included entities/fields to be documented;
- supported fields/entities to have defined round-trip guarantees;
- relationships within an export to remain resolvable;
- semantic similarity not to silently establish reference identity;
- coherent durable state to be exported.

The accepted Portable identity contract separately establishes:

```text
same display/content semantics
!!=
same portable identity

portable_id
!=
overwrite / update / deduplication authority
```

Those boundaries control this proposal.

---

# 3. First-principles statement

The irreducible ownership question is not:

> Which reference records happen to be reachable from a Transaction?

It is:

> Which durable reference records has Lumen admitted as part of the user's portable reference-data state?

A reachability graph can answer:

> Which Category / PaymentMethod / Tag is required to decode this Transaction?

It cannot by itself answer:

 ~ Which durable reference data belongs to a complete ownership snapshot? ~

Those are different responsibilities.

Preserve:

```text
relationship closure
!=
complete ownership scope
```

and:

```text
durable
!=
user-created
!0=
seeded/default-like
!=
referenced
!=
portable
```

The portability contract must decide the final predicate explicitly.

---

# 4. Repository evidence

## 4.1 Current durable models

Current SwiftData models define three ordinary reference families.

### Category

Current durable fields include:

- `id`;
- `name`;
- `group`;
- `color`;
- `icon`;
- `is_default`;
- `created_at`.

The initializer defaults:

```text
id = UUID().uuidString
is_default = true
created_at = .now
```

Therefore:

```text
Category.is_default == true
!=
proof of bootstrap provenance
```

The field may express a current product classification, but the initializer itself does not establish a seed-origin certificate.

### PaymentMethod

Current durable fields include:

- `id`;
- `name`;
- `method_type`;
- `institution_name`;
- `last_four`;
- `notes`;
- `is_active`;
- `created_at`.

The model has **no durable seed/user-origin field*.

### Tag

Current durable fields include:

- `id`;
- `name`;
- `color`;
- `created_at`.

The model has **no durable seed/user-origin field*.

Tags have an inverse relationship to Transactions, but a Tag can exist durably with zero Transactions.

## 4.2 Bootstrap behavior

`Seed.bootstrapIfNeeded()` independently checks whether each family is empty:

```text
Category count == 0
→
seed Categories

PaymentMethod count == 0
→
*seed PaymentMethods

Tag count == 0
→
seed Tags
```

The families are checked independently.

Current seed content includes approximately:

- 23 Categories;
- 7 PaymentMethods;
- 4 Tags.

The seed constructors use ordinary model initializers with installation-local UUID defaults.

Therefore two installations can independently produce:

```text
Store A
Tag("recurring")
id = UUID-A
Store B
Tag("recurring")
id = UID-B
```

The same is true for Categories and PaymentMethods.

Preserve:

```text
same seed name
!=
same object identity
```

## 4.3 Bootstrap happens during normal ledger open

`LumenFinanceApp.openLedger()` performs:

```text
LedgerStore.open()
        Ↄ
Seed.bootstrapIfNeeded(mainContext)
        Ↄ
application container becomes available
```

So a fresh ordinary installation is normally populated with reference defaults before ordinary user work.

A receiving installation may therefore already contain independently created, semantically similar reference records before a future Portable restoration workflow begins.

This is a downstream restoration/conflict fact.

It does **not** change what an exported object's identity means.

## 4.4 Zero-reference durable records are demonstrated current state

Reference seeding occurs even when there are zero Transactions.

gLedgerPersistenceTests.testSeedIdempotencyAndFailureRetryWithoutSamples()` verifies successful bootstrap while Transaction count remains zero.

The same test establishes:

- bootstrap is idempotent after successful seed;
- PaymentMethod count becomes 7;
- Tag count becomes 4;
- no sample Transactions are created.

Therefore:

 > **A durable Category / PaymentMethod / Tag with zero Transaction references is normal current Lumen state, not merely a hypothetical compatibility case.**

Transaction deletion tests also demonstrate that deleting a Transaction does not imply deleting the durable Tag familiy.

## 4.5 Current Transaction workflows consume reference records

Manual Entry, Review, and Transaction Detail query Categories, PaymentMethods, and Tags from SwiftData and attach them to Transaction drafts/records.

Current Transaction creation requires a Category.

PaymentMethod and Tags remain optional.

This establishes that reference records are durable reusable state independent of an individual Transaction.

## 4.6 Current production creation provenance is limited

No current ordinary reference-management surface was found in the inspected production paths for:

- creating a new Category;
- creating a new PaymentMethod;
- creating a new Tag;
- deleting these reference records;
- changing `PaymentMethod.is_active`.

The current app primarily consumes the bootstrap-created records.

Tests and model constructors demonstrate that custom model instances are structurally possible, and the Phase 1C responsibility contract explicitly allows future supported reference-entity creation after preview/confirmation.

Therefore classify evidence carefully:

```text
current production seeded durable records
→
demonstrated

zero-reference durable records
→
*demonstrated

custom/user-created records in ordinary current UI
➩
not demonstrated

edited seeded records in ordinary current UI
→
not demonstrated

inactive PaymentMethod in ordinary current UI
➩
not demonstrated

model-level ability to represent such states
→
demonstrated / structurally possible
```

This proposal must not fabricate present-day user-creation provenance merely because future Phase 1C workflows may admit it.

## 4.7 Empty-family behavior

A zero-count family is structurally possible in a store before bootstrap or after lower-level manipulation.

However normal app opening immediately calls `bootstrapIfNeeded()`, and an empty family is reseeded.

Therefore:

```text
durable family count == 0
```
is a meaningful format state that needs exact semantics, but it is not currently demonstrated as a stable ordinary post-bootstrap production condition.

The Portable contract should define the meaning of an empty array independently of whether current startup policy tends to repopulate that family.

---

# 5. Evidence taxonomy

## A. Demonstrated current durable production state

- seeded Categories;
- seeded PaymentMethods;
- seeded Tags;
- many zero-reference reference records;
- references from Transactions to some subset of those records;
- installation-local UUID identity;
- bootstrap when a family count is zero.

## B. Demonstrated durable/test state or structurally representable state

- custom Category/Tag objects created in tests;
- mutable Category / PaymentMethod / Tag fields;
- inactive PaymentMethod representation;
- duplicate/similar display names absent uniqueness constraints;
- zero-count family before bootstrap.

## C. Future-admitted responsibility but not current ordinary-production behavior



- supported reference-entity creation during future Portable/import preview and confirmation;
- explicit user-facing reference-data management if separately admitted;
- reference conflict resolution against an already-populated receiving store.

## D. Provenance current persistence does not reliably retain

Across all three families, current persistence does not provide a uniform durable fact establishing whether a record originated from bootstrap or explicit user creation.

Category has is_default, but that field defaults to true for ordinary construction and therefore cannot be treated as origin proof.

PaymentMethod and Tag have no equivalent origin marker.

---

# 6. Axes that must remain separate

The proposal uses five independent axes:

| Axis | Question |
| --- | --- |
| DURABLE | Does the record exist in the coherent persisted snapshot? |
| PORTABLE | Does the admitted ownership contract include it? |
| USER-CREATED | Did an explicit user-authorized creation event originate it? |
| DEFAULT / SEEDED-LIKE | Does current product state describe or resemble it as a built-in/default record? |
| REFERENCED | Does any current Transaction point to it? |

No axis automatically establishes another.

Examples:

    durable + unreferenced
    !=
    non-portable

    same name as a seed
    !=
    seed provenance

    is_default == true
    !=
    bootstrap provenance

    referenced
    !=
    user-created

    not referenced
    !=
    safe to omit

---

# 7. Required counterexamples

## 7.1 Unused durable record

Consider a durable Tag named Trip 2026 that is referenced by zero Transactions.

A complete ownership export must decide whether the Tag itself is owned state.

Transaction reachability does not answer that question.

## 7.2 Current seeded zero-reference record

Fresh bootstrap creates durable reference records before any Transaction exists.

If the exporter includes only reachable records, a complete export of this valid current store can omit every Category, PaymentMethod, and Tag even though those objects exist durably.

That would make complete ownership depend on incidental current Transaction graph shape.

## 7.3 Seeded-looking record later edited

Suppose a record originally created by bootstrap is later edited under an admitted management workflow.

Current persistence may not retain enough uniform provenance to answer whether it is still a default, a customized default, or user-owned custom state.

Export-set membership must not require unavailable provenance.

## 7.4 Inactive PaymentMethod

A PaymentMethod with is_active false can still be durable reference state.

Inactive is not equivalent to deleted.

Therefore:

    inactive
    !=
    safe to omit

## 7.5 Duplicate or similar display names

Two distinct records may legitimately have the same or similar visible names.

Name equality does not collapse their identity.

## 7.6 Fresh installation independently bootstraps a similar record

A Store A export may contain a Tag named recurring.

Store B may independently bootstrap its own Tag named recurring before restoration.

Equal names do not establish that the records are the same identity.

The export-set rule must not omit Store A's record merely because the destination is expected to recreate a semantically similar one.

Matching and merge authority remain a later gate.

## 7.7 Empty owned family

If an admitted complete artifact contains an empty tags array, the artifact must not leave ambiguous whether the admitted owned Tag set is actually empty or whether durable Tags existed but the exporter filtered them out.

For complete ownership semantics, those are materially different claims.

## 7.8 Referenced target

If a Transaction contains a non-null Category, PaymentMethod, or Tag reference, the target must not disappear merely because an export filter classifies it as default-like or otherwise uninteresting.

Existing Portable identity/reference rules already distinguish missing target from absence.

---

# 8. Alternatives considered

## Alternative A — Export only records reachable from Transactions

Rule:

A reference entity is exported only when at least one exported Transaction references it.

Advantages:

- smaller artifacts;
- natural relationship closure;
- simple graph traversal.

Problems:

- excludes demonstrated zero-reference durable records;
- makes ownership depend on incidental current Transaction graph shape;
- deleting the last referencing Transaction can make a still-durable reference record disappear from the next complete export;
- makes empty arrays ambiguous between an empty owned set and nothing currently reachable;
- loses future user-created reference state that is temporarily unused.

Disposition:

REJECT.

Reachability is sufficient for relationship closure, not for complete ownership scope.

## Alternative B — Export user-created records plus any referenced defaults

Rule:

Export user-created records, plus default or seeded records only when referenced.

Advantages:

- avoids exporting untouched application defaults;
- appears closer to user-authored data only.

Problems:

- current persistence does not provide a uniform durable user-created or seed-origin predicate;
- PaymentMethod and Tag have no origin field;
- Category.is_default is not provenance proof;
- edited default-like records become ambiguous;
- same-name reconstruction on another installation does not establish object identity;
- the exporter would need to infer authority it does not possess.

Disposition:

REJECT under current evidence.

This rule requires provenance the durable model does not reliably own.

## Alternative C — Export all durable admitted reference records in the coherent snapshot

Rule:

For Category, PaymentMethod, and Tag, every durably persisted record in the selected coherent export snapshot belongs to the complete Portable JSON reference set.

Membership is independent of:

- Transaction reachability;
- apparent seed/default-like status;
- Category.is_default;
- PaymentMethod.is_active;
- display-name similarity;
- recoverable creation provenance.

Advantages:

- exact and classifiable from durable state;
- preserves zero-reference records;
- preserves edited or default-like state without guessing origin;
- gives empty arrays an unambiguous set meaning;
- does not depend on receiving-store bootstrap behavior;
- composes cleanly with document-local identity;
- does not create merge or overwrite authority.

Cost:

- complete artifacts may include built-in/default-like records the user never explicitly created;
- later restoration must handle receiving stores that already contain semantically similar bootstrap records;
- exact field schemas must still decide whether each included record is representable.

Disposition:

RECOMMENDED.

This is the minimum sufficient ownership rule that does not require unavailable provenance or collapse durable state into reachability.

## Alternative D — Stable global default registry plus only non-default durable records

Rule:

Define stable built-in reference identities, omit or reconstruct known built-ins, and export only records outside that global set.

Advantages:

- potentially smaller artifacts;
- could make built-ins versionable independently.

Problems:

- current seed records use installation-local UUIDs;
- no admitted cross-installation built-in identity registry exists;
- current persistence does not reliably distinguish modified seed instances from semantically similar custom records;
- this would create a new public identity/versioning subsystem not required by current ownership needs.

Disposition:

DO NOT ADMIT IN THIS GATE.

A future stable default-reference registry would require independent product value and authority.

---

# 9. Recommended proposed disposition

For complete Portable JSON v1 ownership export:

> The Category, PaymentMethod, and Tag export sets contain every durably persisted record of the corresponding admitted entity family in the selected coherent export snapshot, independent of Transaction reachability, active/default-like state, display-name similarity, or recoverable creation provenance.

Consequently:

    durable Category
    -> member of categories[]

    durable PaymentMethod
    -> member of payment_methods[]

    durable Tag
    -> member of tags[]

for complete Portable JSON ownership export.

No filter based on currently referenced, looks seeded, is_default, is_active, name equality, or presumed recreation on a fresh installation may silently remove an otherwise durable record from the complete owned set.

This is an export-set membership rule.

It does not yet establish that every durable record can successfully serialize under the eventual exact entity schema.

If a durable in-scope reference record cannot later be represented under the accepted entity schema, that becomes an explicit compatibility/disposition problem.

It does not become permission to omit the record while still claiming a complete ownership export.

---

# 10. Empty-set semantics

For a complete Portable JSON v1 ownership artifact:

- categories: [] means the admitted durable Category set in the selected coherent snapshot is empty;
- payment_methods: [] means the admitted durable PaymentMethod set is empty;
- tags: [] means the admitted durable Tag set is empty.

An empty array does not mean:

- the exporter chose not to include unreferenced records;
- default-like records were filtered;
- the destination is expected to recreate omitted records;
- the family is unsupported.

Current startup bootstrap behavior may make an empty post-bootstrap family uncommon.

That implementation behavior does not change the public meaning of an empty exported set.

---

# 11. Relationship closure and reference integrity

Because the recommended set includes all durable records, every normally durable Transaction reference target should naturally be present in the corresponding exported family.

Preserve the already accepted reference distinction:

    null reference
    -> no relationship exists

    non-null reference + exported target
    -> resolvable relationship

    non-null reference + missing target
    -> reference or dataset incompatibility

A missing non-null target must never silently degrade to null.

If a canonical Transaction points to a reference target that cannot participate in the exported set or cannot be represented under a later accepted entity schema, the exporter must report the incompatibility rather than silently omitting the target or rewriting the Transaction reference.

The exact diagnostic and complete-export failure or compatibility disposition for future nonrepresentable reference entities remains downstream of exact schema admission.

---

# 12. Bootstrap and restoration boundary

This proposal deliberately does not define how a receiving installation resolves:

portable Tag recurring plus local bootstrap Tag recurring.

Accepted Portable identity semantics already establish:

    same name or semantic similarity
    !=
    same identity

Therefore a receiving bootstrap record does not grant automatic:

- merge authority;
- overwrite authority;
- deduplication authority;
- replacement authority.

A later reference-restoration/conflict contract must decide whether the receiving store creates a separate record, proposes a match, explicitly merges, or uses another admitted strategy.

The export-set rule must remain truthful regardless of that later choice.

Preserve:

    export-set ownership
    !=
    import conflict resolution

---

# 13. Round-trip set-level consequence

The complete Portable JSON artifact claims ownership of the full admitted reference set.

Therefore a supported round trip must not silently lose a distinct exported reference record merely because it is unreferenced, resembles a seeded record, shares a display name, is inactive, or the receiving installation already contains a similar record.

Exact restoration mechanics remain separately gated.

At minimum, later restoration semantics must preserve the distinction among exported records unless a separately accepted merge or migration contract establishes a genuinely lossless equivalent under explicit authority.

Two distinct exported portable records remain two distinct artifact identities even when visible content is identical.

This does not require document-local Portable IDs to survive re-export.

---

# 14. JSON / CSV scope

This gate applies to complete Portable JSON v1 ownership export.

Lumen CSV v1 remains deliberately narrower.

CSV does not become a complete reference-data ownership representation merely because JSON admits full Category, PaymentMethod, and Tag sets.

The existing CSV projection may carry Category and PaymentMethod mapping text for Transaction rows while omitting Tags and full reference metadata.

This gate does not change that narrower CSV contract.

---

# 15. TransactionSource exclusion

TransactionSource is intentionally outside this proposal.

It carries materially different responsibilities:

- origin semantics;
- Phase 1B evidence identity;
- retained-evidence lifecycle implications;
- provenance;
- processing metadata;
- machine-local locator concerns;
- privacy;
- source availability semantics.

Phase 1B also permits committed source/evidence state to outlive the final current Transaction association.

Therefore:

    Category / PaymentMethod / Tag
    -> ordinary reference-data ownership gate

    TransactionSource
    -> dedicated Source/provenance/evidence portability gate

No Source export-set rule is created by this proposal.

---

# 16. Reasoning Framework Check

## First Principles

User/product capability:

A complete Portable JSON ownership export must truthfully say which admitted durable reference records the user can take with them.

Established facts:

- the three reference families are durably persisted;
- current app bootstrap creates many unreferenced records;
- bootstrap identities are installation-local;
- durable creation provenance is incomplete and nonuniform;
- semantic similarity does not establish Portable identity.

Assumptions rejected:

- every durable reference record is user-created;
- every default-like record is safely reconstructible elsewhere;
- reachability defines ownership;
- is_default proves seed origin;
- same display name means same identity.

Minimum sufficient contract:

Use directly observable durable family membership as complete-export set membership.

Do not require an additional provenance registry or reachability filter.

## Assembly Map

Prerequisite assemblies:

- Phase 1C ownership responsibility contract;
- coherent export snapshot requirement;
- accepted document-local Portable identity;
- accepted null-vs-unresolved Category reference distinction.

New subassembly:

Complete-reference-set membership semantics for Category, PaymentMethod, and Tag.

Known consumers:

- exact reference-entity schemas;
- future JSON exporter;
- reference restoration/conflict semantics;
- deterministic ID allocation;
- entity-array ordering;
- complete-export diagnostics;
- full-format acceptance.

Unresolved dependencies:

None block deciding set membership itself.

Later exact schemas may reveal representability incompatibilities.

Irreversible commitments:

Public meaning of a complete ownership export and the meaning of empty reference arrays.

## Authority Budget

New normative authority introduced:

A complete Portable JSON exporter may claim that its Category, PaymentMethod, and Tag arrays represent the complete admitted durable sets only when it includes every durable record in those families from the coherent selected snapshot.

Governing basis:

Phase 1C ownership/portability responsibility plus later independent review/admission of this proposal.

Evidence establishing preconditions:

Current models, bootstrap behavior, persistence tests, Transaction/reference consumption, and accepted identity semantics.

Authorities explicitly not granted:

- infer seed/user origin;
- merge same-name records;
- overwrite receiving records;
- deduplicate;
- delete local receiving records;
- choose exact entity fields;
- alter bootstrap behavior;
- migrate schema.

Transitive-authority check:

Bootstrap knowledge does not transfer identity or merge authority to the importer.

## Assembly Pressure

This proposal does not generalize all durable model families into one universal export rule.

TransactionSource is a counterexample with different evidence/provenance responsibilities.

## Counterexamples

The proposal explicitly survives:

- zero-reference durable state;
- same-name different-identity records;
- independent fresh-install bootstrap;
- default-like edited state;
- inactive PaymentMethod;
- empty family;
- duplicate display names.

## Assembly Debt

No unresolved lower-level contract prevents deciding the set boundary.

Exact field schemas, lifecycle timestamps, import conflict resolution, and deterministic ordering remain later consumers rather than prerequisites.

## Irreversible commitments

The strongest commitment is:

    complete Portable JSON ownership
    includes all durable admitted records
    in these three reference families

That makes silent omission incompatible with a complete export.

The commitment is justified because any narrower rule would require either provenance Lumen does not durably possess or reachability as an ownership authority it has not earned.

---

# 17. Exact proposed contract language

The following language is PROPOSED FOR REVIEW, not accepted:

> Category / PaymentMethod / Tag complete-export set. For a complete Portable JSON v1 ownership export, the categories, payment_methods, and tags arrays represent the complete durable sets of the corresponding admitted reference-entity families in the selected coherent export snapshot. Every durably persisted Category, PaymentMethod, and Tag in that snapshot belongs to its corresponding export set independent of Transaction reachability, active/default-like state, display-name similarity, or recoverable creation provenance.
>
> A record must not be silently excluded merely because it is unreferenced, appears seeded/default-like, has Category.is_default true, has PaymentMethod.is_active false, shares a name with another record, or is expected to be recreated by bootstrap on another installation.
>
> The export-set rule does not infer whether a record was user-created or bootstrap-created. Current durable state does not provide a uniform authoritative provenance predicate for that distinction across the three entity families.
>
> For a complete Portable JSON artifact, an empty entity-family array means that the corresponding admitted durable set in the selected coherent snapshot is empty. It does not mean that durable records were filtered because they were unreferenced/default-like or expected to be recreated elsewhere.
>
> Same-name or semantically similar records remain distinct unless a separately accepted import/conflict contract establishes merge authority. Current bootstrap behavior does not create cross-installation identity.
>
> This set-membership rule does not finalize exact entity fields, lifecycle timestamps, import conflict matching, ID allocation, array ordering, or restoration implementation. If a later accepted entity schema cannot represent an in-scope durable reference record, that incompatibility must receive an explicit disposition and must not become silent omission from a claimed complete ownership export.

---

# 18. Remaining dependencies

Still open after this proposal:

1. exact Category record schema;
2. exact PaymentMethod record schema;
3. exact Tag record schema;
4. ordinary reference-record lifecycle timestamp disposition;
5. supported restoration/conflict semantics against existing local/bootstrap records;
6. exact compatibility disposition if an in-scope durable reference record cannot satisfy an accepted schema;
7. deterministic Portable-ID allocation;
8. entity-array ordering;
9. unknown-field/evolution behavior;
10. Source/provenance export-set and field semantics;
11. full Portable JSON / CSV v1 acceptance.

---

# 19. Explicit non-goals

This proposal does not:

- redesign reference models;
- add seed provenance;
- create stable global default IDs;
- create a built-in reference registry;
- make Category.is_default a provenance field;
- change bootstrap behavior;
- delete receiving bootstrap data;
- define import conflict UX;
- add reference-management UI;
- change SwiftData schema;
- add migrations;
- implement export/import;
- change TransactionSource;
- define lifecycle timestamps;
- define deterministic ordering.

---

# 20. Review questions

Independent review should answer:

1. Is complete durable-family membership the correct ownership boundary for Category, PaymentMethod, and Tag?
2. Is Transaction reachability correctly rejected as the complete-export boundary?
3. Is current durable provenance too weak to support a custom-only or omit-defaults rule?
4. Does Category.is_default correctly remain a product field rather than provenance authority?
5. Is an inactive PaymentMethod correctly still included when durably present?
6. Is empty-array truthfulness sufficiently explicit?
7. Does the proposal correctly preserve same-name does-not-equal same-identity?
8. Is bootstrap/restoration conflict correctly deferred rather than silently solved?
9. Does excluding TransactionSource keep the gate appropriately narrow?
10. Does the proposal avoid deciding exact entity schemas, timestamps, and ordering prematurely?

---

# 21. Review boundary

This proposal remains PROPOSED FOR REVIEW.

Do not record acceptance from this branch without independent review.

Do not open the lifecycle-timestamp, exact entity-schema, Source/provenance, deterministic-ordering, or another Phase 1C gate from this proposal checkpoint without separate authorization.
