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
an admitted workflow establishes a civil-day meaning
        ↓
only a Date instant survives durably
        ↓
originating calendar/timezone context is absent
```

For a new user-reviewed `transaction_date`, this proposal treats Review/Confirm as the authority event for the visible financial transaction day. For an explicit date-field edit, deliberate selection followed by Save establishes the new visible day.

Current storage still does not retain enough context to prove that same established day invariantly after a later environment change. That is a **lost-information** problem.

For `posted_date`, the revised public meaning is an **optional, separately authorized recorded posting civil day**. When such a day is explicitly supplied, reviewed/admitted from a source, deliberately edited, or restored under separately admitted authority, current storage can likewise lose the calendar/timezone context needed to recover that established day later.

## 3.2 Never-owned information

```text
status changes to Posted
        ↓
current code may synthesize Date T
        ↓
no separate posting-day authority event occurred
```

A synthesized `posted_date = .now` created solely because status became `posted` does **not** establish a separately authorized posting civil day. It also does not establish that an external financial institution posted, settled, or cleared the transaction on the corresponding day.

The lifecycle transition establishes the status fact. It does not automatically establish an additional date fact.

> **Lost information != never-owned information.**

The exporter must not repair either condition by guessing, and it must not treat current implementation synthesis as proof that a separate posting day was ever authorized.

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

## 4.2 posted status and posted_date are separate facts

This gate relies on the already-accepted narrower status fact:

> **`posted` is an ordinary Lumen financial-lifecycle status whose validity does not depend on a separately recorded `posted_date`.**

For explanatory product language, `posted` can be understood as a Transaction being treated as completed/non-provisional rather than pending in Lumen's ordinary financial lifecycle. This date gate does not replace or reopen the accepted five-status compatibility contract with a broader normative status definition.

Portable `posted_date` is instead proposed to mean:

> **an optional, separately authorized recorded posting civil day.**

The field is supplementary. A Transaction may truthfully be `posted` while `posted_date == nil`.

That includes, for example:

- a cash/manual Transaction with no distinct institution posting event;
- an institution-backed Transaction whose source exposes Posted state but no separate posting date;
- any otherwise-valid canonical Transaction for which a separate posting day has not been recorded.

`posted_date` is also **not** the timestamp or civil-day projection of when Lumen itself changed lifecycle status. Any future lifecycle-transition timestamp is a separate concept outside this gate.

## 4.3 posted_date authority events

| Value origin | Repository path | Authority event | Proposed authority result |
| --- | --- | --- | --- |
| `nil` | default/current canonical state | none required | Exact absence: no separately recorded posting day is claimed. |
| Explicit DatePicker value before new confirmation | user adds/edits posted date | new Review → Confirm | The visible field establishes a separately authorized recorded posting civil day. |
| Explicit DatePicker edit on existing Transaction | date-field edit + Save | explicit posted-date edit + Save | Establishes a newly authorized recorded posting civil day. |
| Reviewed institution/source-supplied date | future admitted source/import workflow | source proposal + meaningful Review/Confirm | May establish the same recorded posting-day semantic; the public field need not encode provenance. |
| Supported Lumen restoration | supported round-trip context | separately admitted restoration authority | May restore a previously admitted posting civil day under restoration authority distinct from ordinary creation. |
| Synthesized during new posted confirmation | `makeTransaction`: `posted_date ?? .now` | current implementation coupling only | **Does not establish separate posted-date authority under this revised candidate.** Current Review can show Posted while omitting a Posted-date row. |
| Synthesized on edit transition to posted | `apply(to:)` | current implementation coupling only | **Does not establish separate posted-date authority under this revised candidate.** |
| Synthesized by direct status action | Transaction Detail `setStatus` | current implementation coupling only | **Does not establish separate posted-date authority under this revised candidate.** |
| Inherited canonical value, unchanged during unrelated edit | edit draft copies persisted value | unrelated Save | No new posted-date authority is created. |
| Inherited canonical value | persisted canonical state | none | Stored instant exists, but current persistence does not reveal whether the date was separately authorized or silently synthesized, nor which calendar/timezone established its original civil day. |

The current durable model collapses separately authorized and historically/system-synthesized nonnil `posted_date` provenance into the same `Date?` representation.

Therefore:

> **An arbitrary existing nonnil `posted_date` must not be classified EXACTLY WARRANTED merely because it exists.**

Current implementation behavior is compatibility evidence, not automatic public-semantic authority.

---

# 5. Status × posted_date state space

The persisted model does not structurally constrain `posted_date` by status. Existing-record editing exposes all five persisted status tokens.

The compatibility analysis therefore treats the conceptual matrix as:

| Status | `posted_date == nil` | `posted_date != nil` |
| --- | --- | --- |
| `pending` | representable current state | model can preserve/store; presence does not imply posted |
| `posted` | coherent lifecycle state; no separate posting day claimed | common current state, but provenance/authority may be ambiguous |
| `ignored` | model can preserve/store | model can preserve/store |
| `duplicate` | model can preserve/store | model can preserve/store |
| `review_needed` | model can preserve/store | model can preserve/store |

This table does not reopen accepted status semantics and does not claim every cell should be an ordinary future creation choice.

Normative candidate invariants:

```text
status
!= authority to infer posted_date

