# Lumen Portable v1 Fresh-Install Restoration Bootstrap-State Disposition Proposal

## Status

**PROPOSED FOR REVIEW — docs-only Phase 1C fresh-install Portable ownership-restoration bootstrap-state gate.**

Starting accepted semantic checkpoint:

`e01f87e30beb84c16dddf8eed3a591c8b5e0a182`

Underlying proposal-development composition baseline:

`c7dd2ea639df6db0e98f942f5d906b522d28cf30`

Canonical `main` at gate opening:

`d4884e2180e2f867dee415a48375100097a8d415`

Branch:

`docs/phase1c-portable-v1-fresh-install-restoration-bootstrap-state-proposal`

The accepted semantic checkpoint is the dependency base for this gate. The composition baseline remains composition-only and creates no independent semantic authority.

This proposal consumes and does not reopen the accepted ordinary-reference line:

```text
Category / PaymentMethod / Tag complete-export owned set
→ ACCEPTED AT PROPOSED-CONTRACT LEVEL

exact Category / PaymentMethod / Tag schemas
→ ACCEPTED AT PROPOSED-CONTRACT LEVEL

reference-record complete-export compatibility disposition
→ ACCEPTED AT PROPOSED-CONTRACT LEVEL

existing-store restoration / destination matching / conflict semantics
→ ACCEPTED AT PROPOSED-CONTRACT LEVEL
```

It also preserves the accepted distinction:

```text
existing-store imported-source preservation
!=
fresh-install whole-store round-trip equivalence
```

This proposal does not accept the full Portable JSON / CSV v1 contract and does not authorize implementation.

---

# 1. Decision question

For a genuinely fresh Lumen installation/store entering a supported Portable ownership-restoration workflow:

> **What authoritative condition governs ordinary Category / PaymentMethod / Tag bootstrap so that destination-only defaults do not violate the Phase 1C Roadmap requirement for `Equivalent supported canonical state`, including interruption and relaunch before restoration completes?**

The central question is not:

> Which seed-looking records may Lumen delete afterward?

It is:

> **When does ordinary bootstrap have authority to create canonical reference state at all, and when must that authority yield to a fresh-install ownership-restoration workflow?**

The gate must distinguish:

```text
ordinary fresh-start initialization
```

from:

```text
fresh-install ownership restoration
```

without fabricating bootstrap provenance from already-canonical record contents.

---

# 2. Accepted prerequisites

## 2.1 Round-trip ownership target

The Phase 1C Roadmap requires:

```text
Lumen durable data
→ Versioned export
→ Fresh Lumen installation/store
→ Import
→ Preview / Draft(s)
→ Review / Confirmation
→ Equivalent supported canonical state
```

"Equivalent" applies to the durable fields and entities admitted to the portable format.

## 2.2 Complete ordinary-reference owned sets

For complete Portable JSON v1 ownership export:

```text
every durable Category
→ categories[]

every durable PaymentMethod
→ payment_methods[]

every durable Tag
→ tags[]
```

Membership is independent of Transaction reachability, default-like state, active state, display-name similarity, or guessed bootstrap provenance.

## 2.3 Empty-set semantics

Accepted semantics establish:

```text
categories: []
→ admitted durable Category set is empty

payment_methods: []
→ admitted durable PaymentMethod set is empty

tags: []
→ admitted durable Tag set is empty
```

An empty array does not mean that defaults were omitted because another installation is expected to recreate them.

## 2.4 Ordinary restoration identity boundary

Accepted restoration semantics establish:

```text
portable_id
→ document-local relationship identity only

native model UUID
→ installation-local only

same name
!= historical identity

exact admitted semantic equality
!= historical identity

is_default
!= bootstrap provenance

seed resemblance
!= bootstrap provenance
```

Exact admitted semantic equality makes an existing destination record eligible for explicit non-mutating REUSE. It does not prove bootstrap origin.

## 2.5 Existing-store preservation boundary

For an existing destination:

```text
every imported source reference object
→ one distinct destination target
→ exact source semantics
→ consistent same-document relationship closure
```

Unrelated destination state may remain.

That accepted gate grants no deletion, retirement, bootstrap suppression/deferment, overwrite, merge, or persistent cross-import mapping authority.

## 2.6 Deletion authority remains exact-capability work

The Phase 1C responsibility contract includes meaningful data management but explicitly requires truthful destructive scope.

Broad Roadmap language such as:

```text
category management
payment-method management
tag management
scoped data-management/deletion controls
```

