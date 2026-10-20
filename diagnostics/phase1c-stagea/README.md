# Lumen Phase 1C — Stage A disposable diagnostic (SOURCE REVIEW ONLY)

**Status:** Implementation-only draft. Nothing here has been built, installed, launched,
run, or validated. A separate owner authorization and independent executable-source
review are mandatory before any build, app installation, store access, or signal attempt.

## Authority and containment

This eleven-file, standalone native iOS diagnostic is scoped to **A0/A1/A4 only**
under the Stage A exact-boundary acceptance. It has no project/target dependency on
the production Lumen Xcode project; no Lumen ledger models, bootstrap, migration,
importer, historical fixture, reference-initialization witness/control, CI or user
container is in scope.

The diagnostic bundle identifier is:
org.lumenresearch.phase1c.stagea.probe

Synthetic stores belong exclusively to the diagnostic app's Simulator data
container, under Library/Application Support/Phase1CStageA/<new-UUID>/source-store.
Observer input is a separately verified inspection-copy sibling. Events are in a
third sibling directory. All source/copy evidence is disposable; never use the
installed Lumen app's bundle identifier or data container.

## Review the source before any executable activity

The host Python code is expected to be run on a macOS host with a selected
booted iOS Simulator only **after separate authorization**. There are no
automatic or CI runs. The implementation defines an explicit native Xcode project,
a SwiftUI worker/observer with one artificial SwiftData @Model, and host-side
controller, artifact copier and narrowly scoped result oracles.

The independent review must inspect:
- exact eleven-file allowlist and Xcode build settings;
- isolated Simulator identity and diagnostic bundle verification;
- process attribution and whether process death was genuinely externally caused;
- full source-store subtree capture with no-follow/no-hardlink rules and stable
  regular-file hashes; file protection, extended attributes and possible
  store-associated artifacts outside the captured tree are blockers;
- distinct source pre-open, copy pre-open, copy post-open, source post-open evidence;
- A4 source preservation and copy checks gating A1 reopening conclusions;
- blocked/inconclusive classifications and non-promotion to authority claims.

### Critical A0 process-kill hold

**No host SIGKILL is implemented or armed.** The controller explicitly reports
BLOCKED / TERMINATION UNVERIFIED for the external-kill scenario. This is intentional:
a separate PID check followed by os.kill(pid, SIGKILL) cannot eliminate PID reuse
between verification and signaling. simctl terminate, in-app exit, and injected
errors are not substitutes for a verified external SIGKILL. A process-bound
termination backend needs independent platform evidence and code review before
any future signal attempt. The current source cannot be described as having
demonstrated A0 external termination.

This is an open diagnostic feasibility question, not permission to weaken the
accepted Phase 1C failure model. The two non-kill A0 controls remain distinct.

## Scenario oracles (not yet executed)

- A0 injected error / ordinary exit: explicit negative controls, NOT crash evidence.
- A0 external SIGKILL: BLOCKED pending demonstrably process-bound safe signaling.
- A1 synthetic create/save/reopen: may count only if A4 isolation/copy evidence
  passes and a separate observer process reads the expected synthetic sentinel.
- A4 known-store: pre-open source evidence, quiescent isolated byte copy, source
  unchanged, observer-induced effects independently inventoried.
- A4 missing-store: original absence before observation and continued absence
  afterward, with any copy-created store attributed to the observer.

A2 termination after save, A3 termination during store creation, physical-device
characterization, Stage B and production implementation are NOT CHARACTERIZED.

## Future authorized invocation shape (NOT AUTHORIZATION TO EXECUTE)

Once separately approved, the controller expects a built app and a specific
booted Simulator UDID, with a scenario name such as a1-store, a4-known-store,
a4-missing-store, a0-injected-error, or a0-ordinary-exit. It obtains the app
container using the exact diagnostic bundle ID and allocates an unpredictable
run UUID. Host manifests are retained locally in .runs/ and ignored by Git.
Source/copy/artifact fingerprints and platform metadata in those manifests
require independent inspection; successful samples do not establish general
SwiftData crash guarantees.

A0 external-kill is available only as an explicitly BLOCKED classification in
this code revision; do not edit out the guard without new owner authorization
and an independently reviewed executable mechanism.

## Evidence limitations

A byte-identical copy is not necessarily a logically consistent SwiftData store.
An injected Swift error is not an abrupt process termination. A post-copy
successful fetch is not lifecycle, freshness, store-provenance, or reference
authority proof. Simulator observations alone do not justify device-wide claims.
Any uncertainty about writer quiescence, snapshot/companion-file completeness,
process identity, copy isolation, or original protection must be marked BLOCKED
or INCONCLUSIVE and returned to independent review.

The code has not been compiled or executed in this source-only implementation gate.
