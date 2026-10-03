# Lumen Portable v1 Exact Reference-Initialization Authority Persistence / Recovery Mechanism Proposal

## Status

**PROPOSED FOR REVIEW — docs-only Phase 1C exact mechanism admission gate.**

Clean starting checkpoint:

`dbb5f5ac3edfda1530474d6007f800c9f577ee47`

Accepted capability dependency:

`LUMEN_PORTABLE_V1_FRESH_INSTALL_REFERENCE_INITIALIZATION_AUTHORITY_RECOVERY_PROPOSAL.md`

Canonical `main` at gate opening:

`d4884e2180e2f867dee415a48375100097a8d415`

Branch:

`docs/phase1c-reference-initialization-authority-mechanism-proposal`

This gate proposes an exact persistence/recovery mechanism for the already-accepted reference-initialization authority capability.

It is **not implementation authority**.

It does not modify production Swift, the SwiftData schema, migrations, existing stores, bootstrap behavior, importer behavior, UI, or canonical data.

Any schema/migration/legacy-compatibility consequence identified here remains separately gated.

---

# 1. Decision question

> **What exact durable mechanism can truthfully establish a genuinely new ledger lifecycle before ordinary bootstrap becomes possible, persist and recover reference-initialization authority across interruption, couple initialization resolution to the canonical ledger effects it governs, and remain safe for pre-capability stores that have no admitted authority proof?**

The first question is deliberately not:

> SwiftData, UserDefaults, or a file?

The first question is:

```text
authoritative new ledger lifecycle begins
        ↓
what must become durably authoritative?
        ↓
process terminates before / during
first authority establishment
        ↓
what may recovery truthfully conclude?
        ↓
how is that distinguishable from
a pre-capability legacy/unproven store?
        ↓
only then evaluate mechanism families
```

This ordering prevents storage convenience from defining authority semantics by accident.

---

# 2. Accepted requirements consumed without reopening

This mechanism gate consumes the accepted capability at the clean `dbb5f5ac...` checkpoint.

It must preserve:

- positive lifecycle provenance;
- ledger/store lifecycle coupling;
- non-authorizing unknown/unproven state;
- fresh-restoration hold durability independent of workspace existence;
- mutual exclusion of active ordinary-bootstrap and fresh-restoration authority;
- crash-safe permitted handoffs before reference initialization resolves;
- coherent Category / PaymentMethod / Tag ordinary initialization;
- effect/proof crash consistency;
- reference-confirmation resolution retention;
- fresh-install authority exhaustion after resolution;
- new-lifecycle noninheritance.

Preserve:

```text
absence of authority proof
!=
new-lifecycle establishment

family emptiness
!=
bootstrap authority

workspace/file existence
!=
fresh-restoration hold authority

accepted capability
!=
persistence mechanism

proposed mechanism
!=
implementation authorization
```

The mechanism must not weaken any already-accepted reference-restoration, bootstrap-state, confirmation-boundary, or existing-store semantics.

---

# 3. Primary mechanism problem — the first-write crash paradox

The hardest boundary occurs before later hold/resolution recovery exists:

```text
genuinely new physical ledger store is about to be created
        ↓
process terminates before
lifecycle-authority proof becomes durable
```

On a later launch, a naive implementation may observe:

```text
physical store exists
+
no authority proof
```

That observation cannot authorize freshness.

The same broad observation may describe:

- a pre-capability historical store;
- a new store whose first authority write was interrupted;
- a damaged/corrupt authority representation;
- an unsupported future compatibility state.

Therefore:

```text
store exists
+
authority proof absent
!=
fresh
```

A mechanism that simply classifies every such case as permanently unknown/unproven is safe from unauthorized mutation but is not a sufficient product mechanism for a normal new installation.

The mechanism must either:

1. establish positive lifecycle authority **before** the store can enter the ambiguous state; or
2. provide another recoverable positive proof that distinguishes the interrupted new-lifecycle creation from legacy/unproven state.

This proposal selects the first strategy.

---

# 4. Repository evidence

## 4.1 Current startup order

Current production startup is:

```text
LedgerStore.open()
        ↓
Seed.bootstrapIfNeeded()
        ↓
container exposed to UI
```

That ordering exposes a useful mechanical seam before current reference defaults are inserted.

It is not freshness proof.

## 4.2 Current LedgerWrite / Seed evidence and its limit

Current `Seed.bootstrapIfNeeded` calculates independent family emptiness:

```text
Category count == 0?
PaymentMethod count == 0?
Tag count == 0?
```

and inserts whichever missing subset is needed inside one `LedgerWrite.perform`.

`LedgerWrite.perform` performs one `ModelContext.save()` when its mutation completes and rolls back pending context state on a thrown failure.

Therefore current repository evidence establishes:

```text
one current application-level
ModelContext.save boundary
```

It does **not** establish:

```text
one ModelContext.save
=
proven process-termination atomicity
```

and current conditional family seeding does **not** implement the accepted future coherent initialization semantics.

For example:

```text
Category count == 0
PaymentMethod count > 0
Tag count == 0
        ↓
current Seed
→ inserts Category + Tag defaults only
```

The accepted future authority model instead treats ordinary reference initialization as one coherent Category / PaymentMethod / Tag initialization assembly.

Preserve:

```text
current save boundary
!=
proven crash-atomic authority boundary

current conditional seeding
!=
accepted coherent initialization semantics
```

## 4.3 Current store and schema

