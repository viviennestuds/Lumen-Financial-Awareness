# Lumen PortableMoneyV1 Currency Registry Membership + Version Semantics Proposal

## Status

**PROPOSED FOR REVIEW — Phase 1C currency-domain admission proposal.**

This document does not change production validation, persistence, SwiftData schema, amount-entry behavior, importer/exporter implementation, serializer implementation, migrations, or canonical ledger state.

It proposes two coupled responsibilities:

1. the exact currency-code membership of the first Lumen PortableMoneyV1 currency registry;
2. the immutable/versioned registry identity that tells another implementation which `O(c)` mapping governed a Portable v1 document.

The independently reviewed currency-scale/readiness semantics remain unchanged:

    O(c) = Lumen-owned stable/versioned ordinary currency scale

    S <= O(c)
    → READY on the currency-scale axis

    O(c) < S <= 9
    → workflow-specific handling

This proposal supplies the stable lookup that those semantics require.

It does **not** admit general non-cash rounding increments, cash-specific rounding, historical/current global-out-of-domain disposition, or production code.

---

# 1. Decision Questions

The previous admission work now depends on a registry with deterministic answers to:

> Is currency token c admitted?

and, if admitted:

> What ordinary fractional scale O(c) does this registry version assign?

Those answers cannot depend on:

- the current device locale;
- `Locale.commonISOCurrencyCodes`;
- Foundation formatter behavior;
- a live ISO lookup;
- a live CLDR lookup;
- whatever versions of those datasets happen to ship with the receiving OS.

The coupled questions for this proposal are therefore:

1. Which currency codes are admitted by the first PortableMoneyV1 registry?
2. What immutable registry identifier and source snapshot make that membership and every `O(c)` value reproducible later?

---

# 2. Proposed Registry Identity

The first registry identifier should be:

    lumen-currency-v1

The identifier is intentionally Lumen-owned.

It is **not** named `lumen-iso4217-v1` because the normative registry semantics are synthesized from more than one standards source:

- ISO 4217 / SIX establishes current code and minor-unit evidence;
- stable CLDR establishes the proposed ordinary fractional scale `O(c)`.

Once accepted, the meaning of:

    lumen-currency-v1

must be immutable.

Its code membership and `O(c)` mapping must never change in place when SIX, ISO, CLDR, Foundation, or device data later change.

A changed membership or changed `O(c)` mapping requires a different registry identifier.

---

# 3. Pinned Source Evidence

## 3.1 ISO 4217 / SIX snapshot

SIX Financial Information is the official ISO 4217 Maintenance Agency.

The registry proposal was constructed from a retrieval of the SIX List One XML whose root declared:

    Pblshd="2026-09-17"

Source location used during research:

https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml

That SIX location is mutable.

The exact XML bytes retrieved during the original registry-construction pass were **not** retained in the repository and were **not** fingerprinted at retrieval time.

Therefore this proposal must not claim a SHA-256 or other byte fingerprint for that historical retrieval.

A later retrieval from the same mutable URL — even if it still reports the same `Pblshd` value — cannot retroactively prove byte identity with the bytes used in the original construction pass.

For `lumen-currency-v1`, the normative immutable artifact is therefore the registry definition recorded by this contract itself:

- the exact 155-code membership enumerated below;
- the exact `O(c)` grouping/mapping enumerated below;
- the stated construction rule;
- the recorded SIX publication-date evidence;
- the pinned CLDR 48.2 source identity.

The SIX publication date and mutable source location remain **construction provenance**, not a sufficient byte-level snapshot identifier.

Before any future registry version is admitted, its source-evidence workflow should retain or otherwise immutably fingerprint the exact external source bytes used to construct it.

This source is **not** a runtime dependency.

## 3.2 CLDR snapshot

The ordinary-scale proposal uses Unicode CLDR 48.2, pinned to:

    unicode-org/cldr
    tag: release-48-2

Relevant source:

https://raw.githubusercontent.com/unicode-org/cldr/release-48-2/common/supplemental/supplementalData.xml

CLDR 48.2 is a stable published release.

At the time of this proposal, CLDR 49 is still an alpha/development release and is deliberately not used as normative evidence for `lumen-currency-v1`.

CLDR release data is not consulted dynamically after registry construction.

---

# 4. Membership Construction Rule

For `lumen-currency-v1`, a code is admitted only if the pinned SIX List One snapshot contains an entry satisfying all of:

    Ccy exists
    Ccy matches [A-Z]{3}
    CcyNm IsFund != true
    CcyMnrUnts is a numeric integer

Duplicate territory rows collapse to one currency-code member.

