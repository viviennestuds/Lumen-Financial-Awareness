# Lumen Portable v1 Fresh-Install Reference-Initialization Authority Persistence / Recovery Capability Proposal

## Status

**PROPOSED FOR REVIEW — docs-only Phase 1C capability gate.**

Starting accepted semantic checkpoint:

`d785d7d3981779317f2badc1e87be4e13a4e86ff`

Proposal-development composition baseline:

`c7dd2ea639df6db0e98f942f5d906b522d28cf30`

Canonical `main` at gate opening:

`d4884e2180e2f867dee415a48375100097a8d415`

Branch:

`docs/phase1c-fresh-install-reference-initialization-authority-recovery-proposal`

This gate consumes and does not reopen the accepted fresh-install bootstrap-state semantics.

It is a **capability-requirement proposal**, not a storage, schema, migration, importer, UI, or implementation proposal.

---

# 1. Decision question

> **What durable, store-scoped authority facts and crash/relaunch recovery invariants must Lumen provide to truthfully establish fresh-restoration eligibility, preserve an unresolved fresh-restoration bootstrap hold, establish and retain ordinary-reference initialization resolution through either ordinary bootstrap or canonical reference confirmation, and safely transition that authority through abandonment or a genuinely new store lifecycle—without inferring authority from ledger contents or selecting a persistence mechanism?**

The question begins before persistence of a bootstrap hold.

The gate must establish what makes these statements authoritative:

```text
this ledger/store is eligible for fresh ownership restoration

ordinary reference initialization is unresolved

fresh-restoration bootstrap hold is active

reference initialization is resolved
```

and how those facts survive interruption without being reconstructed from record contents.

---

# 2. Accepted semantic prerequisites

## 2.1 Bootstrap is initialization authority

Accepted:

```text
ordinary bootstrap
= initialization authority

ordinary bootstrap
!= perpetual permission
   to repopulate an empty family
```

Later family emptiness does not independently reauthorize bootstrap after reference initialization has resolved.

## 2.2 Fresh restoration requires two distinct authorities

Accepted:

```text
authoritative fresh-restoration eligibility
+
explicit user restore intent
→ fresh-restoration bootstrap hold
```

Neither operand grants the other.

Therefore:

```text
eligible store
+
no restore intent
→ ordinary bootstrap is not suppressed merely by eligibility
```

and:

```text
restore intent
+
store not authoritatively eligible
→ no fresh-restoration bootstrap authority
```

User intent cannot manufacture freshness.

## 2.3 Freshness is not inferable from ledger contents

Accepted:

```text
LedgerStore.open() success
family counts
Transaction count
names
exact seed equality
Category.is_default
zero relationships
seed resemblance
!= freshness
!= bootstrap provenance
```

## 2.4 Reference initialization and Transaction completion are distinct

Accepted:

```text
fresh-restoration authority established
!=
reference initialization resolved
!=
separate Transaction restoration completed
```

For the v1 fresh-install reference assembly, Category / PaymentMethod / Tag owned sets form one coherent initialization unit.

## 2.5 Canonical reference confirmation resolves initialization

Accepted:

```text
canonical confirmation boundary establishing
complete imported Category /
PaymentMethod / Tag owned sets
        ↓
commits successfully
        ↓
reference initialization RESOLVED
```

A confirmed empty family such as `tags: []` is canonical state even when zero Tag objects are inserted.

A later separate Transaction failure or abandonment cannot reauthorize bootstrap.

## 2.6 Existing import confirmation recovery contract

The accepted Phase 1C responsibility contract requires canonical effects authorized by one import confirmation boundary to satisfy an atomic-proof or provably idempotent/replay-safe property family.

That accepted rule governs **import confirmation boundaries**.

This proposal does not automatically extend that authority to ordinary bootstrap.

Ordinary bootstrap needs its own admitted crash-consistency requirement.

---

# 3. Repository evidence

## 3.1 Current implementation has no admitted initialization-authority fact

Current runtime provides a mechanical sequence:

```text
LedgerStore.open()
        ↓
ModelContainer exists
        ↓
Seed.bootstrapIfNeeded()
```

That exposes a useful intervention seam.

It does not establish:

```text
fresh store
initialized store
legacy/unproven store
fresh-restoration eligible
bootstrap hold active
initialization resolved
```

## 3.2 Current bootstrap trigger is content-derived

Current bootstrap behavior checks family emptiness independently.

That is implementation evidence, not sufficient future authority.

Accepted semantics already establish:

```text
family empty
!= bootstrap authority
```

after initialization has resolved.

## 3.3 Current onboarding state is non-authoritative for ledger initialization

`AppState` explicitly owns lightweight UI state.

`hasOnboarded` is an onboarding-completion preference.

Therefore:

```text
onboarding completion
!= ledger/reference initialization authority

lumen_has_onboarded
!= freshness proof
!= initialization proof
```

This conclusion follows from semantic responsibility, not from the fact that current AppState happens to use UserDefaults.

This gate does not prohibit any persistence technology categorically.

## 3.4 Workspace existence is not import authority