`LedgerStore` currently constructs an unversioned SwiftData `Schema` containing:

- Transaction;
- TransactionSource;
- Category;
- PaymentMethod;
- Tag;
- UserProfile.

The source explicitly preserves the unversioned baseline and states that versioned-schema adoption requires authentic baseline-store compatibility testing first.

No current model represents reference-initialization authority.

## 4.4 Current UserDefaults domain

`AppState` persists onboarding, reporting currency, and timezone through `UserDefaults.standard`.

That is an app-preference domain.

It has no admitted ledger-lifecycle coupling and does not participate in the SwiftData save that establishes canonical ledger effects.

Physical-device Phase 1A evidence supports ordinary installed-product preference persistence, while older hosted-run behavior remains separately characterized.

Neither fact grants UserDefaults reference-initialization authority.

## 4.5 UserProfile is not an authority record

`UserProfile` is an existing SwiftData model for profile/settings semantics.

Current repository evidence does not establish:

- exactly one UserProfile per ledger;
- bootstrap creation of UserProfile;
- reference-initialization authority semantics on UserProfile;
- migration-free permission to add authority fields.

Reusing UserProfile would therefore be a semantic authority change plus persisted-model evolution, not free storage reuse.

## 4.6 Phase 1A compatibility infrastructure

Phase 1A established an executable historical-producer compatibility workflow:

```text
historical producer
→ durable historical state
→ candidate-install continuity
→ supported current read
→ legitimate current mutation
→ relaunch durability
```

That infrastructure is strong evidence that future migration/compatibility candidates can be tested against authentic historical state.

It is **not** evidence that a future schema migration already works.

The accepted Phase 1A closure changed no persisted model and explicitly preserves the rule that future persisted-model changes are migrations requiring their own compatibility evidence.

## 4.7 Existing filesystem discipline

Phase 1B already has Lumen-owned Application Support storage primitives that:

- distinguish regular files/directories/symlinks with `lstat`;
- support atomic file replacement;
- use narrow controlled namespaces;
- fail closed on unsafe node kinds;
- separate filesystem existence from semantic authority.

Those primitives are evidence that Lumen can implement a disciplined internal control-file namespace.

Phase 1B evidence authority does **not** automatically transfer to this mechanism. A reference-initialization lifecycle witness needs its own admitted semantics and namespace.

---

# 5. Supported-platform evidence

This proposal uses public Apple platform behavior only as evidence, not as permission to infer undocumented guarantees.

Apple SwiftData documentation establishes:

- `ModelContainer` manages schema and underlying persistent storage;
- `ModelContext.save()` writes pending inserts, changes, and deletes to persistent storage;
- `ModelContext.transaction(block:)` runs a mutation closure and then writes pending changes;
- SwiftData History groups one or more persisted model changes into chronological transactions at boundaries such as a model-context write;
- `ModelConfiguration.url` exposes the configured on-disk location;
- `SchemaMigrationPlan`, `VersionedSchema`, and `MigrationStage` exist for deliberate schema evolution;
- `ModelContainer.storeIdentifier(forConfigurationNamed:)` exposes an on-disk store identifier, but that identifier is not itself documented as Lumen lifecycle provenance.

Sources:

- https://developer.apple.com/documentation/swiftdata/modelcontainer
- https://developer.apple.com/documentation/swiftdata/modelcontext
- https://developer.apple.com/documentation/swiftdata/fetching-and-filtering-time-based-model-changes
- https://developer.apple.com/documentation/swiftdata/modelconfiguration
- https://developer.apple.com/documentation/swiftdata/schemamigrationplan
- https://developer.apple.com/documentation/swiftdata/migrationstage

Apple Foundation documentation describes `UserDefaults` as persistent app/system settings storage organized into defaults domains.

Source:

- https://developer.apple.com/documentation/foundation/userdefaults

The platform evidence does **not** by itself prove the exact process-termination behavior required for Lumen's authority/effect commit boundary.

That property requires executable characterization before this mechanism can become implementation-authorizing.

---

# 6. Minimum exact mechanism requirements

A candidate mechanism is sufficient only if it can establish all of the following.

## 6.1 Positive origin

A genuinely new ledger lifecycle receives an authoritative positive origin before ordinary reference bootstrap may execute.

## 6.2 Pre-open recovery

The app can recover the first-write lifecycle state **before blindly opening/creating a replacement SwiftData store** when that would erase the distinction between:

- a new lifecycle being established;
- a legacy store;
- a missing/replaced expected store.

## 6.3 Ledger coupling

Ongoing initialization authority is durably coupled to the same ledger lifecycle whose references it governs.

## 6.4 Effect/proof coupling

When ordinary initialization or imported reference confirmation resolves initialization, canonical reference effects and the durable proof of resolution must share one admitted atomic/replay-safe authority boundary.

## 6.5 Hold independence

Fresh-restoration hold authority must be durably representable before a valid resumable import workspace exists.

## 6.6 Mutual exclusion

No recoverable state may make both ordinary-bootstrap authority and fresh-restoration hold authority active for the same initialization lifecycle.

## 6.7 Safe handoff

A released authority cannot transfer to the competing path until the previous authority's admitted terminal conditions are durably satisfied.

## 6.8 Terminal resolution

Resolved reference initialization must survive:

- relaunch;
- workspace cleanup;
- later Category / PaymentMethod / Tag edits;
- later intentional family emptiness.

## 6.9 Legacy safety

A pre-capability store with no admitted mechanism proof must become:

