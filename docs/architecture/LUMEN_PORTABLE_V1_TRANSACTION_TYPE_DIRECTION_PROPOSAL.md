# Lumen Portable JSON v1 Transaction Type / Direction Sufficiency Proposal

## Status

**ACCEPTED AT PROPOSED-CONTRACT LEVEL — Phase 1C Portable Transaction type/direction semantic gate.**

Starts exactly from accepted categoryless checkpoint `aa549af4193fc0445d8b9e9abedd566daa076f10`.

This proposal does not modify production code, tests, persistence/schema, analytics behavior, `TransactionType`, importer/exporter implementation, PortableMoneyV1, or any previously accepted compatibility semantics.

It does not add account modeling, transfer pairing, double-entry semantics, debit/credit-side fields, or bank-feed reconciliation.

# 1. Decision Question

For every proposed Portable JSON v1 Transaction type, does:

```text
unsigned PortableMoneyV1 magnitude
+
exact Lumen Transaction type token
```

carry enough **Lumen-owned canonical semantic information** to represent the corresponding current `Transaction` truthfully and without invented meaning?

The question is deliberately **not**:

> Does Portable v1 reconstruct every real-world economic fact that might exist for this transaction?

The relevant boundary is:

```text
economically richer representation
!=
required portable representation

Portable v1 preserves canonical truth Lumen owns
!=
financial facts Lumen never stored
```

The four candidate tokens are:

```text
expense
income
transfer
refund
```

# 2. Governing Distinctions

This gate preserves:

```text
positive display / signed projection
!=
income semantics

not outflow
!=
necessarily inflow

foreign source sign
!=
Lumen canonical direction authority

canonical model under-specification
!=
portable serialization loss
```

A helper such as `TransactionType.isOutflow` is implementation evidence, not by itself the complete semantic contract.

# 3. Current Type Model and Creation Path

`TransactionType` is a raw-string, Codable, CaseIterable enum:

```swift
expense
income
transfer
refund
```

`Transaction.transaction_type` is nonoptional and defaults to `.expense`.

`TransactionDraft.transaction_type` likewise defaults to `.expense`.

The ordinary Transaction form exposes every `TransactionType.allCases` value for user selection.

Current draft validity contains no type-specific rejection. `makeTransaction` copies the selected `transaction_type` directly to the new `Transaction`, and existing-record `apply(to:)` writes the selected type directly.

Therefore all four tokens are part of the current ordinary canonical-creation/edit vocabulary at the code-path level.

Evidence strength differs by type:

- authentic Phase 1A inherited-store evidence explicitly includes historical `expense` and `income`;
- seed/reference sample behavior includes `expense` and `income`;
- current unit evidence exercises `refund` and `transfer` semantics;
- no separate authentic historical-store or dedicated URL-backed persistence fixture for `refund` or `transfer` was found in this trace.

The proposal does not overstate that last point.

# 4. Stored Amount Is Magnitude, Not Direction

Current canonical creation requires a positive finite amount.

`makeTransaction` writes:

```swift
amount: abs(amount)
```

and existing-record application similarly stores `abs(amount)`.

So the current canonical model already separates:

```text
stored amount
→ positive magnitude

transaction_type
→ flow classification / semantic direction
```

PortableMoneyV1's unsigned positive magnitude is therefore aligned with the current canonical model rather than introducing a new sign-removal convention.

# 5. Implementation Helper vs Semantic Authority

`TransactionType.isOutflow` currently returns:

```text
expense → true
income → false
transfer → false
refund → false
```

`Transaction.signedAmount` then derives:

```swift
transaction_type.isOutflow ? -abs(amount) : abs(amount)
```

Taken alone, that helper would make income, transfer, and refund numerically positive.

The rest of the repository proves that this is **not** a semantic equivalence relation:

- Analytics includes income and refund in incoming flow;
- Analytics excludes transfer from both incoming and spending;
- Dashboard explicitly says “In includes refunds; transfers do not affect flow”;
- Detail/row presentation suppresses signed presentation for transfer;
- Phase 1A explicitly states “expenses reduce flow, income/refunds add flow, transfers do not affect net flow” and “No account-balance direction is inferred for transfers.”

Therefore:

```text
isOutflow == false
!=
inflow
```

# 6. Expense Trace

## 6.1 Canonical evidence