The accepted Phase 1C responsibility contract establishes:

```text
physical workspace existence
!= import authority
```

and requires explicit discard to durably remove edit/promotion authority.

The fresh-restoration bootstrap hold must likewise not derive its authority merely from file or workspace existence.

---

# 4. Minimum sufficient authority model

The following labels are **semantic capability states**, not persisted enums or required model names.

## 4.1 Ordinary initialization eligible

A truthfully established lifecycle condition under which ordinary reference initialization may still be performed.

This cannot be inferred merely from family emptiness.

## 4.2 Fresh-restoration eligible

A truthfully established lifecycle condition that allows an explicit user restore choice to acquire the fresh-restoration reference-initialization path.

Eligibility alone does not suppress ordinary bootstrap.

## 4.3 Fresh-restoration bootstrap hold active

Established only when:

```text
fresh-restoration eligibility
+
explicit restore intent
```

are both authoritative.

The hold suppresses ordinary bootstrap while reference initialization remains unresolved.

## 4.4 Reference initialization resolved

A store-lifecycle fact that ordinary reference initialization has completed through one accepted path:

```text
ordinary bootstrap completion
OR
canonical fresh-restoration reference confirmation
```

Resolution outlives any particular import workspace or source file.

## 4.5 Authority unknown / unproven

A compatibility-bearing condition in which the capability cannot truthfully establish the relevant initialization authority from admitted proof.

Preserve:

```text
authority unknown / unproven
!= fresh
!= unresolved initialization
!= ordinary-bootstrap authority
```

This is an uncertainty posture, not necessarily a persisted state.

It applies to pre-capability legacy stores and any future situation in which the required authority proof is absent, corrupt, incompatible, or cannot be truthfully recovered.

---

# 5. Uncertainty is non-authorizing

Normative invariant:

> **Uncertainty about initialization authority must never itself grant mutation authority.**

Therefore:

```text
missing proof
corrupt proof
unsupported proof
incompatible proof
unrecoverable proof
        ↓
NO inference of freshness
NO inference of unresolved initialization
NO ordinary-bootstrap mutation authority
```

The gate does not decide the eventual repair, compatibility, or user-resolution UX for that condition.

A historical ledger may remain usable.

What is prohibited is silently creating reference defaults merely because the future authority proof is absent.

---

# 6. Fresh-restoration eligibility and intent remain separate

## 6.1 Eligibility without intent

```text
fresh-restoration eligible
+
no explicit restore intent
```

does not itself establish a bootstrap hold.

Ordinary initialization may remain eligible under the applicable lifecycle contract.

## 6.2 Intent without eligibility

```text
user selects / requests restoration
+
fresh-restoration eligibility not established
```

does not create fresh-install authority.

The request may enter another supported existing-store workflow, remain blocked, or require later compatibility resolution.

This gate does not define that UX.

## 6.3 Eligibility must precede fresh-restoration authority

Restore intent is an authorization choice inside an already truthful eligibility boundary.

It is not evidence that the receiving ledger is fresh.

## 6.4 Positive origin of initialization eligibility

Initialization eligibility must originate from an authoritative lifecycle establishment, not from absence of authority state.

Proposed provenance rule:

```text
authoritative new-initialization-lifecycle establishment
OR
separately admitted compatibility transition
        ↓
may establish initialization eligibility
```

Preserve:

```text
absence of prior authority proof
!= new-lifecycle establishment
!= initialization eligibility
```

This applies even to a genuinely new physical store whose future authority representation has not yet been written. A future mechanism must positively establish the initialization lifecycle rather than infer it from missing state.

This gate does not decide which concrete event performs that establishment. It does not select store-file creation, SwiftData container creation, a control record, platform/store metadata, a store identifier, an epoch field, filesystem state, or another representation.

## 6.5 Mutual exclusion and crash-safe initialization-authority transfer

Ordinary-initialization eligibility and fresh-restoration eligibility may coexist as candidate paths before an initialization choice becomes authoritative.

Eligibility is not active authority.

Within one initialization epoch:

```text
ordinary-bootstrap authority ACTIVE
+
fresh-restoration bootstrap-hold authority ACTIVE
→ FORBIDDEN
```

At any point in the epoch, at most one initialization authority may be active / authoritative.

Acquisition by one path invalidates stale eligibility observations of the competing path while the acquired authority remains active.

Therefore:

```text
fresh-restoration hold ACTIVE
→ ordinary bootstrap cannot acquire authority
  from a prior/stale eligibility observation
```

and:

```text
ordinary-bootstrap authority ACTIVE
→ fresh-restoration hold cannot acquire authority
  from a prior/stale eligibility observation
```

This mutual exclusion does **not** mean only one path may ever acquire authority during the entire unresolved epoch.

A later competing acquisition is permitted only after the previously active authority reaches an admitted terminal/release transition that durably and recoverably removes that authority.

### Fresh-restoration → ordinary-bootstrap handoff

The already-accepted explicit-abandonment path remains valid while reference initialization is unresolved:

```text
fresh-restoration hold ACTIVE
        ↓
explicit abandonment permitted
        ↓
associated workspace promotion authority,
if any, durably removed
        ↓
fresh-restoration hold
terminally released
        ↓
recovery proves no surviving
fresh-restoration initialization authority
        ↓
ordinary initialization may
become eligible again
        ↓
ordinary bootstrap may acquire authority
```

The ordinary path acquires only after the fresh-restoration authority has been terminally released.

### Ordinary-bootstrap → fresh-restoration handoff after failed attempt

If ordinary bootstrap had acquired authority but its attempt fails or is interrupted, fresh restoration may later acquire only when crash-safe recovery truthfully establishes:

```text
ordinary-bootstrap attempt
→ produced no canonical reference effects
→ produced no initialization-resolution effects
→ retains no surviving ordinary-bootstrap authority
→ ordinary authority terminally released
→ initialization epoch truthfully returned
  to an eligible pre-initialization state
```

Only then may the fresh-restoration path later acquire authority.

A stale eligibility observation never survives a competing **active** authority. A new eligibility decision after admitted terminal release is a new authoritative lifecycle decision, not continuation of the stale observation.

This is a mechanism-neutral mutual-exclusion and authority-transfer property. It does not require a persisted enum, mutex, actor, database transaction, uniqueness constraint, store identifier, or another particular implementation mechanism.

## 6.6 Resolution exhausts fresh-install initialization authority for the epoch

Once reference initialization resolves:

```text
reference initialization RESOLVED
→ fresh-install initialization authority
  for that epoch is exhausted
```

A later restore may still use the accepted existing-store restoration path.

It is no longer a fresh-install initialization operation for that resolved epoch.

---

# 7. Bootstrap hold is independent of workspace existence

A legitimate bootstrap hold may exist before a valid resumable import workspace exists.

Counterexample:

```text
fresh-restoration eligible
→ user explicitly chooses restore
→ bootstrap hold established
→ selected artifact invalid
→ no valid promotable workspace exists yet
```

Accepted semantics already establish that invalid input does not restore bootstrap authority.

Therefore:

```text
bootstrap hold active
iff active workspace exists
```

is **rejected**.

Likewise:

```text
file exists
→ hold exists
```

is rejected.

Workspace persistence must not become the source of bootstrap authority.

---

# 8. Workspace-promotion interaction

Once an associated restoration workspace does possess canonical promotion authority:

```text
associated workspace promotable
→ ordinary bootstrap NOT eligible
```

This invariant must survive process interruption.

The store must never recover into:

```text
ordinary bootstrap eligible
+
old fresh-restoration workspace still promotable
```

because that would create competing initialization authorities.

Physical cleanup residue that has already lost promotion authority does not by itself keep bootstrap suppressed.

Authority follows admitted lifecycle state, not file existence.

---

# 9. Abandonment and durable workspace discard

Explicit abandonment may release a fresh-restoration hold only while reference initialization remains unresolved.

When an associated promotable workspace exists, release of the hold and loss of workspace promotion authority must compose crash-safely.

Unsafe sequence A:

```text
fresh-restoration hold active
+
workspace promotable
        ↓
hold released
        ↓
process dies
        ↓
workspace discard not durably accepted
```

Potential invalid recovery:

```text
ordinary bootstrap eligible
+
workspace still promotable
```

Unsafe sequence B:

```text
workspace discard durably accepted
        ↓
process dies
        ↓
hold still recovered as active
```

Potential result:

```text
no promotable restoration workspace
+
ordinary bootstrap permanently withheld
```

Required capability invariant:

> **Ordinary bootstrap must not regain authority while the associated fresh-restoration workspace retains canonical promotion authority.**

And:

> **Durably accepted abandonment/discard must have a recoverable terminal authority effect sufficient to avoid permanently stranding ordinary initialization.**

This gate does not select an atomic storage mechanism.

---

# 10. Ordinary-bootstrap crash consistency

Ordinary bootstrap is not an import confirmation boundary.

Therefore it does not automatically inherit §24's import-promotion proof contract.

The capability nevertheless requires its own equivalent crash-safety property.

The coherent v1 ordinary-reference initialization assembly is:

- Category defaults;
- PaymentMethod defaults;
- Tag defaults;
- initialization resolution.

Unsafe conceptual sequence:

```text
default reference effects commit
        ↓
process dies
        ↓
initialization-resolution authority does not commit
```

Recovery cannot repair that ambiguity by inspecting seed-looking records.

Therefore ordinary bootstrap completion must satisfy an admitted property such that:

```text
complete authorized ordinary-reference
initialization assembly
+
initialization-resolution authority
```

cannot diverge across interruption.

This proposal does not require the same implementation mechanism as import confirmation.

It requires equivalent correctness properties:

- no partial authority;
- no family-level accidental resolution;
- no content-inference repair;
- crash/relaunch determinism.

---

# 11. Coherent three-family initialization

The accepted v1 reference-initialization assembly is coherent across:

- Category;
- PaymentMethod;
- Tag.

Ordinary bootstrap therefore resolves reference initialization only when its **complete authorized ordinary-reference initialization assembly** has crossed its crash-safe completion boundary.