does not itself admit arbitrary Category / PaymentMethod / Tag deletion.

Ordinary reference management remains independently admissible only within exact contracts.

---

# 3. Repository evidence

## 3.1 The current open/bootstrap seam is mechanically real

Current launch behavior is:

```text
LumenApp.openLedger()
        ↓
LedgerStore.open()
        ↓
ModelContainer exists
        ↓
Seed.bootstrapIfNeeded(mainContext)
        ↓
container exposed to UI
```

`LedgerStore.open()` creates/opens the persistent ModelContainer and returns it.

`Seed.bootstrapIfNeeded()` is a separate subsequent operation.

Therefore current implementation contains a real mechanical seam:

```text
store open
        ↓
[ possible authority boundary ]
        ↓
reference bootstrap
```

This seam is relevant evidence.

It is **not** itself semantic proof that the store is fresh.

## 3.2 Current bootstrap is family-emptiness-driven

`Seed.bootstrapIfNeeded()` currently computes:

```text
Category count == 0
→ seed Categories

PaymentMethod count == 0
→ seed PaymentMethods

Tag count == 0
→ seed Tags
```

The three family predicates are evaluated independently.

If any family needs defaults, all currently needed insertions are committed through one `LedgerWrite.perform` operation.

Current seed definitions create ordinary canonical records using normal model initializers and installation-local UUID defaults.

## 3.3 Bootstrap creates durable reference state without Transactions

`LedgerPersistenceTests.testSeedIdempotencyAndFailureRetryWithoutSamples()` establishes that after successful bootstrap:

- PaymentMethod count is 7;
- Tag count is 4;
- Category state is populated;
- Transaction count remains 0.

The same test establishes that:

- a failed bootstrap commit leaves all three tested reference-family counts at zero;
- a later successful bootstrap can retry;
- repeating bootstrap after success preserves the existing Category identities rather than reseeding them.

Therefore destination-only default state is concrete durable canonical state, not UI decoration.

## 3.4 Freshness is not currently encoded by the seam

Current `LedgerStore.open()` does not return a semantic result such as:

```text
newly created store
existing store
previously initialized store
fresh restoration eligible
```

Opening a ModelContainer therefore proves only that the store can be accessed.

It does not prove:

```text
this receiving store is a genuinely fresh ownership-restoration target
```

## 3.5 Family emptiness is not authoritative freshness proof

Current bootstrap uses family count zero as an implementation trigger.

But the accepted ownership contract gives empty sets independent semantic meaning.

Future ordinary reference-management behavior may also legitimately produce an empty family.

Therefore:

```text
Category count == 0
!= proof of fresh installation

PaymentMethod count == 0
!= proof of fresh installation

Tag count == 0
!= proof of fresh installation
```

and:

```text
all three families empty
!= sufficient durable proof of fresh-install restoration eligibility
```

The next contract must not turn current bootstrap predicates into historical provenance.

## 3.6 Current records do not carry reliable bootstrap provenance

Across ordinary Category / PaymentMethod / Tag state:

- native IDs are installation-local;
- PaymentMethod and Tag have no seed/user-origin field;
- `Category.is_default` defaults to true in the ordinary initializer and is not provenance;
- exact equality with current `Seed.swift` definitions does not prove origin;
- zero Transaction references are demonstrated normal durable state.

Therefore, after bootstrap has committed:

```text
record looks seeded
!= record is proven disposable bootstrap state
```

## 3.7 Current startup policy conflicts with stable empty restored families

Suppose a valid source artifact contains:

```json
{
  "tags": []
}
```

and a fresh restoration successfully establishes an empty canonical Tag set.

If a later launch still applies:

```text
Tag count == 0
→ seed Tags
```

then the next launch recreates:

- recurring;
- treat;
- essential;
- reimbursable.

The restored empty owned set does not survive ordinary startup.

Therefore merely deferring bootstrap during one restore session is insufficient.

The semantic contract must also answer when bootstrap authority is permanently resolved for that store.

---

# 4. First-principles framing

The minimum product truths are:

1. ordinary first-run Lumen may create useful default reference state;
2. a supported fresh-install Portable ownership restore must be able to reproduce admitted source reference state, including empty families;
3. destination-only defaults must not silently become part of a source-equivalent restored state;
4. record contents cannot prove bootstrap provenance after canonical creation;
5. arbitrary existing user state must not become disposable merely because it resembles current defaults;
6. process interruption must not silently change who has authority to initialize the reference graph.

Preserve:

```text
bootstrap convenience
!= ownership authority
```

and:

