# Lumen Portable v1 Reference Restoration / Destination Matching / Conflict Semantics Proposal

## Status

**PROPOSED FOR REVIEW — docs-only Phase 1C ordinary reference restoration / destination matching / conflict gate.**

Starting accepted semantic checkpoint:

`3982d96d5dc11a6c924d2319e93c94361be50740`

Underlying composition-only current-main baseline:

`c7dd2ea639df6db0e98f942f5d906b522d28cf30`

Canonical `main` at gate opening:

`d4884e2180e2f867dee415a48375100097a8d415`

Branch:

`docs/phase1c-portable-v1-reference-restoration-conflict-semantics-proposal`

The accepted semantic checkpoint is the dependency base for this gate. The older composition baseline remains composition-only and creates no independent semantic authority.

This proposal does not reopen:

- the accepted complete-export owned set for Category / PaymentMethod / Tag;
- the accepted exact Category / PaymentMethod / Tag record schemas;
- accepted ordinary lifecycle-timestamp exclusion;
- accepted Portable document-local identity semantics;
- accepted reference-record complete-export compatibility disposition;
- Transaction status, categoryless, type/direction, money-compatibility, currency-registry, or financial-date component gates.

It does not decide:

- Source / TransactionSource portability or evidence/provenance semantics;
- unknown-input-field / schema-evolution policy;
- PortableMoney lexical/governance closure;
- exact financial-date lexical/year validity;
- timestamp lexical spelling;
- deterministic Portable-ID allocation or emitted ordering;
- workspace persistence mechanics;
- promotion-receipt / idempotency persistence;
- production implementation, migrations, tests, or UI.

---

# 1. Decision question

For one valid admitted Portable JSON v1 Category, PaymentMethod, or Tag record arriving at a receiving Lumen store:

> **What authority exists to reuse an existing destination reference object, create a distinct destination object, require user resolution, mutate/update an existing destination object, merge source and destination state, or declare a conflict while preserving Portable v1 round-trip meaning and same-document relationship closure?**

The gate must distinguish four operations that are easy to collapse accidentally:

```text
MATCH / REUSE
use one existing destination object as this imported
reference object's restoration target without mutating it

CREATE
create one new destination object carrying this imported
reference object's admitted v1 semantic state

UPDATE / OVERWRITE
mutate one existing destination object so its admitted
semantic state changes because of the imported record

MERGE
synthesize destination state from both source and
destination values
```

Those operations do not carry the same authority.

---

# 2. Accepted prerequisites

## 2.1 Owned source-record set

For complete Portable JSON v1 ownership export, every durably persisted:

- Category;
- PaymentMethod;
- Tag;

belongs to the corresponding source record set independent of Transaction reachability, default-like appearance, display-name similarity, active state, or inferred bootstrap provenance.

## 2.2 Exact accepted source schemas

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

The admitted string, token, boolean, null, and `last_four` semantics are already frozen at the proposed-contract level.

## 2.3 Portable identity

Accepted Portable identity establishes:

- `portable_id` is document-local;
- one document has one global Portable-ID namespace;
- same-document references resolve through `portable_id`;
- native SwiftData IDs are not public Portable identity;
- equal `portable_id` spelling across documents does not establish equal canonical identity;
- `portable_id` grants no overwrite, update, delete, deduplication, synchronization, or replay authority.

## 2.4 Reference-record export compatibility

An owned Category / PaymentMethod / Tag that cannot satisfy its accepted v1 schema blocks the complete-export success claim.

This gate therefore reasons only about a reference record that has already passed the accepted source-side v1 compatibility boundary.

## 2.5 Phase 1C restoration authority

The accepted Phase 1C responsibility contract already requires:

- reference entities use entity-appropriate preview / confirmation rather than artificial `TransactionDraft` objects;
- an established identity may match only when that identity can actually be proven under the admitted contract;
- name / semantic similarity may produce a proposal but does not silently establish identity;
- ambiguity requires explicit resolution or deliberate creation of a separate entity;
- transaction proposals must not silently bind to a semantically similar but unconfirmed reference entity;
- meaningful accepted reference mapping is durable import-workspace progress once implementation is separately admitted;
- equivalent repeated ambiguity should be resolved at the broadest valid scope.

This proposal narrows those higher-level rules into the ordinary Category / PaymentMethod / Tag v1 conflict matrix.

---

# 3. Current repository evidence

## 3.1 A normal fresh launch already has destination reference state

`LumenApp.openLedger()` currently performs:

```text
LedgerStore.open()
        ↓
Seed.bootstrapIfNeeded(opened.mainContext)
        ↓
container exposed to UI
```

So a normal fresh installation is not reliably an empty destination when Portable import begins.

For each family, `Seed.bootstrapIfNeeded()` checks whether the current family count is zero and, when it is, inserts that family's current defaults.

Therefore an ordinary fresh-store restoration can immediately encounter independently created destination records that look the same as source records.

## 3.2 Seeded records receive installation-local IDs

Current Category, PaymentMethod, and Tag initializers assign:

```text
id = UUID().uuidString
```

unless a caller supplies another local ID.

The current seed functions do not provide fixed IDs.

Therefore two installations that independently seed `Groceries`, `Cash`, or `recurring` receive different local model IDs.

Those IDs are not exported by the accepted v1 schemas.

## 3.3 Seed resemblance is not admitted provenance

The accepted owned-set and schema gates already establish:

```text
is_default
!= bootstrap provenance

same current seed spelling
!= established cross-install identity

receiving-store bootstrap
!= permission to omit source-owned state
```

Current Category also defaults `is_default` to `true` in its initializer, which further demonstrates why the boolean is current canonical state rather than a reliable creation-provenance proof.

PaymentMethod and Tag carry no admitted portable creation-provenance field.

## 3.4 Current models do not establish semantic uniqueness

The current Category, PaymentMethod, and Tag model declarations do not establish a model-level uniqueness contract for:

- `name`;
- the complete admitted semantic field tuple;
- current seed content.

Therefore duplicate-looking destination records are technically possible.

This is a model-level capability observation, not a claim that ordinary current UI intentionally creates duplicates.

## 3.5 No generally available cross-install exact identity is established today

For the three ordinary reference families:

```text
portable_id
→ document-local only

native model id
→ installation-local and not exported

same name
→ not identity

same complete admitted field content
→ not historical identity

is_default
→ not bootstrap provenance

seed resemblance
→ not identity
```

The repository currently establishes no generally available stable cross-install identity token for Category, PaymentMethod, or Tag under Portable v1.

That is not a defect in Portable v1.

It means destination restoration must not pretend that content similarity proves historical object identity.

---

# 4. First-principles restoration rule

Portable ownership needs two things simultaneously:

1. preserve every imported source reference object's admitted semantic state and relationship role;
2. avoid mutating or coalescing pre-existing destination state without sufficient authority.

The minimum sufficient contract is:

```text
no automatic cross-install identity inference

exact admitted semantic equality
→ may make an existing destination object eligible
  for explicit non-mutating reuse

field difference
→ does not permit reuse for a complete source-state restoration
  and does not permit import-driven overwrite/merge

no accepted reuse
→ create a distinct destination object after explicit confirmation
```

Exact semantic equality is therefore a **reuse-eligibility condition**, not proof that the source and destination records are historically the same object.

The distinction matters because reuse creates durable future coupling: later edits to the reused destination object affect both pre-existing destination relationships and newly imported relationships.

That coupling requires user authority even when current field values are identical.

---

# 5. Operation-scoped restoration mapping

During one Portable import, each imported reference object must resolve to exactly one canonical destination object of the same family before dependent non-null relationships can be canonically confirmed.

Conceptually:

```text
imported Category portable_id P
        ↓
one accepted restoration resolution
        ↓
destination Category D
        ↓
every same-document category_ref == P
resolves to D
```

The same rule applies to PaymentMethod and Tag references.

This restoration mapping:

- is scoped to the current import operation;
- preserves same-document relationship closure;
- is not cross-document Portable identity;
- is not a durable synchronization mapping;
- is not an overwrite key;
- is not transaction duplicate identity;
- is not promotion replay identity.

This proposal does not authorize persistence mechanics for the mapping.

---

# 6. One-to-one source-object preservation

Distinct imported reference objects must not collapse silently onto one destination object.

Within one entity family, the accepted restoration mapping must be injective:

```text
source A != source B
        ↓
target(A) != target(B)
```

even when A and B have exactly equal admitted semantic fields.

Reason:

The source document asserted two distinct reference objects through two distinct Portable identities. Different Transactions may intentionally reference them separately.

Mapping both to one destination object would collapse source object multiplicity and create future mutation coupling that the source did not express.

Therefore:

- one imported object resolves to exactly one destination object;
- one destination object may satisfy at most one imported object in that import operation;
- if an otherwise eligible destination object is already assigned to another imported source object, it is no longer eligible for reuse by the second source object;
- the second source object must use another eligible destination object or be restored by creation.

---

# 7. Exact semantic equality by family