Reject:

```text
Categories completed
→ reference initialization RESOLVED
```

while PaymentMethods or Tags remain unsettled.

Reject independent family-level initialization epochs unless separately admitted later.

This requirement remains even if future implementation no longer uses today's single `LedgerWrite.perform` shape.

---

# 12. Store-lifecycle coupling

Reference initialization resolution is not merely import-session state.

Once resolved, it must remain authoritative after:

- import workspace retirement;
- source-file cleanup;
- relaunch;
- later ordinary edits;
- legitimate later family emptiness.

Preserve:

```text
Tag count == 0
after resolved initialization
!= permission to bootstrap
```

The authority fact therefore belongs semantically to the ledger/store lifecycle whose bootstrap authority it governs.

This is a semantic lifecycle requirement.

It does **not** authorize:

- a persisted store ID;
- an epoch integer;
- a UUID;
- a schema field;
- a migration.

---

# 13. New store lifecycle / initialization epoch

A genuinely new ledger/store lifecycle must not inherit stale reference-initialization authority from a previous ledger lifecycle.

Normative invariant:

```text
new ledger/store lifecycle
!= inherit prior lifecycle's
reference-initialization authority
```

The gate uses "initialization epoch" only as a conceptual boundary:

> the lifecycle interval over which one coherent reference-initialization authority decision remains valid.

The start of a new initialization epoch must be positively established through an authoritative new-initialization-lifecycle event or a separately admitted compatibility transition.

This gate does not decide what concrete operation or representation establishes that event.

Potential future interactions include:

- fresh installation;
- intentional creation of a new ledger;
- a separately admitted "erase/reset all managed data" capability.

Family emptiness does not create a new epoch.

Absence of prior authority proof does not create a new epoch.

The exact lifecycle trigger and proof mechanism remain downstream admission work.

---

# 14. Legacy and compatibility-bearing stores

A store created before this capability exists may lack an admitted initialization-authority proof.

That absence must not be upgraded into ordinary-bootstrap permission.

Preserve:

```text
legacy store
+
no new authority proof
        ↓
authority unknown / unproven
        ↓
NO content-derived freshness inference
NO bootstrap mutation authority
```

A later exact compatibility/migration admission may establish:

- deterministic compatibility treatment;
- a migration proof;
- user resolution;
- another safe mechanism.

None is selected here.

If this proposal's requirements necessarily imply such compatibility handling, that requirement becomes a separately authorized downstream gate.

---

# 15. Reference-confirmation recovery

For a fresh-restoration path, the accepted Phase 1C import-confirmation recovery contract remains controlling.

If the complete Category / PaymentMethod / Tag owned sets cross a canonical confirmation boundary, that boundary's existing atomicity/replay-safety requirement governs the canonical effects.

This capability consumes the resulting authoritative fact:

```text
reference confirmation succeeded
→ reference initialization RESOLVED
```

Recovery must preserve that resolution even if:

- the Transaction portion remains active;
- the Transaction portion later fails;
- the Transaction portion is abandoned;
- the workspace is later retired;
- one or more confirmed families are empty.

The capability must not create a second weaker proof path around the accepted confirmation boundary.

---

# 16. Hold-before-workspace and workspace-after-hold lifecycle

The capability must support this ordering:

```text
fresh-restoration eligibility
+
explicit restore intent
        ↓
bootstrap hold active
        ↓
artifact selection / validation
        ↓
workspace may or may not become valid/promotable
```

If no valid workspace exists yet, the hold can remain authoritative.

Once a promotable workspace exists:

```text
bootstrap hold
+
workspace promotion authority
```

must recover consistently.

Abandonment may only transition toward ordinary initialization after any associated workspace promotion authority is durably removed.

---

# 17. Recovery precedence

A future launch/recovery path must determine authority before using reference-family contents as bootstrap triggers.

Conceptual precedence:

```text
recover ledger/store lifecycle authority
        ↓
classify authority truthfully
        ↓
then decide whether ordinary bootstrap
has mutation authority
```

Required outcomes include:

### Resolved

```text
reference initialization RESOLVED
→ ordinary bootstrap forbidden
  solely due to family emptiness
```

### Active fresh-restoration hold

```text
hold active
→ ordinary bootstrap withheld
```

### Ordinary initialization truthfully eligible

```text
ordinary initialization eligible
→ bootstrap may proceed under
  its crash-consistency contract
```

### Unknown / unproven

```text
authority unknown
→ no bootstrap mutation authority
```

This is not a required four-case persisted enum.

---

# 18. Capability alternatives considered

## Alternative A — Capability facts with mechanism-neutral recovery contracts

Define the authority facts/invariants above, then admit persistence implementation separately.

Advantages:

- keeps semantics independent of storage;
- exposes legacy compatibility rather than hiding it;
- preserves uncertainty as non-authorizing;
- lets implementation compare persistence substrates later;
- composes with accepted import-confirmation authority.

Disposition:

**RECOMMENDED.**

## Alternative B — Treat a resumable import workspace as the bootstrap authority record

Rejected.