`expense` is:

- the default `TransactionType`;
- selectable in ordinary creation/editing;
- present in current seed/sample definitions;
- present in authentic Phase 1A inherited-store evidence;
- exercised in analytics and filtering tests.

## 6.2 Flow meaning

Repository behavior consistently treats expense as an **outflow**.

`signedAmount` projects it negative.

Analytics:

```text
expense
→ included in totalSpending
→ excluded from totalIncome
→ negative contribution to netFlow
→ included in weekly logged spending
→ included in categoryTotals
→ included in groupTotals
```

The Activity `expenses` filter matches only `expense`.

## 6.3 Display meaning

Row/detail presentation uses negative signed display for expense.

Review itself shows the unsigned magnitude and separately displays the type, which reinforces that sign is presentation derived from type rather than stored direction.

## 6.4 Proposed Portable interpretation

```text
type = expense
+ unsigned amount x
→ canonical outflow of magnitude x
→ gross-spending semantic
→ negative net-flow contribution under current Lumen reporting
```

No separate negative amount or direction field is required.

# 7. Income Trace

## 7.1 Canonical evidence

`income` is:

- selectable in ordinary creation/editing;
- present in current seed/sample definitions;
- present in authentic Phase 1A inherited-store evidence via Paycheck Direct Deposit;
- exercised in current analytics tests.

## 7.2 Flow meaning

Repository behavior treats income as an **inflow**.

Analytics:

```text
income
→ excluded from totalSpending
→ included in totalIncome
→ positive contribution to netFlow
→ excluded from expense category totals
```

The Activity `income` filter includes `income` and `refund`, but that shared filter does not erase their distinct type identity.

## 7.3 Display meaning

`signedAmount` projects income positive, and row/detail signed presentation shows the positive direction.

## 7.4 Proposed Portable interpretation

```text
type = income
+ unsigned amount x
→ canonical inflow of magnitude x
→ incoming semantic
→ positive net-flow contribution
```

# 8. Refund Trace

Refund requires separate treatment because:

```text
positive numeric projection
!=
ordinary income identity
```

## 8.1 Canonical/type evidence

`refund` is a distinct persisted `TransactionType` token and distinct UI choice.

Current ordinary form logic permits selecting it; no type-specific validation rejects it.

Unit evidence constructs refund Transactions and verifies aggregate behavior.

The duplicate matcher also treats a refund proposal as semantically different from an otherwise matching expense because transaction type participates in duplicate comparison.

No authentic historical-store refund fixture was identified in this trace.

## 8.2 Current financial treatment

Phase 1A explicitly froze the current aggregate policy:

> expenses reduce flow, income/refunds add flow, transfers do not affect net flow.

Current Analytics implements:

```text
refund
→ excluded from totalSpending
→ included in totalIncome
→ positive contribution to netFlow
→ excluded from expense categoryTotals
→ excluded from expense groupTotals
```

The Dashboard discloses:

> In includes refunds.

The Activity `income` filter includes refunds.

## 8.3 What the evidence does NOT establish

The repository does not establish a richer canonical relationship such as:

- which original expense was refunded;
- whether a refund must offset a particular category;
- whether gross spending should be retrospectively reduced;
- paired reversal identity;
- account-side settlement direction.

Indeed, current gross-spending analytics does **not** subtract refunds from `totalSpending`; refunds instead enter the incoming side.

Therefore Portable v1 must not invent an expense-linkage/reversal model.

## 8.4 Proposed Portable interpretation

```text
type = refund
+ unsigned amount x
→ distinct refund / positive-flow classification of magnitude x
→ included in current Lumen incoming semantics
→ excluded from current gross-spending/category-spending semantics
→ positive net-flow contribution
→ NOT semantically remapped to income
```

This preserves the distinct token even though current aggregate math groups refund with income for incoming totals.

# 9. Transfer Trace

Transfer is the central sufficiency question.

## 9.1 Canonical/type evidence

`transfer` is a distinct `TransactionType`, selectable through ordinary creation/editing.

Current unit evidence constructs a transfer Transaction.

No authentic historical-store transfer fixture was identified in this trace.

The current canonical `Transaction` model does **not** store:

- source account;
- destination account;
- transfer debit side;
- transfer credit side;
- transfer direction;
- paired-transfer identifier;
- account-balance effect;
- double-entry counterpart.

