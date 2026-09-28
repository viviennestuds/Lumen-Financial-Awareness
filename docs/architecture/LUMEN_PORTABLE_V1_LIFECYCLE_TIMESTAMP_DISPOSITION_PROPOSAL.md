# Lumen Portable v1 Ordinary Canonical-Record Lifecycle Timestamp Disposition

## Status

**PROPOSED FOR REVIEW — Phase 1C lifecycle-timestamp semantic-disposition proposal.**

This document proposes only the Portable v1 semantic disposition of these current durable fields:

- `Transaction.created_at`;
- `Transaction.updated_at`;
- `Category.created_at`;
- `PaymentMethod.created_at`;
- `Tag.created_at`.

It does **not** accept the full Portable JSON / CSV v1 contract and does not authorize production implementation.

Starting proposal-development checkpoint:

`f6678f0b274c5374f9359f03506cc703f71dd85e`

Branch:

`docs/phase1c-portable-v1-lifecycle-timestamp-disposition-proposal`

---

# 1. Decision question

For each in-scope canonical lifecycle timestamp:

> **Does Portable JSON v1 admit the source-store timestamp as round-trip portable state, emit it only as non-authoritative informational metadata, or exclude it from the v1 portable contract?**

The decision must be made from Lumen-owned semantics rather than from Swift type equality or persistence convenience.

Preserve:

    persisted
    !=
    portable

    machine-generated
    !=
    automatically non-portable

    operationally consumed
    !=
    portable authority

    same Swift Date type
    !=
    same semantic responsibility

---

# 2. Scope

## 2.1 In scope

Only:

- `Transaction.created_at`;
- `Transaction.updated_at`;
- `Category.created_at`;
- `PaymentMethod.created_at`;
- `Tag.created_at`.

## 2.2 Explicitly out of scope

This gate does not decide:

- top-level `exported_at`;
- `TransactionSource.created_at`;
- `TransactionSource.uploaded_at`;
- `TransactionSource.captured_at`;
- `TransactionSource.source_timezone`;
- `Transaction.transaction_date`;
- `Transaction.posted_date`;
- `UserProfile.created_at`;
- `UserProfile.updated_at`;
- exact RFC 3339 / ISO-8601 fractional-second spelling;
- exact financial-date lexical validity;
- exact Category / PaymentMethod / Tag record schemas beyond the timestamp consequence of this gate;
- Source/provenance portability;
- import conflict matching;
- Portable-ID allocation;
- entity-array ordering;
- schema migrations;
- production importer/exporter implementation.

`transaction_date` and `posted_date` already belong to the accepted financial civil-date gate.

Source temporal facts remain with the dedicated Source/provenance line.

`UserProfile` is not currently an admitted Portable v1 entity.

---

# 3. Governing contracts

This proposal is subordinate to:

1. `LUMEN_ARCHITECTURE_CONTRACT_V1.md`;
2. `PHASE_1C_OWNERSHIP_PORTABILITY_DATA_MANAGEMENT_RESPONSIBILITIES.md`;
3. accepted Phase 1C component gates;
4. `LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`.

The Phase 1C responsibility contract establishes that Portable JSON is the highest-fidelity portable representation of **durable state explicitly admitted** to the portability contract.

It also explicitly rejects blind serialization of the internal object graph.

Therefore:

    durable SwiftData field
    !=
    automatically admitted Portable field

Round-trip equivalence is defined by the durable fields and entities explicitly supported by the final Portable contract.

---

# 4. Disposition taxonomy

Each field is evaluated independently against three possible dispositions.

## 4.1 ROUND-TRIP PORTABLE STATE

Meaning:

- the source-store instant is admitted Portable semantic state;
- a complete export includes it;
- supported restoration preserves the same admitted instant;
- semantic round-trip equality requires preservation of that instant;
- later lexical work may choose a canonical timestamp spelling, but different spellings of the same admitted instant need not be semantically different unless the later lexical contract says otherwise.

This disposition creates a durable public ownership commitment.

## 4.2 INFORMATIONAL EXPORT METADATA

Meaning:

- the source-store instant may appear in the artifact;
- the value does **not** define restored canonical state;
- equality is not required after supported semantic round trip;
- restoration may legitimately create a different local lifecycle timestamp;
- the exported timestamp grants no identity, overwrite, merge, deduplication, freshness, conflict, ordering, restoration, or synchronization authority;
- the value must not silently become an operational source of truth merely because it was present in the artifact.