A bootstrap hold can predate a valid workspace.

Workspace existence is already non-authoritative.

It also couples ledger initialization authority to a temporary workflow representation.

## Alternative C — Use onboarding completion as initialization authority

Rejected.

Onboarding is lightweight UI preference state and has no admitted ledger-initialization semantics.

## Alternative D — Reconstruct initialization from existing seeded records

Rejected.

Seed resemblance, names, `is_default`, counts, relationships, or exact semantic equality do not establish provenance.

## Alternative E — Absence of proof means bootstrap eligible

Rejected.

This would make legacy/corrupt/incompatible authority uncertainty destructive.

## Alternative F — Select a storage mechanism now

Rejected for this gate.

SwiftData, UserDefaults, file-backed state, a RestoreSession, a store ID, an epoch field, or another mechanism must compete later against the accepted capability requirements.

---

# 19. Counterexample tests

## 19.1 Eligible but no restore intent

```text
fresh-restoration eligible
+
user does not choose restore
```

No bootstrap hold exists solely from eligibility.

## 19.2 Restore intent on an existing/unproven store

```text
user chooses backup
+
fresh-restoration eligibility not established
```

Intent cannot manufacture freshness or bootstrap suppression authority.

## 19.3 Legacy store with no future proof

```text
pre-capability store
+
no admitted initialization proof
```

Must not become ordinary-bootstrap eligible by default.

## 19.4 Corrupt or incompatible authority proof

Failure to recover an admitted proof cannot authorize mutation.

## 19.5 Hold exists before valid workspace

```text
eligible
→ restore chosen
→ hold acquired
→ malformed artifact
```

No valid workspace is required for the hold to remain active.

## 19.6 Workspace promotable during abandonment

Ordinary bootstrap cannot regain authority before workspace promotion authority is durably gone.

## 19.7 Workspace discarded but hold recovery lags

Recovery must not permanently strand initialization because one authority transition survived and the other did not.

## 19.8 Ordinary bootstrap partial-family interruption

```text
Categories written
→ process termination
→ PaymentMethods / Tags unsettled
```

Must not recover as reference initialization RESOLVED.

## 19.9 Ordinary bootstrap effects written without resolution proof

Seed-looking objects cannot be used to infer successful initialization.

## 19.10 Reference confirmation with empty Tags

```text
tags: []
→ reference confirmation succeeds
→ zero Tag objects
→ reference initialization RESOLVED
```

Later launch must not seed Tags.

## 19.11 Reference resolution survives workspace retirement

Resolved initialization remains authoritative after import cleanup.

## 19.12 Later legitimate family emptiness

A future management action that removes all Tags does not create a new initialization epoch.

## 19.13 Genuinely new ledger lifecycle

A new ledger must not inherit the previous ledger's resolved/held initialization authority.

## 19.14 Simultaneous eligibility observations

```text
ordinary initialization eligible
+
fresh-restoration eligible
```

Two activities may observe those candidate facts concurrently.

That coexistence is permitted.

They must never recover or progress into:

```text
ordinary-bootstrap authority ACTIVE
+
fresh-restoration hold authority ACTIVE
```

for the same epoch.

## 19.15 Stale eligibility while competing authority is active

```text
ordinary path observes eligibility
→ fresh-restoration hold becomes ACTIVE
→ ordinary path continues from stale observation
```

The stale observation grants no right to acquire ordinary-bootstrap authority while the fresh-restoration hold remains active.

The converse applies while ordinary-bootstrap authority remains active.

## 19.16 Interruption during authority acquisition

Process termination while either path is acquiring authority must recover to a state in which both initialization authorities are never simultaneously active for the same epoch.

Recovery may return the epoch to pre-initialization eligibility only after the prior authority is truthfully absent under the applicable terminal/release rule.

## 19.17 Fresh hold abandoned before resolution

```text
fresh-restoration hold ACTIVE
→ explicit abandonment permitted
→ associated workspace promotion authority durably gone
→ hold terminally released
→ no surviving fresh-restoration authority
→ ordinary initialization may become eligible
→ ordinary bootstrap may later acquire
```

This is a valid authority transfer within the same unresolved initialization epoch.

It does not violate mutual exclusion because the two authorities are not active simultaneously.

## 19.18 Ordinary-bootstrap attempt fails before effects

```text
ordinary-bootstrap authority ACTIVE
→ attempt fails / process terminates
→ recovery proves:
   no canonical reference effects
   no initialization-resolution effects
   no surviving ordinary-bootstrap authority
→ ordinary authority terminally released
→ epoch returns to eligible pre-initialization state
→ fresh-restoration hold may later acquire
```

Again, the later acquisition is valid because the prior authority is no longer active.

## 19.19 Successful resolution is not a transferable release

```text
reference initialization RESOLVED
→ fresh-install authority for the epoch exhausted
```

Resolution is terminal for fresh-install initialization.

It must not be treated like abandonment or a failed pre-effect acquisition.

## 19.20 Missing authority state on a brand-new store

```text
new physical store
+
no authority proof exists yet
```

must not be interpreted as initialization eligibility merely because state is absent.