Payment method is a separate optional classification and does not establish transfer-side direction.

## 9.2 Current financial treatment

Analytics deliberately treats transfer as neither spending nor incoming:

```text
transfer
→ excluded from totalSpending
→ excluded from totalIncome
→ zero contribution to netFlow
→ excluded from expense categoryTotals
→ excluded from expense groupTotals
```

Phase 1A states explicitly:

> transfers do not affect net flow.

and:

> No account-balance direction is inferred for transfers.

The Dashboard repeats:

> transfers do not affect flow.

## 9.3 Display evidence

The generic `signedAmount` helper numerically projects transfer positive because transfer is not `isOutflow`.

But row/detail presentation special-cases transfer:

```swift
signed: transaction.transaction_type != .transfer
```

so transfer is displayed without an incoming plus sign.

This is direct evidence that:

```text
positive helper projection
!=
canonical transfer inflow semantics
```

Review also shows the unsigned magnitude with the separate Transfer label.

## 9.4 Canonical semantic boundary

The repository supports this current Lumen-owned meaning:

```text
type = transfer
+ unsigned amount x
→ transfer / movement classification of magnitude x
→ direction-neutral / non-nettable at canonical Transaction level
→ neither spending nor incoming
→ neutral to current net-flow reporting
→ no account-side meaning implied
```

That may be economically less rich than a real-world bank transfer, but it is a truthful representation of the state Lumen currently owns.

## 9.5 No representational gap from absent facts

Because the canonical model itself does not own transfer-side direction, Portable v1 is not lossy merely because it also does not contain that direction.

The rule is:

```text
canonical model does not know transfer side
→ Portable v1 must not invent transfer side
→ absence of invented side is not portability loss
```

If a future canonical model admits account-linked or paired-transfer semantics, that future state will require a separately admitted portable contract/version.

# 10. Four-Type Semantic Matrix

| Type | Portable amount | Canonical Lumen flow meaning | Spending | Incoming | Current net-flow treatment | Display/sign evidence | Proposed Portable sufficiency |
|---|---|---|---|---|---|---|---|
| `expense` | unsigned magnitude | outflow | included | excluded | negative contribution | row/detail negative | sufficient |
| `income` | unsigned magnitude | inflow | excluded | included | positive contribution | row/detail positive | sufficient |
| `refund` | unsigned magnitude | distinct refund / positive-flow class | excluded from gross spending | included | positive contribution | row/detail positive | sufficient if refund meaning is frozen distinctly |
| `transfer` | unsigned magnitude | direction-neutral/non-nettable movement class | excluded | excluded | neutral | no incoming/outgoing sign shown | sufficient if no account-side meaning is implied |

This table describes **current Lumen canonical/reporting semantics**, not universal accounting semantics.

# 11. Representational Sufficiency Analysis

The repository evidence supports outcome:

> **All four current type tokens are semantically sufficient for Portable JSON v1 when paired with an unsigned PortableMoneyV1 magnitude, provided their exact Lumen-owned meanings are normatively frozen.**

No additional generic `direction` field is required for the current canonical model.

Why:

1. `expense` already identifies the outflow semantic;
2. `income` already identifies the inflow semantic;
3. `refund` preserves a distinct positive/refund semantic despite sharing incoming aggregate treatment with income;
4. `transfer` truthfully identifies a direction-neutral/non-nettable movement because current canonical state owns no account-side direction to serialize.

The format therefore has no demonstrated representational gap on this axis.

# 12. Round-Trip Equivalence on the Type Axis

Current analytics, filters, Dashboard disclosures, category/group totals, and sign presentation are **evidence and present-day consequences** of the admitted type meanings. They are not themselves an independently frozen Portable v1 UI/API/reporting surface.

The governing boundary is:

```text
core admitted type meaning
!=
specific current reporting implementation

reporting implementation changes
!=
necessarily Portable v1 semantic changes

canonical type meaning changes
=
Portable contract evolution / separate admission
```

Proposed supported-state equivalence is therefore:

```text
same admitted type token
+
same admitted unsigned amount semantics
+
preservation of the same admitted Lumen-owned type meaning
```

For example:

```text
refund
must restore as refund
not income

transfer
must restore as transfer
not income
not expense
```