```text
unknown / unproven
```

not fresh.

## 6.10 New-lifecycle noninheritance

A genuinely new ledger lifecycle must not inherit an old lifecycle's hold/resolved authority merely because app-global files or preferences survived.

## 6.11 Reset/store-loss behavior

Unexpected loss/replacement of a previously bound ledger must not silently become a new authorized bootstrap lifecycle.

## 6.12 Testability

Every authority transition and interruption window must be executable in isolated tests/diagnostics without relying on private SwiftData/Core Data table names.

---

# 7. Candidate mechanism comparison

## 7.1 SwiftData control state only

Candidate:

```text
new SwiftData authority-control model
→ all lifecycle/hold/resolution state
```

Strengths:

- ledger co-location;
- potential participation in the same save as canonical reference effects;
- natural relaunch recovery;
- clear durable ownership.

Primary blocker:

```text
new store created
→ crash before first control record save
→ store exists + control absent
```

That state is not distinguishable from a pre-capability/unproven store by absence alone.

A SwiftData-only solution therefore needs some separately proven lifecycle-establishment mechanism or migration fact.

It is not sufficient by itself.

## 7.2 UserDefaults-only authority state

Candidate:

```text
UserDefaults
→ lifecycle / hold / resolved authority
```

Strengths:

- simple durable app-level state;
- no SwiftData model change.

Problems:

- current semantics are app preferences, not ledger control;
- no inherent binding to one ledger lifecycle;
- survives independently from the SwiftData store;
- does not share the canonical SwiftData effect/proof save boundary;
- stale app-domain state can outlive a deleted/replaced ledger.

It is not sufficient as the sole mechanism.

## 7.3 Sidecar/file-only authority state

Candidate:

```text
Application Support control file
→ all lifecycle / hold / resolved authority
```

Strengths:

- can exist before SwiftData store creation;
- can solve positive lifecycle origin;
- deterministic controlled namespace is feasible.

Problem:

Canonical reference effects remain in SwiftData.

A file-only authority model would require a two-durable-system protocol for every resolution transition:

```text
SwiftData canonical effects
+
sidecar resolved proof
```

without one shared commit authority.

That recreates the exact split effect/proof failure the accepted capability is intended to eliminate.

It is not sufficient as the sole ongoing authority mechanism.

## 7.4 Existing UserProfile reuse

Candidate:

```text
UserProfile
→ add initialization authority fields
```

Problems:

- UserProfile owns profile/settings semantics;
- no admitted singleton invariant;
- no current startup creation guarantee;
- same first-write problem as any in-store-only record;
- adding fields is a persisted-model change and therefore a migration.

No evidence supports overloading UserProfile.

Reject as the proposed authority representation.

## 7.5 Platform/store metadata only

Candidate inputs include:

- `ModelConfiguration.url`;
- SwiftData store identifier;
- filesystem store presence.

These are useful observations.

They do not by themselves encode:

- explicit fresh-restoration hold;
- resolved reference initialization;
- abandonment handoff;
- positive distinction between old and new stores in all required cases.

Platform metadata may support validation but is not sufficient authority state.

## 7.6 SwiftData History as permanent authority proof

SwiftData History can identify chronological store transactions and transaction authors.

However history is operational change history:

- applications may delete old history;
- history tokens can expire;
- it does not itself represent the accepted stable lifecycle state.

It is useful characterization evidence and may support diagnostics.

It should not become the permanent semantic authority record for resolved initialization.

## 7.7 Split lifecycle-witness + ledger-control assembly

Candidate:

```text
pre-store durable lifecycle witness
        +
ledger-resident authority-control record
```

This separates two different responsibilities:

```text
lifecycle witness
→ proves positive origin before store creation
→ prevents silent replacement/new-lifecycle inference

ledger control
→ owns ongoing eligible / fresh-hold / resolved state
→ can participate with canonical reference effects
  in the same ledger transaction
```

This is the minimum candidate that directly addresses both:

- the first-write origin paradox; and
- later canonical effect/proof coupling.

**This is the proposed mechanism family.**

---

# 8. Proposed exact mechanism assembly

The proposal consists of two internal control records with distinct authority roles.

## 8.1 Layer A — LedgerLifecycleWitnessV1

A small Lumen-owned internal control record stored outside SwiftData in controlled Application Support storage.

Its sole authority purpose is:

> establish and preserve positive ledger-lifecycle origin across the period before the ledger-resident authority record can safely become authoritative.

It is not:

- portable data;
- a user preference;
- a reference record;
- an import workspace;
- evidence/provenance;
- canonical financial state.

## 8.2 Layer B — ReferenceInitializationAuthorityControlV1

A dedicated internal ledger-resident control record stored in the same SwiftData store as Category / PaymentMethod / Tag.

Its authority purpose is:

> represent the ongoing reference-initialization authority state of the bound ledger lifecycle and participate in the same canonical ledger transaction that resolves initialization.

It is not:

- UserProfile state;
- a portable export record;
- a Transaction;
- an import-session record;
- an arbitrary workflow log.

## 8.3 Why two layers

Preserve:

```text
pre-store positive origin responsibility
!=
ongoing canonical authority responsibility
```

Trying to force both into one substrate either:

- leaves the pre-store origin paradox unresolved; or
- leaves later canonical effect/proof state split across two durable systems.

The split is therefore an Assembly Map result, not an abstraction preference.

---

# 9. Proposed LedgerLifecycleWitnessV1 semantics

## 9.1 Semantic shape