Portable `portable_id` is excluded from semantic-equality comparison because it is a transport relationship handle, not destination identity.

Ordinary lifecycle timestamps are also excluded because they are not in these accepted v1 records.

## 7.1 Category equality

A destination Category is exactly semantically equal to an imported Category only when all of the following are exactly equal under accepted v1 semantics:

- `name`;
- `group`;
- `color`;
- `icon`;
- `is_default`.

No trimming, case folding, color normalization, seed recognition, or `is_default` provenance inference is part of exact equality.

## 7.2 PaymentMethod equality

A destination PaymentMethod is exactly semantically equal only when all of the following are exactly equal:

- `name`;
- `method_type`;
- `institution_name` including exact null;
- `last_four` including exact null;
- `notes` including exact null;
- `is_active`.

The comparison does not widen the accepted `last_four` domain and does not create permission to disclose credential-like values outside already authorized local handling.

## 7.3 Tag equality

A destination Tag is exactly semantically equal only when both are exactly equal:

- `name`;
- `color`.

---

# 8. Destination-resolution matrix

The following matrix is proposed for all three ordinary reference families.

| Destination situation for one imported record | Automatic authority | Proposed user-facing semantic resolution | Complete source-state restoration |
| --- | --- | --- | --- |
| No exactly equal destination record | none | CREATE a distinct record | yes |
| Exactly one exactly equal, unassigned destination record | none | confirm REUSE or choose CREATE | yes |
| Multiple exactly equal destination records | none | explicitly choose one eligible record or CREATE | yes |
| Same/similar name but admitted field difference exists | none | similarity may be shown; CREATE is the v1 lossless resolution | yes through CREATE |
| User selects a field-different destination record | none | UPDATE / MERGE not admitted by this gate; choose CREATE or cancel | not through reuse |
| Candidate destination already assigned to another imported source object | none | choose another eligible record or CREATE | yes |
| Imported object has unresolved non-null dependent references | none | resolve reference object before dependent confirmation | not yet |

Nothing in this matrix silently asserts historical sameness.

---

# 9. MATCH / REUSE authority

## 9.1 No automatic match

Portable v1 currently has no general cross-install identity proof for Category / PaymentMethod / Tag.

Therefore no destination record is automatically reused merely because:

- names match;
- normalized names match;
- all admitted fields match;
- it looks like a current seed;
- `is_default == true`;
- `portable_id` spelling happened to appear in another import;
- native IDs happen to be equal through some external manipulation.

## 9.2 Confirmable exact-equality reuse

An existing destination object may be proposed for non-mutating reuse when:

1. it is the correct entity family;
2. its complete admitted v1 semantic field tuple exactly equals the imported record;
3. it is not already assigned to another imported source object in the current operation.

The user must explicitly confirm reuse through the reference import preview/resolution boundary.

The confirmation establishes:

```text
for this import operation:
source object S
→ use destination object D
```

It does **not** establish:

```text
S and D have proven shared historical identity
```

and it does not create a durable mapping for later imports.

## 9.3 Broad-scope confirmation

Where many imported records each have one unambiguous exact-equality candidate and no destination target collision, the accepted Phase 1C broadest-valid-scope rule permits an explicit group/file-level confirmation such as conceptually:

```text
reuse these N exactly equal existing reference records
```

The exact UX, wording, ordering, and selection controls remain downstream.

Bulk confirmation is still user authority.

It is not automatic matching.

---

# 10. CREATE authority

If no destination object has been explicitly accepted for reuse, the lossless v1 fallback is creation of one distinct destination object carrying the source record's exact admitted semantic state.

Creation requires entity-appropriate explicit import confirmation.

Creation is valid when:

- there is no similar destination record;
- there is a same-name but field-different destination record;
- current seed state differs from the imported record;
- multiple candidates are ambiguous and the user chooses to preserve the imported object separately;
- an exact-equality candidate exists but the user declines reuse.

Destination similarity does not by itself make creation invalid.

This proposal does not create a uniqueness constraint that the current canonical model does not have.

---

# 11. UPDATE / OVERWRITE authority

Import-driven update / overwrite is **not admitted by this proposed v1 gate**.

A field-different destination object cannot be mutated merely because it:

- has the same name;
- looks like a current seed;
- is marked `is_default`;
- shares some or most fields;
- is selected by a heuristic candidate matcher.

Why this is deferred:

- the destination object may already be referenced by local Transactions;
- changing the object changes meaning/display for those existing relationships;
- no cross-install identity proof says the source record owns mutation authority over that destination object;
- fresh-seed resemblance cannot safely distinguish bootstrap origin from legitimate existing state;
- update semantics introduce destructive authority that is unnecessary because CREATE preserves the source record without mutating destination state.

A future separately admitted conflict-resolution capability may add explicit replacement/update behavior if product value and impact-preview requirements justify that authority.

This proposal does not forbid ordinary user-authorized reference editing outside the import operation under separately admitted product behavior.

---

# 12. MERGE authority

Import-driven field merge is **not admitted by this proposed v1 gate**.

Examples of unadmitted behavior include:

- source Category name + destination Category color;
- source PaymentMethod `last_four` + destination notes;
- source Tag name + destination color;
- choosing one side field-by-field to synthesize a third state.

A merged object would be neither the exact source record nor necessarily the exact pre-existing destination record.

That creates new canonical meaning rather than restoring admitted source meaning.

A future merge capability would need its own:

- field precedence rules;
- impact semantics;
- relationship behavior;
- auditability;
- user-authority contract.

Portable v1 restoration does not require that extra assembly.

---

# 13. Bootstrap-specific case

The normal fresh-install case is first-class:

```text
Installation A
        ↓
export owned reference record S
        ↓
Installation B first opens
        ↓
Seed.bootstrapIfNeeded()
        ↓
destination independently contains D
        ↓
Portable import
```

## 13.1 Same-version exact seed equality

If S and D are exactly equal on all admitted v1 semantic fields, D may be proposed for explicit reuse.

Current-seed resemblance is not the authority.

Exact semantic equality plus user confirmation is the authority for non-mutating operation-scoped reuse.

## 13.2 Seed version drift or source edits

If a source record and receiving seed differ on any admitted semantic field:

```text
same seed-ish name
+
field difference
        ↓
not eligible for non-mutating reuse
```

The v1 lossless resolution is CREATE.

This avoids turning current seed tables into a hidden permanent cross-version built-in registry.

## 13.3 is_default does not strengthen the match

`is_default == true` remains portable canonical state only.

It does not upgrade a candidate from similarity to identity and does not authorize overwrite.

---

# 14. Same-name / semantic-similarity candidates

Normalized name or other semantic similarity may help Import Review surface relevant destination candidates.

Similarity is advisory only.

It may support:

- displaying likely related records;
- grouping review attention;
- explaining why explicit resolution is needed.

It does not by itself make a destination record eligible for complete-restoration REUSE when any admitted semantic field differs.

This gate does not freeze:

- fuzzy matching algorithms;
- normalization rules;
- similarity scores;
- thresholds;
- ranking;
- UI ordering.

Those mechanisms must not acquire more authority than the accepted restoration rules.

---

# 15. Ambiguity counterexamples

## 15.1 One source → multiple destination candidates

Example:

```text
source Tag S
name = recurring
color = #5C6E8A

destination Tag A
same exact admitted state

destination Tag B
same exact admitted state
```

There is no identity evidence selecting A over B.

Result:

- no automatic choice;
- user may explicitly select A or B;
- or CREATE a separate Tag.

## 15.2 Multiple source objects → one destination candidate

Example:

```text
source Category A
name = Dining
...

source Category B
name = Dining
...

destination Category X
same exact admitted state
```

A and B are distinct source objects.

They may not both resolve to X.

At most one may reuse X; the other must resolve to another distinct eligible destination object or be created separately.

## 15.3 Same name, different state

Example:

```text
source Category
name = Groceries
color = #123456

destination Category
name = Groceries
color = #5C6E8A
```

Name similarity may surface the candidate.

It does not authorize reuse, overwrite, or merge under this v1 proposal.

CREATE preserves both states.

## 15.4 Existing destination relationships

An exactly equal destination Category may already be referenced by local Transactions.

Confirmed non-mutating reuse is still semantically possible because current reference state is equal, but the user confirmation matters: reuse intentionally couples imported and existing Transactions to one future-mutable reference object.

No silent reuse is allowed.

---

# 16. Relationship closure and readiness

A valid Portable record can still require destination resolution before dependent records are ready for complete restoration.

For every non-null imported reference:

```text
portable reference
        ↓
resolve imported reference object
        ↓
one accepted destination target
        ↓
dependent transaction proposal uses that target
```

Preserve:

```text
non-null source reference
!= silently drop to null

unresolved destination mapping
!= pick first candidate

reference resolution once at entity scope
!= repeat the same decision on every Transaction row
```

For required Category association, unresolved mapping remains a required semantic resolution before Transaction confirmation.

