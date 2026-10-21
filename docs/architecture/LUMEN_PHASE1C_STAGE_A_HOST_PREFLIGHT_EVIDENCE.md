# Lumen Phase 1C — Stage A macOS host-only preflight evidence

**Disposition: BLOCKED — macOS Python extended-attribute API unavailable.**

This record indexes one owner-authorized, non-destructive host compatibility check. It does **not** accept A0/A1/A4 runtime behavior or authorize an executable diagnostic.

| Evidence | Observed |
| --- | --- |
| GitHub Actions run | [39527229619](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39527229619) |
| Job | `macos-host-compatibility`, 118984629341 |
| Workflow commit | `eadf20450843e0ffed63db5e5943f4af6c06133f` |
| Source checked out (unmodified) | `31f416be32cc78717d6c0eb87f067ee47807570b` |
| Runner | Standard `macos-15` |
| Python | 3.14.7 |
| Overall job | **FAILURE** — genuine host compatibility defect, not an Xcode build result |
| Verified host APIs | `O_NOFOLLOW`, `O_DIRECTORY`, `O_CLOEXEC`, descriptor-relative `open/stat/mkdir`, `stat(...follow_symlinks=...)` |
| Process observation | `controller.process_snapshot(os.getpid())` successfully observed only the preflight's own Python process |
| Failure point | `artifact_capture.inventory(source)` on a disposable, inert file tree |
| Root cause | `artifact_capture._extended_attributes(fd)` calls `os.listxattr(fd)`, but this macOS Python interpreter has **no `os.listxattr` attribute**. The resulting exception is `AttributeError`, not the intended `IntegrityBlocked`. |
| Evidence completeness | Subsequent host-copy, containment-negative, and source-root mutation tests **NOT REACHED**; no conclusions about their behavior. |
| Diagnostic execution | **NOT PERFORMED**: no Simulator install/launch, SwiftData stores, A0/A1/A4 scenarios, SIGKILL, A2/A3, Stage B, or production code changed. |

The previous successful build-only run [39525288019](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39525288019) remains valid: exact diagnostic source compiles and links under Xcode 16.4 / iOS 18.5 Simulator SDK. Build success did not exercise this Python runtime API.

**Required next gate:** Independently review a targeted Darwin-compatible, descriptor-based extended-attribute enumeration design (for both regular-file and directory descriptors) that preserves no-follow and fail-closed behavior. Do **not** bypass or silently omit extended-attribute inspection. A source correction requires review, an exact new diagnostic source checkpoint, and fresh host compatibility evidence before considering A1/A4 execution.

**No accepted diagnostic source was modified.** This note lives only on the isolated host-validation branch, not on `main` or the implementation branch.