Eligibility requires positive authoritative lifecycle establishment.

---

# 20. Assembly Map

## 20.1 Accepted prerequisites

- Phase 1C round-trip ownership requirement;
- ordinary reference owned-set and empty-set semantics;
- exact reference schemas;
- reference compatibility/export disposition;
- existing-store restoration/matching/conflict semantics;
- fresh-install bootstrap-state semantic disposition;
- coherent Category / PaymentMethod / Tag v1 initialization assembly;
- per-confirmation-boundary atomicity/replay-safety responsibilities;
- durable import-workspace and discard authority responsibilities.

## 20.2 This gate owns

Only the mechanism-neutral authority/recovery capability for:

- positive authoritative origin of initialization eligibility;
- fresh-restoration eligibility;
- explicit-intent composition;
- mutual exclusion of active ordinary-bootstrap versus fresh-restoration authority plus admitted crash-safe authority transfer;
- bootstrap hold;
- uncertainty posture;
- ordinary-bootstrap crash consistency;
- reference-initialization resolution retention;
- fresh-install authority exhaustion after resolution;
- store-lifecycle coupling;
- new-lifecycle noninheritance;
- abandonment/workspace ordering;
- recovery precedence.

## 20.3 Required downstream mechanism admission and possible additional dependencies

If this capability is accepted, an **exact authority persistence/recovery mechanism admission is required before implementation**.

That downstream gate must select or admit the concrete mechanism by which these authority facts and transitions survive interruption and are lifecycle-coupled correctly.

What remains unresolved is whether satisfying that exact mechanism admission requires any of the following:

- new canonical-control persistence;
- legacy-store compatibility handling;
- SwiftData or other schema/version state;
- migration;
- store-lifecycle identity;
- filesystem/platform metadata;
- another persistence substrate or mechanism;
- implementation sequencing;
- tests.

Those concrete mechanisms and compatibility consequences are not admitted here.

## 20.4 Independent sibling work

This gate does not require closure of:

- normalized precision authority;
- upper-magnitude authority;
- canonical money lexical serialization;
- financial-date lexical/parser closure;
- Source/provenance portability;
- deterministic Portable-ID allocation/order;
- unknown-field/evolution policy.

---

# 21. Authority Budget

## New authority proposed

This gate proposes only these capability requirements:

- positive authoritative new-lifecycle or separately admitted compatibility provenance for initialization eligibility;
- a truthfully established fresh-restoration eligibility fact;
- explicit restore intent as a separate required authority input;
- mutual exclusion of simultaneously active initialization authorities within one initialization epoch, with only admitted crash-safe terminal/release handoff;
- a recoverable fresh-restoration bootstrap hold;
- a non-authorizing unknown/unproven posture;
- a crash-safe coherent ordinary-bootstrap completion/resolution contract;
- durable recognition that successful canonical reference confirmation resolved initialization;
- exhaustion of fresh-install initialization authority once the epoch resolves;
- store-lifecycle coupling of initialization authority;
- no inheritance of stale authority by a genuinely new ledger lifecycle;
- crash-safe ordering between abandonment and associated workspace promotion authority;
- recovery precedence that resolves authority before content-derived bootstrap checks.

## Authority not granted

This gate does **not** authorize:

- SwiftData;
- UserDefaults;
- filesystem state;
- a RestoreSession;
- persisted authority enums;
- a store identifier;
- an epoch identifier/field;
- schema changes;
- migrations;
- legacy-store migration behavior;
- UI;
- importer implementation;
- exporter implementation;
- production bootstrap changes;
- reference deletion/retirement;
- arbitrary existing-store reconciliation;
- Source/provenance changes;
- a specific atomicity mechanism;
- full Portable JSON / CSV v1 acceptance.

---

# 22. Assembly Debt and Pressure

Assembly Pressure is high because the accepted bootstrap semantic gate explicitly requires truthful fresh-restoration eligibility and durable recovery of unresolved versus resolved initialization authority.

The capability is therefore a direct lower-level dependency of an already-accepted semantic promise.

However:

```text
Assembly Pressure
!= implementation authorization
```

and:

```text
capability requirement
!= storage mechanism
```

The proposal deliberately stops before choosing persistence.

---

# 23. Irreversible commitments

If accepted, the capability contract would freeze:

1. eligibility and restore intent as separate authority inputs;
2. initialization eligibility as requiring positive authoritative lifecycle provenance rather than missing-state inference;
3. mutual exclusion of live ordinary-bootstrap and fresh-restoration hold authority within one initialization epoch, while permitting only admitted crash-safe authority transfer after the prior authority is terminally released;
4. uncertainty as non-authorizing;
5. bootstrap hold authority independent from workspace/file existence;
6. workspace promotion authority as a blocker to reactivating ordinary bootstrap;
7. ordinary bootstrap as one coherent three-family crash-consistent initialization assembly;
8. resolved initialization as a store-lifecycle fact rather than session state;
9. fresh-install initialization authority as exhausted for an epoch once reference initialization resolves;
10. later family emptiness as non-authorizing;
11. new ledger lifecycle as unable to inherit stale prior-lifecycle initialization authority;
12. legacy/unproven stores as requiring explicit compatibility treatment rather than inferred freshness;
13. a required downstream exact authority persistence/recovery mechanism admission before implementation, while its storage/schema/migration consequences remain unresolved.