For non-null PaymentMethod and Tag references, optionality of the canonical field does not authorize dropping an explicitly present Portable relationship. Complete Portable round-trip restoration requires those non-null relationships to resolve or the affected source state cannot claim complete preservation.

The exact workspace state representation for unresolved mappings remains downstream.

---

# 17. Repeated imports and cross-document non-authority

A later import is a new workflow.

Therefore:

```text
import #1:
p1-000000000017 → destination UUID X
```

does not establish:

```text
future document:
p1-000000000017 → UUID X
```

and does not establish:

```text
same file imported next week
→ automatically reuse UUID X
```

A later import may again surface UUID X as an exactly equal candidate based on current destination semantics, but reuse requires the authority defined for that later operation.

This proposal does not admit persistent cross-import reference mappings.

---

# 18. Existing-store imported-source preservation vs fresh-install round-trip equivalence

This gate must distinguish two valid but different guarantees.

## 18.1 Existing-store imported-source semantic preservation

When importing into an already-existing destination, the proposed non-destructive preservation condition is:

```text
for every imported source Category / PaymentMethod / Tag
        ↓
exactly one distinct destination target exists
        ↓
target carries exactly the source object's admitted v1 semantics
        ↓
every imported same-document reference resolves consistently
to that target
```

Under this guarantee, unrelated destination reference objects may remain.

This gate grants no authority to delete, retire, overwrite, merge, or otherwise mutate destination-only reference state merely because it is absent from the imported source set.

Therefore:

```text
imported-source semantic preservation
!=
whole-store equivalence
```

The distinction is especially important for existing non-empty stores, where additional destination state may be legitimate and intentionally unrelated to the imported artifact.

## 18.2 Fresh-install ownership round trip is stronger

The Phase 1C Roadmap separately requires:

```text
Lumen durable data
        ↓
versioned export
        ↓
Fresh Lumen installation/store
        ↓
import
        ↓
preview / Review / confirmation
        ↓
Equivalent supported canonical state
```

That stronger guarantee is not satisfied merely by proving that every imported source object survived.

Accepted reference owned-set semantics make absence meaningful too.

For example:

```text
source Portable JSON
tags: []
        ↓
source supported Tag set is empty
```

A normal fresh destination currently opens and may independently bootstrap:

```text
recurring
treat
essential
reimbursable
```

If import preserves the empty source set but leaves all four destination-only bootstrap Tags untouched, then:

```text
source supported Tag set = 0
destination supported Tag set = 4
```

No imported source object was lost, because there were none.

But imported-source preservation alone does **not** establish that the fresh destination has reached the Roadmap's stronger `Equivalent supported canonical state`.

The same issue can arise for destination-only bootstrapped Categories or PaymentMethods absent from the source owned set.

## 18.3 This gate does not choose the destination-only bootstrap strategy

Resolving the fresh-install whole-store equivalence problem may eventually require a separately admitted strategy such as:

- reconciliation of destination-only bootstrap state;
- suppression or deferral of bootstrap before restoration;
- explicit retirement/deletion under appropriate authority;
- another mechanism that preserves accepted ownership and round-trip semantics.

This proposal does **not** select among those possibilities.

It grants no:

- deletion authority;
- bootstrap suppression/deferment authority;
- retirement authority;
- overwrite/update authority;
- merge authority;
- implementation mechanism.

The current gate establishes only the ordinary source-object restoration/matching/conflict rules.

Fresh-install destination-only supported reference state remains an unresolved round-trip assembly that must close before Phase 1C can claim whole-store Portable ownership equivalence.

Preserve:

```text
existing-store import
→ imported-source semantic preservation

fresh-install ownership round trip
→ equivalent supported canonical state

the first
!=
automatic proof of the second
```

This distinction does not permit omission of any imported source object and does not weaken the accepted meaning of an empty owned reference set.

---

# 19. Per-family conflict matrix

## 19.1 Category

| Source vs destination | Proposed disposition |
| --- | --- |
| exact equality of `name/group/color/icon/is_default`, one eligible target | explicit REUSE proposal or CREATE |
| multiple exact-equality targets | explicit target selection or CREATE |
| same name but any field differs | similarity only; CREATE for lossless v1 restoration |
| seed-like / `is_default == true` | no extra authority |
| update existing Category from source | not admitted |
| merge fields | not admitted |

## 19.2 PaymentMethod

