# Lumen Phase 1C — A4 missing-store first Simulator experiment

**Disposition: BLOCKED / OBSERVATION INTEGRITY UNPROVEN.**
This is the evidence index for the narrowly owner-authorized **single A4 missing-store negative-control scenario**. It is not an acceptance of A4, A1, SwiftData reopening, or the reference-initialization authority mechanism.

## Execution provenance

| Property | Observed evidence |
| --- | --- |
| Diagnostic source (exact checked-out, clean) | `ab7de1532a9e75106a52c377da334dbe1843a381` |
| Isolated workflow branch | `validation/phase1c-stagea-a4-missing-only` |
| First workflow run | [39534946202](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39534946202) — **FAILED BEFORE SCENARIO INVOCATION** because of self-referential same-step Simulator-UDID output lookup; standalone Xcode build succeeded. This is a CI-orchestration defect, not diagnostic runtime evidence. |
| Corrected workflow commit | `83852d787f2c13b402f47d43f180d0259db23d27` |
| Executed scenario run | [39535161853](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39535161853) |
| Job | `a4-missing-store-once`, job ID `119010013878` |
| Scenario | **`a4-missing-store` only**, controller generated UUID `c72aeb89-21c2-4b42-b937-bdea94c51aa6` |
| Environment | macOS 15.7.9 ARM64, Xcode 16.4 (16F6), Swift 6.1.2, iOS Simulator 18.5, Python 3.14.7 |
| Isolated simulator | New disposable iOS 18.5 simulator `LumenStageA-A4Missing-39535161853` |
| Native diagnostic binary fingerprint | SHA-256 `b23b3db4980fb6d9ee9ba8b8a569f5f66a694d0e5887c009fde9bd2d869fa9ee` |
| Oracle | `phase1c-stagea-a0-a1-a4-oracles-v3` |
| Scenario exit code | 2 — **BLOCKED / OBSERVATION INTEGRITY UNPROVEN** |
| Evidence artifact | GitHub Actions artifact `lumen-stagea-a4-missing-json-evidence` (ID `12316749438`, JSON only, 14-day retention) |

## What was actually established

The approved source was checked out, the standalone diagnostic compiled, the fresh simulator was booted, and the controller entered only the approved A4 missing-store scenario. The controller verified the exclusive diagnostic bundle and recorded its binary SHA-256.

The scenario manifest contains a **pre-worker physical baseline**: the run root existed and contained only the `events` directory; **source-store was absent** and **inspection-copy was absent**. These are bounded observations made before any diagnostic observer opened a SwiftData store.

The controller then returned `BLOCKED / OBSERVATION INTEGRITY UNPROVEN` with reason:
`Uncharacterized accessible extended attributes reported by Darwin flistxattr`.

The manifest contains `pre_worker_baseline` but **not** `app_container_pre_worker`. The approved `controller.perform()` obtains the latter via `inventory(data)` after recording the pre-worker baseline and before assigning `source_initially_absent` or beginning the missing-store observer path. This is consistent with a fail-closed extended-attribute finding while inventorying the diagnostic application's broader Simulator data-container subtree, **before observer launch**. The manifest does not identify the object whose attributes caused the rejection: neither its pathname nor the attribute name(s) are established.

**NOT REACHED / NOT ESTABLISHED:** completed app-container pre-worker inventory, host-copy preservation, observer launch/identity/exit, observer-created artifact attribution, copy post-open inventory, source-still-absent check after observation, `a4_integrity_verified`, or a narrow `OBSERVED` A4 disposition. In particular, the initial source absence does **not** prove continued absence after any observer activity, since none was demonstrated.

## Boundaries preserved

Only an isolated disposable Simulator was created and the standalone diagnostic built/installed. No A1 known-store worker ran. No A0 external SIGKILL, A2/A3, Stage B, physical-device validation, or production-Lumen operation occurred. Canonical `main` and the independently accepted diagnostic source branch were not modified.

The previous [macOS host-only preflight (20/20 PASS)](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39531584972) remains valid for its **ordinary disposable host fixtures**. This new finding is not a contradiction: the real Simulator app container exposes uncharacterized attributes under this broader traversal.

## Next engineering gate, not authorized by this record

Return the manifest and workflow logs for **independent read-only assessment**. Consider a **separately reviewed, read-only attribution preflight** to identify the scope/provenance of extended attributes within the isolated diagnostic Simulator container without bypassing or relaxing the existing fail-closed guard. Do not label any platform-created xattr as harmless without concrete evidence and a reviewed policy. A4 repeat execution and A1 remain separately gated.