This is intentionally stricter than a vague "best effort" field.

If those constraints make an informational field useless, exclusion is preferable.

## 4.3 EXCLUDED FROM PORTABLE V1

Meaning:

- the field remains current canonical/persistence state but is outside the v1 portable ownership contract;
- complete Portable v1 export does not emit it;
- supported restoration may create new installation-local lifecycle timestamps;
- those destination timestamps need not equal the source values;
- source/destination timestamp inequality does not violate Portable round-trip equivalence;
- exclusion grants no permission to mutate or discard the source canonical field in the originating store.

Exclusion from v1 is a public-format decision, not a persistence migration.

---

# 5. Repository evidence

# 5.1 Current model definitions

Current SwiftData models establish:

## Transaction

`Transaction` persists:

- `created_at: Date`;
- `updated_at: Date`.

Both initializer defaults are `.now`.

The initializer also accepts explicit values, so current persistence can represent historical/custom instants.

## Category

`Category.created_at: Date` defaults to `.now`.

## PaymentMethod

`PaymentMethod.created_at: Date` defaults to `.now`.

## Tag

`Tag.created_at: Date` defaults to `.now`.

All five fields are durable under the current model.

Durability establishes existence.

It does not establish Portable ownership semantics.

---

# 5.2 Transaction creation semantics

`TransactionDraft` has no `created_at` or `updated_at` fields.

Ordinary new confirmation calls `Transaction(...)` without passing either timestamp.

Therefore ordinary canonical creation produces:

    user reviews financial draft
            ↓
    confirmed write boundary
            ↓
    Transaction initializer
            ↓
    created_at = .now
    updated_at = .now

The user reviews the financial Transaction fields represented by the draft.

The user does not review or select the hidden lifecycle timestamps.

Therefore ordinary confirmation establishes canonical Transaction creation, but it does not by itself prove that the exact hidden clock instants are user-authored financial facts.

---

# 5.3 Transaction.created_at behavior

Current evidence shows:

- generated automatically at Transaction construction unless explicitly injected;
- copied nowhere into `TransactionDraft`;
- preserved across ordinary edits because `TransactionDraft.apply(to:)` does not overwrite it;
- explicitly preserved by existing tests during unrelated edit;
- accepted by the model as an explicit injected Date in persistence/recovery fixtures;
- no current production Dashboard, Insights, Transactions, Review, Settings, Analytics, search, or row/detail presentation inspected for this gate uses `Transaction.created_at` as user-facing financial semantics.

This supports:

    stable durable record metadata
    !=
    demonstrated user-facing financial fact

The preservation test proves current edit behavior.

It does not independently grant Portable authority.

---

# 5.4 Transaction.updated_at behavior

Current evidence is materially different.

`Transaction.updated_at`:

- defaults to `.now` when the Transaction is constructed;
- is not part of `TransactionDraft`;
- is set to `.now` by `TransactionDraft.apply(to:)`;
- is set to `.now` by the direct Transaction-detail status action;
- is restored to its prior committed value when a write fails;
- participates in `TransactionDetailView.evidenceResolutionKey` through `timeIntervalSince1970`.

Current behavior therefore gives it at least two responsibilities:

    persisted last-local-mutation metadata
    +
    current operational invalidation / refresh input

The second responsibility is implementation behavior.

It does not automatically establish a portable semantic.

Preserve:

    current operational consumer
    !=
    portable semantic authority

Also preserve the inverse caution:

    operational coupling
    !=
    proof that the field must be excluded

The proposal must decide the Portable meaning independently and then record any implementation-alignment consequence.

---

# 5.5 Category / PaymentMethod / Tag creation semantics

All three ordinary reference families generate `created_at = .now` through their ordinary model initializers.

Current bootstrap uses those ordinary initializers.

Therefore a fresh installation creates timestamps that primarily reflect that installation's bootstrap event.

For example:

    Store A bootstrap
    Category "Dining"
    created_at = instant A

    Store B bootstrap
    Category "Dining"
    created_at = instant B

Accepted Portable identity semantics already establish:

    same visible reference content
    !=
    same object identity

The accepted complete-export-set semantics also establish that every durable record belongs to the owned set independent of seed/default provenance.

Neither accepted rule establishes that installation-local bootstrap time is user-owned Portable history.

---

