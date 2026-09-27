# Lumen Portable v1 Financial-Date Conversion, Compatibility, and Restoration Semantics

## Status

**PROPOSED FOR REVIEW — Phase 1C date-semantics research/proposal gate.**

- **Frozen effective Phase 1C proposal-development baseline:** `ab7e75675b1d11061fdac30cb8ed4f2189103598`
- **Branch:** `docs/phase1c-portable-v1-financial-date-semantics-proposal`
- **Governing methodology:** `docs/architecture/LUMEN_ENGINEERING_REASONING_FRAMEWORK.md`
- **Implementation disposition:** no production Swift, schema, migration, importer, exporter, or persisted civil-date change is authorized.
- **Characterization disposition:** bounded probe tests may establish current representation behavior. They are evidence instruments, not product acceptance gates.

This gate is intentionally limited to `Transaction.transaction_date`, `Transaction.posted_date`, their proposed Portable JSON / Lumen CSV `YYYY-MM-DD` meaning, compatibility/export disposition, restoration into the current Foundation `Date` representation, and semantic round-trip equivalence.

It does not decide lifecycle timestamps, PortableMoney spelling, reference-entity schemas/export sets, Source/provenance portability, deterministic Portable-ID allocation, array ordering, parser evolution, or a new persisted civil-date type.

---

# 1. Central decision question

> Given that current canonical `transaction_date` and `posted_date` persist Foundation `Date` instants without durable per-record civil-date context—and may arise through user-selected, inherited, default-generated, or system-synthesized paths—what Portable v1 financial calendar-date meaning can Lumen truthfully export as `YYYY-MM-DD`, which canonical states actually warrant or can preserve that meaning, and what restoration rule can preserve the admitted meaning without inventing unavailable or never-established financial facts?

The problem is not primarily formatting. It is semantic authority and representability.

---

# 2. Framework check

## First-Principles Lens

The user-facing concept is a financial calendar day. The current storage type is an instant. Those are not interchangeable.

The gate therefore asks what fact Lumen owns before asking how to spell it.

## Repository-Evidence Discipline

Current evidence establishes:

- both fields persist Foundation `Date` values (`posted_date` optional);
- `TransactionDraft.transaction_date` defaults to `.now`;
- `TransactionDraft.posted_date` defaults to `nil`;
- both form controls use `DatePicker(... displayedComponents: .date)`;
- no production code normalizes either field with `startOfDay` before persistence;
- editing an existing Transaction copies both stored values unchanged into the draft;
- new confirmation with status `posted` synthesizes `posted_date = .now` when the draft has no posted date;
- an existing non-posted Transaction transitioned to `posted` through edit application similarly synthesizes `.now` when no posted date was supplied;
- the direct Transaction Detail status action also synthesizes `.now` when moving to `posted` and the field is nil;
- existing persisted `posted + nil` state is a compatibility state and must not be reinterpreted merely because current new-posting paths often fill the field;
- current date-window analytics can classify one unchanged instant differently under different calendars/timezones without rewriting the stored instant;
- Phase 1A deliberately left richer civil-date semantics for future work and retained existing Date values as instants interpreted in the device calendar/timezone.

Evidence supports these observations. It does not by itself grant a new Portable semantic.

## Minimum Sufficient Contract

The smallest complete public commitment must:

1. define the calendar used by Portable year/month/day;
2. define when a current canonical state truthfully warrants that financial-day meaning;
3. preserve true absence separately from incompatibility;
4. define export compatibility without guessing;
5. define restoration meaning without silently promoting an implementation time-of-day;
6. keep JSON and CSV semantically identical for shared fields.

It does **not** require solving persistence with a schema migration in this gate.

## Assembly Map

```text
current canonical Date / nil
        ↓
field provenance + authority analysis
        ↓
financial-date compatibility
        ↓
Portable civil-date semantic
        ↓
YYYY-MM-DD lexical representation
        ↓
restoration interpretation
        ↓
semantic round-trip test
```

Later deterministic serialization may consume this decision. It must not establish it.

## Authority Budget

```text
Date instant exists
!= original civil-date context is recoverable

DatePicker displayed a day
!= hidden time-of-day was user-confirmed

status == posted
!= missing posted_date may be inferred

posted_date != nil
!= status must be posted

system generated posted_date at T
!= external institution posted on financial day D
```

Any normative Portable meaning must come from an accepted contract/admission. Evidence only establishes the factual preconditions.