No public file grammar or storage representation is frozen by this gate.

---

# 24. Proposed exact contract language

The following is **PROPOSED FOR REVIEW**.

> **Initialization-eligibility provenance.** Ordinary/fresh initialization eligibility must originate from an authoritative new-initialization-lifecycle establishment or a separately admitted compatibility transition. Absence of prior authority proof is not itself lifecycle establishment and does not establish eligibility. The exact establishment event and representation remain downstream.
>
> **Fresh-restoration eligibility and intent.** Fresh-install reference restoration requires both truthfully established fresh-restoration eligibility and explicit user restore intent. Eligibility alone does not establish a bootstrap hold. Restore intent alone does not establish freshness or fresh-restoration authority.
>
> **Mutual exclusion and authority transfer.** Ordinary-bootstrap eligibility and fresh-restoration eligibility may coexist as candidate paths, but ordinary-bootstrap authority and fresh-restoration bootstrap-hold authority must never be simultaneously active for the same initialization epoch. While one authority remains active, stale eligibility observations cannot authorize the competing path to acquire. A competing path may acquire later only after an admitted terminal/release transition has durably and recoverably removed the prior authority.
>
> **Fresh-restoration abandonment handoff.** While reference initialization remains unresolved, permitted explicit abandonment may release an active fresh-restoration hold only after any associated workspace promotion authority is durably removed and recovery can establish that no fresh-restoration initialization authority survives. Ordinary initialization may then become eligible again and ordinary bootstrap may later acquire authority.
>
> **Failed ordinary-bootstrap handoff.** If ordinary bootstrap acquired authority but fails or is interrupted before successful initialization, the epoch may return to pre-initialization eligibility only when crash-safe recovery truthfully establishes no canonical reference effects, no initialization-resolution effects, and no surviving ordinary-bootstrap authority. Only then may a fresh-restoration hold later acquire.
>
> **Resolution exhausts fresh-install authority.** Once reference initialization resolves, fresh-install initialization authority for that epoch is exhausted. Any later restoration is governed by the accepted existing-store restoration path unless a later separately admitted lifecycle creates a genuinely new initialization epoch.
>
> **Non-authorizing uncertainty.** Absence, corruption, incompatibility, or inability to recover an admitted initialization-authority proof must not be interpreted as freshness, unresolved initialization, or ordinary-bootstrap authority. Initialization-authority uncertainty does not grant mutation authority.
>
> **Hold independence.** A legitimate fresh-restoration bootstrap hold may exist before a valid resumable import workspace exists. File presence and workspace existence do not create the hold. Invalid or unsupported selected input does not by itself restore ordinary bootstrap authority.
>
> **Workspace interaction.** Once an associated fresh-restoration workspace has canonical promotion authority, ordinary bootstrap must remain ineligible until that workspace loses promotion authority through an admitted terminal transition. Physical cleanup residue without promotion authority is not itself a bootstrap blocker.
>
> **Abandonment/discard recovery.** When abandonment is permitted because reference initialization remains unresolved, the transition from fresh-restoration hold to ordinary initialization must compose crash-safely with durable loss of any associated workspace promotion authority. Recovery must never expose ordinary bootstrap authority while the associated workspace remains promotable and must not permanently strand initialization after discard has become authoritative.
>
> **Ordinary-bootstrap crash consistency.** Ordinary bootstrap is not an import confirmation boundary and does not inherit import-confirmation recovery authority automatically. The complete authorized Category / PaymentMethod / Tag ordinary-reference initialization assembly and its initialization-resolution authority must satisfy a separately admitted crash-consistency property that prevents partial-family resolution, split effect/proof state, and recovery by seed-content inference.
>
> **Coherent assembly.** Ordinary bootstrap resolves reference initialization only after its complete authorized Category / PaymentMethod / Tag initialization assembly crosses its admitted crash-safe completion boundary. Family-level completion does not independently resolve v1 reference initialization.
>
> **Reference-confirmation resolution.** Successful canonical confirmation of the complete imported Category / PaymentMethod / Tag owned sets resolves reference initialization under the already-accepted per-confirmation-boundary recovery contract, including when one or more confirmed families are empty.
>
> **Store-lifecycle authority.** Resolved reference initialization is a lifecycle fact of the ledger/store whose bootstrap authority it governs. It remains authoritative after workspace/source cleanup, relaunch, later edits, and later family emptiness. A genuinely new ledger/store lifecycle must not inherit stale initialization authority from the prior lifecycle.
>
> **Legacy/unproven compatibility.** A pre-capability or otherwise unproven store lacking admitted initialization-authority proof must not be treated as fresh or bootstrap-eligible by absence of proof. Any required compatibility, migration, or user-resolution mechanism requires separate admission.
>
> **Recovery precedence.** Lumen must recover initialization authority before using reference-family contents as an ordinary-bootstrap trigger. A resolved initialization forbids reseeding solely from emptiness; an active hold withholds bootstrap; truthfully eligible ordinary initialization may bootstrap under its admitted crash-consistency contract; unknown/unproven authority grants no bootstrap mutation authority.
>
> **Required downstream mechanism admission.** Acceptance of this capability requires a later exact authority persistence/recovery mechanism admission before implementation. Whether that mechanism requires new SwiftData state, schema changes, migration, UserDefaults, filesystem/platform metadata, store identity, or another substrate remains unresolved and is not admitted here.
>
> **Mechanism neutrality.** This capability contract selects no persistence substrate, persisted model, store identifier, epoch field, schema change, migration, importer implementation, UI, or production bootstrap change.