```text
family emptiness
!= perpetual permission to recreate defaults
```

The initial question is an **initialization-authority** question, not a deduplication question.

---

# 5. Terminology for this gate

These terms are semantic concepts only. They do not select persisted model types, storage locations, or UI.

## 5.1 Ordinary bootstrap authority

Authority for Lumen to establish its ordinary default Category / PaymentMethod / Tag state for a store that has not yet completed another admitted initialization path.

## 5.2 Fresh-restoration eligibility

An authoritative fact that the receiving store is eligible to enter the special fresh-install ownership-restoration path.

It must not be inferred solely from:

- opening the store;
- family counts;
- record names;
- exact seed equality;
- `is_default`;
- zero relationships;
- current seed-table resemblance.

## 5.3 Fresh-restoration bootstrap hold

The semantic condition under which ordinary reference bootstrap has yielded to an explicitly chosen fresh-install Portable ownership-restoration workflow.

"Hold" describes authority, not a required implementation object.

## 5.4 Initialization resolved

The point after which ordinary bootstrap may no longer treat an empty reference family as evidence that default initialization still needs to occur.

Resolution may be reached through:

- successful ordinary bootstrap; or
- successful fresh-install ownership restoration.

An explicitly abandoned fresh-restoration attempt may instead release the hold and return to the unresolved ordinary initialization path.

---

# 6. Minimum sufficient proposed contract

## 6.1 Bootstrap is initialization authority, not a repair invariant

Proposed:

> Ordinary reference bootstrap is authority to initialize a store's default reference state. It is not permanent authority to recreate defaults whenever a canonical reference family later happens to be empty.

Therefore:

```text
initialized store
+
Tag count == 0
        ↓
no automatic conclusion that Tag bootstrap is authorized
```

This is necessary to preserve accepted empty-set ownership semantics across later launches.

## 6.2 Fresh restoration must acquire authority before ordinary bootstrap commits

A fresh-install ownership-restoration workflow may reserve the reference initialization path only before ordinary Category / PaymentMethod / Tag bootstrap has committed canonical defaults for that initialization.

Required conceptual ordering:

```text
open receiving store
        ↓
establish authoritative fresh-restoration eligibility
        ↓
explicit user choice to restore supported Portable ownership state
        ↓
fresh-restoration bootstrap hold established
        ↓
ordinary reference bootstrap yields
        ↓
restore / preview / confirmation workflow
```

This does not require a particular launch screen or UI flow.

## 6.3 Mechanical pre-bootstrap position is necessary but not sufficient

The current seam:

```text
LedgerStore.open()
→ before Seed.bootstrapIfNeeded()
```

is a useful implementation position.

It is not by itself the authority predicate.

A conforming implementation must establish fresh-restoration eligibility through an authoritative lifecycle/workflow fact rather than infer it from current record contents.

The exact proof mechanism is downstream capability/persistence work.

## 6.4 Explicit restoration intent is required

Fresh-restoration bootstrap authority must not arise silently because a file exists on disk or because a store is empty.

The user must deliberately choose a supported ownership-restoration workflow.

Preserve:

```text
freshness eligibility
+
explicit restoration intent
→ candidate authority to hold ordinary bootstrap
```

Neither condition alone is sufficient.

## 6.5 The hold applies to the ordinary reference bootstrap assembly

For complete Portable ownership restoration, the relevant initialization authority covers:

- Category;
- PaymentMethod;
- Tag.

The workflow must not allow one family to be silently bootstrapped while another family is controlled by the source artifact merely because current `Seed.bootstrapIfNeeded()` evaluates family emptiness independently.

The source document's admitted owned sets must remain authoritative for all three families in a successful fresh-install round trip.

## 6.6 Source empty families remain empty after successful restoration

If the source artifact says:

```text
tags: []
```

then successful fresh-install ownership restoration must not add destination-only Tags merely to satisfy ordinary bootstrap defaults.

Likewise for empty Category or PaymentMethod sets where the complete source artifact validly establishes them.

This gate does not alter downstream Transaction readiness requirements. A restored dataset whose Transactions require a non-null Category must still satisfy accepted relationship/reference validity.

## 6.7 Successful fresh restoration resolves ordinary bootstrap authority

After successful fresh-install ownership restoration:

```text
restored admitted reference state
→ initialization resolved
```

A later application launch must not reauthorize ordinary default insertion solely because one restored family is empty.

Therefore current count-only bootstrap behavior is not sufficient for the eventual implementation of this contract.

The exact mechanism that remembers initialization resolution is not selected here.