status
!= authority to erase posted_date

status becoming posted
!= authority to synthesize posted_date

posted_date presence
!= proof of posted status

posted_date == nil
= exact absence of a separately recorded posting day

posted_date == nil
!= ambiguous/incompatible nonnil date
```

No exporter may convert an unresolved nonnil date into null.

Canonical representability remains distinct from ordinary creation readiness.

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

For `posted_date`, equivalence additionally requires preservation of whether a separately authorized recorded posting day is present or absent.

Restoration must not:

- infer a posting date merely because `status == posted`;
- erase an existing admitted posting day merely because current status is not `posted`;
- upgrade an unresolved historical/synthesized nonnil value into newly proven posting-day authority.

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

> **Posted-status independence.** `posted` is an ordinary Lumen financial-lifecycle status whose validity does not depend on a separately recorded `posted_date`. Choosing or restoring `status == posted` authorizes the lifecycle fact only; it does not itself authorize an additional posting date.

> **posted_date meaning.** Portable non-null `posted_date` denotes an **optional, separately authorized recorded posting civil day**. It may be established through explicit field entry/edit, reviewed source/institution data, or supported Lumen restoration under separately admitted authority. Its public semantic does not require encoding which provenance path supplied it.

> **posted_date absence.** `posted_date == nil` means no separately recorded posting civil day is claimed. This is a truthful state even when `status == posted`.

> **posted_date non-inference.** A transition to `status == posted` does not authorize synthesizing `posted_date`. Conversely, a change away from `posted` does not authorize erasing an existing recorded posting day, and presence of `posted_date` does not establish current status.

> **Lifecycle-timestamp separation.** `posted_date` is not the timestamp or civil-day projection of when Lumen itself changed lifecycle status. Any future lifecycle-transition timestamp is a separate concept outside this gate.

> **Hidden representation.** Confirmation or Save does not grant Portable authority to hidden time-of-day, timezone, or raw-instant details that were not presented or admitted as financial meaning.

> **Current durable classifiability.** Current Transaction state stores Date / Date? but no per-record calendar, timezone, confirmed civil-date spelling, or date-provenance class. Therefore an arbitrary existing nonnil `transaction_date` or `posted_date` is not generally proven **EXACTLY WARRANTED** from current Transaction state alone. For `posted_date`, current storage additionally cannot distinguish separately authorized values from historical/system-synthesized values.

> **Recovery versus new authority.** Recovery using admitted already-existing durable context is distinct from explicit user resolution that creates or replaces financial-date authority. The format and exporter must not describe a new user assertion as recovery of historical truth.

> **Absence.** `posted_date == nil` is exact absence. An unresolved, not-export-compatible, or otherwise unsupported nonnil posted Date must not be serialized as null/blank merely because its financial civil-day meaning cannot be established.

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

This hardening pass proposes:

- `transaction_date` = user-owned financial transaction civil day;
- `posted_date` = optional, separately authorized recorded posting civil day;
- `status == posted` does not require, infer, synthesize, or erase `posted_date`;
- `posted_date` is not a Lumen lifecycle-transition timestamp;
- proleptic Gregorian = Portable calendar candidate;
- current arbitrary persisted nonnil Dates are not generally classifiable as exactly warranted from Transaction state alone.

Remaining implications are operational and storage-related:

1. later work must decide whether and how admitted durable context can recover existing financial days;
2. later work must decide whether explicit user resolution is available and how a new authoritative assertion is persisted;
3. complete-export behavior must account for records that are not export-compatible as-is;
4. restoration into Foundation `Date` must not let its anchor representation become public financial meaning;
5. exact year domain and full lexical/parser validation for Portable dates remain separately gated;
6. if this revised candidate is accepted, current production behavior must later be aligned so that `makeTransaction()`, `TransactionDraft.apply(to:)`, and direct `setStatus(.posted)` do not synthesize `.now` solely because status becomes `posted`.

Until that separate implementation alignment occurs, newly created system-synthesized nonnil `posted_date` values remain compatibility-bearing current state; contract review alone does not retroactively grant them separate posted-date authority.

This gate does not choose a SwiftData migration, new civil-date field, resolution UX, lifecycle timestamp, or exporter/importer implementation.

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

# 19. Independent-review hardening and evidence audit

## 19.1 Hardening applied

Independent review of `ecf9a4ec9096b9ee70977167cb700c67c6a6d7df` accepted the central architectural finding but requested authority/classifiability hardening before proposed-contract acceptance.

This pass therefore makes the following proposal-level choices explicit:

1. **Current record-local classifiability**
   - an arbitrary existing nonnil `transaction_date` or `posted_date` is **not generally proven EXACTLY WARRANTED from current Transaction state alone**;
   - current persistence has no per-record originating calendar, timezone, confirmed civil-date spelling, or date-provenance class.

2. **Recovery versus new authority**
   - **RECOVERABLE WITH ADMITTED CONTEXT** means already-existing durable evidence/context recovers a previously established date;
   - **USER RESOLUTION REQUIRED** means the user must make a new authoritative assertion;
   - recovery and new authority are not interchangeable.

3. **Field-specific authority**
   - new Review/Confirm establishes the visible `transaction_date` financial day;
   - an explicit financial-date-field edit followed by Save establishes new date-level authority;
   - an unrelated edit does not reauthorize an unchanged inherited Date;
   - system synthesis after Review/direct status transition is not retroactively user-confirmed date authority.

4. **posted_date public meaning at the c6dc093... checkpoint — subsequently reopened**
   - that checkpoint proposed **Lumen-effective posting civil day**;
   - later physical-device/product review showed that Review can authorize `status == posted` while displaying no Posted-date row;
   - the current document supersedes that candidate with the narrower optional/separately-authorized model in Sections 4, 15, 17, and 20.

5. **Lexical scope**
   - this gate selects proleptic Gregorian calendar semantics and candidate `YYYY-MM-DD` shape;
   - exact admitted year interval and complete lexical/parser validity remain separately gated;
   - `YYYY-MM-DD` shape alone does not make an impossible date valid.

These refinements remain **PROPOSED FOR REVIEW** and do not record acceptance.

## 19.2 Executed characterization evidence

A temporary branch-scoped GitHub Actions workflow executed only the five bounded financial-date probe tests.

Execution identity:

- workflow run ID: `36298026371`;
- tested commit: `48085e7af3bb0081e55725df0ac6fab305d0be6f`;
- tested branch: `docs/phase1c-portable-v1-financial-date-semantics-proposal`;
- macOS: `26.6.2`;
- Xcode: `26.6` / build `17F113`;
- iPhone Simulator SDK: `26.5`;
- artifact: `Lumen-Phase1C-FinancialDate-1`;
- artifact ID: `10924892081`;
- artifact SHA-256 digest: `d96b3ada612d07fe5d0a80939607d7a6159543558dc6a552520a437f8b587687`.

Result:

```text
Selected tests
Executed: 5
Failures: 0
Unexpected: 0
Result: TEST SUCCEEDED
```

Passed probes:

- `testFinancialDateProbeSameInstantProjectsToDifferentGregorianDaysAcrossTimeZones`;
- `testFinancialDateProbeCalendarSystemChangesYearMonthDayInterpretation`;
- `testFinancialDateProbeDSTCivilDaysAreNotUniformTwentyFourHourIntervals`;
- `testFinancialDateProbeFixedZoneRestorationAnchorCanRenderAsAdjacentDayElsewhere`;
- `testFinancialDateProbePostedDatePresenceIsStructurallyIndependentOfStatus`.

The run establishes the bounded representation facts encoded by those probes:

- one instant can map to different Gregorian civil days across timezones;
- calendar-system choice can change year/month/day interpretation;
- New York civil days around the tested DST transitions span 23 or 25 elapsed hours;
- a fixed-zone restoration anchor can render as an adjacent civil day in another timezone;
- the model can hold `posted_date` independently of status in the characterized combinations.

The run does **not** establish:

- original historical user intent;
- a per-record original timezone/calendar;
- whether an arbitrary existing Date is exactly warranted;
- external institution posting-day truth;
- a production conversion/restoration algorithm;
- acceptance of the proposed public semantics.

The runner emitted CoreData store-creation/recovery diagnostics during application startup; recovery succeeded and the selected characterization suite completed with 5/5 passes. Those diagnostics are not used as financial-date evidence.

## 19.3 Temporary workflow disposition

The temporary characterization workflow was created only to execute this evidence pass and was removed after the successful run.

```text
temporary executable evidence mechanism
!= permanent CI acceptance gate
```

The final branch tree therefore does not retain a new financial-date workflow.

## 19.4 Branch / diff audit

Frozen base:

`integration/phase1c-portable-v1-framework-baseline @ ab7e75675b1d11061fdac30cb8ed4f2189103598`

Relevant checkpoints in this gate:

- initial proposal: `3202505ae53e780150e5098c12673453acd8d20c`;
- characterization source: `c8ea6c0f7743e2c12d28554481beabc86ab48ff3`;
- initial format-contract application: `56618a00b8d2b714b0566b53571296352c5aaedb`;
- pre-review audit checkpoint: `ecf9a4ec9096b9ee70977167cb700c67c6a6d7df`;
- authority-model hardening: `0b4c8c69a2ba2aa22008b6d0da906f595bdcf72f`;
- format-contract authority alignment: `99f0c1e87a17e4790b4919d72bc8a9af275861be`;
- temporary characterization workflow/run trigger: `48085e7af3bb0081e55725df0ac6fab305d0be6f`;
- temporary workflow removal: `e08ef01cbe545d35f6b7e98fdf225d3389fad0f3`.

Final-tree intent remains limited to:

1. `docs/architecture/LUMEN_PORTABLE_V1_FINANCIAL_DATE_SEMANTICS_PROPOSAL.md`;
2. date sections of `docs/architecture/LUMEN_PORTABLE_JSON_CSV_V1_FORMAT_CONTRACT.md`;
3. bounded characterization probes in `ios-lumen-finance/LumenFinanceTests/LumenFinanceTests.swift`.

No production Swift, persisted model/schema, migration, importer/exporter implementation, lifecycle-timestamp, PortableMoney, reference-entity, Source/provenance, identity-allocation, ordering, or parser-evolution implementation is authorized or changed by this gate.

The gate remains **PROPOSED FOR REVIEW**. Stop here for independent review before recording proposed-contract acceptance or opening another gate.


---

# 20. Narrow posted_date semantic reopening

Independent review of `c6dc093b8d1b074ed4f41c327f4757ec1f773a13`, combined with physical-device use of the current Review flow, reopened **only** the public meaning and authority model of `posted_date`.

## 20.1 Product/UI evidence

Current Review can present a confirmable draft with:

```text
Status = Posted
Posted date = absent
Payment method = absent
```

while `draft.canConfirm` remains true when the ordinary base Transaction requirements are satisfied.

Current persistence then has three implementation paths that can synthesize `.now` solely because status becomes `posted`:

- `TransactionDraft.makeTransaction()`;
- `TransactionDraft.apply(to:)`;
- `TransactionDetailView.setStatus(.posted)`.

This establishes a product/implementation mismatch:

```text
reviewed lifecycle fact
= Posted

