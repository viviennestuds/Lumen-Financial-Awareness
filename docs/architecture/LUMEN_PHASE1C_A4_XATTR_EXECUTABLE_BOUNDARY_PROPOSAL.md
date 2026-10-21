# Lumen Phase 1C — A4 xattr attribution: exact executable boundary

**PROPOSED ONLY — independent boundary/source review and separate execution authorization required.** Supplements the approved proposed-plan checkpoint `2758f944095e0caacf5e8dbbf197686b21ee4364`. The original A4 run `39535161853` remains **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**.

## Exact proposed additions

Create an isolated branch `validation/phase1c-stagea-a4-xattr-attribution` from the unchanged approved diagnostic SHA `ab7de1532a9e75106a52c377da334dbe1843a381`.

Only two newly tracked executable files are proposed:

1. `.github/workflows/phase1c-stagea-a4-xattr-attribution.yml` — single-run, push-triggered macOS workflow for a fresh isolated iOS 18.5 Simulator, exact-source build/install without launch, controlled disposable run layout, two read-only attribution phases, JSON-only evidence.
2. `investigations/phase1c-stagea-a4-xattr-attribution/attribute_names.py` — standalone descriptor-only, bounded Darwin xattr **name** attribution utility with a structured evidence report; never a replacement diagnostic controller.

No additional scripts, tests, fixtures, deployment targets, or configuration files are authorized by this proposal. No change to the original eleven diagnostic files, canonical main, or production Lumen. Implement the Python helper before the workflow file; the latter's initial push must await separate permission because it triggers execution.

The workflow will use two independently verified checkouts: exact diagnostic SHA into `source/` and triggering validation-commit SHA into `investigation/`. Verify the only differences against the approved source are the two proposed files; record host-module/helper SHA-256, compiled diagnostic binary SHA-256, Xcode/Swift/Python/runner versions, Simulator UDID/runtime, bundle ID, run UUID, and workflow SHA. `permissions: contents: read`; branch/path-specific `push`; single `github.run_number == 1 && github.run_attempt == 1` gate; no reusable dispatch or automatic retry. Upload JSON only, not the app binary.

## Refinement A: useful partial attribution

Read directory entries in deterministic sorted order through verified directory descriptors. Open children relative to their already-verified parent with `O_NOFOLLOW`, compare `stat(...,follow_symlinks=False)` against `fstat`, and record relative path, device/inode/type, modes, link count, times, and identity/stability.

An unsafe/unreadable **child** must produce a typed `INCOMPLETE` record, with continued examination of independent siblings where their parent/root containment remains trustworthy. Never follow an unsupported node. Any loss of verified **container-root** identity or containment terminates the traversal (fatal, not partial). Stop safely at the agreed object/depth/time caps, recording `INCOMPLETE`.

For each directory, compare a fresh bounded listing of immediate entry names **before and after** inspecting its children. Changed membership or directory identity marks `UNSTABLE`; identical membership does not prove absence of transient changes.

Record two independent axes: coverage (`COMPLETE`, `INCOMPLETE`, `UNSTABLE`, `ROOT_BLOCKED`) and the set of positively identified attribute-bearing objects. Finding an attributable object does not convert incomplete overall coverage into complete coverage.

## Native name-only enumeration

Use descriptor-based Darwin `flistxattr` with `XATTR_SHOWCOMPRESSION=0x0020`, declared `ctypes` C signature and `use_errno=True`. Query required size, retrieve a bounded NUL-delimited name list (64 KiB per-object cap), and validate returned count, termination, UTF-8 names and uniqueness. Permit at most three bounded attempts on size races; errors, ERANGE exhaustion, cap breaches, malformed names, inaccessible objects, or unstable identity are typed incomplete/unstable evidence. **Never read attribute values**, use pathname-based fallback, change the approved `_extended_attributes()` guard, or label attributes as harmless.

## Refinement B: explicitly expected absence

Record `EXPECTED_ABSENT` separately from `UNREADABLE`, `UNRESOLVED`, `UNSTABLE`, and `UNEXPECTED_PRESENT`. Phase A (after install, before setup): the new run root and its dependent events/store/copy paths are expected absent. Phase B (after approved disposable run setup): the run root and events must be present, while source-store and inspection-copy must remain absent. Only use a verified-parent `ENOENT` observation or a documented descendant of an independently established absent ancestor as evidence of expected absence. An inaccessible existing object is never absent.

Retain distinct location roles: container root; shared ancestor; run root; events; actual source-store artifact; actual inspection-copy artifact; other ambient container state. These are **location**, not ownership or safety classifications. A fresh Simulator finding identifies a candidate corresponding to the earlier failure, not proof of the precise object involved in the previous run.

## Authorization holds

Only after **approval of this exact two-file inventory** may the utility and workflow be implemented for independent source review. Pushing the workflow is a separate **execution gate** requiring explicit owner permission to provision and install into one disposable Simulator, create the run layout and inspect two phases. No worker/observer launch, `simctl launch`, controller scenario, SwiftData store open, xattr modification, signal, A1/A4 behavioral retry, A2/A3, Stage B or production change is authorized. Return JSON and logs for independent assessment before any policy decision.
