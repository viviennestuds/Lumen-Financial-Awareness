# Lumen Phase 1C — Stage A macOS host-only compatibility evidence

**Current disposition: HOST-ONLY PREFLIGHT PASS (review of evidence pending).** This is bounded compatibility evidence from disposable host files, **not** authorization to execute A0/A1/A4, not a claim of real SwiftData artifact completeness, and not proof of the reference-authority mechanism.

## Earlier failure — archived, not reclassified

| Evidence | Observed result |
| --- | --- |
| GitHub Actions run | [39527229619](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39527229619) |
| Workflow commit | `eadf20450843e0ffed63db5e5943f4af6c06133f` |
| Diagnostic source | `31f416be32cc78717d6c0eb87f067ee47807570b` |
| Runner / Python | `macos-15` / 3.14.7 |
| Outcome | **BLOCKED:** `os.listxattr(fd)` unavailable on macOS Python; subsequent tests NOT REACHED |

This failure revealed a genuine host-portability defect. The prior [successful Xcode build](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39525288019) remains independently supported for the **earlier** source SHA; it did not exercise Python runtime behavior.

## Corrected source — non-destructive host preflight successful

| Evidence | Observed result |
| --- | --- |
| GitHub Actions run | [39531584972](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39531584972) |
| Job | `macos-host-compatibility`, ID `118998477501` |
| Workflow commit | `9bed821ebb7ebe50c6faae34dee3fe0d63b53820` |
| Exact reviewed source checkout | `ab7de1532a9e75106a52c377da334dbe1843a381` |
| macOS | 15.7.9, build 24G830, standard `macos-15` runner |
| Runner image | `20260907.0337.1` |
| Python | 3.14.7 |
| Workflow conclusion | **SUCCESS** |
| Checked host assertions | **20 PASSED**, 0 failed in the successful run |
| Scope | Only inert, disposable host-side fixtures and self-process observation. No Simulator operations or SwiftData store usage. |

The corrected `flistxattr(fd, NULL, 0, XATTR_SHOWCOMPRESSION)` behavior was exercised using the approved, **unchanged** diagnostic implementation at the exact SHA above:

- Ordinary regular file and directory descriptors with zero accessible reported xattrs: **accepted**.
- Real xattrs created on disposable regular file and directory descriptors via native `fsetxattr`: setter returned success; independent `fgetxattr` readback confirmed the exact value; `_extended_attributes()` and the actual `inventory()` call sites both raised `IntegrityBlocked` for each type.
- Negative descriptor argument: rejected. Native enumeration on unusable positive descriptor: blocked with native errno recorded. Injected native-library loading failure and unexpected negative native return: blocked.
- Previously **NOT REACHED** checks now passed: descriptor-relative no-follow file open, copying inert bytes and permission modes, source-root permission-change rejection, synthetic symlink rejection, and out-of-scope sibling-change rejection.
- Required host interface presence and observation of the preflight's **own** Python process: passed.

The native enumeration result of zero means **no accessible extended attributes were reported with the tested enumeration options and process visibility**. It is not proof of universal attribute absence.

The workflow emitted a nonblocking Python syntax warning about backslash-backtick escapes within summary-generation text. It did not affect any compatibility assertions or the final PASS, but the workflow should be tidied during subsequent maintenance rather than modifying the reviewed diagnostic.

## Authority boundary and next gate

The evidence supports **tested host-side Python/macOS interface compatibility** for the approved corrected source, **not** verification of a real SwiftData store, complete store-associated artifact scope, pre-open SQLite logical consistency, controller/observer identity across process launches, or A4 attribution under actual Simulator conditions. The host-only preflight deliberately did not execute `controller.py` scenario entry points, start a Simulator, install or launch any diagnostic app, create a SwiftData store, or issue any termination signal.

A1/A4 runtime experiments remain **NOT AUTHORIZED**. A0 external SIGKILL remains **BLOCKED / TERMINATION UNVERIFIED**. A2/A3, Stage B, and production implementation are outside scope. No diagnostic source or `main` branch changes occurred in the successful host-preflight workflow.

**Next step:** independent review of this exact host-preflight run and its logs, followed by a separate controlled Simulator experiment authorization only if justified.