reviewed posted-date fact
= absent

current persistence
→ may manufacture posted_date anyway
```

The existence of that implementation behavior does not grant it product-semantic authority.

## 20.2 Revised Minimum Sufficient Contract

```text
status
→ lifecycle classification

transaction_date
→ financial transaction civil day

posted_date
→ optional separately authorized recorded posting civil day

payment_method
→ optional payment-instrument association
```

The date gate does not reopen the full accepted Transaction-status contract. It relies only on the narrower accepted fact that `pending` and `posted` are ordinary financial-lifecycle statuses and proposes:

> **Validity of `status == posted` does not depend on a separately recorded `posted_date`.**

“Completed/non-provisional rather than pending” is explanatory product language here, not a replacement full definition of the accepted status contract.

## 20.3 Revised Authority Budget

```text
explicit authority for status = posted
        ↓
Lumen owns the lifecycle assertion only

separately supplied/admitted posting day D
        ↓
Lumen owns posted_date = D
```

No additional posting-day fact appears merely because lifecycle status changed.

## 20.4 Historical/current compatibility consequence

Current persistence erases posted-date provenance:

```text
separately authorized posting day
        ↓
Date?

silently synthesized .now
        ↓
Date?
```

Therefore an arbitrary existing nonnil `posted_date` cannot be presumed to satisfy the revised public semantic.

This remains true for records created by still-unmodified production paths after this proposal checkpoint. Contract review alone does not change runtime behavior or retroactively grant authority to synthesized values.

## 20.5 Downstream alignment requirement

If this revised contract is accepted, a later implementation pass must reconcile the three known synthesis paths so that:

```text
status becomes posted
+
posted_date == nil
        ↓
