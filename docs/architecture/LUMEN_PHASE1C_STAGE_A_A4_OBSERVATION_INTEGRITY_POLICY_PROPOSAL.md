# Lumen Phase 1C — Stage A A4 Observation-Integrity Policy Separation

**STATUS: DOCUMENTATION-ONLY PROPOSAL — INDEPENDENT DESIGN REVIEW PENDING.**
**Authority:** no code changes, no new diagnostic admission, no Simulator execution, no permission to weaken existing fail-closed behavior. This proposal preserves the distinction between *observing* ambient filesystem state and *faithfully preserving* SwiftData store-associated artifacts. Repository residency is not acceptance.

## 1. Narrow decision

**Question:** Can the Stage A diagnostic account for accessible metadata on the *enclosing disposable diagnostic application-container root* without rejecting the entire container inventory, while preserving strict store-artifact copying rules and fail-closed detection of unexpected filesystem changes?

This is **not** authorization to ignore attributes; allow all directory attributes; allowlist `com.apple.*`; use names-only evidence as proof of unchanged values; expand A4 scenarios; characterize production containers; or make claims about SwiftData logical consistency.

The original approved eleven-file Stage A diagnostic remains pinned to `ab7de1532a9e75106a52c377da334dbe1843a381`. The independently reviewed attribution executable remains pinned to `5143cc37d109853254ce689fdd6a9ba0508cc6d6`. Neither is changed by this proposal.

## 2. Evidence provenance, what it shows, and what it does not

| Evidence | Scoped finding | Boundary |
| --- | --- | --- |
| [First A4 behavioral run 39535161853](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39535161853), original synthetic UUID `c72aeb89-21c2-4b42-b937-bdea94c51aa6` | Run-root initial baseline succeeded; source-store and inspection-copy absent; following whole-container inventory returned **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**. | Observer never launched; exact offending object not recorded; no successful A4 behavioral acceptance. |
| [One-shot attribution run 39728992926](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39728992926), artifact ID `12404725542`, attribution UUID `fa3c11b2-66aa-4826-b010-47feb3521a3b` | Approved `5143cc37...` workflow used approved `ab7de153...` diagnostic source, fresh iOS 18.5 Simulator. Phase A: **8** objects, COMPLETE; Phase B: **12** objects, COMPLETE; **one** attribute-bearing object in each: `.` (data-container root). | Separate environment from first run; finite object/visibility scope; neither values nor value stability characterized; no SwiftData store existed. |
| Attribute names observed at root in *both* attribution phases | `com.apple.containermanager.identifier`; `com.apple.containermanager.schema-version`; `com.apple.containermanager.uuid`. Inspected shared ancestors, run root, and `events/` reported no accessible attributes. | Names suggest container-management metadata but do not prove origin, harmlessness, semantic meaning, or value equality. |

Run 39728992926's JSON artifact was preserved by GitHub Actions with 14-day retention (reported expiry **2026-11-05 UTC**). The attribution result is independently accepted as **ATTRIBUTION OBSERVED (SCOPED)**. The earlier behavioral result remains **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**. Source compilation and attributed names do not authorize a policy correction.

### Causal explanation, without historical overclaim

In `diagnostics/phase1c-stagea/Host/artifact_capture.py`, `inventory(data)` checks `_extended_attributes(fd)` on the **inventory root before recursively traversing children**. That function uses a descriptor-based, size-only `flistxattr(..., XATTR_SHOWCOMPRESSION)` query and rejects *every* positive accessible-name-list size. In `Host/controller.py`, A4 calls `inventory(data)` after its narrower pre-worker run-root baseline. The newly observed container-root attributes would be sufficient to cause the same guard to block in the characterized environment.

This strongly explains the mechanism but cannot prove the exact object or values in the historical run, which used a different Simulator.

## 3. Responsibilities that must not be conflated

| Object / responsibility | Required property | Proposed default |
| --- | --- | --- |
| **Actual source-store tree** (store files and directories, including its root) | Faithful copy of relevant bytes, modes, structure, and metadata; avoid an apparently valid copy missing metadata. | **Retain current strict rejection** of uncharacterized extended attributes. No value-observation substitute for preservation. |
| **Inspection-copy tree** | Independent observer isolation, source unchanged, attributable effects on copy; never silently lose store-associated metadata. | Retain existing strict copy/source integrity checks and isolation requirements. |
| **Unexpected store-associated object anywhere else in container** | Detect, classify, and block or independently account for writes *outside* the prescribed store tree. | **No exemption.** Such objects may not be reclassified as harmless ambient state based on location or attribute prefix. |
| **Shared ancestors of source/inspection paths** | Establish containment, directory identity, access/mode, and changes that could affect store or observer. | **Retain strict handling until separately characterized**; no generic ancestor or directory exception. |
| **Verified data-container root (`.`)** | Retain whole-container change detection; distinguish observed root metadata from copied store artifacts. | **Candidate for a narrowly role-scoped, value-sensitive observation witness**, contingent on value-access characterization and independent acceptance. |
| **All other ambient container objects** | Preserve baseline-to-final change detection and unknown-node blocking. | Current strict guard remains; no inference that root-specific evidence generalizes. |