| Source vs destination | Proposed disposition |
| --- | --- |
| exact equality of `name/method_type/institution_name/last_four/notes/is_active`, one eligible target | explicit REUSE proposal or CREATE |
| multiple exact-equality targets | explicit target selection or CREATE |
| same name/type but institution, `last_four`, notes, or active state differs | similarity only; CREATE |
| current-seed resemblance | no extra authority |
| update existing PaymentMethod | not admitted |
| merge fields | not admitted |

## 19.3 Tag

| Source vs destination | Proposed disposition |
| --- | --- |
| exact equality of `name/color`, one eligible target | explicit REUSE proposal or CREATE |
| multiple exact-equality targets | explicit target selection or CREATE |
| same name, different color | similarity only; CREATE |
| current-seed resemblance | no extra authority |
| update existing Tag | not admitted |
| merge fields | not admitted |

---

# 20. Alternatives considered

## Alternative A — Always create

Every imported source reference object becomes a new destination object.

Advantages:

- maximally simple;
- never mutates destination state;
- preserves source multiplicity.

Cost:

- normal fresh installs would duplicate many independently bootstrapped records even when current semantics are exactly equal;
- user experience would underuse the accepted entity-resolution boundary.

Disposition:

**Not recommended as the only v1 behavior.**

CREATE remains the universal lossless fallback.

## Alternative B — Automatically reuse exact field equality

Advantages:

- avoids duplicates on same-version fresh installs;
- deterministic.

Rejected because:

- exact field equality is not historical identity;
- coalescing creates durable future mutation coupling;
- multiple identical destination candidates can exist;
- two distinct source objects must not collapse onto one destination object;
- user authority is already required by the Phase 1C reference preview/confirmation contract.

## Alternative C — Treat current seed definitions as built-in stable identity

Rejected.

Current seed records use fresh UUIDs and the accepted contract contains no stable seed key or creation provenance.

Seed-content matching would create a hidden cross-version registry not admitted by Phase 1C.

## Alternative D — Name-based automatic matching

Rejected.

Name similarity is explicitly not identity and cannot preserve field-different source state.

## Alternative E — Explicit overwrite/update of a selected destination record

Potentially useful later, especially for a receiving store with destination state the user deliberately wants to replace.

Not admitted here because it changes existing canonical reference state and potentially all local relationships that already point to it.

CREATE solves the required v1 restoration problem without this destructive authority.

## Alternative F — Field merge

Rejected for initial v1.

A merge synthesizes canonical state rather than restoring exact source state.

## Alternative G — Persistent cross-import match memory

Deferred.

It would create a new durable identity/mapping responsibility and persistence lifecycle.

This gate needs only operation-scoped restoration resolution.

---

# 21. Reasoning Framework check

## First Principles

Capability:

Restore admitted source reference state and same-document relationships into a destination that may already contain independently created reference objects.

Necessary truths:

- source Portable IDs distinguish source objects within the document;
- destination local IDs do not establish source identity;
- source state must not be lost;
- destination state must not be mutated without earned authority;
- ordinary fresh installs already contain seed state.

Minimum sufficient contract:

- exact-equality candidates may be explicitly reused without mutation;
- otherwise create the source reference object separately;
- preserve one-to-one source-object resolution;
- defer merge/update.

## Repository Evidence

Established facts:

- normal launch seeds reference families before exposing the store to UI;
- seed records receive fresh UUID-string IDs;
- accepted Portable schemas do not export those IDs;
- `portable_id` is document-local;
- `is_default` is not provenance;
- exact record schemas are accepted;
- source-side compatibility is accepted;
- no model-level semantic uniqueness contract is established for the three families.

Not established:

- stable cross-install reference identity;
- stable seed identity;
- durable prior-import mapping;
- overwrite authority;
- merge authority.

## Assembly Map

Prerequisites:

- reference complete-export owned set;
- exact reference schemas;
- Portable identity semantics;
- source compatibility disposition;
- Phase 1C resolution / atomicity responsibilities.

New subassembly:

Operation-scoped ordinary reference restoration and destination conflict semantics.

Consumers:

- Portable JSON round-trip contract;
- reference import preview / resolution;
- dependent Transaction reference reconstruction;
- later implementation capability/persistence admission.

Still separate:

- Source/provenance;
- parser evolution;
- deterministic serialization;
- workspace persistence;
- promotion proof.

## Authority Budget

New authority proposed:

- present existing exact-semantics destination records as reuse candidates;
- allow explicit confirmed non-mutating reuse;
- create distinct reference records after explicit confirmation;
- enforce one-to-one operation-scoped source→destination mapping;
- resolve all same-document references through that accepted mapping.

Authority explicitly not granted:

- automatic cross-install identity;
- silent matching;
- many-to-one source collapse;
- overwrite/update;
- field merge;
- destination deletion;
- persistent cross-import mappings;
- Source/provenance handling;
- implementation.

## Assembly Debt

No lower-level semantic dependency blocks this gate.

Unknown-field policy determines whether an input object is recognized as valid, not what to do after a valid known-field record exists.

Source/provenance is intentionally outside the ordinary reference-data line.

Money/date lexical gates govern Transaction scalar representation.

Deterministic Portable-ID allocation/order does not change already-accepted document-local relationship semantics.

## Assembly Pressure

The three reference families now share enough accepted structure to justify one cross-family restoration rule:

```text
exact v1 semantic equality
→ eligible for explicit non-mutating reuse

otherwise
→ create for lossless restoration
```

Per-family equality tuples remain explicit.

This does not justify a generic entity-merging framework.

## Counterexample Test

- same name, different color: cannot reuse without losing source state;
- two source objects, one identical destination: cannot collapse both;
- one source object, two identical destinations: cannot pick one silently;
- exact seed resemblance: does not prove provenance;
- exact equality with existing referenced destination record: still requires confirmation because future edits become coupled;
- repeated file import: prior `portable_id` resolution has no cross-document authority;
- optional PaymentMethod field: a non-null imported reference cannot silently disappear because the destination field is optional;
- source `tags: []` imported into a freshly bootstrapped store with four destination-only Tags: imported-source preservation may hold while fresh-install whole-store equivalence remains unresolved.

## Irreversible Commitments

If accepted, v1 would promise:

- no automatic ordinary-reference coalescing;
- exact-semantics-only eligibility for non-mutating reuse;
- one-to-one operation-scoped resolution;
- source-preserving CREATE fallback;
- no import-driven update/merge authority;
- imported-source preservation is not by itself a definition of fresh-install whole-store round-trip equivalence;
- destination-only bootstrap state remains relevant to the Roadmap's stronger equivalence requirement.

A future overwrite, merge, persistent identity system, or fresh-install bootstrap-state disposition would therefore require explicit additional admission.

---

# 22. Proposed exact contract language

The following language is **PROPOSED FOR REVIEW**.

> **Ordinary reference restoration identity boundary.** Portable JSON v1 does not currently establish a generally available cross-install identity mechanism for Category, PaymentMethod, or Tag. Document-local `portable_id` values and installation-local native model IDs do not establish destination identity; exact name or exact admitted-field equality does not by itself prove historical identity; `Category.is_default` and resemblance to current seed data do not prove bootstrap provenance.
>
> **Operation-scoped restoration mapping.** During one import operation, each imported Category, PaymentMethod, and Tag must resolve to exactly one destination object of the same family before dependent non-null Portable references can be canonically confirmed. All same-document references to that imported object's `portable_id` must resolve through the same accepted target. Distinct imported objects must resolve to distinct destination objects. The mapping is operation-scoped and grants no cross-document identity, synchronization, overwrite, deduplication, or promotion-replay authority.
>
> **Existing-object reuse.** An existing destination Category / PaymentMethod / Tag is eligible for non-mutating reuse only when its complete admitted Portable v1 semantic field tuple is exactly equal to the imported record, excluding `portable_id` and excluded lifecycle timestamps, and when that destination object is not already assigned to another imported source object in the same operation. Reuse always requires explicit reference-import confirmation. Exact equality makes reuse semantically lossless; it does not establish shared historical identity.
>
> **Ambiguity.** If more than one destination object is eligible for reuse, Lumen must not select one silently. The user must explicitly select one eligible destination object or choose creation of a distinct destination object. If an otherwise eligible destination object is already assigned to another imported source object, it is unavailable to the second source object.
>
> **Creation fallback.** If no existing destination object is explicitly accepted for reuse, Lumen may restore the imported reference by creating one distinct destination object carrying exactly the imported record's admitted v1 semantic state after entity-appropriate explicit confirmation. Same-name, default-like, seed-like, or otherwise similar destination state does not remove this lossless creation path.
>
> **Similarity boundary.** Name normalization or other semantic/content similarity may surface review candidates but grants no match authority. A destination object whose admitted v1 semantic state differs from the source record is not eligible for non-mutating reuse in a complete source-state restoration under this v1 gate.
>
> **No merge or overwrite authority.** This gate does not authorize import-driven mutation/update of an existing destination Category / PaymentMethod / Tag and does not authorize field-level merge or synthesis of a third state. Those capabilities require separate admission.
>
> **Bootstrap neutrality.** Independently bootstrapped destination records are evaluated under the same rules as all other destination records. Current seed resemblance and `is_default` do not create a privileged identity or overwrite path.
>
> **Resolution scope.** Repeated dependent Transaction references must consume one accepted reference-entity resolution rather than requiring duplicate row-level decisions. Where a set of imported reference records each has one unambiguous exact-equality candidate with no target collisions, explicit confirmation may occur at the broadest valid group/file scope. Exact UX remains downstream.
>
> **Existing-store imported-source preservation.** For an import into an already-existing destination, preservation of imported ordinary reference state requires every imported Category / PaymentMethod / Tag to have one distinct destination target carrying its exact admitted v1 semantics and every imported same-document reference to resolve consistently to that target. Unrelated destination reference objects may remain. This gate grants no deletion, retirement, overwrite, merge, or bootstrap-suppression authority over destination-only state.
>
> **Fresh-install round-trip boundary.** Existing-store imported-source preservation does not by itself establish the Phase 1C Roadmap's stronger fresh-install guarantee of `Equivalent supported canonical state`. Accepted owned-set and empty-set semantics remain meaningful: a source family with an empty owned set is not automatically equivalent to a freshly bootstrapped destination family containing destination-only records. The disposition of destination-only bootstrap state remains unresolved by this gate and must be separately admitted before whole-store fresh-install Portable round-trip equivalence is claimed.
>
> **Repeated-import boundary.** A reference resolution accepted in one import does not by itself create a durable mapping for later imports. Re-import of the same or overlapping Portable document is a new workflow unless a future separately admitted persistent identity/mapping contract states otherwise.

