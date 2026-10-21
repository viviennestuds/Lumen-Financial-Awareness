# Lumen Phase 1C — A4 Simulator xattr attribution preflight

**Status: PROPOSED SCOPE / REVIEW PENDING — NOT AN EXECUTABLE AUTHORIZATION.**
This narrow plan follows independent acceptance of the blocked A4 missing-store negative control. This document neither modifies the approved eleven-file diagnostic nor authorizes a new Simulator run.

## Fixed evidence and question

- Original blocked A4 negative control: [GitHub Actions run 39535161853](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39535161853); workflow SHA `83852d787f2c13b402f47d43f180d0259db23d27`; diagnostic source `ab7de1532a9e75106a52c377da334dbe1843a381`; synthetic run UUID `c72aeb89-21c2-4b42-b937-bdea94c51aa6`.
- Immutable disposition: **BLOCKED / OBSERVATION INTEGRITY UNPROVEN**, due to accessible xattrs reported by Darwin `flistxattr` during `inventory(app_data_container)`. The original run's pre-worker baseline established run root plus `events/` present, but source-store and inspection-copy absent; **observer was NOT launched**. The exact offending object and attribute name(s) were **not** observed.
- Earlier [host-only API preflight 39531584972](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39531584972) remains valid within its ordinary disposable file/directory scope.
- **Decision question:** On a freshly installed, isolated *diagnostic* Simulator container, where are accessible xattrs reported? Are they on a store-preservation object, a shared ancestor, or on ambient container state encountered only in whole-container change detection? Structural position alone does **not** establish safety, ownership, origin, stability, or harmlessness.

## Scope and sequence, only if separately owner-authorized

1. **Separate execution identity:** one fresh macOS GitHub-hosted runner, one newly created/booted iOS 18.5 Simulator, its UDID and device/runtime metadata, new preflight run UUID, workflow commit SHA, diagnostic source SHA, Xcode version, and a SHA-256 of the compiled diagnostic binary and every host attribution module. Never reuse or mutate the original A4 Simulator container.
2. **Build and install only:** check out exact approved diagnostic source `ab7de1532a9e75106a52c377da334dbe1843a381` clean; compile the standalone Stage A target for the generic iOS Simulator with signing disabled; verify the exclusive bundle identifier `org.lumenresearch.phase1c.stagea.probe`; install that diagnostic app **without launching it**. Confirm the returned data container is absolute and belongs to that exact bundle on the freshly identified Simulator. Do not install production Lumen.
3. **Before host-created run layout:** attempt bounded, read-only descriptor-based attribution of the diagnostic app data-container root and descendants, including the root itself. Record an explicit `pre_run_layout` phase, whether complete or blocked. This can distinguish pre-existing ambient state from objects created as part of the synthetic run setup, but cannot establish exact provenance of every attribute.
4. **Controlled setup only:** use the approved, narrowly scoped `create_disposable_run()` host helper to create a new UUID directory with its required `events/` sibling. Check and record that `source-store/` and `inspection-copy/` remain absent. This **does mutate the disposable diagnostic container**; the subsequent filesystem *inspection* is read-only. Do not synthesize a SwiftData store or launch a worker/observer.
5. **After setup:** perform a second bounded descriptor-based attribution of the container root and descendants (`post_run_layout` phase). Independently compare the observations; record any changed/unreadable node and avoid assuming stable state. Optionally call the **unmodified, fail-closed** diagnostic `inventory(data)` only to capture its blocked/accepted disposition. The independent attribution must never bypass or disable that guard.
6. **Evidence:** preserve a JSON-only artifact with relative paths, classified object roles, native xattr names, native errors, per-object identity/stat snapshots, coverage and instability flags, the two stage labels, source/build fingerprints, and explicit nonclaims. No compiled application uploaded. Preserve console logs. Report both a *native attribution completeness disposition* and the *unchanged A4 blocker* separately; do not convert the earlier A4 run into a success.

**No** diagnostic `controller.main()`, `perform()`, `simctl launch`, app launch, worker/observer process, SwiftData store open/save, A1, A0 signal, A2/A3, Stage B, production app/container access, xattr modification/removal, chmod repair, or execution of any other scenario.

## Descriptor-only read-only traversal design