## 6.8 Interruption must not silently give bootstrap authority back

Counterexample:

```text
fresh-restoration eligibility established
        ↓
user explicitly chooses restore
        ↓
ordinary bootstrap yields
        ↓
process terminates before restoration completes
        ↓
application relaunches
```

If relaunch forgets the authority state and runs ordinary bootstrap, destination-only defaults reappear and can defeat whole-store equivalence.

Proposed semantic rule:

> Once a legitimate fresh-restoration bootstrap hold has acquired authority, ordinary bootstrap must not silently regain authority merely because the process terminates or the application relaunches.

If the product permits the restoration workflow to survive interruption, the authority needed to keep bootstrap deferred must be recoverable across that interruption.

This establishes a **downstream exact persistence/recovery admission dependency**.

It does not choose:

- SwiftData;
- UserDefaults;
- a file;
- a new RestoreSession model;
- schema changes;
- a specific atomicity mechanism.

## 6.9 Failure is not implicit cancellation

Parsing failure, unsupported input, validation failure, or an interrupted attempt must not automatically mean:

```text
restore failed
→ bootstrap now owns the store
```

The workflow must distinguish:

- continue/repair/select another supported artifact;
- explicitly abandon fresh restoration and choose ordinary initialization;
- successfully complete restoration.

The exact UX is downstream.

## 6.10 Explicit abandonment can release the hold before restoration commits

If the user explicitly abandons the fresh-install restoration path before successful canonical restoration, the special bootstrap hold may be released.

Then ordinary bootstrap may again become eligible under the still-unresolved initialization path.

This does not authorize deletion of any canonical state already created by another operation.

A future implementation must define safe failure/cleanup behavior for any noncanonical workspace state.

## 6.11 Already-bootstrapped receiving state is outside the narrow path

If ordinary bootstrap has already committed destination reference defaults before fresh-restoration authority is established, this gate does not permit the application to infer:

```text
these records look like current seeds
→ therefore delete them
```

That situation remains governed by accepted existing-store restoration semantics unless separately admitted destructive/reconciliation authority exists.

Therefore the narrow fresh-install path requires the bootstrap/restoration authority decision to occur before ordinary defaults become canonical under that initialization.

## 6.12 Existing stores remain existing stores

A store containing unrelated pre-existing canonical state does not become "fresh" because:

- all current Transactions were deleted;
- a family is empty;
- all records happen to equal current seed values;
- the user wants to import a backup.

This gate does not weaken the accepted existing-store non-destructive contract.

---

# 7. Freshness authority: what is and is not established

## 7.1 What current evidence establishes

Current code establishes:

```text
store can be opened
before
ordinary reference bootstrap runs
```

Current tests establish:

```text
bootstrap reference state
can exist durably
with zero Transactions
```

Accepted contracts establish:

```text
record content
does not prove
bootstrap provenance
```

## 7.2 What current evidence does not establish

Current repository evidence does not provide a generally admitted durable fact equivalent to:

```text
this store has never completed initialization
and is eligible for fresh ownership restoration
```

The next implementation/capability layer will need a truthful way to establish that fact.

## 7.3 Constraint on the future proof

Whatever proof is later admitted must distinguish lifecycle authority from record-content inference.

Preserve:

```text
authoritative pre-bootstrap lifecycle/workflow observation
may establish initialization authority

post-bootstrap content inspection
must not fabricate provenance
```

This proposal does not require per-record provenance.

---

# 8. Interruption and recovery semantics

## 8.1 Authority-acquired vs workflow-completed

The gate distinguishes:

```text
fresh-restoration authority established
```

from:

```text
fresh-restoration workflow successfully completed
```

Those are not the same event.

Between them, ordinary bootstrap remains withheld.

## 8.2 Relaunch while unresolved

If interruption occurs after authority is established but before a terminal outcome:

```text
relaunch
→ recover unresolved fresh-restoration authority
→ do not run ordinary reference bootstrap
→ resume / repair / explicitly abandon restoration
```

The exact persistence and recovery mechanism remains downstream.

## 8.3 Successful completion

On successful restoration:

```text
accepted source reference owned sets
+
accepted same-document relationship reconstruction
+
successful confirmation
        ↓
fresh-restoration initialization resolved
```

After resolution, later startup must respect the restored state, including deliberately empty families.

## 8.4 Explicit abandonment

On explicit abandonment before canonical restore completion:

```text
fresh-restoration hold released
→ ordinary initialization path may resume
```