The internal record should carry exactly the semantic information needed to establish/bind one ledger lifecycle:

```json
{
  "format": "lumen-ledger-lifecycle-authority",
  "version": 1,
  "lifecycle_id": "550e8400-e29b-41d4-a716-446655440000",
  "phase": "establishing"
}
```

or:

```json
{
  "format": "lumen-ledger-lifecycle-authority",
  "version": 1,
  "lifecycle_id": "550e8400-e29b-41d4-a716-446655440000",
  "phase": "bound"
}
```

Proposed exact semantics:

- `format` is the literal internal token `lumen-ledger-lifecycle-authority`;
- `version` is integer `1`;
- `lifecycle_id` is a canonical UUID string generated once for the lifecycle;
- `phase` is exactly `establishing` or `bound`.

No timestamp is needed for authority.

No human-facing name is needed.

No portable/public identity meaning is granted.

## 9.2 Storage domain

The witness belongs in a deterministic Lumen-controlled Application Support control namespace.

It must not live in:

- temporary storage;
- the Phase 1B retained-evidence namespace;
- UserDefaults;
- Documents;
- an import-workspace directory.

The exact path spelling may remain an implementation-plan detail, but the namespace must be dedicated to ledger lifecycle control and must not collide with evidence/import cleanup authority.

## 9.3 Whole-record integrity

A partial, malformed, unsupported-version, unexpected-node-kind, or unreadable witness is:

```text
unknown / unproven
```

not freshness.

The implementation must use a whole-record replacement/creation discipline whose process-interruption behavior is independently characterized.

Existing Phase 1B filesystem helpers are reusable implementation evidence, not automatically admitted authority.

---

# 10. Pre-open lifecycle establishment protocol

A future implementation must determine the expected SwiftData store location using supported configuration behavior **before it permits a new store to be opened/created**.

The following decision table is proposed.

## 10.1 No witness + no existing configured store

```text
witness = absent
configured store = absent
        ↓
eligible to establish a genuinely new ledger lifecycle
        ↓
create durable witness:
phase = establishing
lifecycle_id = new UUID
        ↓
ONLY AFTER witness establishment succeeds
may Lumen open/create the SwiftData store
```

The authoritative event is the successful witness establishment.

It is not the absence of the store by itself.

## 10.2 No witness + existing store

```text
witness = absent
configured store = present
        ↓
legacy / unproven lifecycle
        ↓
NO inferred fresh authority
NO ordinary bootstrap authority
```

The exact compatibility/migration/user-resolution path remains downstream.

## 10.3 Establishing witness + no store

```text
valid establishing witness
+
store absent
        ↓
interrupted new-lifecycle establishment
        ↓
may continue creating the store
under the same lifecycle_id
```

This is the first-write crash recovery path.

The positive authority comes from the already-durable witness.

## 10.4 Establishing witness + store present

The store may have been created immediately before process termination.

Lumen may open it only to continue/recover the already-authorized lifecycle establishment.

Before any reference bootstrap:

- fetch the authority-control record;
- require zero or one valid matching control record;
- reject/make unknown any mismatch/conflict.

A missing control record in this exact state does **not** mean freshness by absence.

The establishing witness is the positive origin that permits creation of the initial control record.

## 10.5 Bound witness + expected store present

Open the store.

Require a valid matching ledger-resident control record.

If the control is missing, duplicated, malformed, or carries another lifecycle ID:

```text
authority = unknown / unproven
```

No bootstrap authority is inferred.

## 10.6 Bound witness + expected store absent

Do **not** silently create a replacement store.

Treat as a missing/replaced-ledger failure state requiring separately admitted recovery/reset behavior.

Preserve:

```text
old bound witness
+
missing store
!=
new ledger lifecycle
```

## 10.7 Invalid witness

Malformed, unsupported, unreadable, or unsafe filesystem state is non-authorizing.

Do not fall back to:

- family counts;
- Transaction counts;
- default-name resemblance;
- store-file age;
- onboarding state.

---

# 11. Proposed ledger-resident authority control

## 11.1 Semantic record

The proposed internal control record needs only:

```text
control_key
lifecycle_id
reference_initialization_state
```

where:

```text
control_key
= fixed internal singleton key
  for reference-initialization authority v1

lifecycle_id
= canonical UUID
  matching LedgerLifecycleWitnessV1

reference_initialization_state
∈ {
    eligible,
    fresh_restoration_hold,
    resolved
  }
```

No timestamp is authority-bearing.

No workspace ID is required.

No Portable ID is involved.

No source/provenance field is involved.

## 11.2 Singleton invariant

Exactly one valid authority-control record may govern one bound ledger lifecycle.

Zero, multiple, malformed, or lifecycle-mismatched records are non-authorizing except for the narrowly admitted:

```text
witness = establishing
+
store created under that witness
+
control absent
```

recovery case used to finish first establishment.

Whether the eventual SwiftData schema enforces uniqueness or the application enforces it is a downstream schema/admission question.

## 11.3 Unknown is not a persisted positive state

`unknown / unproven` is a recovery classification when Lumen cannot establish a valid authority assembly.

It is not necessary to persist an `unknown` token into an ambiguous legacy store merely to describe uncertainty.

That avoids turning absence into write authority.

---

# 12. Initial binding protocol and interruption matrix

The proposed new-lifecycle establishment sequence is:

```text
1. construct supported store configuration
2. inspect expected store presence
3. require: witness absent + store absent
4. generate lifecycle_id T
5. durably create witness(T, establishing)
6. open/create SwiftData store
7. create authority control(T, eligible)
8. commit control durably
9. re-read/validate control(T, eligible)
10. atomically replace witness phase:
    establishing → bound
11. re-read/validate bound witness
12. only then expose ordinary/fresh initialization choices
```

Crash windows:

### Before step 5 completes

The store must not have been opened/created.

Recovery can retry new-lifecycle witness creation.

### After step 5, before step 6

```text
establishing witness
+
no store
```

Recovery continues store creation for T.

### After store creation, before control commit

```text
establishing witness T
+
store exists
+
control absent
```

Recovery may finish creating control(T, eligible).

### After control commit, before witness becomes bound

```text
establishing witness T
+
store exists
+
control(T, eligible)
```

Recovery validates the match and completes witness binding.

### After bound witness commit

Normal startup requires:

```text
bound witness T
+
expected store exists
+
exactly one valid control with lifecycle_id T
```

Any conflicting assembly fails closed.

---

# 13. Ongoing authority-state transitions

Once the witness is bound, ongoing initialization authority belongs to the ledger-resident control record.

The witness must not mirror mutable hold/resolved state.

That prevents two independent stores from both claiming current authority.

## 13.1 Eligible → fresh-restoration hold

Explicit restore intent against a truthfully eligible lifecycle requires:

```text
control = eligible
        ↓
durable ledger save
        ↓
control = fresh_restoration_hold
```

The save must succeed before any workspace/file is treated as having fresh-restoration promotion authority.

The hold may exist with no valid workspace.

## 13.2 Eligible → ordinary initialization resolved

Ordinary bootstrap must stop using independent per-family emptiness as the completion contract.

The proposed authority boundary is:

```text
control = eligible
        ↓
ONE admitted ledger transaction containing:
  complete authorized Category initialization
  complete authorized PaymentMethod initialization
  complete authorized Tag initialization
  control → resolved
        ↓
commit
```

Success means all four semantic effects become durable together.

Failure/interruption must recover as either:

```text
eligible
+
no canonical ordinary-initialization effects
```

or:

```text
resolved
+
complete canonical ordinary-initialization effects
```

A split state is invalid.

## 13.3 Fresh hold → resolved through reference confirmation

When imported Category / PaymentMethod / Tag owned sets are canonically confirmed:

```text
control = fresh_restoration_hold
        ↓
same admitted canonical confirmation boundary:
  complete imported reference effects
  control → resolved
        ↓
commit
```

If reference entities use a separate confirmation boundary from Transactions, that reference boundary carries the resolution update.

If references and Transactions share one confirmation boundary, the resolution update belongs in that combined boundary.

## 13.4 Fresh hold → eligible through explicit abandonment

Only while reference initialization remains unresolved:

```text
fresh_restoration_hold
+
associated workspace promotion authority,
if any, durably terminal/nonpromotable
        ↓
control → eligible
```

Ordering is intentionally one-way:

```text
workspace promotion authority terminal first
        ↓
hold release second
```

Crash after workspace terminalization but before control release leaves an over-conservative hold that recovery may finish releasing.

Crash after control release cannot leave a promotable workspace because the workspace terminal condition was required first.

## 13.5 Resolved is terminal for fresh-install authority

```text
resolved
→ no transition to eligible
→ no transition to fresh_restoration_hold
```

Later existing-store restoration does not reuse fresh-install authority.

Later family emptiness does not alter resolved state.

---

# 14. Process-termination atomicity remains an evidence requirement

The proposed ledger-control mechanism depends on one crucial property:

> canonical reference effects and the authority-control resolution update placed in one SwiftData persistent transaction must not recover after process termination as a split durable outcome.

Current repository evidence does not prove that property.

Apple documentation establishes a save/transaction boundary and grouped history transactions, but this proposal does not convert that into an untested process-crash guarantee.

Before this mechanism is accepted for implementation, executable characterization must test supported product environments at least at:

```text
before transaction/save
during transaction/save
immediately after save returns
after container/process termination
after reopen
```

for both:

1. ordinary reference initialization + `control → resolved`;
2. imported reference confirmation + `control → resolved`.

Required observable result:

```text
all effects + resolved control
OR
no effects + prior control state
```

Never:

```text
some reference effects
+
prior/unresolved control

or

resolved control
+
missing authorized reference effects
```

If supported-environment characterization cannot establish this property, the proposed mechanism must return to design and adopt an equivalent replay-safe authority mechanism.

Do not silently weaken the accepted all-or-nothing boundary.

---

# 15. Legacy / unproven store boundary

This mechanism gate defines the safe classification:

```text
pre-capability store
+
no admitted lifecycle witness/control proof
        ↓
unknown / unproven
        ↓
NO inferred ordinary bootstrap authority
NO inferred fresh-restoration eligibility
```

It does **not** automatically decide how that historical store becomes compatible.

Possible future treatments include:

- schema migration;
- compatibility control record;
- explicit user resolution;
- one-time lifecycle conversion;
- another separately admitted transition.

If the selected mechanism requires one of those treatments, that is a downstream compatibility/migration admission.

Preserve:

```text
mechanism gate must define
safe legacy disposition
!=
mechanism gate must solve
legacy migration
```

The Phase 1A historical-producer workflow is the required testing foundation for any future persisted-model/schema compatibility proposal.

It is not prior proof of that future migration.

---

# 16. New-lifecycle loss, reset, and noninheritance

