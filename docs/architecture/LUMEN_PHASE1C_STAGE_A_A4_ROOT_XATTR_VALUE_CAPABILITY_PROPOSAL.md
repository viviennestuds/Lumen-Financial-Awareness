# Lumen Phase 1C — A4 Container-Root Xattr Value-Access Characterization

**STATUS: PROPOSED CAPABILITY INVESTIGATION / DOCUMENTATION ONLY — INDEPENDENT REVIEW PENDING.**
**Authority:** No value-reading executable, GitHub Actions workflow, Simulator operation, diagnostic-source correction, A4 behavioral rerun, A1 experiment or production change is authorized by this document. Its proposed exact executable inventory is likewise **not** admitted until independently reviewed and owner-authorized.

## 1. Evidence and next decision

The independently accepted [A4 observation-integrity policy proposal](LUMEN_PHASE1C_STAGE_A_A4_OBSERVATION_INTEGRITY_POLICY_PROPOSAL.md) is at `84d1ed9fb51ce37b54242d1fb1aae01f835c2c17`, based on independently accepted names-only attribution workflow `39728992926`, implementing `5143cc37d109853254ce689fdd6a9ba0508cc6d6`, with approved Stage A diagnostic source `ab7de1532a9e75106a52c377da334dbe1843a381`.

Attribution reported **one** attribute-bearing object in each of two complete bounded phases: the isolated diagnostic app's **data-container root** (`.`), with accessible names `com.apple.containermanager.identifier`, `com.apple.containermanager.schema-version`, and `com.apple.containermanager.uuid`. No attribute **values** were read. The first A4 behavioral run `39535161853` stays **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**, and its exact offending object is historically unproven.

**Precise decision:** Can a newly provisioned, disposable iOS Simulator's *independently verified diagnostic container root* support bounded, descriptor-only, privacy-preserving acquisition and comparison of **all accessible reported attribute values**? Can it distinguish successful zero-length values, change, disappearance, unreadability, buffer races, unstable identities, and unsupported operations *without* persisting values or reusable fingerprints?

This is a **native capability and evidence-feasibility** question, not an assertion of metadata safety, SwiftData consistency or A4 acceptance.

## 2. Narrow proposed experiment (subject to separate execution approval)

1. Use one newly provisioned isolated iOS 18.5 Simulator on a macOS GitHub-hosted runner. Pin the exact approved Stage A diagnostic source and separately reviewed attribution implementation. Build/install only the exclusive diagnostic probe bundle `org.lumenresearch.phase1c.stagea.probe`, **without launch**. Do not access production Lumen, any real financial data or a prior Simulator.
2. Before any run-layout creation, independently verify the Simulator UDID, bundle ID, absolute app data-container path and complete no-symlink ancestor chain. Open the **exact returned container root** with `O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC`; hold that descriptor across both observations. Revalidate `fstat` identity, device, kind and containment against the verified path before/after each step. Loss of trusted identity is **fatal** and forbids subsequent setup.
3. **Observation A:** On that root descriptor alone, enumerate accessible attribute names under the same `flistxattr(..., XATTR_SHOWCOMPRESSION=0x0020)` visibility as the accepted attribution. Attempt a bounded **complete** native value observation for each name under the supported value API/options. Preserve the values *only in short-lived process memory* for comparisons. Include immediate within-phase rechecks sufficient to expose name-set or size/read instability; do not claim an atomic filesystem snapshot.
4. **Controlled setup:** Only after Observation A's containment and acquisition are established, create exactly one new UUID run root and `events/` directory using the approved `artifact_capture.create_disposable_run` helper. Verify `source-store/` and `inspection-copy/` are absent. This setup is an explicitly permitted mutation of the disposable *diagnostic* container; the value-inspection operations remain read-only. **No observer, worker, SwiftData store, or app launch.**
5. **Observation B:** Revalidate the same root and obtain names and full accessible values again. Compare the two in **one process**, using constant-time comparison if practical, but without retaining or publishing values, ordinary hashes or persistent comparison keys. Capture a separate conclusion for value equality, different values, added/removed names or an unestablished comparison. Setup might legitimately coincide with external Simulator activity: never infer exclusive causality from A/B changes.
6. **Negative controls:** Exercise native behavior on **separately confined disposable host-only fixtures** (not on the diagnostic container root): known absent attribute, legitimate empty value, nonempty equality and deliberate difference, name addition/removal, buffer-too-small/ERANGE, missing attribute/ENOATTR, inaccessible/unsupported options and forced size/read races where reproducible. Simulated native responses may supplement but not replace real Darwin API checks. No fixture may reside in another app's container or become a production test.
7. Emit a bounded JSON-only artifact and job logs with *names, structural role, typed status and equality/inequality results only*. The observation **must not serialize values, value prefixes, base64, raw hex, ordinary SHA hashes, unkeyed digests, reusable HMAC tags, keys, or process memory dumps**. Do not log native buffer contents. Dispose of transient native buffers as far as the runtime permits and document remaining memory/coredump limitations. The user-facing artifact can include the scope, name membership, zero-length classification and failure codes, but must not expose secret-bearing value bytes.