This is not authority to retain partially promoted canonical state. Existing all-or-nothing promotion responsibilities remain controlling.

---

# 9. Relationship to current bootstrap implementation

Current `Seed.bootstrapIfNeeded()` uses:

```text
family count == 0
→ needs family seed
```

That is sufficient for today's ordinary startup behavior.

It is not sufficient for the proposed Phase 1C fresh-restore contract because:

1. it cannot distinguish a never-initialized empty family from an intentionally empty restored family;
2. it has no fresh-restoration hold input;
3. it has no durable initialization-resolution input;
4. it will reseed an intentionally empty restored family on a later launch.

This is an implementation-alignment finding only.

The proposal does not authorize production changes to `Seed.swift`, `LumenApp.swift`, `LedgerStore.swift`, persistence schema, or tests.

---

# 10. Alternatives considered

## Alternative A — Authority-gated pre-bootstrap restoration path

Rule:

```text
authoritative fresh-restoration eligibility
+
explicit restore intent
        ↓
ordinary bootstrap yields before creating defaults
        ↓
source owned sets initialize canonical reference state
        ↓
successful restore resolves initialization
```

Interruption preserves the hold until explicit resolution.

Advantages:

- preserves empty source-family semantics;
- does not need to identify/delete already-created seed records;
- preserves accepted identity boundaries;
- keeps arbitrary existing-store reconciliation outside scope;
- minimizes destructive authority;
- aligns with the current mechanical open/bootstrap seam.

Cost:

- requires authoritative store/workflow freshness semantics;
- requires recoverable bootstrap-hold / initialization-resolution behavior across interruption if restoration is resumable;
- current count-only bootstrap implementation cannot satisfy it unchanged.

Disposition:

**RECOMMENDED AS THE MINIMUM SUFFICIENT SEMANTIC CONTRACT.**

This recommendation is about authority behavior, not a storage mechanism.

## Alternative B — Bootstrap normally, then delete/reconcile destination-only defaults

Rule:

```text
ordinary bootstrap runs
→ restore begins
→ identify defaults
→ remove/reconcile records absent from source
```

Problems:

- current records do not carry reliable bootstrap provenance;
- exact seed equality is not provenance;
- `is_default` is not provenance;
- zero references are not provenance;
- broad reference deletion authority is not yet admitted;
- the path risks treating user-owned existing state as disposable.

Disposition:

**DO NOT ADMIT IN THIS GATE.**

A future separately justified destructive capability could revisit a narrower post-bootstrap path.

## Alternative C — Add per-record bootstrap-origin provenance

Rule:

Persist origin metadata such as:

```text
created_by_bootstrap = true
```

and use it for later reconciliation.

Advantages:

- could distinguish seed-created state from other records after creation.

Costs:

- creates new durable provenance responsibility;
- likely introduces schema/migration implications;
- requires lifecycle semantics when a seeded record is edited;
- is unnecessary if pre-bootstrap authority solves the initial round-trip problem.

Disposition:

**NOT REQUIRED FOR THIS GATE; DO NOT ADMIT.**

## Alternative D — Stable built-in/default identities

Rule:

Assign permanent cross-install identity to built-in Categories / PaymentMethods / Tags.

Problems:

- current seeds use installation-local UUIDs;
- accepted Portable identity does not define stable built-in identity;
- modified defaults would require version/provenance semantics;
- this creates a broad public identity subsystem beyond the immediate need.

Disposition:

**REJECT FOR INITIAL V1.**

## Alternative E — Infer freshness from empty families

Rule:

```text
all reference counts == 0
→ treat store as fresh
```

Problems:

- empty families are valid portable state;
- future management can legitimately produce emptiness;
- content state is not lifecycle provenance.

Disposition:

**REJECT.**

## Alternative F — Infer bootstrap-only state from exact seed equality

Rule:

If all records exactly match current `Seed.swift`, treat them as disposable.

Problems:

- exact equality is already accepted as non-provenance;
- user-owned or restored state can exactly equal defaults;
- current seed definitions can evolve.

Disposition:

**REJECT.**

## Alternative G — Restore into a separate isolated store and swap stores

This could potentially avoid ordinary defaults in the target store.

However it introduces:

- alternate-store lifecycle;
- replacement/swap authority;
- failure recovery;
- evidence/storage ownership interactions;
- migration and atomic replacement questions.

Disposition:

**NOT NEEDED TO ADMIT THE SEMANTIC CONTRACT.**

It may remain a future implementation alternative if independently justified.

---

# 11. Counterexample tests

## 11.1 Empty Tags source