The bound witness exists partly to prevent silent ledger replacement.

## 16.1 Bound witness + missing store

Do not create a new ledger automatically.

This state may represent:

- deletion;
- corruption;
- platform/storage loss;
- an unsupported reset;
- external intervention.

It is not fresh-install authority.

## 16.2 Explicit new-ledger/reset behavior

Any future explicit destructive reset/new-ledger capability must:

- terminally retire old lifecycle authority;
- ensure old witness/control authority cannot govern the new store;
- establish a new lifecycle through the same positive-origin protocol;
- use a new lifecycle ID.

The exact destructive reset operation is outside this gate.

## 16.3 App reinstall / genuinely new application container

When both the controlled lifecycle witness and configured ledger store are genuinely absent in a new application container, the normal positive establishment protocol may create a new lifecycle.

The authority comes from the new witness creation, not from treating missing old state as proof.

---

# 17. Why UserDefaults is not selected as the lifecycle witness

A preference key could technically exist before SwiftData store creation.

It is not selected because:

- current UserDefaults semantics are app/settings scoped;
- the witness is ledger-lifecycle authority, not a preference;
- app defaults can survive or reset independently from a store;
- current repository history already contains environment-specific UserDefaults lifecycle ambiguity;
- Lumen already has a more explicit controlled Application Support filesystem discipline for authority-sensitive local artifacts.

This does not mean UserDefaults is unreliable in ordinary use.

It means its current responsibility boundary is the wrong one for this authority.

---

# 18. Why SwiftData storeIdentifier is not selected as lifecycle authority

A documented SwiftData store identifier may be useful for diagnostics or consistency checking.

It is not selected as the normative lifecycle ID because:

- it is obtained after a store exists;
- it does not solve the pre-store first-write origin paradox;
- it does not represent eligible/hold/resolved state;
- Lumen does not need to expose a platform-derived identity as public or durable product semantics.

The Lumen lifecycle ID is internal and Lumen-owned.

A future implementation may record/store-correlate platform identifiers only if separate evidence shows value and the admission is updated accordingly.

---

# 19. Assembly Map

## 19.1 Accepted prerequisites

- reference owned-set semantics;
- reference record schemas;
- reference compatibility/export disposition;
- ordinary reference restoration/matching/conflict semantics;
- fresh-install bootstrap-state disposition;
- accepted reference-initialization authority persistence/recovery capability;
- confirmation-boundary all-or-nothing/replay-safety responsibilities;
- Phase 1A durable persistence and historical-store compatibility evidence;
- Phase 1B controlled Application Support filesystem discipline as implementation evidence only.

## 19.2 New proposed assembly

```text
LedgerLifecycleWitnessV1
(pre-store positive lifecycle origin)
        +
ReferenceInitializationAuthorityControlV1
(ledger-resident ongoing authority)
        +
same-ledger effect/proof transaction
(for resolution)
```

## 19.3 Known consumers

- startup bootstrap disposition;
- fresh-install Portable reference restoration;
- ordinary reference initialization;
- reference confirmation recovery;
- future import-workspace abandonment ordering.

## 19.4 Downstream dependencies exposed

If accepted, implementation still requires separately authorized work for any needed:

- SwiftData schema/version change;
- migration plan;
- historical-store compatibility conversion;
- exact control-model schema;
- lifecycle-witness physical path/codec implementation;
- process-termination atomicity validation;
- import-workspace persistence mechanism;
- production bootstrap refactor;
- UI.

## 19.5 Possible split discovered by this gate

The mechanism is intentionally a two-part assembly:

```text
positive lifecycle establishment mechanism
!=
ongoing ledger authority-state mechanism
```

This split is accepted as a design possibility rather than hidden behind one vague "persistence" abstraction.

---

# 20. Authority Budget

## New authority proposed

This gate proposes only the following mechanism authority:

1. Lumen may establish a new internal ledger lifecycle by durably creating a valid `LedgerLifecycleWitnessV1` **before** opening/creating a previously absent configured ledger store.
2. That witness may authorize continuation of the interrupted first-establishment sequence for its lifecycle ID.
3. A dedicated ledger-resident control record may own ongoing reference-initialization authority for that lifecycle.
4. A matching bound witness + ledger control may establish the normal startup authority assembly.
5. Ongoing states are exactly:
   - eligible;
   - fresh_restoration_hold;
   - resolved.
6. Resolution proof may become authoritative only in the same admitted ledger transaction as the canonical reference effects that resolve initialization.
7. A bound witness with a missing/replaced store withholds automatic new-lifecycle authority.
8. A missing witness with an existing store classifies the lifecycle as unknown/unproven rather than fresh.

## Authority not granted

This proposal does **not** authorize:

- production code;
- creation of either record in production;
- a SwiftData model/schema change;
- `VersionedSchema`;
- `SchemaMigrationPlan`;
- a migration;
- legacy-store conversion;
- a UserProfile change;
- UserDefaults authority keys;
- a persistent import workspace;
- a workspace schema;
- reference deletion/retirement;
- destructive reset;
- a user-facing recovery flow;
- full Portable JSON / CSV v1 acceptance;
- Source/provenance changes;
- multi-process ledger writers;
- cloud/sync authority.

---

# 21. Irreversible commitments if accepted

Acceptance would freeze these internal semantics:

1. positive new-lifecycle origin occurs before store creation can erase new-versus-legacy distinction;
2. lifecycle origin is represented outside the SwiftData store;
3. ongoing reference-initialization authority is represented inside the ledger store;
4. the two records share a Lumen-owned internal lifecycle UUID;
5. witness phases are `establishing` and `bound`;
6. ledger control states are `eligible`, `fresh_restoration_hold`, and `resolved`;
7. unknown/unproven is a non-authorizing recovery classification, not inferred freshness;
8. ordinary initialization resolves only with the complete coherent three-family effect set;
9. reference-confirmation resolution proof shares the canonical reference-effect boundary;
10. a bound witness prevents silent recreation of a missing ledger;
11. legacy stores with no admitted proof remain unknown pending separate compatibility admission;
12. lifecycle IDs are internal only and never become Portable identity.

Acceptance would **not** yet freeze:

- exact Swift type names;
- exact filesystem path string;
- JSON encoder implementation;
- SwiftData attribute annotations;
- database uniqueness mechanism;
- migration stages;
- UI text;
- compatibility UX.

---

# 22. Counterexamples

## 22.1 New store crash before witness

```text
store not opened
witness write fails/interrupted
```

No store has entered the ambiguous state.

Retry establishment.

## 22.2 New store crash after witness, before store

```text
establishing witness T
store absent
```

Continue creating the store for T.

## 22.3 New store crash after store, before control

```text
establishing witness T
store present
control absent
```

The positive witness, not control absence, authorizes completion of control creation.

## 22.4 Legacy store

```text
witness absent
store present
```

Unknown/unproven.

No fresh authority.

## 22.5 Bound lifecycle loses store

```text
bound witness T
store absent
```

Do not create a replacement and inherit T.

Fail closed.

## 22.6 Bound store loses control

```text
bound witness T
store present
control absent
```

Unknown/unproven.

Do not infer eligible from absence.

## 22.7 Family later becomes empty

```text
control = resolved
Tag count = 0
```

Still resolved.

No reseeding authority.

## 22.8 Stale workspace remains after abandonment

The hold cannot release until workspace promotion authority is durably terminal.

Therefore a stale physical workspace file cannot regain promotion authority after control returns to eligible.

## 22.9 Sidecar alone says resolved

Impossible under the proposed authority model.

The witness does not carry mutable reference-initialization state.

---

# 23. Required characterization / validation before implementation admission

The mechanism proposal requires an executable evidence plan covering at least:

## 23.1 Lifecycle witness

- successful whole-record creation;
- interruption during initial creation;
- interruption during `establishing → bound` replacement;
- malformed/truncated record;
- unsupported version;
- unexpected filesystem node kind;
- bound witness with missing store;
- no witness with historical store.

## 23.2 Initial control binding

- witness created / store absent;
- store created / control absent;
- control saved / witness still establishing;
- duplicate control records;
- lifecycle-ID mismatch.

## 23.3 SwiftData effect/proof atomicity

Representative interruption at:

- immediately before save;
- while save is executing;
- immediately after save returns;
- process termination and reopen.

For:

- coherent ordinary reference initialization + resolved control;
- imported reference confirmation + resolved control.

## 23.4 Hold transitions

- eligible → fresh hold;
- hold survives relaunch without workspace;
- explicit abandonment ordering;
- crash after workspace becomes nonpromotable but before hold release.

## 23.5 Legacy compatibility

Using the authentic Phase 1A historical producer:

- old store is not classified fresh by missing new proof;
- no automatic bootstrap occurs from unknown state;
- any proposed migration/compatibility treatment is tested only after separate authorization.

## 23.6 New-lifecycle noninheritance

- bound witness + missing store does not recreate automatically;
- a separately authorized explicit new-ledger operation would require a new lifecycle ID.

No test may depend on private SwiftData/Core Data table names as the product contract.

---

# 24. Proposed exact contract language

The following is **PROPOSED FOR REVIEW**.