- Begin at a verified application data-container directory, validated against the fresh diagnostic Simulator/bundle. Validate every ancestor with `lstat`/identity checks. Open the target root with `O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC`; record `fstat`.
- Enumerate directories using their already-open descriptor. For each relative entry, `stat(..., dir_fd=parentfd, follow_symlinks=False)`, open through the parent descriptor with `O_NOFOLLOW`, and verify `fstat` matches the observed device and inode before inspection. Check stability of identity/stat fields before and after; record races as **ATTRIBUTION INCOMPLETE**, not successful enumeration.
- Inspect only verified regular-file and directory descriptors. Encountering symlinks, mount transitions, special files, inaccessible objects, suspicious hard links, or unsupported operations must never cause following an alias or silent omission. Record typed blockers and mark coverage **INCOMPLETE**.
- Use Darwin `flistxattr(fd, NULL, 0, XATTR_SHOWCOMPRESSION)` to query the required bytes. For attribution *only*, unlike the production guard, allocate a bounded name buffer (proposed cap **64 KiB per object**) and call descriptor-based `flistxattr(fd, buffer, capacity, XATTR_SHOWCOMPRESSION)`; use correctly declared ctypes signatures and `use_errno=True`. Never add `XATTR_NOFOLLOW` to `flistxattr`.
- Permit at most **three** total size/read attempts for a changing list; `ERANGE` requires a bounded new query, never an empty-list interpretation. ENOTSUP, EACCES, EPERM, EBADF, unexpected returns, oversize buffers, exhausted retries or malformed names yield a recorded failure and **INCOMPLETE** coverage. Enforce returned-size <= allocated capacity and a complete sequence of nonempty, NUL-terminated UTF-8 names; reject duplicated/malformed names. Do not use `fgetxattr` or read attribute **values**.
- Optionally repeat the size-only query and stat observation immediately after retrieval. A differing name-list length or changed file identity/metadata marks **UNSTABLE**; no equivalence guarantee follows from a same-length repeat.
- Bound traversal (proposed: at most **4,096 filesystem objects**, max **32 directory levels**, max **60 seconds** of attribute enumeration after setup), mark explicit coverage failure on exhaustion, and avoid unbounded diagnostic/container logs. The controller's existing fail-closed behavior is untouched.

### Required report categories (not safety classifications)

| Role | Example relative path | Interpretation |
| --- | --- | --- |
| `container_root` | `.` | Diagnostic app data-container root; metadata may be managed by Simulator |
| `shared_ancestor` | `Library/`, `Library/Application Support/`, `Library/Application Support/Phase1CStageA/` | Ancestor of synthetic run/store paths; **not itself copied store content** |
| `run_root` | `Library/Application Support/Phase1CStageA/<new-UUID>/` | Disposable run root, checked separately |
| `events` | `.../<new-UUID>/events/` | Host/app handshake subtree, not the store |
| `source_store_artifact` | `.../<new-UUID>/source-store/...` | Store-preservation boundary; expected absent in missing-store control |
| `inspection_copy_artifact` | `.../<new-UUID>/inspection-copy/...` | Observer inspection boundary; expected absent before any observer |
| `ambient_container_state` | Other objects relative to diagnostic container | Broad change-detection context; may be OS-managed, **unproven** |

Record relative path, object type, `st_dev`, `st_ino`, `st_mode`, `st_nlink`, file size if relevant, `st_mtime_ns`, `st_ctime_ns`, xattr names (names only), native options `0x0020`, errno/phase if blocked, and before/after identity stability. Do not publish an absolute host path, xattr values, or production-user information.

### Coverage and evidence acceptance

- **ATTRIBUTION OBSERVED (SCOPED)** only if the supported object traversal completed with stable descriptor identities, valid native enumeration and no unreported/unreadable nodes in the bounded container at the recorded phase(s). This does **not** mean that every possible xattr is visible or that the source's A4 policy should change.
- **PARTIAL / INCOMPLETE / UNSTABLE** for any unreadable object, unsupported object type, native error, size cap, traversal limit, object replacement, or unverified provenance. Preserve the last verified evidence; do not infer absence or mark the original A4 scenario as observed.
- An xattr on a real store object would directly implicate preservation semantics. An xattr on unrelated ambient content may instead require a **separate, independently reviewed** whole-container observation policy. An xattr on a *shared ancestor* requires special attention; it cannot be dismissed by relabeling as ambient.
- Observed attribute names and locations do **not** by themselves prove that the attributes are safe to ignore. No allowlisting or source exception is proposed here.
- The original A4 negative-control result and the host-preflight PASS remain separate, unchanged experimental checkpoints.

## Execution hold

**No workflow or attribution executable has been added or triggered by this proposal.** Obtain independent technical review of the specific read-only attribution tool/workflow and explicit owner permission for the single installation/setup/inspection run before committing a push-triggered workflow. The workflow should be scoped to one branch, one run number and one attempt, and must not trigger any other Stage A scenario. A1/A4 behavioral rerun, A0 external SIGKILL, A2/A3, Stage B, and production changes remain unauthorized.