## Assembly Debt

No new lower-level unresolved semantic dependency is introduced by researching this gate. Final deterministic record serialization would incur Assembly Debt if it assumed a date meaning before this gate closes.

## Assembly Pressure

No generalized civil-date infrastructure is admitted here. One public date contract may later earn a production representation seam, but that is downstream implementation work.

## Counterexamples

The proposal must survive:

- an instant near a timezone day boundary;
- DST spring-forward and fall-back dates;
- a non-default/non-Gregorian device calendar;
- `posted + nil`;
- non-posted + nonnil `posted_date`;
- new `posted` confirmation whose reviewed draft has nil `posted_date`;
- environment A export followed by environment B export of the unchanged instant;
- Portable date restoration in environment B followed by re-export in environment C.

## Irreversible Commitments

Publicly declaring `YYYY-MM-DD` to mean an original financial day would create an interoperability and ownership promise. Current storage must not be made to appear more informative than it is.

---

# 3. Two distinct information failures

## 3.1 Lost information

```text
Lumen may once have displayed or accepted a civil-day meaning
        ↓
only a Date instant survives durably
        ↓
originating calendar/timezone context is absent
```

For a user-reviewed `transaction_date`, confirmation may plausibly establish the visible day-level meaning. Current storage still does not retain enough context to prove that same day invariantly after an environment change.

## 3.2 Never-owned information

```text
Lumen generates/stores Date T
        ↓
no independent event establishes stronger external fact D
```

A synthesized `posted_date = .now` proves at least that Lumen saved or transitioned the record as posted around T. It does not by itself prove that an external financial institution posted the transaction on the corresponding calendar day.

> **Lost information != never-owned information.**

The exporter must not repair either condition by guessing.

---

# 4. Value origin and authority-event taxonomy

## 4.1 transaction_date

| Value origin | Repository path | Candidate authority event | What is established before this gate is accepted |
| --- | --- | --- | --- |
| Draft default `.now` | `TransactionDraft` initialization | Review → Confirm | A Date value exists; Review shows a date-only rendering before confirmation. The stronger durable civil-day contract remains to be admitted. |
| Explicit DatePicker interaction | Transaction form | Review → Confirm or edit Save | User selects through a date-only control, but the resulting Date is persisted unchanged; hidden time/context behavior is not a Portable fact. |
| Upload-flow untouched default | upload-created draft using ordinary draft defaults | Review → Confirm | Confirmation can canonize the reviewed Transaction, but source acquisition did not independently establish the transaction day. |
| Inherited existing value | `TransactionDraft.init(from:)` | edit Save if edited; otherwise preservation | Existing instant is preserved. Original calendar/timezone/provenance is not reconstructed. |

Candidate field-specific principle:

> Confirmation may grant authority to the **visible date-level meaning actually presented for confirmation**. It does not grant semantic authority to hidden time-of-day, timezone, or instant details that were not presented as financial meaning.

That principle is proposed, not yet accepted.

## 4.2 posted_date

| Value origin | Repository path | Candidate authority event | What is established before this gate is accepted |
| --- | --- | --- | --- |
| `nil` | default/current canonical state | none required | Exact absence. |
| Explicit DatePicker value | user adds/edits posted date | Review → Confirm or edit Save | User-visible date-level meaning may be confirmed; hidden instant payload is not thereby public meaning. |
| Synthesized during new posted confirmation | `makeTransaction`: `posted_date ?? .now` | confirmation creates record | Lumen generated a posting-associated instant after the draft could have been reviewed with no Posted row. External-institution posting day is not established by that synthesis alone. |
| Synthesized on edit transition to posted | `apply(to:)` | edit Save | Lumen generated an instant because status changed. Stronger external posting-day meaning is not established by synthesis alone. |
| Synthesized by direct status action | Transaction Detail `setStatus` | status action | Same limitation: action time is known; external posting day is not independently known. |
| Inherited canonical value | edit draft copies persisted value | preservation/edit | Stored instant exists; original provenance/context may be unavailable. |

---

# 5. Status × posted_date state space

The persisted model does not structurally constrain `posted_date` by status. Existing-record editing exposes all five persisted status tokens.

The compatibility analysis therefore treats the conceptual matrix as:

| Status | `posted_date == nil` | `posted_date != nil` |
| --- | --- | --- |
| `pending` | representable current state | model can preserve/store; presence does not imply posted |
| `posted` | known compatibility state; must remain true absence | common current state, provenance may vary |
| `ignored` | model can preserve/store | model can preserve/store |
| `duplicate` | model can preserve/store | model can preserve/store |
| `review_needed` | model can preserve/store | model can preserve/store |

This table does not reopen accepted status semantics and does not claim every cell has an authentic historical fixture.

Normative candidate invariants:

```text
status
!= authority to infer posted_date

posted_date presence
!= proof of posted status

posted_date == nil
= exact absence

posted_date == nil
!= ambiguous/incompatible nonnil date
```

No exporter may convert an unresolved nonnil date into null.

---

# 6. Calendar authority and timezone authority

A Portable value such as `2026-03-01` needs three separate decisions:

1. **calendar system** — what year/month/day system gives the digits meaning;
2. **conversion context** — what timezone/context maps an existing instant into that calendar;
3. **restoration convention** — what calendar/timezone/time-of-day maps the civil day back into Foundation `Date`.

These are not supplied merely by:

- `Calendar.current`;
- current locale;
- device timezone;
- an ISO-looking formatter;
- the Foundation `Date` type.

## Candidate calendar

For interoperability, the strongest candidate is the **proleptic Gregorian calendar** represented lexically as fixed-width ASCII `YYYY-MM-DD`.

This is proposed because Portable v1 needs one installation-independent calendar system. It is not derived from the user's current display calendar.

## Conversion-context problem

No durable per-Transaction field records the calendar/timezone under which an existing `transaction_date` or `posted_date` acquired its user-facing day meaning.

Therefore neither of these is presently justified as a universal recovery rule:

```text
current device timezone
= original financial-date timezone

UTC day containing the instant
= original user-confirmed financial day
```

A fixed UTC projection is deterministic, but it answers a different question: **which Gregorian UTC day contains this instant?** It must not be relabeled as recovered original financial-day truth without a governing semantic decision.

---

# 7. Hidden time component

Source inspection establishes that `DatePicker(... displayedComponents: .date)` binds directly to the draft `Date`. No production normalization to `startOfDay` occurs before persistence.

Therefore:

```text
date-only control
!= proven midnight normalization

hidden Date time-of-day
!= automatically admitted Portable meaning
```

A bounded characterization test accompanies this proposal for timezone/calendar/DST projection and restoration behavior. Direct SwiftUI DatePicker interaction remains a UI/runtime characterization question; source evidence alone is sufficient to establish that Lumen does not explicitly normalize the bound Date before persistence.

---

# 8. Compatibility alternatives

## Alternative A — recover original financial civil day from current Date

**Not supported by current evidence as a universal rule.**

The originating per-record timezone/calendar is not durably retained. Some records may once have had a visible confirmed day, but arbitrary historical recovery cannot be proven.

## Alternative B — require per-record explicit resolution/context

Truthful but operationally heavy. Current canonical records do not carry a durable flag distinguishing explicit selection, default confirmation, inherited values, or synthesized posted dates. A future resolution workflow could supply missing authority, but this gate does not design one.

## Alternative C — classify unsupported states as incompatible with the stronger Portable financial-day contract

Semantically conservative. If Portable v1 promises preservation of a durable financial civil day, current storage cannot prove that promise for every canonical nonnil Date.

This can protect ownership truth but may make complete export unavailable until a separate resolution/storage strategy exists.

## Alternative D — define Portable dates as export-time observed calendar days

This is implementable without historical recovery if the governing environment is defined.

However:

- device-local observation is not stable across timezone/calendar changes;
- fixed UTC observation is stable but is not necessarily the user's financial day;
- the result is a projection of an instant, not recovery of historical civil intent.

This is a materially weaker product semantic and should be named as such if selected.

## Proposed disposition for review

**Do not collapse the contract to Alternative D merely to make serialization easy.**

For the intended meaning “financial calendar date,” the proposal recommends treating the stronger date semantic as **not universally recoverable from current persisted Date state**.

Candidate compatibility taxonomy:

- **EXACTLY WARRANTED** — the exporter has an admitted, durable basis for the financial civil day;
- **CONTEXT / RESOLUTION REQUIRED** — a financial day may be resolvable only with separately admitted context or explicit user resolution;
- **SEMANTICALLY INCOMPATIBLE** — the requested stronger date meaning cannot be truthfully established from available canonical state;
- **ABSENT** — only for nullable `posted_date == nil`.