---

# 25. Independent-review questions

1. Does the proposal start at the correct authority boundary rather than assuming fresh-restoration eligibility?
2. Are eligibility and restore intent correctly preserved as two separate required inputs?
3. Is unknown/unproven authority correctly non-authorizing?
4. Does the legacy-store posture avoid treating absence of future proof as freshness?
5. Is the bootstrap hold correctly independent of valid workspace existence?
6. Is workspace promotion authority correctly prevented from coexisting with ordinary-bootstrap eligibility?
7. Are abandonment/discard crash-ordering requirements sufficient without choosing an atomic mechanism?
8. Is ordinary bootstrap correctly treated as requiring its own crash-consistency admission rather than automatically inheriting import-confirmation §24 authority?
9. Is ordinary bootstrap correctly modeled as one coherent Category / PaymentMethod / Tag assembly?
10. Does the proposal avoid family-level resolution semantics?
11. Is resolved reference initialization correctly store-lifecycle-scoped rather than workspace-scoped?
12. Is later family emptiness correctly prevented from creating new bootstrap authority?
13. Is a new ledger lifecycle correctly prohibited from inheriting stale prior authority?
14. Does "initialization epoch" remain a semantic concept rather than a persisted field requirement?
15. Does the proposal preserve accepted reference-confirmation atomicity/replay-safety instead of redefining it?
16. Does confirmed `tags: []` remain a valid resolved initialization case?
17. Does the proposal preserve the distinction between cleanup residue and promotion authority?
18. Does it avoid treating onboarding completion as ledger-initialization authority for semantic—not technological—reasons?
19. Is the exact compatibility/migration treatment for legacy/unproven stores correctly downstream?
20. Is the gate sufficiently mechanism-neutral to compare SwiftData, UserDefaults, filesystem, or another future substrate later without pre-authorizing any?
21. Are Source/provenance, money/date closure, parser evolution, deterministic ordering, deletion, and implementation correctly excluded?
22. Does any requirement accidentally authorize production mutation or schema change?
23. Is every newly proposed authority necessary to satisfy an already-accepted fresh-install ownership semantic rather than implementation convenience?
24. Are ordinary-bootstrap authority and fresh-restoration hold authority explicitly mutually exclusive while active within one initialization epoch?
25. Can candidate eligibility coexist without creating simultaneous live authority?
26. Do stale eligibility observations correctly lose force while a competing authority remains active?
27. Does the proposal preserve the accepted fresh-restoration abandonment path as a valid crash-safe handoff to ordinary initialization before resolution?
28. Must associated workspace promotion authority be durably gone before a fresh-restoration hold can terminally release into ordinary-bootstrap eligibility?
29. Does a failed/interrupted ordinary-bootstrap attempt permit later fresh-restoration acquisition only after recovery proves no canonical reference effects, no resolution effects, and no surviving ordinary-bootstrap authority?
30. Does recovery from interrupted acquisition forbid both authorities from becoming simultaneously active?
31. Is successful reference initialization correctly distinguished from abandonment/failed acquisition as a terminal exhaustion of fresh-install authority for that epoch?
32. Is initialization eligibility positively established by an authoritative new-lifecycle event or separately admitted compatibility transition rather than inferred from missing state?
33. Is the downstream exact authority persistence/recovery mechanism admission correctly required while its concrete storage/schema/migration consequences remain unresolved?

---

# 26. Review boundary

This proposal is ready for independent review.

It is not accepted merely because it is present in the repository.

Do not:

- record proposed-contract acceptance;
- select a persistence substrate;
- add a freshness/store/epoch identifier;
- add persisted enums or control records;
- alter SwiftData schema;
- add migrations;
- define legacy-store migration behavior;
- implement import workspace state;
- implement bootstrap suppression/recovery;
- change `Seed.swift`, `LedgerStore.swift`, `LumenApp.swift`, or `AppState.swift`;
- open Source/provenance;
- open another Phase 1C gate

without separate review and authorization.

If this capability is accepted, a downstream **exact authority persistence/recovery mechanism admission is required before implementation**.

That downstream mechanism gate must remain separately authorized.

Whether the required mechanism also needs new canonical-control persistence, legacy compatibility handling, schema/version state, migration, store identity, filesystem/platform metadata, or another substrate remains unresolved and must not be solved inside this capability gate.