Exact raw token preservation is required because current behavior distinguishes the four types in filtering, display, duplicate comparison, and/or financial treatment.

No round trip may silently map:

```text
refund → income
transfer → income
transfer → expense
expense → transfer
```

merely because some helper or presentation path yields a numerically similar sign.

# 13. Foreign-Format Boundary

The structured-format survey observed that a foreign source may provide:

```text
signed Amount
+
source Type
```

The accepted interpretation remains:

```text
foreign sign/type
→ adapter/mapping evidence
→ user/resolution semantics where required
→ Lumen positive magnitude + Lumen type
```

Foreign sign is not authority over Lumen Portable semantics.

Once a Transaction crosses the canonical boundary, Lumen-owned type semantics control the portable representation.

This proposal does not define provider-specific mappings or generic CSV direction inference.

# 14. Alternatives Considered

## Alternative A — Freeze current four-token meanings

**Recommended.**

Define exact Lumen-owned semantics for expense, income, refund, and transfer as established by current canonical/reporting behavior.

No new field is needed.

## Alternative B — Infer all non-expense types as inflow

Rejected.

`transfer` is explicitly neutral and display-special-cased.

`refund` is a distinct type even though current aggregate incoming treatment is positive.

```text
isOutflow == false
!=
inflow
```

## Alternative C — Map refund to income in Portable v1

Rejected.

It would erase canonical type identity and the current distinct refund semantic.

## Alternative D — Add a generic `direction` field

Not justified by current evidence.

Expense/income/refund meanings are already carried by type, and transfer has no canonical account-side direction to populate truthfully.

Adding a field would risk inventing semantics rather than preserving them.

## Alternative E — Add account/source/destination semantics for transfer

Rejected for v1.

Current canonical `Transaction` owns none of those facts.

## Alternative F — Treat transfer as representationally incomplete because real transfers have sides

Rejected.

That confuses real-world model richness with fidelity to current canonical state.

## Alternative G — Declare current canonical transfer state under-specified

Not selected.

The canonical model is intentionally limited, but its present semantics are sufficiently explicit for current Lumen behavior: a transfer magnitude classified as neutral/non-nettable with no account-side claim.

Future product evolution may make that model insufficient for future features without making current Portable v1 dishonest.

# 15. Exact Proposed Portable JSON Contract Language

> **Portable JSON v1 Transaction `amount` is an unsigned PortableMoneyV1 magnitude. Transaction flow meaning is carried by the exact admitted `type` token rather than by amount sign.**

> **The admitted Portable JSON v1 Transaction type tokens are `expense`, `income`, `refund`, and `transfer`. Their meanings are Lumen-owned canonical semantics, not universal accounting definitions.**

> **`expense` means an outflow of the stated magnitude under current Lumen canonical/reporting semantics. It participates in gross spending and contributes negatively to current net-flow treatment.**

> **`income` means an inflow of the stated magnitude. It participates in incoming totals and contributes positively to current net-flow treatment.**

> **`refund` remains a distinct refund/positive-flow type. Under current Lumen semantics it is excluded from gross spending/category-spending totals, included in incoming totals, and contributes positively to current net flow. Its positive treatment does not make it an alias for `income`, and Portable v1 must preserve the `refund` token.**

> **`transfer` means a transfer/movement classification of the stated magnitude that is direction-neutral/non-nettable at the current canonical Transaction level. It is excluded from spending and incoming totals and is neutral to current net-flow treatment. Portable v1 does not imply a source account, destination account, debit side, credit side, balance direction, paired-transfer identity, or other account-side meaning that current canonical Transaction does not own.**

> **`TransactionType.isOutflow`, `signedAmount`, or another derived helper does not independently define Portable type semantics. In particular, `isOutflow == false` does not imply inflow.**

> **Supported type-axis round-trip equivalence requires preservation of the same admitted type token, the same admitted unsigned amount semantics, and the same admitted Lumen-owned type meaning. Current analytics, filters, labels, grouping, and sign presentation are evidence/consequences of that meaning rather than independently frozen Portable v1 implementations. Portable restoration must not silently remap `refund` to `income` or `transfer` to `income`/`expense`.**

> **Foreign signed amounts and provider type vocabularies are mapping evidence upstream of canonicalization; they do not redefine Lumen Portable direction semantics.**