At present, the existing model does not durably encode enough provenance/context to classify arbitrary historical nonnil Date records as EXACTLY WARRANTED solely from their stored fields.

This is intentionally a proposal result, not an implementation authorization.

---

# 9. Complete-export consequence alternatives

The money gate established a useful pattern: incompatibility must be explicit. It did not grant dates the same all-or-nothing policy automatically.

Alternatives:

1. **All-or-nothing complete ownership export:** any required incompatible `transaction_date` or incompatible nonnil `posted_date` prevents a claim of complete Portable JSON ownership export.
2. **Explicit resolution prerequisite:** complete export pauses until required date semantics are resolved under an admitted workflow.
3. **Weaken the public date meaning:** admit an export-observed projection instead of durable financial-day truth.

### Candidate recommendation

If Portable v1 retains the stronger “financial calendar date” meaning, a complete ownership export **must not claim complete success while guessing or projecting an incompatible required date**.

The exact operational choice between failure and a future explicit-resolution workflow remains downstream. What is proposed here is the truthfulness invariant:

> A claimed complete Portable ownership export may not silently substitute an environment-dependent or UTC projection for an admitted financial civil-date fact that Lumen cannot establish.

For nullable `posted_date`, exact absence remains exportable as null/blank according to the containing format's admitted null representation. Incompatibility of a nonnil date is never converted to absence.

---

# 10. Restoration alternatives

Portable `YYYY-MM-DD` contains no instant, timezone, or time-of-day.

Restoring it into current Foundation `Date` therefore necessarily adds representation that is not present in the portable value.

## R1 — environment-local midnight

Simple, but environment-dependent. Re-export after timezone/calendar changes can shift the observed day.

## R2 — fixed-calendar/fixed-zone anchor instant

For example, a proleptic-Gregorian day mapped to a documented fixed-zone anchor time.

This can improve deterministic reconstruction, but the anchor instant is an implementation representation, not user financial meaning. Extreme timezone changes can still make a Date render as an adjacent local day if ordinary UI continues to interpret it using the device environment.

## R3 — new durable civil-date representation

Would directly preserve the semantic but requires schema/migration work explicitly outside this gate.

## Proposed restoration conclusion

Current `Date` storage can reconstruct **an instant representing a portable day under a documented convention**, but it cannot make that instant intrinsically timezone-independent when existing UI/helpers later reinterpret it through arbitrary device calendars/timezones.

Therefore a strong invariant such as:

```text
Portable D
→ restore to current Date
→ arbitrary device environment change
→ ordinary current Date rendering/re-export
→ always D
```

cannot be guaranteed solely by choosing a clever hidden time-of-day for all possible environments.

A future implementation can preserve Portable day semantics only if the governing conversion context remains explicit at the portability boundary or the canonical representation evolves. This proposal does not authorize that evolution.

---

# 11. Round-trip equivalence

Raw Foundation `Date` equality is **not** the proposed Portable date equivalence criterion.

Candidate semantic equivalence is:

```text
same admitted Portable calendar
+
same admitted financial civil day
+
same absence state for nullable posted_date
```

For `posted_date`, semantic equivalence additionally requires that restoration not upgrade a weaker/synthesized fact into a stronger external-institution posting claim.

A restored implementation anchor time is not itself part of Portable semantics unless separately admitted.

---

# 12. Cross-environment stability

For a durable financial-day contract, the desired public property is:

```text
same admitted financial-date fact
→ same Portable YYYY-MM-DD
regardless of device locale/calendar/timezone
```

Current arbitrary Date instants do not supply enough information to guarantee that they encode such a fact.

A current-environment formatter therefore fails the desired stability property at timezone boundaries.

A fixed UTC projection can satisfy representation stability for the instant but does not prove financial-day semantic fidelity.

This distinction is central:

```text
deterministic projection
!= truthful recovery
```

---

# 13. Current helper behavior is not Portable authority

Current code uses Date as an instant in implementation behavior including:

- calendar-window analytics;
- duplicate-similarity time intervals;
- ordinary date rendering.

Those consumers characterize today's representation.

They do not automatically establish that Portable v1 must preserve:

- hidden time-of-day;
- raw instant identity;
- current device calendar;
- current duplicate-window mechanics.

Portable semantics should preserve the admitted financial fact, not incidental richness of the storage type.