If duplicate rows for the same code disagree on name or numeric minor-unit evidence, registry construction must fail rather than choose one silently.

This rule deliberately excludes:

- rows with no currency code;
- codes explicitly marked as funds;
- precious-metal and special codes whose minor unit is N.A.;
- testing code;
- "no currency" code;
- unit/accounting codes with N.A. minor units.

The rule does not consult the host runtime's currency list.

---

# 5. Proposed Membership

The pinned construction produces exactly:

    155 admitted currency codes

The following lists are normative membership for `lumen-currency-v1`.

## 5.1 O(c) = 0

```text
AFN ALL BIF CLP COP DJF GNF HUF IDR IQD IRR ISK
JPY KMF KPW KRW LAK LBP MGA MMK PKR PYG RWF SOS
SYP UGX VND VUV XAF XOF XPF YER
```

Count:

    32

## 5.2 O(c) = 2

```text
AED AMD AOA ARS AUD AWG AZN BAM BBD BDT BMD BND
BOB BRL BSD BTN BWP BYN BZD CAD CDF CHF CNY CRC
CUP CVE CZK DKK DOP DZD EGP ERN ETB EUR FJD FKP
GBP GEL GHS GIP GMD GTQ GYD HKD HNL HTG ILS INR
JMD KES KGS KHR KYD KZT LKR LRD LSL MAD MDL MKD
MNT MOP MRU MUR MVR MWK MXN MYR MZN NAD NGN NIO
NOK NPR NZD PAB PEN PGK PHP PLN QAR RON RSD RUB
SAR SBD SCR SDG SEK SGD SHP SLE SRD SSP STN SVC
SZL THB TJS TMT TOP TRY TTD TWD TZS UAH USD UYU
UZS VED VES WST XCD XCG ZAR ZMW ZWG
```

Count:

    117

## 5.3 O(c) = 3

```text
BHD JOD KWD LYD OMR TND
```

Count:

    6

No admitted `lumen-currency-v1` member has `O(c) = 1` or `O(c) > 3`.

The globally admitted structural ceiling remains independently:

    S <= 9

Therefore registry membership does not shrink the structural representation ceiling; it supplies currency-specific ordinary-scale expectations.

---

# 6. O(c) Construction Rule

For every admitted code `c`, `lumen-currency-v1` derives ordinary scale from the pinned CLDR 48.2 fraction data:

    if CLDR 48.2 has a currency-specific general digits entry for c:
        O(c) = that digits value

    otherwise:
        O(c) = CLDR 48.2 DEFAULT digits

The pinned CLDR 48.2 default is:

    DEFAULT digits = 2

The absence of a currency-specific override is therefore resolved from the pinned registry source at construction time.

A receiving implementation does **not** rerun this fallback against its own CLDR version.

It reads the immutable Lumen registry semantics.

---

# 7. ISO Minor Unit and O(c) Are Deliberately Distinct

The pinned sources demonstrate why the registry must own both the membership decision and `O(c)` semantics rather than treating ISO minor unit as definitionally identical to ordinary scale.

For 16 admitted codes, the pinned ISO minor-unit evidence differs from CLDR 48.2 general `digits`:

| Code | ISO minor-unit evidence | Proposed O(c) |
| --- | ---: | ---: |
| AFN | 2 | 0 |
| ALL | 2 | 0 |
| COP | 2 | 0 |
| HUF | 2 | 0 |
| IDR | 2 | 0 |
| IQD | 3 | 0 |
| IRR | 2 | 0 |
| KPW | 2 | 0 |
| LAK | 2 | 0 |
| LBP | 2 | 0 |
| MGA | 2 | 0 |
| MMK | 2 | 0 |
| PKR | 2 | 0 |
| SOS | 2 | 0 |
| SYP | 2 | 0 |
| YER | 2 | 0 |

This does not make the ISO data wrong.

It reflects the already-approved architecture:

- ISO 4217 / SIX supplies authoritative code/minor-unit evidence;
- CLDR general `digits` supplies the proposed ordinary-format scale basis;
- Lumen freezes the resulting `O(c)` into its own versioned contract.

---

# 8. Explicitly Excluded Current List-One Categories

## 8.1 Fund / unit codes

The pinned SIX snapshot marks these codes with `IsFund="true"`:

```text
BOV CHE CHW CLF COU MXV USN UYI UYW XAD
```

They are not members of `lumen-currency-v1`.

Their exclusion is a v1 product-domain choice, not a claim that the ISO assignments are invalid.

## 8.2 N.A. minor-unit special codes

These coded List One entries have nonnumeric / N.A. minor-unit evidence in the pinned snapshot:

```text
XAG XAU XBA XBB XBC XBD XDR XPD XPT XSU XTS XUA XXX
```

They are not members of `lumen-currency-v1`.

This excludes, among other categories:

- precious metals;
- bond-market units;
- SDR;
- testing;
- no-currency;
- other special units.

## 8.3 No-code territory rows

List One also contains territory rows such as "No universal currency" without a `Ccy` value.

Those rows do not produce registry members.

---

# 9. Historical / Withdrawn Codes

Historical / withdrawn ISO codes from SIX List Three are **not** admitted into `lumen-currency-v1` by this proposal.

That does not authorize Lumen to destroy, rewrite, round, substitute, or omit an existing canonical record merely because its currency code is not a member of this registry.

The separate historical/current out-of-domain compatibility gate remains responsible for existing canonical state that cannot be represented under the eventually accepted Portable v1 domain.

Therefore:

    not a lumen-currency-v1 member
    !=
    permission to mutate existing canonical state

---

# 10. Registry Identity Must Travel With Portable Data

The registry version is semantic state.

A receiving implementation must not have to infer which `O(c)` table the exporter meant from:

- export date;
- app version;
- operating-system version;
- current standards data;
- currency code alone.

The proposal therefore requires the registry identifier to travel with both Lumen-owned portable formats.

---

# 11. Portable JSON v1 Registry Field

Portable JSON v1 should add the required top-level field:

```json
{
  "format": "lumen-portable",
  "version": 1,
  "currency_registry": "lumen-currency-v1",
  "exported_at": "2026-09-24T20:00:00Z",
  "categories": [],
  "payment_methods": [],
  "tags": [],
  "sources": [],
  "transactions": []
}
```

The field is document-wide.

Every Transaction currency in the document is interpreted against that registry.

For the initially proposed contract:

    currency_registry == "lumen-currency-v1"

is the only supported registry value.

A future implementation may explicitly support another registry identifier without reinterpreting the immutable meaning of v1.

An unknown registry identifier is a well-formed but unsupported portable semantic.

It must not fall back to the receiver's current registry.

---

# 12. Lumen CSV v1 Registry Field

CSV has no top-level object envelope.

The registry identifier should therefore be carried as a required column repeated on every row.

The proposed exact header becomes:

```text
currency_registry,transaction_date,posted_date,amount,currency,type,status,merchant_name,category_name,category_group,payment_method_name,notes
```

Every data row must contain the same nonempty registry identifier.

For the initially proposed contract:

    lumen-currency-v1

is the only supported value.

A file whose rows contain conflicting registry identifiers is not a valid Lumen CSV v1 semantic document.

A file with the correct header but an unknown registry identifier is syntactically recognizable as Lumen CSV v1 but contains an unsupported portable semantic.

The blank template may contain only the header; rows created from that template must populate the registry identifier.

---

# 13. Registry Versioning Rules

## 13.1 Registry IDs are immutable

Once accepted and published:

    lumen-currency-v1

must never change its:

- admitted code set;
- `O(c)` values;
- source-snapshot identity.

Corrections or standards evolution require a new registry ID.

## 13.2 Registry evolution is independent from schema evolution

The registry identifier is explicit so currency semantics do not need to be guessed from the top-level Portable format version alone.

A later Lumen implementation may understand:

    format = lumen-portable
    version = 1
    currency_registry = lumen-currency-v2

only if that combination is explicitly admitted.

Older implementations that do not know `lumen-currency-v2` must return an unsupported-registry result rather than reinterpret it through v1.

This proposal does not pre-admit `lumen-currency-v2`.

## 13.3 No "latest registry" semantics

Portable data must never mean:

    use whatever registry is latest when this file is opened

Registry lookup is by exact identifier.

## 13.4 Export selection remains constrained by exact representability

An exporter must not choose a registry merely because it is newest.

The selected registry must be capable of representing every currency semantic the export claims to support.

The disposition for existing canonical records whose currencies are outside every currently admitted portable registry remains part of the separate historical/current out-of-domain gate.

---

# 14. Runtime and UI Lists Are Not Registry Authority

Current production code may expose:

- a small hard-coded Settings currency menu;
- a somewhat different Transaction form menu;
- `Locale.commonISOCurrencyCodes` validation.

None of those lists defines `lumen-currency-v1`.

After eventual implementation admission, product UI may choose a smaller convenience list or search experience.

But Portable v1 registry membership must come from the Lumen-owned registry contract, not from those presentation choices.

This proposal does not authorize changing current production validation.

---

# 15. General Rounding Remains Separate

The pinned CLDR 48.2 fraction data resolves general `rounding = 0` for every admitted `lumen-currency-v1` member.