# 5.6 Current production consumers of reference created_at

In the inspected current production surfaces for:

- Dashboard;
- Insights;
- Transactions;
- Manual Entry;
- Review;
- Settings;
- Transaction rows/details;
- upload;
- analytics/search;
- bootstrap;

no current consumer was found that uses Category / PaymentMethod / Tag `created_at` to establish user-facing financial semantics.

That is repository evidence about current behavior.

It is not a guarantee that no future consumer can be admitted.

---

# 5.7 Current test evidence

Existing tests establish useful persistence facts:

- Transaction `created_at` is preserved through unrelated edit;
- Transaction `updated_at` advances on successful mutation and restores after failed writes;
- recovery fixtures serialize both Transaction lifecycle instants into test-observation state;
- characterization fixtures can inject explicit lifecycle instants.

Those tests prove persistence/edit/recovery behavior.

They do **not** prove:

- that lifecycle timestamps are part of the user's financial truth;
- that complete Portable ownership requires them;
- that exact source timestamps must survive fresh-store restoration;
- that they should acquire matching/conflict/freshness authority in a portable artifact.

---

# 6. Evidence classification by field

| Field | Durable? | How normally created | Current mutation behavior | Current production semantic consumer | Proven portable authority? |
| --- | --- | --- | --- | --- | --- |
| `Transaction.created_at` | yes | automatic `.now` at canonical object creation | preserved on edit | none found | no |
| `Transaction.updated_at` | yes | automatic `.now` at creation | reset to `.now` on edit/status mutation | evidence-resolution refresh key | no |
| `Category.created_at` | yes | automatic `.now`; bootstrap uses ordinary initializer | no ordinary current mutation path found | none found | no |
| `PaymentMethod.created_at` | yes | automatic `.now`; bootstrap uses ordinary initializer | no ordinary current mutation path found | none found | no |
| `Tag.created_at` | yes | automatic `.now`; bootstrap uses ordinary initializer | no ordinary current mutation path found | none found | no |

The last column is an Authority Budget conclusion:

    evidence of persistence
    !=
    governance authority for portability

---

# 7. First-principles semantic questions

The gate asks:

1. Does the timestamp express financial meaning, object-history meaning, or local implementation history?
2. Does the user need the exact source instant to recover equivalent supported canonical state?
3. Does the timestamp affect any admitted Portable semantic today?
4. Would preserving it introduce accidental freshness/matching/conflict authority?
5. Would exporting it expose installation/use chronology without a corresponding ownership requirement?
6. Can the admitted Phase 1C capability be satisfied without it?
7. Would exclusion prevent a known accepted near-term consumer?

For these five fields, current evidence does not identify an accepted consumer that requires source-instant preservation.

---

# 8. Alternatives considered

## Alternative A — Admit all five as ROUND-TRIP PORTABLE STATE

Advantages:

- highest literal fidelity to current SwiftData lifecycle fields;
- source creation/mutation instants survive fresh-store restoration;
- candidate record shapes need little structural change.

Problems:

- equates persistence with Portable ownership;
- preserves bootstrap-generated reference timestamps with no demonstrated user-facing meaning;
- makes Transaction `updated_at` a public round-trip fact despite its current operational invalidation role;
- creates restoration obligations no accepted product capability currently consumes;
- expands timestamp lexical/versioning surface;
- exposes source-installation activity chronology without a demonstrated requirement.

Disposition:

REJECT.

The evidence does not earn this level of public commitment.

## Alternative B — Emit all five as INFORMATIONAL EXPORT METADATA

Advantages:

- preserves source-side inspection/audit context in exported artifacts;
- avoids requiring exact restoration.

Problems:

- no current admitted consumer requires the values;
- creates a half-portable surface that later agents may mistake for freshness or conflict authority;
- adds lexical and privacy/correlation surface without round-trip value;
- re-export after restoration may differ by design;
- makes complete-export artifacts carry metadata whose public use is unclear.

Disposition:

REJECT for v1.

The middle category is valid in principle but is not earned merely to avoid choosing between ownership and exclusion.

## Alternative C — Transaction.created_at ROUND-TRIP; exclude the other four

Rationale:

Transaction creation time may appear more closely tied to a durable financial record than reference bootstrap time or mutable `updated_at`.

Advantages:

- preserves one potentially meaningful piece of ledger history;
- avoids exporting operational `updated_at` and seed/bootstrap timestamps.