> **No generic direction field, account-side transfer metadata, transfer pairing, or double-entry semantics are admitted by this gate. If future canonical Lumen state owns such facts, their portability requires a separately admitted contract/version.**

# 16. Evidence Strength by Type

## Expense

Strongest evidence:

- authentic Phase 1A inherited-store example;
- seed/sample data;
- ordinary creation path;
- tests;
- analytics/filter/display behavior.

## Income

Strong evidence:

- authentic Phase 1A inherited-store example;
- seed/sample data;
- ordinary creation path;
- tests;
- analytics/filter/display behavior.

## Refund

Current semantic evidence:

- distinct enum/UI token;
- ordinary creation/edit code path;
- analytics test;
- duplicate type distinction;
- Phase 1A explicit incoming/refund policy;
- Dashboard disclosure.

No authentic historical refund fixture was identified.

## Transfer

Current semantic evidence:

- distinct enum/UI token;
- ordinary creation/edit code path;
- analytics test;
- Phase 1A explicit neutral-flow/no-account-direction policy;
- Dashboard disclosure;
- row/detail no-sign special case.

No authentic historical transfer fixture was identified.

# 17. Unresolved Dependencies

This gate does not resolve:

- account modeling;
- source/destination account identity;
- transfer pairing;
- bank-feed reconciliation;
- double-entry accounting;
- balance impact;
- payment-method semantics;
- future refund-to-original-transaction linkage;
- Category semantics;
- status compatibility;
- portable identity;
- date semantics;
- serializer spelling;
- CSV-specific format semantics;
- foreign-source mapping implementation.

Current analytics, filtering, Dashboard copy, category/group aggregation, and sign presentation are evidence used to infer and document the present type meanings; this proposal does not freeze their specific implementation shape. A future reporting refactor that preserves the admitted type meanings is not automatically a Portable v1 semantic change. A future change that materially changes an admitted type meaning—such as adding canonical refund linkage/reversal semantics or canonical transfer account-side direction—requires separate portability admission/version review.

# 18. Review Questions

Independent review should decide whether:

1. the decision question correctly targets Lumen-owned canonical semantics rather than richer real-world economics;
2. `expense` is sufficiently defined as an outflow when paired with unsigned magnitude;
3. `income` is sufficiently defined as an inflow;
4. `refund` should remain a distinct positive/refund semantic with current incoming/net treatment rather than being collapsed into income;
5. `transfer` should be frozen as direction-neutral/non-nettable at current canonical Transaction level;
6. the absence of source/destination/account-side direction for transfer is correctly treated as absent canonical information rather than portable loss;
7. all four tokens are therefore representationally sufficient once their meanings are normatively frozen;
8. exact type token + unsigned amount semantics + preservation of admitted Lumen-owned type meaning is the correct type-axis round-trip equivalence;
9. no generic `direction` field is earned by current evidence;
10. foreign source sign remains adapter evidence only.

## Independent-review acceptance

Independent review accepted the four-token type/direction disposition after the semantic boundary between core type meaning and derived reporting manifestations was tightened.

Accepted at the proposed-contract level:

- Portable Transaction amount remains an unsigned PortableMoneyV1 magnitude;
- exact type token carries Lumen-owned flow semantics;
- `expense` means outflow;
- `income` means inflow;
- `refund` remains a distinct refund/positive-flow semantic and is not an alias for income;
- `transfer` is direction-neutral/non-nettable at the current canonical Transaction level and implies no account-side direction that current canonical state does not own;
- `isOutflow == false` does not imply inflow;
- no generic direction field, transfer-side account metadata, transfer pairing, or double-entry semantics are earned by current evidence;
- foreign sign/type conventions remain upstream mapping evidence;
- type-axis round-trip equivalence preserves the same admitted type token, unsigned amount semantics, and admitted Lumen-owned type meaning;
- current analytics, filters, labels, grouping, Dashboard copy, and sign presentation are evidence/consequences of those meanings, not independently frozen Portable v1 implementations;
- future reporting refactors that preserve the admitted type meanings are not automatically Portable semantic changes;
- future canonical changes such as linked-refund reversal semantics or account-sided transfer meaning require separate portability admission/version review.

No production implementation, analytics redesign, account modeling, refund linkage, transfer pairing, or PortableMoneyV1 change is authorized by this acceptance.