### Exact Darwin interface proposal

- `flistxattr(int fd, void *namebuf, size_t size, int options)` for **name enumeration** with `XATTR_SHOWCOMPRESSION=0x0020`, as in the accepted attribution experiment.
- `fgetxattr(int fd, const char *name, void *value, size_t size, u_int32_t position, int options)` for **value size query and retrieval**. Declare all **six** ctypes arguments and `ssize_t` return type with `use_errno=True`; use `position=0` for these non-resource-fork attributes. Begin with documented supported `options=0`; **do not assume** `XATTR_SHOWCOMPRESSION` or `XATTR_NOFOLLOW` is an admissible value-read option. The held no-follow descriptor supplies the object binding.
- Distinguish size-query success returning **0 bytes** from `ENOATTR`, `EACCES`, `EPERM`, `ENOTSUP`, `EINVAL`, `ERANGE`, unexpected return lengths and native invocation errors. Do not map errors to empty values or absent names.
- Proposed bounded limits (reviewable, not platform guarantees): **64 KiB name-list**; **64 KiB maximum value per attribute**; at most **three size/read attempts per attribute per phase**; **32 names maximum** on this root; a fixed total observation deadline **60 seconds per phase**. Exceeding any limit is **INCOMPLETE/BLOCKED**, never accepted equality. Recheck the name list and relevant descriptor identity after retrieval.
- Values should be held in mutable native buffers for in-process comparison and explicitly cleared when no longer needed. Avoid creating immutable copies that cannot be erased. This is best-effort process-memory hygiene, **not a guarantee** against runtime allocation copies or memory inspection. Any alternative keyed comparison method needs a separate reviewed confidentiality rationale.