Problems:

- current production does not present or consume Transaction `created_at` as financial semantics;
- ordinary Review does not expose the generated instant;
- Phase 1C has no accepted audit/history consumer that requires source creation instant;
- creates a one-field round-trip commitment primarily from intuition rather than admitted product semantics.

Disposition:

DO NOT ADMIT ON CURRENT EVIDENCE.

This may be reconsidered by a future version or audit-history capability.

## Alternative D — Exclude all five ordinary canonical-record lifecycle timestamps from Portable v1

Rule:

- none of the five timestamps appear in the Portable v1 semantic record;
- destination canonical objects may receive new local lifecycle timestamps during supported restoration;
- those local timestamps are outside Portable semantic equivalence;
- current source values remain untouched in the originating store.

Advantages:

- satisfies the admitted ownership capability without serializing internal lifecycle machinery;
- avoids turning `updated_at` into public freshness/conflict authority;
- avoids preserving installation-local bootstrap chronology for reference defaults;
- reduces privacy/correlation surface;
- removes unnecessary timestamp lexical dependencies from Transaction and ordinary reference schemas;
- preserves a clean future boundary for a separately admitted audit/history model if product value later earns one.

Cost:

- source installation creation/update chronology is not portable in v1;
- later introduction of lifecycle-history portability would require an additive/new-version contract.

Disposition:

**RECOMMENDED.**

This is the minimum sufficient contract supported by current evidence.

---

# 9. Proposed per-field disposition

| Field | Proposed disposition | Reason |
| --- | --- | --- |
| `Transaction.created_at` | EXCLUDED FROM PORTABLE V1 | durable local creation metadata; no admitted consumer requires source instant |
| `Transaction.updated_at` | EXCLUDED FROM PORTABLE V1 | machine-maintained mutation metadata with current operational refresh coupling; no portable freshness authority |
| `Category.created_at` | EXCLUDED FROM PORTABLE V1 | often bootstrap-generated installation-local chronology; no admitted portable semantic |
| `PaymentMethod.created_at` | EXCLUDED FROM PORTABLE V1 | often bootstrap-generated installation-local chronology; no admitted portable semantic |
| `Tag.created_at` | EXCLUDED FROM PORTABLE V1 | often bootstrap-generated installation-local chronology; no admitted portable semantic |

No in-scope field uses INFORMATIONAL EXPORT METADATA in v1.

That is deliberate.

---

# 10. Round-trip consequence

Under the proposed rule:

    Store A canonical Transaction
    created_at = A-created
    updated_at = A-updated
            ↓
    Portable JSON v1
    no ordinary lifecycle timestamps
            ↓
    supported restoration in Store B
            ↓
    new canonical Transaction
    created_at = B-local
    updated_at = B-local

This can still be a successful Portable semantic round trip because the A lifecycle timestamps were not admitted portable semantics.

Likewise:

    Store A Category
    created_at = bootstrap-A
            ↓
    Portable record
    no created_at
            ↓
    Store B supported restoration
            ↓
    local Category lifecycle timestamp may differ

Portable equivalence remains based on admitted financial/reference semantics and relationships.

Raw lifecycle timestamp equality is not required.

---

# 11. Transaction.updated_at operational boundary

The proposal explicitly separates:

    Portable semantic state
    from
    local operational invalidation state

Current `TransactionDetailView.evidenceResolutionKey` uses `updated_at`.

If this proposal is later accepted, that current local use remains allowed.

But the Portable contract must not turn an imported historical `updated_at` into:

- evidence availability authority;
- freshness authority;
- merge precedence;
- overwrite permission;
- conflict winner;
- synchronization version;
- object identity.

Because `updated_at` is proposed excluded, supported restoration should use the receiving installation's ordinary local lifecycle behavior rather than importing a source-store operational token.

No production implementation change is authorized by this proposal.

---

# 12. Privacy / correlation consequence

Lifecycle timestamps reveal chronology about when a record or installation-local default was created or last edited.

Portable v1 already contains financial dates where those dates are admitted user-owned financial facts.

The five timestamps in this gate do not currently have equivalent admitted product meaning.

Excluding them avoids adding an unnecessary source-installation activity/correlation surface.

This does not make Portable exports anonymous.

It applies Minimum Sufficient Contract to metadata that current ownership semantics do not require.

---

# 13. Exact schema consequence