---

# 23. Remaining dependencies after this proposal

Even if this proposal is later accepted, still open include:

1. Source/provenance portability;
2. PortableMoney lexical/governance closure, including unresolved precision/upper-magnitude authority items and canonical decimal serialization;
3. exact financial-date lexical/year validity;
4. top-level/admitted timestamp lexical rules;
5. deterministic Portable-ID allocation and emitted ordering;
6. unknown-field/evolution policy;
7. fresh-install destination-only bootstrap reference-state disposition required for whole-store round-trip equivalence;
8. full Portable JSON / CSV v1 acceptance;
9. exact implementation capability selection;
10. persistence/recovery admission where required;
11. implementation and validation.

This proposal deliberately does not preselect those later gates.

---

# 24. Independent-review questions

Independent review should answer:

1. Does current repository evidence support the conclusion that no generally available cross-install exact identity exists for Category / PaymentMethod / Tag under Portable v1?
2. Is exact admitted-field equality correctly treated as eligibility for explicit non-mutating reuse rather than proof of historical identity?
3. Is explicit confirmation still required for exact-equality reuse because reuse creates durable future mutation coupling?
4. Is the one-to-one / injective source→destination mapping requirement necessary to preserve distinct source object multiplicity?
5. Does the proposal correctly handle one-source/multiple-destination and multiple-source/one-destination ambiguity?
6. Is CREATE the correct universal lossless fallback when a field-different or ambiguous destination exists?
7. Should import-driven UPDATE / OVERWRITE remain unadmitted in v1 rather than being introduced to make bootstrapped destinations look cleaner?
8. Should field MERGE remain unadmitted because it synthesizes new canonical state?
9. Does the bootstrap rule avoid accidentally turning current seed definitions into stable cross-version identity?
10. Does entity-scope resolution correctly preserve same-document relationship closure without repeating decisions per Transaction row?
11. Is the repeated-import boundary consistent with document-local Portable identity?
12. Is existing-store imported-source semantic preservation correctly distinguished from whole-store fresh-install round-trip equivalence?
13. Does the `tags: []` fresh-bootstrap counterexample correctly demonstrate why source-object preservation alone is insufficient for the stronger Roadmap guarantee?
14. Does the proposal preserve accepted empty-set semantics without inventing deletion, retirement, bootstrap-suppression, overwrite, or merge authority?
15. Is destination-only bootstrap reference-state disposition correctly left unresolved as a later round-trip dependency?
16. Are Source/provenance, parser evolution, money/date lexical closure, deterministic ordering, workspace persistence, and implementation kept outside this gate?
17. Does the proposed contract preserve all accepted upstream reference ownership/schema/compatibility semantics without reopening them?

---

# 25. Review boundary

This proposal is ready for independent review.

It is not accepted merely because it is checked into the repository.

Do not promote the aggregate contract, open Source/provenance, introduce merge/update authority, or begin implementation from this proposal without separate acceptance / authorization.