```text
source tags: []
→ fresh restore
→ destination tags must remain []
```

Later launch must not recreate four defaults solely because Tag count is zero.

## 11.2 Empty Category family

A valid complete source artifact can semantically declare an empty Category set even though current ordinary Transaction confirmation normally requires Category for new Transactions.

The bootstrap contract must not redefine:

```text
categories: []
```

as:

```text
please recreate default Categories
```

Transaction/reference validity remains a separate dataset/readiness concern.

## 11.3 Restore chosen, process killed

```text
fresh eligibility
→ restore chosen
→ bootstrap held
→ process killed
→ relaunch
```

Ordinary bootstrap must not silently run if fresh-restoration authority remains unresolved.

## 11.4 Invalid selected artifact

```text
fresh restore chosen
→ bootstrap held
→ selected file invalid
```

Invalid input does not itself authorize default bootstrap.

User may repair/select another artifact or explicitly abandon restoration.

## 11.5 Explicit user cancellation

```text
fresh restore chosen
→ user explicitly cancels / abandons before canonical restore
→ hold released
→ ordinary initialization may proceed
```

This is a legitimate return to ordinary startup.

## 11.6 Existing store happens to equal current seeds

An established store may contain exact current seed semantics.

That does not make it fresh or make those records disposable.

## 11.7 Existing store with zero Transactions

Bootstrap tests already demonstrate zero-Transaction durable reference state.

Therefore:

```text
Transaction count == 0
!= fresh restoration proof
```

## 11.8 Existing initialized store with an empty family

Future legitimate management may leave a family empty.

Therefore:

```text
family empty
!= bootstrap authority
```

after initialization has been resolved.

## 11.9 Partial-family bootstrap must not leak into fresh restore

Because current seed decisions are family-specific, a future implementation must not allow:

```text
Category defaults created
PaymentMethods withheld
Tags restored from source
```

merely because the authority decision was made independently per family.

A complete fresh ownership restoration needs one coherent ordinary-reference bootstrap disposition.

---

# 12. Assembly Map

## 12.1 Prerequisite assemblies

Accepted prerequisites:

- complete Category / PaymentMethod / Tag owned-set semantics;
- empty-set semantics;
- exact ordinary-reference schemas;
- reference-record compatibility disposition;
- Portable document-local identity;
- existing-store restoration / matching / conflict semantics;
- Phase 1C round-trip ownership requirement;
- Phase 1C all-or-nothing canonical confirmation responsibility.

## 12.2 New subassembly

```text
fresh-install ordinary-reference
bootstrap/restoration authority disposition
```

It decides:

- when ordinary bootstrap is eligible;
- when fresh restoration may hold it;
- how interruption affects that authority;
- when initialization is resolved;
- why restored empty families do not later trigger reseeding.

## 12.3 Consumers

Downstream consumers include:

- whole-store Portable JSON v1 round-trip acceptance;
- fresh-install import entry flow;
- exact persistence/recovery capability admission;
- eventual bootstrap implementation alignment;
- Phase 1C validation.

## 12.4 Unresolved dependencies produced by this gate

If accepted, implementation still requires:

1. an authoritative mechanism for establishing fresh-restoration eligibility;
2. an exact persistence/recovery disposition sufficient to preserve bootstrap authority across interruption;
3. exact implementation sequencing / UI;
4. tests for ordinary startup, fresh restore, cancellation, interruption, and intentionally empty restored families.

These are implementation/capability dependencies, not reasons to block the semantic gate.

## 12.5 Sibling work not required by this gate

The following remain independent partial-order lines:

- PortableMoney lexical/governance closure;
- exact financial-date lexical/year validity;
- Source / TransactionSource provenance portability;
- unknown-field/evolution policy;
- deterministic Portable-ID allocation and emitted ordering.

---

# 13. Authority Budget

## New authority proposed

Only within a truthfully established fresh-install ownership-restoration lifecycle:

- allow explicit fresh-restoration intent to reserve the ordinary reference initialization path before default bootstrap commits;
- require ordinary Category / PaymentMethod / Tag bootstrap to yield while that authority is active;
- require unresolved bootstrap-restoration authority not to disappear silently across process interruption;
- allow explicit pre-restore abandonment to release the hold and return to ordinary initialization;
- treat successful fresh restoration as resolving ordinary reference initialization;
- prevent later family emptiness alone from reauthorizing defaults after initialization has resolved.

## Authority explicitly not granted

This gate does not authorize:

- generic Category deletion;
- generic PaymentMethod deletion;
- generic Tag deletion;
- retirement of arbitrary existing reference records;
- arbitrary existing-store reconciliation;
- inferring bootstrap origin from names, fields, `is_default`, zero references, or seed resemblance;
- stable built-in/default identities;
- per-record provenance fields;
- a specific freshness marker;
- a specific restoration-session model;
- SwiftData schema changes;
- migrations;
- UserDefaults/file/storage selection;
- import-workspace persistence implementation;
- importer/exporter implementation;
- UI;
- Source/provenance behavior;
- full Portable JSON / CSV v1 acceptance.

---

# 14. Assembly Debt and Pressure

## Assembly Pressure

Pressure is high.

The accepted reference-data line now reaches:

```text
owned set
→ accepted

exact schemas
→ accepted

compatibility
→ accepted

existing-store restoration
→ accepted

fresh-install bootstrap disposition
→ required for whole-store round-trip equivalence
```

The Roadmap explicitly requires a fresh-install ownership round trip.

Current startup behavior independently creates destination-only reference state before ordinary import can begin.

Therefore this is a direct blocking assembly, not speculative architecture.

## Assembly Debt

The semantic gate can close without choosing persistence mechanics.

However, it deliberately creates a later exact dependency:

```text
accepted interruption semantics
→ exact persistence/recovery capability admission
→ implementation
```

That dependency must remain visible.

It must not be smuggled into this proposal as a chosen storage mechanism.

---

# 15. Irreversible commitments

If accepted, Portable v1 fresh-install restoration would promise:

1. ordinary reference bootstrap is initialization authority, not a perpetual family-emptiness repair invariant;
2. fresh ownership restoration must acquire authority before ordinary default reference state is canonically established under that initialization;
3. opening a store or observing empty families does not by itself prove freshness;
4. explicit user restore intent is required;
5. record-content resemblance cannot retroactively prove bootstrap provenance;
6. once fresh-restoration bootstrap authority is established, process interruption cannot silently return authority to ordinary bootstrap;
7. successful restoration resolves initialization so intentionally empty restored families remain empty across later launches;
8. cancellation before successful canonical restore may explicitly return authority to ordinary initialization;
9. already-bootstrapped or arbitrary existing state remains non-disposable without separate authority;
10. exact persistence/recovery mechanism remains separately admitted.

A future design that wants ordinary bootstrap to reappear after successful restoration merely because a family is empty would require explicit contract revision.

---

# 16. Proposed exact contract language

The following language is **PROPOSED FOR REVIEW**.

> **Fresh-install restoration bootstrap boundary.** For complete Portable JSON v1 ownership restoration into a genuinely fresh Lumen receiving store, ordinary Category / PaymentMethod / Tag bootstrap is an initialization authority rather than a permanent rule that any empty family must be repopulated. A successful fresh ownership restoration must preserve the source artifact's admitted reference owned sets, including valid empty families, without adding destination-only defaults merely because ordinary startup would otherwise seed them.
>
> **Freshness authority.** The mechanical fact that `LedgerStore.open()` returns before `Seed.bootstrapIfNeeded()` runs is not itself proof that a receiving store is fresh. Family counts, Transaction count, names, exact seed-field equality, `Category.is_default`, relationship counts, and current seed resemblance do not establish fresh-install or bootstrap-origin provenance. Fresh-restoration eligibility must be established by an authoritative lifecycle/workflow fact whose exact implementation is separately admitted.
>
> **Explicit restoration intent.** Fresh-restoration bootstrap authority requires deliberate user entry into a supported Portable ownership-restoration workflow. Store emptiness or file presence alone must not suppress ordinary bootstrap.
>
> **Pre-bootstrap acquisition.** The narrow fresh-install path acquires authority before ordinary Category / PaymentMethod / Tag defaults have been canonically committed for that initialization. Once ordinary defaults are already canonical, this gate grants no authority to identify and delete them from content resemblance; accepted existing-store restoration rules continue to apply unless a separate destructive/reconciliation capability is admitted.
>
> **Coherent reference-bootstrap disposition.** The fresh-restoration bootstrap decision governs the ordinary Category, PaymentMethod, and Tag initialization assembly coherently. Current family-specific emptiness checks must not cause destination-only defaults in one family to leak into a complete fresh ownership restoration while another family is controlled by the source artifact.
>
> **Bootstrap hold.** Once authoritative fresh-restoration eligibility and explicit restore intent have established the fresh-restoration path, ordinary reference bootstrap must yield until the workflow reaches an authoritative terminal outcome. Parse failure, unsupported input, validation failure, or process interruption does not by itself restore bootstrap authority.
>
> **Interruption boundary.** If fresh-restoration bootstrap authority has been established and the workflow may survive process termination, ordinary bootstrap must not silently regain authority after relaunch. The authority state necessary to preserve that behavior must be recoverable across interruption. The exact persistence/recovery mechanism is not selected by this gate and requires separate admission before implementation.
>
> **Successful restoration.** Successful fresh-install ownership restoration resolves ordinary reference initialization. Later startup must not reinsert defaults solely because a restored Category / PaymentMethod / Tag family is empty. Accepted empty-set semantics remain authoritative.
>
> **Explicit abandonment.** Before successful canonical restoration, an explicit user decision to abandon the fresh-restoration path may release the bootstrap hold and return the store to the ordinary initialization path, subject to existing all-or-nothing import/promotion and cleanup responsibilities.
>
> **No inferred provenance or destructive authority.** This gate does not make seed resemblance, exact equality, `is_default`, zero references, zero Transactions, or family emptiness into bootstrap provenance. It does not authorize generic reference deletion, retirement, overwrite, merge, arbitrary existing-store reconciliation, stable built-in identity, per-record provenance fields, schema changes, migrations, or implementation.
>
> **Downstream implementation dependency.** The accepted semantic behavior, if later admitted, requires an exact capability/persistence design that can truthfully establish fresh-restoration eligibility, preserve unresolved bootstrap authority across interruption where required, and remember initialization resolution so intentional empty restored families remain stable. No storage mechanism is chosen here.

