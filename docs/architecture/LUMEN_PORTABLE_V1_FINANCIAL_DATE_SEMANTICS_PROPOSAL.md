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

Value origin and semantic authority are separate questions.

```text
where a Date value came from
!=
what event grants financial-day authority
```

## 4.1 transaction_date

Portable `transaction_date` is proposed to mean the **user-owned financial transaction civil day** for the Transaction.

| Value origin | Repository path | Authority event | Proposed authority result |
| --- | --- | --- | --- |
| Draft default `.now` | `TransactionDraft` initialization | new Review → Confirm | Confirmation establishes the **visible transaction day presented in Review** as the user-authorized financial transaction day. The default's hidden instant/time-of-day is not thereby authorized. |
| Explicit DatePicker interaction before new confirmation | Transaction form | new Review → Confirm | Confirmation establishes the visibly selected financial transaction day. |
| Upload-flow untouched default | upload-created draft using ordinary draft defaults | new Review → Confirm | Confirmation establishes the visible reviewed transaction day. Source acquisition did not independently establish it. |
| Explicit date-field edit on an existing Transaction | DatePicker change followed by Save | explicit date-field edit + Save | The newly selected visible financial transaction day becomes the new user-authorized day. |
| Inherited existing value, unchanged during unrelated edit | `TransactionDraft.init(from:)` | unrelated Save | **No new date authority is created.** Saving another field does not reauthorize or reinterpret an unchanged date, even if the environment now renders the stored instant as another day. |
| Inherited existing value, no edit | persisted canonical state | none | Existing instant is preserved, but original calendar/timezone/provenance is not recovered merely from persistence. |

Field-specific rule:

> **New Review/Confirm establishes authority only for the date-level meaning actually presented for confirmation. An explicit financial-date-field edit followed by Save can establish new date-level authority. An unrelated edit does not reauthorize or reinterpret an unchanged inherited date. Hidden time-of-day, timezone, and raw-instant details that were not presented as financial meaning do not gain Portable authority merely because the Transaction was confirmed or saved.**

## 4.2 posted_date public meaning

Portable `posted_date` is proposed to mean the **Lumen-effective posting civil day**:

> **the financial civil day on which the Transaction is considered posted within Lumen's canonical ledger under an admitted user or Lumen posting workflow.**

It does **not** mean, and must not be presented as proof of:

- the financial institution's externally observed posting day;
- settlement day;
- clearing-network day;
- an independently verified bank/provider timestamp.

This choice deliberately gives explicit user selection and system posting transitions one public semantic instead of preserving indistinguishable mixed meanings.

A system transition can therefore establish a **Lumen-owned effective posting day** under the admitted posting workflow without pretending that the day was externally observed or user-confirmed.

## 4.3 posted_date authority events

| Value origin | Repository path | Authority event | Proposed authority result |
| --- | --- | --- | --- |
| `nil` | default/current canonical state | none required | Exact absence. |
| Explicit DatePicker value before new confirmation | user adds/edits posted date | new Review → Confirm | The visible selected value establishes a user-authorized Lumen-effective posting day. |
| Explicit DatePicker edit on existing Transaction | date-field edit + Save | explicit posted-date edit + Save | Establishes a newly user-authorized Lumen-effective posting day. |
| Synthesized during new posted confirmation | `makeTransaction`: `posted_date ?? .now` | admitted new-posted confirmation workflow | Establishes a **system-owned Lumen-effective posting day**, not a user-confirmed date and not an external-institution posting day. The current reviewed screen may have shown no Posted row. |
| Synthesized on edit transition to posted | `apply(to:)` | admitted status-transition Save | Establishes a system-owned Lumen-effective posting day under the transition rule; not external posting evidence. |
| Synthesized by direct status action | Transaction Detail `setStatus` | admitted direct posting action | Same Lumen-effective meaning; not external posting evidence. |
| Inherited canonical value, unchanged during unrelated edit | edit draft copies persisted value | unrelated Save | No new posted-date authority is created. |
| Inherited canonical value | persisted canonical state | none | Stored instant exists, but the current model does not preserve which authority path produced it or which calendar/timezone established its original civil day. |

The current durable model collapses explicit and synthesized nonnil `posted_date` provenance into the same `Date?` representation. Because Portable v1 now proposes **one Lumen-effective posted-day semantic**, that provenance collapse need not create two public meanings. It still creates a serious **recoverability** limitation: after persistence, the record does not prove which civil day was originally established.

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

# 8. Compatibility and authority classification

## 8.1 Current record-local classifiability

The current durable `Transaction` representation contains:

```text
transaction_date: Date
posted_date: Date?
status
other Transaction fields
```

It does **not** durably contain:

- the calendar used when a date-level meaning was established;
- the timezone used when that civil day was established;
- a provenance marker saying whether `transaction_date` was defaulted, explicitly selected, or inherited;
- a provenance marker saying whether nonnil `posted_date` was explicitly selected or system-synthesized;
- a durable copy of the visible date string the user confirmed.

Therefore:

> **For an arbitrary existing persisted nonnil `transaction_date` or `posted_date`, current Transaction state alone does not provide a general record-local proof of the originally established financial civil day.**

Accordingly, the class **EXACTLY WARRANTED FROM CURRENT TRANSACTION STATE ALONE** is not presently shown to contain arbitrary existing nonnil financial dates.

A value that happens to project to a plausible day does not cure this:

```text
plausible/currently displayed day
!=
durable authority for original financial civil day
```

A future accepted durable auxiliary source could change classifiability for a specific record, but no such general auxiliary authority is admitted by this proposal.

## 8.2 Recovery is not new authority

The proposal separates two operations that must not share one label.

### EXACTLY WARRANTED

The admitted durable state itself proves the financial civil day.

### RECOVERABLE WITH ADMITTED CONTEXT

The Transaction alone is insufficient, but separately admitted **already-existing durable evidence/context** can recover the previously established financial civil day without asking the user to invent or replace it.

No general current repository source has yet been admitted to perform this role for arbitrary Transaction dates.

### USER RESOLUTION REQUIRED

The available durable state cannot recover the financial civil day. A user must make a **new explicit authoritative date assertion**.

This is not recovery:

```text
existing fact recovered from evidence
!=
new user authority supplied now
```

A future resolution workflow could make the newly asserted day exportable. This gate does not design that UX or persistence mechanism.

### ABSENT

Only `posted_date == nil` has this state.

True absence is not a recovery failure.

## 8.3 Export readiness is a separate axis

Authority origin and export readiness are related but not identical.

A date may be:

- **READY** once exactly warranted or successfully recovered under admitted context;
- **NEEDS USER RESOLUTION** when new date authority is required and such resolution is admitted by the operation;
- **NOT EXPORT-COMPATIBLE AS-IS** when the requested stronger financial-day semantic cannot currently be established for the export operation;
- **ABSENT** for nullable `posted_date == nil`.

This avoids using “semantically incompatible” to mean both “not recoverable from current state” and “impossible to repair forever.”

## 8.4 Rejected convenience alternative — export-time observed projection

Defining Portable dates as the day observed at export time would avoid historical recovery.

However:

- device-local observation changes with timezone/calendar environment;
- fixed UTC observation is stable but is not necessarily the user-owned financial day;
- both are projections of an instant, not proof of the previously established financial civil day.

**This proposal rejects export-time observed projection as the primary Portable v1 financial-date meaning.**

The stronger user/Lumen-owned financial civil-day semantic is retained, with incompatibility/resolution consequences made explicit.

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

> **Portable financial calendar.** Portable v1 financial-date values use the proleptic Gregorian calendar and the candidate fixed-width ASCII date shape `YYYY-MM-DD`. Device locale, device calendar, and formatter defaults do not define Portable calendar authority. This gate selects the civil calendar and semantic date shape; exact admitted year range and complete lexical/parser validity rules remain separately gated. A syntactically shaped value is not thereby a valid calendar date.

> **transaction_date meaning.** Portable `transaction_date` denotes the user-owned financial transaction civil day, not a generic instant. A new Review/Confirm establishes the visible transaction day presented for confirmation. An explicit transaction-date-field edit followed by Save establishes a new user-authorized transaction day. An unrelated edit does not reauthorize or reinterpret an unchanged inherited date.

> **posted_date meaning.** Portable non-null `posted_date` denotes the **Lumen-effective posting civil day**: the financial civil day on which the Transaction is considered posted within Lumen's canonical ledger under an admitted user or Lumen posting workflow. It is not proof of an externally observed financial-institution posting, settlement, or clearing day.

> **posted_date authority.** Explicit user selection can establish a user-authorized Lumen-effective posting day. An admitted workflow that synthesizes a posting date when a Transaction becomes posted can establish a system-owned Lumen-effective posting day, but does not make that date user-confirmed or externally observed. An unrelated edit does not reauthorize an unchanged inherited posted date.

> **Hidden representation.** Confirmation or Save does not grant Portable authority to hidden time-of-day, timezone, or raw-instant details that were not presented or admitted as financial meaning.