posted_date remains nil
```

unless an independent, admitted posted-date authority event supplies a value.

That future pass is not authorized here.

## 20.6 Scope boundary

This reopening does **not**:

- modify production code;
- change schema/migrations;
- add lifecycle timestamps;
- redesign PaymentMethod;
- change Category/merchant/base Transaction validity;
- reopen the five-status compatibility gate;
- decide whether ordinary future creation should allow every status × posted_date combination;
- alter the completed characterization evidence;
- open another Phase 1C gate.

This gate remains **PROPOSED FOR REVIEW**.


---

# 21. Narrow reopening branch audit

Audit immediately before this bookkeeping update:

- frozen effective Phase 1C proposal-development baseline: `ab7e75675b1d11061fdac30cb8ed4f2189103598`;
- pre-reopening checkpoint reviewed: `c6dc093b8d1b074ed4f41c327f4757ec1f773a13`;
- posted-date semantic revision: `904d39fa9a58fd19c818775f65bd92715be87183`;
- Portable format-contract alignment: `bb61ee8584bafee8d3af3e5a3d919d9f16bfccb5`;
- branch compare against frozen base before this bookkeeping commit: ahead 12, behind 0;
- merge base remains exactly `ab7e75675b1d11061fdac30cb8ed4f2189103598`;
- canonical `main` remains unchanged at `8e0b71d17c14ae917a2726ccdc0403157d3cb53a`;
- frozen convergence branch remains unchanged at `ab7e75675b1d11061fdac30cb8ed4f2189103598`.

Net final-tree scope remains limited to:

1. `docs/architecture/LUMEN_PORTABLE_V1_FINANCIAL_DATE_SEMANTICS_PROPOSAL.md`;
2. date sections of `docs/architecture/LUMEN_PORTABLE_JSON_CSV_V1_FORMAT_CONTRACT.md`;
3. bounded characterization probes already present in `ios-lumen-finance/LumenFinanceTests/LumenFinanceTests.swift`.

This reopening changed **no production Swift** and changed no test source beyond the characterization probes already present at the earlier reviewed checkpoint.

The revised proposal explicitly treats the three current `.now` synthesis paths as downstream implementation-alignment requirements if this contract is accepted; it does not modify them here.

The gate remains **PROPOSED FOR REVIEW**. Do not record proposed-contract acceptance or open another gate from this checkpoint without separate review/authorization.