**Role means an identity-verified position with a defined observation duty, not a filename, an attribute name, or a mere directory type.** No object containing a real store artifact, an unrecognized store sidecar, or a storage-metadata dependency can silently qualify for relaxed preservation.

## 4. Proposed minimum semantics for any container-root witness

A future implementation **must not** simply skip `_extended_attributes()` on the application root or compare only its attribute names. Its admission would require all of the following, **subject to independent characterization first**:

1. **Identity and scope:** independently verify the disposable diagnostic Simulator UDID, exclusive bundle and exact returned data-container location. Open the container root through no-follow descriptor-based traversal, verify root/ancestor identity before and after observation, reject replacement/alias/mount/containment failures. Only this exact verified root role may use the proposed *observation*, rather than *preservation*, mechanism.
2. **Accessible-name set:** enumerate all names reported under explicit native options (including the existing `XATTR_SHOWCOMPRESSION` visibility choice). Capture a canonical set sorted by raw name bytes, reject duplicate/malformed names and unstable enumeration. Record name additions, removals, and changes across the controlled baseline-to-final comparison. Visibility remains scoped to accessible native results; zero accessible names is **not** a universal absence guarantee.
3. **Attribute-value state:** for **every** reported accessible name, obtain a complete, bounded, descriptor-bound observation of the value (including valid zero-length values), or fail closed. Name equality and ordinary `stat` equality are **insufficient**. Value equality, change, unknown, and unreadability are different evidence outcomes. No attribute is automatically admitted solely because its name appeared in the attribution run.
4. **Privacy-conscious representation:** prefer comparing values only within a single short-lived diagnostic process and emitting **only per-object/per-name equality or changed/error classifications**, never raw values. An alternative may use a keyed run-local opaque comparison (e.g. an ephemeral HMAC key never written to disk or logs); that option requires separate review, explicit domain separation, appropriate value-size bounds, and leakage analysis. **Do not emit ordinary unsalted digests** of potentially small or sensitive attribute values as if they were confidentiality-preserving. This proposal does not select or authorize any value-reading API, key scheme, or digest format.
5. **Snapshot stability:** bound name/value sizes, memory/time, native retries, and filesystem node counts. Revalidate descriptor identity, name-set membership, and applicable metadata around value reads; detect native size races, `ENOATTR`, `ERANGE`, authorization errors, mutation during retrieval, or exhausted limits. Without a sufficiently trustworthy paired observation, report **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**. A two-pass observation is not an atomic snapshot and cannot disprove all transient mutations.
6. **Paired observation window:** establish the container baseline **after intentional setup mutations and before worker/observer activity**; compare to the corresponding post-activity whole-container observation. Preserve existing separate comparisons after worker and after observer, including A4 missing-store's no-worker boundary, rather than substituting attribution pre-/post-run-layout snapshots. Do not treat permitted setup changes as permission for unrelated runtime writes.
7. **Whole-container change detection:** keep recursive no-follow inventories and checks for file bytes, modes, directory membership, and relevant metadata outside the permitted subtrees. Compare root metadata and attribute-state witness independently, not just descendants. Unexpected changes outside narrowly recorded permitted paths **must fail**, including created, relocated, replaced, deleted, unreadable or attribute-bearing store-associated artifacts. Do not let an allowed ancestor or container-root observation mask a descendant change.
8. **Failure provenance:** distinguish `VALUE_CHANGED`, `NAME_SET_CHANGED`, `VALUE_UNREADABLE`, `VALUE_UNSTABLE`, `IDENTITY_LOST`, `OBSERVATION_INCOMPLETE`, `UNEXPECTED_ASSOCIATED_WRITE`, and `NO_DETECTED_CHANGE_WITHIN_SCOPE` in diagnostic evidence; preserve error/stage provenance without writing attribute values. None of those categories may turn the original failed A4 run into a PASS.

**Positive equality witness:** in a separately authorized future A4 run, two trustworthy observations with identical reported names and values would establish only *no detected change to the accessible attributes within that bounded comparison*. It would **not** establish the attributes' safety, their creation provenance, invisibility of privileged attributes, or absence of transient changes; nor would it prove SwiftData pre-open consistency.

## 5. Decision alternatives and recommendation