> **Current durable classifiability.** Current Transaction state stores Date / Date? but no per-record calendar, timezone, confirmed civil-date spelling, or date-provenance class. Therefore an arbitrary existing nonnil `transaction_date` or `posted_date` is not generally proven **EXACTLY WARRANTED** from current Transaction state alone.

> **Recovery versus new authority.** Recovery using admitted already-existing durable context is distinct from explicit user resolution that creates or replaces financial-date authority. The format and exporter must not describe a new user assertion as recovery of historical truth.

> **Absence.** `posted_date == nil` is exact absence. An unresolved, not-export-compatible, or otherwise unsupported nonnil posted Date must not be serialized as null/blank merely because its financial civil-day meaning cannot be established.

> **Status independence.** Transaction status does not authorize inference of a missing `posted_date`, and presence of `posted_date` does not establish Transaction status.

> **Compatibility.** Current device timezone, current device calendar, export-time rendering, or a fixed UTC projection must not be treated as recovery of the admitted financial civil day. A deterministic projection is not truthful recovery.

> **Complete export truthfulness.** A claimed complete Portable ownership export must not silently guess, null, normalize, or substitute an environment-dependent/UTC projection for a required admitted financial civil-day fact that cannot be established. The exact failure/resolution mechanism remains separately gated.

> **Restoration.** Restoring `YYYY-MM-DD` into the current Foundation `Date` representation necessarily uses a documented calendar/timezone/time-of-day convention. The resulting anchor instant is representation, not additional Portable financial meaning. Semantic round-trip equivalence is evaluated on the admitted financial civil day and exact absence state, not raw Date equality.

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

This hardening pass now proposes the stronger Portable meaning rather than export-time projection:

- `transaction_date` = user-owned financial transaction civil day;
- `posted_date` = Lumen-effective posting civil day, not external-institution posting evidence;
- proleptic Gregorian = Portable calendar candidate;
- current arbitrary persisted nonnil Dates are not generally classifiable as exactly warranted from Transaction state alone.

Remaining implications are operational and storage-related rather than semantic ambiguity about those field names:

1. later work must decide whether and how admitted durable context can recover existing financial days;
2. later work must decide whether explicit user resolution is available and how a new authoritative assertion is persisted;
3. complete-export behavior must account for records that are not export-compatible as-is;
4. restoration into Foundation `Date` must not let its anchor representation become public financial meaning;
5. exact year domain and full lexical/parser validation for Portable dates remain separately gated.

If current storage cannot support the accepted ownership guarantee without future persistence evolution, that limitation must be carried forward explicitly.

This gate does not choose a SwiftData migration, new civil-date field, resolution UX, or exporter/importer implementation.

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


---

# 19. Branch / evidence audit

Audit before this bookkeeping update:

- frozen base: `ab7e75675b1d11061fdac30cb8ed4f2189103598`;
- proposal branch: `docs/phase1c-portable-v1-financial-date-semantics-proposal`;
- proposal commit: `3202505ae53e780150e5098c12673453acd8d20c`;
- characterization-source commit: `c8ea6c0f7743e2c12d28554481beabc86ab48ff3`;
- format-contract application commit: `56618a00b8d2b714b0566b53571296352c5aaedb`;
- compare against frozen base: ahead 3, behind 0;
- merge base remains exactly `ab7e75675b1d11061fdac30cb8ed4f2189103598`.

Changed files at that checkpoint:

1. `docs/architecture/LUMEN_PORTABLE_V1_FINANCIAL_DATE_SEMANTICS_PROPOSAL.md` — new proposal;
2. `docs/architecture/LUMEN_PORTABLE_JSON_CSV_V1_FORMAT_CONTRACT.md` — date sections only moved from evidence-gated placeholders to proposed-for-review candidate language;
3. `ios-lumen-finance/LumenFinanceTests/LumenFinanceTests.swift` — bounded characterization probes only.

No production Swift, model/schema, migration, workflow, importer/exporter, implementation-plan, PortableMoney, lifecycle-timestamp, reference-entity, Source/provenance, identity-allocation, ordering, or parser-evolution file changed.

The characterization probes were **not executed by this repository write**. The commits used `[skip ci]`, the commit has no reported status contexts, and no workflow run is associated with the checkpoint. Their current evidentiary status is therefore:

```text
probe source added
!= probe execution passed
```

Independent review should treat source-inspection findings and already-existing executable evidence separately from these newly added but not-yet-executed probes. No acceptance claim depends on pretending they ran.

This bookkeeping section does not record acceptance. The gate remains **PROPOSED FOR REVIEW**.
