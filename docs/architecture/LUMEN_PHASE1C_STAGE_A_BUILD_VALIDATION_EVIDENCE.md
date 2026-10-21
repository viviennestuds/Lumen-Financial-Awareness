# Lumen Phase 1C — Stage A build-validation evidence

**Evidence scope:** Build-only, independently reviewed. No diagnostic scenario was executed. This note is an evidence index, not a production contract, executable permission, or authority-mechanism acceptance.

| Field | Observed value |
| --- | --- |
| GitHub Actions run | [39525288019](https://github.com/viviennestuds/Lumen-Financial-Awareness/actions/runs/39525288019) |
| GitHub Actions job | 118978355566 |
| Workflow run conclusion | SUCCESS |
| Workflow branch | `validation/phase1c-stagea-build-only` |
| Workflow commit | `148960a98fd396f1b82eae2f42a6fe2058b03b2c` |
| Reviewed diagnostic checkout | `31f416be32cc78717d6c0eb87f067ee47807570b` |
| Host runner | Standard `macos-15`, ARM64 |
| Runner image | `20260907.0337.1` |
| Xcode | 16.4, build 16F6 |
| Swift | 6.1.2 |
| Simulator SDK | iOS 18.5 |
| Python | 3.14.7 |
| Build target | Standalone `Phase1CStageAProbe.xcodeproj`; Debug; generic iOS Simulator; signing off |
| Xcode build | **BUILD SUCCEEDED**; compiled/linked ARM64 and x86_64 Simulator |
| Python check | All three host modules bytecode-compiled successfully; no diagnostic entry points invoked |
| Installation, SwiftData execution, process signals | **NOT PERFORMED / NOT AUTHORIZED** |

The independently checked build log contained a nonblocking App Intents metadata-extraction warning and a note about disabled SwiftUI previews. The toolchain-version preflight also emitted a nonfatal broken-pipe exception from piping `xcodebuild -version` into `head`. GitHub noted that `actions/checkout@v4` used a deprecated Node runtime. These preflight/maintenance issues do not undo the separate successful compilation. Correct these issues if the workflow is later maintained; do not change the reviewed diagnostic source merely to eliminate them.

**Conclusions permitted:** The exact reviewed standalone diagnostic source compiled and linked under the recorded Apple toolchain. All three host Python modules passed syntax/bytecode checks.

**Conclusions NOT permitted:** Python macOS runtime API compatibility, Simulator installation or execution, worker/observer process integrity, SwiftData synthetic-store creation/reopening, A4 artifact isolation, pre-open database logical consistency, generic crash recovery, process-bound external SIGKILL, A2/A3, Stage B, or production authority-mechanism behavior.

**Next distinct gate:** Host-only, non-destructive Python/macOS interface preflight using isolated disposable host-side data. No diagnostic app installation, launch, real SwiftData store, or termination operation follows from this build-evidence record.