Reference: [Apple fgetxattr(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fgetxattr.2.html), including the six-argument interface, `position=0` for non-resource-fork attributes, size-query behavior, and native error cases. API availability does **not** prove access to the three reported Simulator values.

## 3. Independent result axes and fail-closed criteria

| Axis | Reported states | Meaning |
| --- | --- | --- |
| Root/containment | `TRUSTED` / `ROOT_BLOCKED` | A root-blocked observation terminates the investigation, including preventing controlled setup. |
| Native value acquisition | `COMPLETE` / `INCOMPLETE` / `UNSTABLE` | Complete requires every accessible reported name and full value observed under bounded checks in both phases. |
| Value comparison | `EQUAL` / `VALUES_CHANGED` / `NAMES_CHANGED` / `NOT_ESTABLISHED` | A detected difference is **useful observed evidence**, not a pass for later A4 integrity acceptance. |
| Capability conclusion | `SCOPED_COMPARISON_OBSERVED` / `BLOCKED_OR_UNESTABLISHED` | A scoped observation requires complete acquisition in both phases. It does **not** establish stability over future worker/observer windows. |

A **scoped comparison may be complete even if it detects a genuine difference** between two trustworthy phase observations. Such a result supports native change-detection capability but **does not** support an assumption of attribute stability and could not pass a subsequent A4 root-unchanged gate. A name/value change *during a single phase* which prevents a trustworthy phase observation is `UNSTABLE`, not a comparable change. Missing/inaccessible/unbounded/malformed observations must lead to a failing workflow verdict while preserving whatever nonsecret evidence was established.

A workflow green result would mean only that its proposed capability experiment completed within scope; it must never be displayed as “A4 integrity passed” or “root metadata harmless.” The previous behavioral A4 failure remains unchanged regardless of this experiment.

## 4. Explicit proposed executable inventory — **not approved by this proposal**

If the characterization direction is independently accepted, propose **exactly two new tracked executables** to the reviewer **before implementing either**:

| Proposed path | Exclusive responsibility |
| --- | --- |
| `investigations/phase1c-stagea-a4-root-value-access/root_value_probe.py` | Bounded descriptor-bound Darwin value capability observation, private in-process comparison, typed JSON and controlled disposable run-layout setup. |
| `.github/workflows/phase1c-stagea-a4-root-value-access.yml` | Verify exact source provenance, compile and install the exclusive diagnostic without launch, provision one fresh Simulator, invoke the helper once, preserve sanitized JSON, and fail closed. |

Suggested implementation lineage: branch from accepted **attribution source checkpoint** `5143cc37d109853254ce689fdd6a9ba0508cc6d6`; retain its existing **two** attribution executables unchanged and add only these **two new paths**. Verify the diff against that checkpoint is exactly these files and all eleven original Stage A files remain byte-identical to `ab7de153...`. This proposal's policy and capability documents retain their own independent review authority; they need not be copied into the executable branch merely to establish ancestry.

**Source review staging:** implement both files initially on non-triggering `review/phase1c-stagea-a4-root-value-access`, with workflow `push` restricted to a distinct `validation/phase1c-stagea-a4-root-value-access` branch plus its exact workflow-file path. Do not create a run merely by writing the source. An existing validation ref may be safely staged at the approved base checkpoint *without a matching workflow-file change*, then fast-forwarded to an independently approved exact SHA **only after separate owner execution authorization**. Verify the real GitHub `push` event, exact SHA, branch, one-run/first-attempt guard and actual JSON. Do not infer execution from branch identity alone. No manual dispatch, automatic retries, or additional scenarios.

The **two-file inventory, executable implementation and one-time Simulator execution each require their own authorization gate**. No additional tracked fixtures, source modifications or more permissive workflow triggers are included.

## 5. Mandatory future integration constraints (not part of this characterization)

The independently approved policy demands two requirements at any later **diagnostic-source correction** gate:

1. **Root-state witness is a mandatory acceptance gate.** In the current `require_changes_within()`, only descendant `entries` are compared; the application-container root itself is *not*. Any approved value-sensitive witness must be checked at every applicable pre-/post-worker and pre-/post-observer comparison (including missing-store no-worker behavior). Failed root identity, name set, value equality, readability or completeness must override a successful descendant comparison, and preclude A4 acceptance.
2. **Strict copier isolation remains unweakened.** The existing `_extended_attributes()` rejection must still apply to source-store and inspection-copy roots and descendants, shared ancestors and other unadmitted ambient objects. A root-only observation mechanism must require independently proven identity/role and may not be exposed as a generic `ignore_xattrs` parameter, path-prefix allowlist or directory-wide exception. Unexpected store-associated sidecars anywhere else must remain observable and blocking.

Later deterministic tests must show **root mismatch blocks even when all descendants match** and **a new xattr-bearing descendant is still rejected**. These are future integration tests—not justification to edit `artifact_capture.py` or `controller.py` now.

## 6. Release and authority holds

**Next decision for independent review:** Is this the minimum sufficient **value-access capability experiment** and is the **proposed exact two-file boundary** an appropriate separate implementation surface? Reviewer may approve the direction, require refinements, or withhold admission. No more generic xattr name discovery is requested.

**Unchanged holds:** No value-reading code or workflow has been created or run. No modifications to the original eleven-file diagnostic or its strict extended-attribute guard; no A4 missing-store behavioral rerun, A1, A0 external SIGKILL, A2/A3, Stage B, production Lumen, or canonical main changes. The historical A4 disposition is permanently **BLOCKED / OBSERVATION INTEGRITY UNPROVEN** pending a **new, separately authorized** behavioral experiment (which this proposal does not authorize).