If this proposal is later accepted, candidate exact schemas should no longer include:

- Transaction `created_at`;
- Transaction `updated_at`;
- Category `created_at`;
- PaymentMethod `created_at`;
- Tag `created_at`.

That does not delete those fields from SwiftData.

It only removes them from the Portable v1 DTO contract.

This resolves the lifecycle-timestamp dependency before exact Category / PaymentMethod / Tag schema admission.

---

# 14. Lexical timestamp consequence

Because all five in-scope timestamps are proposed excluded, their exact RFC 3339 fractional-second canonicalization no longer blocks Transaction or ordinary reference-record schema closure.

Timestamp lexical work still remains where timestamps are actually admitted or proposed, including:

- top-level `exported_at`;
- any Source/provenance temporal field later admitted.

Therefore:

    ordinary lifecycle timestamp exclusion
    !=
    all timestamp lexical work is closed

---

# 15. Compatibility consequence

An existing canonical record with any valid current value in these lifecycle fields remains representable under the proposed Portable v1 semantics because the fields are outside the admitted portable projection.

This is not silent loss inside an admitted field.

It is explicit format exclusion.

Preserve:

    excluded by accepted public contract
    !=
    unrepresentable admitted state

and:

    excluded source field
    !=
    permission to mutate source canonical state

No separate historical compatibility failure is created merely because source lifecycle timestamps differ from the destination's local values after restoration.

---

# 16. JSON / CSV consequence

This gate is principally a Portable JSON semantic decision.

Lumen CSV v1 already does not carry these five lifecycle fields.

The proposed exclusion therefore keeps JSON and CSV from accidentally assigning conflicting shared semantics to ordinary record lifecycle history.

CSV remains narrower for many other reasons and is not promoted to complete ownership equivalence.

---

# 17. Reasoning Framework Check

## First Principles

User/product capability:

Export and restore meaningful durable financial/reference state without blindly serializing internal persistence machinery.

Established facts:

- all five fields are durable;
- all are generated automatically in ordinary current workflows;
- reference `created_at` is generated during bootstrap;
- Transaction `updated_at` is machine-maintained and operationally consumed;
- no inspected current user-facing financial workflow uses these instants as financial meaning;
- the Phase 1C contract admits only explicitly supported durable fields.

Minimum sufficient contract:

Exclude the five ordinary lifecycle timestamps from Portable v1.

Stronger behavior intentionally not admitted:

- portable audit-history semantics;
- cross-installation source creation chronology;
- portable last-edit/freshness semantics.

## Assembly Map

Prerequisites:

- Phase 1C ownership responsibility contract;
- accepted financial-date semantics;
- accepted ordinary reference-entity durable export-set semantics;
- accepted Portable identity semantics.

New subassembly:

A precise boundary between portable semantic records and installation-local ordinary lifecycle metadata.

Consumers:

- exact Transaction shape;
- exact Category / PaymentMethod / Tag schemas;
- timestamp lexical gate;
- deterministic serializer;
- round-trip restoration semantics.

Unresolved dependencies:

None block this disposition.

Irreversible commitment:

Portable v1 will not preserve source installation ordinary lifecycle timestamps for these five fields.

## Authority Budget

New normative authority proposed:

The Portable v1 format may exclude these five lifecycle timestamps from its admitted semantic state while still claiming complete ownership of the fields/entities v1 explicitly supports.

Governing basis if accepted:

Phase 1C ownership contract plus independent admission of this proposal.

Evidence establishing preconditions:

Current model defaults, Transaction mutation paths, reference bootstrap behavior, current consumers, and persistence tests.

Authorities explicitly not granted:

- delete or reset source-store timestamps;
- use imported timestamps for identity;
- use them for conflict/freshness authority;
- redefine Source temporal semantics;
- redefine financial civil dates;
- add audit-history semantics.

Transitive-authority check:

Current operational use of `updated_at` does not transfer freshness/conflict authority into Portable v1.

## Assembly Pressure

This proposal does not generalize:

    machine-generated timestamp
    -> always exclude

`exported_at` has a distinct export-event purpose.

Source/provenance timestamps may have separate evidence meaning.

Financial dates already have admitted user-owned semantics.

## Counterexamples

The proposal explicitly handles:

- automatically generated but stable Transaction `created_at`;
- mutable Transaction `updated_at`;
- `updated_at` operationally used for evidence refresh;
- seeded reference records with installation-specific creation times;
- explicit test injection of historical timestamp values;
- fresh-store restoration producing different local lifecycle times.