---

# 14. JSON / CSV shared rule

Candidate shared semantic rule:

> In Portable JSON v1 and Lumen CSV v1, `transaction_date` and non-absent `posted_date` represent the same admitted proleptic-Gregorian financial civil-day semantic using `YYYY-MM-DD`. CSV is not permitted to reinterpret an incompatible Date using locale-specific formatting or a different timezone rule.

Representation of true absence may differ according to each format's already-admitted null/blank mechanics, but semantic absence is identical.

---

# 15. Exact candidate contract language

The following language is proposed for independent review, not accepted:

> **Portable financial calendar.** Portable v1 financial-date values use the proleptic Gregorian calendar and fixed-width ASCII `YYYY-MM-DD` spelling. Device locale, device calendar, and formatter defaults do not define Portable calendar authority.

> **Financial-date meaning.** `transaction_date` and a non-null `posted_date` denote admitted financial civil-day meanings, not generic instants. Foundation `Date` is the current persistence representation and does not, by itself, prove the originating civil-day context.

> **Field-specific authority.** Confirmation or editing may establish the date-level meaning actually presented to the user under the governing workflow. It does not automatically grant Portable authority to hidden time-of-day, timezone, or instant details that were not presented as financial meaning. A system-synthesized `posted_date` establishes the fact admitted by that workflow; it must not be upgraded without separate authority into proof of an externally observed financial-institution posting day.

> **Absence.** `posted_date == nil` is exact absence. An unresolved or incompatible nonnil posted Date must not be serialized as null/blank merely because its financial civil-day meaning cannot be established.

> **Status independence.** Transaction status does not authorize inference of a missing `posted_date`, and presence of `posted_date` does not establish Transaction status.

> **Compatibility.** A current canonical Date is Portable-financial-date compatible only when Lumen has an admitted basis for mapping it to the required financial civil day. Current device timezone, current device calendar, or a fixed UTC projection must not be treated as recovery of original financial-day intent unless the governing contract explicitly defines that weaker projection as the Portable meaning.

> **Complete export truthfulness.** A claimed complete Portable ownership export must not silently guess, null, normalize, or substitute an environment-dependent/UTC projection for a required admitted financial civil-day fact that cannot be established. The operational resolution/failure mechanism remains separately gated.

> **Restoration.** Restoring `YYYY-MM-DD` into the current Foundation `Date` representation necessarily uses a documented calendar/timezone/time-of-day convention. The resulting anchor instant is representation, not additional Portable financial meaning. Semantic round-trip equivalence is evaluated on the admitted financial civil day and absence state, not raw Date equality.

> **JSON/CSV equivalence.** Shared financial-date fields have the same semantic meaning in Portable JSON v1 and Lumen CSV v1. Syntax or null representation may differ only where separately admitted; date meaning may not.

---

# 16. Characterization plan

The bounded probe evidence should establish, without production changes:

1. one instant can project to different Gregorian civil days in UTC vs America/Los_Angeles;
2. the same instant can produce different year/month/day components under different calendar systems;
3. DST transition dates do not justify assuming every civil day has a uniform 24-hour duration;
4. a restored day mapped to an anchor instant can re-render as an adjacent day in another timezone;
5. direct model state can preserve `posted_date` independently of status;
6. current creation/status-transition code synthesizes `.now` for selected posted workflows;
7. no source-level start-of-day normalization exists before persistence.

The tests are characterization evidence only.

---

# 17. Unresolved implications

Independent review must decide whether the intended Portable v1 product contract should:

- retain the stronger durable financial-day meaning and accept that current historical state may require explicit resolution / be incompatible;
- deliberately adopt a narrower projection semantic;
- or defer final financial-date admission until a future storage/resolution design can support the stronger meaning.

If the stronger meaning is retained, later work must decide how complete export handles incompatible current records operationally.

If restoration into Foundation `Date` remains part of v1 implementation, later implementation design must ensure the representation convention does not silently become new semantic authority.

This gate does not choose a SwiftData migration or new civil-date field.

---

# 18. Review boundary

This proposal remains **PROPOSED FOR REVIEW**.

It does not:

- accept the date contract;
- change the canonical model;
- authorize exporter/importer implementation;
- alter existing records;
- reopen status semantics;
- change lifecycle timestamps;
- open deterministic serialization/order.

After the proposal and characterization evidence are committed, stop for independent review.