- **A — Keep unconditional rejection everywhere.** Safest with current evidence, but blocks A4 whenever the container root has these attributes. **Retain as current policy pending a better-characterized mechanism.**
- **B — Ignore root attributes, admit names-only, or exempt all directories/`com.apple.*`.** Unacceptable: cannot detect value changes; can hide security-relevant metadata or unknown store-associated writes.
- **C — One narrow root-only value-state observation witness, strict preservation elsewhere.** **Preferred design candidate**, not yet implementable: requires demonstrated native value access and privacy-safe, stable comparison semantics plus an independently reviewed exact diagnostic-source correction.
- **D — Extend role-aware observation to other ambient objects.** Not supported by these results; would require separate object-role evidence, scope analysis, and authorization.

No automatic normalization of changing OS metadata is proposed. If the platform changes root values during ordinary permitted setup or observation, a conservative BLOCKED outcome remains appropriate until the actual change window, relevance, and alternative controls receive separate review.

## 6. Counterexample tests the eventual design must survive

| Counterexample | Required behavior |
| --- | --- |
| Same root attribute names; **different value bytes** | Detect change; fail; never report unchanged from names alone. |
| Same root attribute names; different order | Canonicalize names; do not report false change solely due to listing order. |
| Root attribute added or removed | Detect and fail/require review; do not silently accept as ambient. |
| Attribute becomes unreadable, too large, or changes between size/read | Fail closed with typed error; do not substitute empty value or absent attribute. |
| Root or ancestor replaced during inspection | Terminate due to untrusted containment, without proceeding to worker/observer. |
| Attributed value/bytes observed on **real store artifact** | Preserve current rejection; root-specific mechanism is inapplicable. |
| Attribute-bearing sidecar appears **outside** `source-store/` | Detect unexpected associated path or a whole-container failure; do not mask it as ambient. |
| File within allowed inspection-copy changes while original source changes | Source unchanged must fail; permission to modify copy is not permission to modify source. |
| Parent membership changes but original children still match | Record change/instability; not a complete observation. |
| Root metadata legitimately changes during run-layout setup | Establish correct post-setup baseline; do not globally ignore root metadata or allow later unaccounted mutations. |
| Some xattrs invisible under current process permissions/options | Declare visibility limitation; no absolute absence claim. |

## 7. Next evidence gate — proposal, not permission

The names-only attribution has answered its stated question. **Do not rerun generic attribute discovery or A4 behavior** simply to repeat it.

Before deciding whether option C can be implemented, separately propose and independently review the **minimum value-access capability characterization** on a disposable diagnostic Simulator root. It should answer:

- Can each currently reported accessible root attribute's full value be read *through an independently verified file descriptor*, under the actual host/Simulator environment?
- Can a bounded, race-sensitive before/after equality comparison be made under the intended native API and options, distinguishing empty, missing, inaccessible, oversize, and changed values?
- Can the test compare values without publishing raw bytes, ordinary low-entropy hashes, attribute contents, or long-lived keys? What exactly remains in runner memory and logs?
- Is there unavoidable platform-managed change within a controlled observation window, and, if so, must it remain blocking?
- Can full container inventory still detect unanticipated store-associated writes and descendant changes without relying on attribute-name exemptions?

Apple's published Darwin interface documents descriptor-based `flistxattr` for accessible names and `fgetxattr` for values, including a size-query form. Their existence is **not** evidence that the needed values are readable, stable, or semantically admissible on this Simulator filesystem.

Reference manuals: [Apple flistxattr(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/flistxattr.2.html); [Apple fgetxattr(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fgetxattr.2.html).

Any resulting experiment needs its own **exact executable-file boundary**, independent source review, single-run authorization, provenance and fail-closed JSON classification. **No attribute-value experiment or diagnostic implementation is authorized by this document.**

## 8. Authority and release holds

**Design review required:** Can the proposed per-role integrity duties and value-sensitive witness prevent unobserved attribute changes and unexpected store-associated writes without weakening source-copy preservation? A reviewer should reject any attempt to treat the three observed root names as a permission list.

**Separate implementation review required:** Even if the policy candidate is accepted at proposal level, any modification of `artifact_capture.py`, `controller.py`, orchestration, tests, or evidence schema requires its own exact authorization, diff/source review, and controlled preflight. Do not modify the accepted diagnostic as part of this proposal.

**Unchanged gates:** The historical A4 missing-store run remains **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**. A4 behavioral retry, A1, A0 external SIGKILL, A2/A3, Stage B, and production changes remain unauthorized.

**Explicit nonclaims:** No production data access; no source implementation; no implicit acceptance of pre-open SwiftData/SQLite consistency; no assumption that attribute values are stable or harmless; no claim that a complete bounded inventory detects every possible external write.
