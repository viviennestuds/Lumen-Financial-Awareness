# ADR-001: Canonical Financial Truth and Transaction Ingestion

- **Status:** Accepted
- **Date:** 2026-09-10
- **Decision Type:** Foundational architecture
- **Applies To:** Ledger and transaction-bearing ingestion
- **Related Documents:**
  - `docs/architecture/LUMEN_ARCHITECTURE_CONTRACT_V1.md`
  - `docs/ROADMAP.md`
  - `docs/NON_GOALS.md`

---

## Context

Lumen accepts financial information through multiple paths.

Current and planned examples include:

- manual entry;
- structured CSV/JSON import;
- receipt photos;
- screenshots;
- transaction notifications;
- future OCR or vision extraction;
- future enrichment providers.

These inputs have fundamentally different reliability characteristics.

A **user-confirmed financial record** represents a user decision about what should become part of their financial history after a meaningful opportunity to review or edit the proposed state.

By contrast, OCR output, parser output, imported fields, model inference, metadata, merchant normalization, and other machine-generated information may be:

- incomplete;
- ambiguous;
- incorrect;
- duplicated;
- stale;
- provider-specific;
- probabilistic.

If these different forms of information are treated as equally authoritative, Lumen risks allowing uncertain interpretation to become durable financial history without an explicit trust boundary.

Lumen therefore requires a clear distinction between:

1. what an input or machine proposes;
2. what the user has a meaningful opportunity to review or modify;
3. what the user explicitly authorizes;
4. what becomes canonical financial state after successful durable persistence.

The architecture must also remain compatible with Lumen's local-first direction and must not make a particular OCR, AI, import, cloud, or bank-data provider the source of financial truth.

---

## Decision

The canonical financial record in Lumen is the **user-confirmed `Transaction`**.

For transaction-bearing ingestion, the canonical convergence path is:

`Input / Proposal`  
→ `TransactionDraft`  
→ `Review`  
→ `Confirm`  
→ `Transaction`

A new `Transaction` becomes canonical only after:

1. proposed financial data reaches the Draft boundary;
2. the user has a meaningful opportunity to inspect, edit, exclude, or otherwise resolve the proposed state;
3. the user explicitly authorizes the record or selected set of records;
4. the required durable persistence succeeds.

Machine extraction, imports, enrichment, metadata, and external providers may create or populate proposals.

They may not create confirmed Transactions in a way that bypasses this boundary.

### Scope of This Decision

This ADR governs the **adoption of transaction-bearing input into canonical financial history**.

It does **not** require every later user-authored edit to an existing canonical Transaction to replay the original ingestion pipeline.

For example:

`New transaction-bearing input`  
→ `TransactionDraft`  
→ `Review`  
→ `Confirm`  
→ `Transaction`

while an existing canonical record may follow an edit workflow such as:

`Existing Transaction`  
→ `User-authorized edit`  
→ `Validate`  
→ `Durable save`  
→ `Updated Transaction`

An implementation may still use drafts, edit buffers, confirmation UI, or additional safeguards for later edits where useful.

The architectural requirement is that canonical edits remain:

- user-authorized;
- valid according to applicable domain rules;
- durably persisted before being represented as successful.

---

## Canonical Paths

### Manual Entry

Manual entry does not require evidence or machine extraction.

`User Input`  
→ `TransactionDraft`  
→ `Review`  
→ `Confirm`  
→ `Transaction`

Manual entry remains first-class.

It must not be forced through an artificial `EvidenceArtifact` solely for architectural uniformity.

---

### Evidence-Assisted Entry

Evidence-assisted ingestion may introduce additional interpretation stages before the Draft boundary.

`EvidenceArtifact`  
→ `Extraction`  
→ `Observation(s)`  
→ `FieldCandidate(s)`  
→ `Resolution`  
→ `TransactionDraft`  
→ `Review`  
→ `Confirm`  
→ `Transaction`

The extraction stages exist to improve the Draft presented to the user.

They do not change the source-of-truth rule.

---

### Structured Transaction Import

Structured transaction-bearing imports follow:

`CSV / JSON`  
→ `Parse`  
→ `TransactionDraft(s)`  
→ `Review`  
→ `Confirm`  
→ `Transaction(s)`

A structured format may be highly reliable, including Lumen's own versioned export format, but reliability does not eliminate the canonical Review/Confirm boundary for imported Transactions.

#### Batch Review and Confirmation

Review and confirmation may be **batch-oriented** where appropriate.

This ADR does not require a user to individually confirm every record in a large import.

For example:

```text
300 imported records
        ↓
300 TransactionDrafts
        ↓
Import Review
├── inspect proposed records
├── edit where necessary
├── identify warnings
├── resolve likely duplicates
├── exclude unwanted records
└── explicitly confirm selected/all
        ↓
Durable persistence
        ↓
Transactions