That is a characterization of this pinned source snapshot.

It does **not** collapse the already-separate rounding gate into registry membership.

The accepted ordinary-scale contract remains:

    O(c) models fractional scale only

If a later registry source snapshot contains a nonzero general rounding increment for an admitted code, Lumen must have an explicit admitted rounding policy before that increment can affect readiness, confirmation, display authority, or normalization.

Cash `cashDigits` / `cashRounding` remain separately out of the generic Transaction readiness rule.

---

# 16. Import and Validation Classification

For a recognized Portable v1 document:

## Known registry + admitted currency

Proceed to structural money and currency-scale readiness evaluation.

## Known registry + currency not in registry

Result:

    well-formed token
    but unsupported portable currency semantic

Do not silently treat it as admitted because the receiver's OS recognizes it.

## Unknown registry identifier

Result:

    unsupported registry semantic

Do not reinterpret through `lumen-currency-v1`.

## Foreign CSV without the registry column

It is not Lumen CSV v1 merely because the other columns look similar.

It belongs to the foreign-CSV mapping path.

---

# 17. Round-Trip Implication

A Portable JSON / CSV v1 document carrying:

    lumen-currency-v1

gives the receiver enough information to determine, without network access:

- whether a three-letter token is a registry member;
- the exact `O(c)` that governed currency-scale readiness;
- that those semantics came from the immutable Lumen registry definition rather than the receiver's current platform data.

This closes the ambiguity that existed when membership and `O(c)` were stable responsibilities but no versioned definition traveled with the document.

It does not by itself close the broader historical/global-out-of-domain round-trip gate.

---

# 18. What This Proposal Does Not Admit

This proposal does not admit:

- historical / withdrawn List Three codes into `lumen-currency-v1`;
- SIX fund/unit entries marked `IsFund="true"`;
- precious-metal codes;
- SDR or bond-market unit codes;
- testing or no-currency codes;
- CLDR general non-cash rounding increments as behavioral rules;
- cash-specific rounding;
- FX conversion;
- a new canonical storage model;
- runtime registry fetching;
- automatic registry upgrades for old files;
- production implementation;
- final historical/current out-of-domain export behavior;
- exact canonical decimal serialization.

---

# 19. Proposed Contract Language

PortableMoneyV1 should state:

> **Portable v1 currency semantics are interpreted against an explicit immutable Lumen currency-registry identifier carried by the portable document. The first proposed registry is `lumen-currency-v1`.**

It should state:

> **`lumen-currency-v1` admits the 155 codes enumerated by this contract. Its enumerated membership and `O(c)` mapping are the normative immutable registry definition. Construction used SIX ISO 4217 List One data reporting publication date 2026-09-17 plus pinned CLDR 48.2 general currency `digits` data. The original SIX retrieval bytes were not retained or fingerprinted, so the publication date and mutable SIX source location are construction provenance rather than a claimed immutable byte snapshot. Neither external source is consulted dynamically at runtime.**

It should state:

> **A registry identifier is semantic version state. Unknown registry identifiers must not be interpreted using the receiver's current registry or platform currency metadata.**

It should state:

> **Lumen CSV v1 carries the registry identifier as a required repeated `currency_registry` column whose value must be consistent across all rows. Portable JSON v1 carries the identifier once at the top-level envelope.**

---

# 20. Review Questions

Independent review should answer:

1. Is the pinned SIX List One membership filter an appropriate v1 boundary for ordinary currencies?
2. Should entries explicitly marked `IsFund="true"` remain outside the first registry?
3. Should coded entries with N.A. minor units, including metals, SDR, testing, no-currency, and special units, remain outside the first registry?
4. Is the exact 155-code membership list appropriately normative given the recorded 2026-09-17 SIX construction evidence and the explicit limitation that the original SIX XML bytes were not retained/fingerprinted?
5. Is pinned CLDR 48.2 general `digits`, including its DEFAULT=2 rule, the correct source for immutable `O(c)` values?
6. Is the explicit 16-code ISO-minor-unit / CLDR-ordinary-scale divergence documented clearly enough?
7. Should `lumen-currency-v1` be immutable, requiring a new registry ID for later membership or `O(c)` changes?
8. Should registry identity travel explicitly in Portable JSON and CSV rather than being inferred only from format version or export date?
9. Is a repeated required `currency_registry` CSV column the correct file-level compromise for a flat format?
10. Is it sufficiently clear that historical/current canonical compatibility and general rounding increments remain separate gates?

Until independent review is complete, `lumen-currency-v1` membership and registry-version semantics remain **PROPOSED**, not accepted.