---

# 17. Review questions

Independent review should answer:

1. Does repository evidence support treating the current `LedgerStore.open() → Seed.bootstrapIfNeeded()` separation as a usable mechanical seam without treating it as freshness proof?
2. Is ordinary bootstrap correctly modeled as initialization authority rather than a perpetual family-emptiness repair invariant?
3. Does accepted empty-set ownership semantics require intentionally empty restored families to remain empty after later launches?
4. Is explicit user restore intent necessary in addition to fresh-restoration eligibility?
5. Must the fresh-install authority decision occur before ordinary reference defaults become canonical for the narrow non-destructive path?
6. Is it correct that family counts, Transaction count, `is_default`, exact seed equality, and seed resemblance cannot establish freshness or bootstrap provenance?
7. Should Category / PaymentMethod / Tag bootstrap disposition be coherent across all three families for complete fresh ownership restoration?
8. Does process interruption require ordinary bootstrap to remain withheld once fresh-restoration authority has been established?
9. Does that interruption rule create a downstream exact persistence/recovery admission without requiring this proposal to choose a persistence mechanism?
10. Is parse/validation failure correctly distinguished from explicit abandonment?
11. Is explicit abandonment before successful canonical restoration a sufficient semantic event to release the bootstrap hold?
12. Is successful fresh restoration correctly treated as resolving initialization so later emptiness alone cannot trigger reseeding?
13. Is post-bootstrap deletion/reconciliation correctly excluded because current records lack authoritative bootstrap provenance and destructive authority?
14. Are per-record bootstrap provenance and stable built-in identity correctly rejected as unnecessary initial-v1 commitments?
15. Does the proposal preserve the accepted existing-store restoration contract without weakening it?
16. Are money/date lexical closure, Source/provenance, unknown-field/evolution, and deterministic ordering correctly treated as sibling work rather than prerequisites?
17. Does the proposed contract avoid selecting SwiftData/UserDefaults/files/new models while still making recovery requirements explicit?
18. Does any accepted upstream contract require ordinary bootstrap to retain authority after successful restoration merely because a family is empty?
19. Is the narrow scope sufficient to unblock the Roadmap's fresh-install whole-store round-trip requirement without admitting generic reference management/deletion?
20. Are all new irreversible commitments justified by the ownership guarantee rather than implementation convenience?

---

# 18. Review boundary

This proposal is ready for independent review.

It is not accepted merely because it is checked into the repository.

Do not:

- record proposed-contract acceptance;
- implement bootstrap suppression/deferment;
- add a freshness marker;
- add a restore-session model;
- alter SwiftData schema;
- add migrations;
- implement persistence/recovery;
- change `Seed.swift`, `LumenApp.swift`, or `LedgerStore.swift`;
- open generic reference deletion/management;
- open Source/provenance;
- open another Phase 1C gate

without separate acceptance / authorization.

The exact downstream persistence/recovery admission, if required after review acceptance, must be opened separately.