None requires these values to become Portable semantic state.

## Assembly Debt

None in the strict semantic sense.

The lifecycle disposition is the unresolved prerequisite blocking genuinely exact ordinary reference schemas.

## Irreversible Commitments

Exclusion means a v1 artifact cannot later be interpreted as having preserved source-side ordinary lifecycle chronology.

If future product value requires audit/history portability, that richer contract must be admitted explicitly and compatibly rather than inferred from v1.

---

# 18. Exact proposed contract language

The following language is **PROPOSED FOR REVIEW**, not accepted:

> **Ordinary canonical-record lifecycle timestamps.** Portable JSON v1 does not admit `Transaction.created_at`, `Transaction.updated_at`, `Category.created_at`, `PaymentMethod.created_at`, or `Tag.created_at` as portable semantic fields.
>
> These values remain valid current persistence state in their originating store. Their exclusion from Portable v1 does not authorize mutation, deletion, or normalization of source canonical state.
>
> Supported fresh-store restoration may create new installation-local lifecycle timestamps for restored Transactions, Categories, PaymentMethods, and Tags. Equality of those destination-local values with source-store lifecycle timestamps is not part of Portable v1 semantic round-trip equivalence.
>
> In particular, `Transaction.updated_at` carries no Portable identity, merge, overwrite, freshness, conflict, restoration, synchronization, or ordering authority. Current local operational use of that field does not convert it into portable authority.
>
> Portable v1 does not use an informational-only representation of these five lifecycle timestamps. If future product value requires portable audit/history chronology, that capability requires separate admission rather than being inferred from v1.
>
> This disposition does not govern top-level `exported_at`, financial `transaction_date` / `posted_date`, `UserProfile` lifecycle fields, or any `TransactionSource` / provenance temporal fields.

---

# 19. Downstream consequences if accepted

1. remove these five lifecycle fields from candidate Portable record shapes;
2. exact Category / PaymentMethod / Tag schema work no longer depends on their timestamp disposition;
3. Transaction exact-schema work no longer carries `created_at` / `updated_at`;
4. exact timestamp fractional-second spelling remains necessary only for timestamp fields actually admitted elsewhere;
5. restoration may generate new local lifecycle timestamps without violating Portable semantic equivalence;
6. imported external timestamps must not be smuggled into `updated_at` as freshness/conflict authority;
7. no persistence/schema migration is implied.

---

# 20. Remaining gates

Still open after this proposal:

- independent review/admission of this lifecycle disposition;
- exact Category schema;
- exact PaymentMethod schema;
- exact Tag schema;
- reference-record representability/compatibility once those schemas close;
- reference restoration/conflict semantics;
- PortableMoney lexical/governance closure;
- exact financial-date lexical/year validity;
- Source/provenance portability and its temporal semantics;
- top-level `exported_at` / admitted timestamp lexical rules;
- deterministic Portable-ID allocation and array ordering;
- unknown-field/evolution policy;
- full Portable JSON / CSV v1 acceptance.

---

# 21. Review questions

Independent review should answer:

1. Does persistence alone correctly fail to establish portable authority for these fields?
2. Is exclusion of all five the minimum sufficient v1 contract?
3. Does Transaction `created_at` have enough current product meaning to justify a stronger disposition despite having no inspected user-facing consumer?
4. Does `Transaction.updated_at` operational use remain correctly separated from portable freshness/conflict authority?
5. Are reference `created_at` values correctly treated as installation-local lifecycle chronology, especially for bootstrap-created records?
6. Is the informational-metadata disposition defined strictly enough, and is rejecting it for all five fields justified?
7. Does source/destination lifecycle timestamp inequality correctly remain outside semantic round-trip equivalence?
8. Does this gate avoid leaking into Source/provenance, financial-date, exact lexical, or implementation work?
9. Does the proposed exclusion simplify exact reference schemas without silently redefining the already accepted owned record set?
10. Are there any accepted near-term consumers that actually require source instant preservation and were missed by this evidence trace?

---

# 22. Review boundary

This proposal remains **PROPOSED FOR REVIEW**.

Do not record acceptance without independent review.

Do not open exact reference-schema, Source/provenance, deterministic-ordering, or another Phase 1C gate from this checkpoint without separate authorization.