> **Two-layer mechanism.** Reference-initialization authority persistence/recovery uses two distinct internal authority layers: a pre-store `LedgerLifecycleWitnessV1` that establishes positive new-ledger lifecycle origin, and a ledger-resident `ReferenceInitializationAuthorityControlV1` that owns ongoing eligible / fresh-restoration-hold / resolved state. Neither layer may silently assume the other's authority.
>
> **Positive establishment.** When the configured ledger store and lifecycle witness are both absent, Lumen may establish a genuinely new ledger lifecycle only by durably creating a valid `LedgerLifecycleWitnessV1` before opening/creating the SwiftData store. Store absence alone is not lifecycle authority.
>
> **First-write recovery.** A valid witness in `establishing` phase authorizes continuation of that same lifecycle establishment after interruption. It may authorize creation/recovery of the matching initial ledger authority control even when the store now exists, because the witness was established before store creation. Control absence alone never grants that authority.
>
> **Legacy disposition.** Existing store + no admitted lifecycle witness is unknown/unproven. It grants neither ordinary-bootstrap authority nor fresh-restoration eligibility. Exact legacy conversion/migration remains separately gated.
>
> **Bound assembly.** Normal startup authority requires a valid bound lifecycle witness and exactly one valid ledger authority control carrying the same lifecycle ID. Missing, duplicate, malformed, unsupported, or mismatched authority state is non-authorizing.
>
> **Witness scope.** The lifecycle witness owns positive lifecycle origin/binding only. It must not mirror ongoing eligible/hold/resolved reference-initialization state.
>
> **Ledger control states.** Ongoing reference-initialization state is exactly `eligible`, `fresh_restoration_hold`, or `resolved`. Unknown/unproven is a recovery classification, not inferred eligible state.
>
> **Ordinary initialization boundary.** Ordinary reference initialization resolves only through one admitted ledger transaction that establishes the complete authorized Category / PaymentMethod / Tag initialization assembly and changes the ledger authority control to `resolved`. Current family-by-family emptiness repair is not the future resolution contract.
>
> **Reference-confirmation boundary.** Canonical confirmation of imported reference owned sets changes the authority control to `resolved` within the same canonical confirmation boundary as the reference effects that establish those sets.
>
> **Hold acquisition.** Explicit restore intent may change an eligible control to `fresh_restoration_hold` before a valid import workspace exists. Workspace/file existence never creates the hold.
>
> **Hold release.** A fresh-restoration hold may return to eligible only while initialization remains unresolved and only after any associated workspace promotion authority is durably terminal/nonpromotable.
>
> **Resolution terminality.** `resolved` exhausts fresh-install initialization authority for that ledger lifecycle. Later family emptiness, workspace cleanup, or existing-store restoration does not transition it back to eligible.
>
> **Missing bound store.** A bound lifecycle witness whose expected ledger is missing does not authorize automatic creation of a replacement ledger. New-ledger/reset recovery requires separate authority.
>
> **Process-termination proof requirement.** Before implementation admission, supported-environment characterization must establish that one proposed ledger effect/proof transaction recovers after process termination as all authorized canonical effects plus resolved control, or as no authorized canonical effects plus the prior control state. A split durable outcome is not admitted.
>
> **Internal identity.** The lifecycle UUID is an internal ledger-control identity only. It is not Portable identity, user identity, sync identity, source identity, or public API.
>
> **Mechanism admission does not admit migration.** If implementing the ledger control requires versioned SwiftData schema, migration, historical-store conversion, compatibility markers, or explicit legacy user resolution, those remain separately authorized downstream admissions.

---

# 25. Independent-review questions

1. Does the proposal solve the first-write crash paradox through positive pre-store establishment rather than missing-state inference?
2. Is the lifecycle witness created before any action that can create the configured SwiftData store?
3. Does the proposal distinguish store absence from the authoritative act of creating the witness?
4. Is `establishing` sufficient to recover a new lifecycle without making legacy store absence/presence heuristics authoritative?
5. Does a bound witness prevent silent ledger replacement?
6. Is a dedicated ledger control necessary for effect/proof coupling after establishment?
7. Should the witness remain intentionally ignorant of eligible/hold/resolved state?
8. Are exactly three positive ledger states sufficient?
9. Is unknown/unproven correctly represented as a recovery classification rather than a positive persisted state?
10. Does ordinary initialization correctly require the complete Category / PaymentMethod / Tag assembly instead of current per-family repair semantics?
11. Does the ordinary resolution update belong in the same ledger transaction as the complete default-reference effects?
12. Does imported reference-confirmation resolution belong in the same confirmation transaction as the imported reference effects?
13. Is current `LedgerWrite.perform` correctly treated as save-boundary evidence rather than proof of process-crash atomicity?
14. Is executable process-termination characterization correctly required before implementation admission?
15. Does the proposal preserve the accepted fresh hold before workspace existence?
16. Does abandonment ordering prevent a released hold from coexisting with a promotable workspace?
17. Does resolved state remain terminal despite later reference edits/emptiness?
18. Is legacy no-proof state correctly unknown/unproven?
19. Does the mechanism gate avoid silently deciding the legacy migration/conversion path?
20. Is the Phase 1A historical-producer workflow correctly treated as future migration-test infrastructure rather than migration proof?
21. Is UserDefaults correctly rejected as the sole authority mechanism because it lacks ledger coupling/effect boundary?
22. Is a file-only ongoing authority mechanism correctly rejected because it splits canonical effects and proof?
23. Is UserProfile reuse correctly rejected as semantic overloading and persisted-model evolution?
24. Is SwiftData store metadata correctly limited to observation/corroboration rather than lifecycle authority?
25. Is the proposed lifecycle UUID sufficiently narrow and internal?
26. Does any proposed rule accidentally grant Portable identity, source identity, sync identity, or public API semantics?
27. Are reset/destructive recovery and multi-process writers correctly excluded?
28. Are schema/version/migration consequences clearly routed to separate admission?
29. If process-crash characterization fails, does the proposal require redesign rather than weakening accepted all-or-nothing semantics?
30. Is the two-layer assembly the minimum sufficient mechanism supported by current authority requirements?

---

# 26. Review boundary

This proposal is ready for independent review as an exact mechanism **proposal**.

It is not accepted merely because it exists.

Do not:

- record mechanism acceptance;
- add `LedgerLifecycleWitnessV1` to production;
- add `ReferenceInitializationAuthorityControlV1` to SwiftData;
- adopt a versioned schema;
- add a migration plan;
- mutate historical stores;
- add store/lifecycle fields to UserProfile;
- add UserDefaults authority keys;
- change `LedgerStore.open()`;
- change `Seed.bootstrapIfNeeded()`;
- change production reference confirmation;
- implement fresh-restoration workspace persistence;
- implement reset/recovery UI;
- open a downstream schema/migration/legacy-compatibility implementation gate

without independent review and separate authorization.

If the mechanism is accepted, the next work must be derived from the accepted mechanism's actual consequences.

If those consequences include a SwiftData schema/version change or historical-store conversion, exact schema/migration/compatibility admission remains separately required before implementation.
