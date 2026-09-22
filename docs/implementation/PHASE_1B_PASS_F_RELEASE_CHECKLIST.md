# Phase 1B Pass F — Release Correctness Checklist

Canonical Phase 1B baseline: `5e8397c4bd37e888185314a9fa11848d5c5ba30d`

Pass F validates the integrated Confirmed Evidence Retention v1 capability. Passes A–E are fixed dependencies. Validation inconvenience does not authorize architecture expansion; a failing acceptance check must be diagnosed before any production correction is admitted.

## Automated release gates

- [x] Complete `LumenFinanceTests` target passes, allowing only previously documented simulator-only characterization skips.
- [x] Manual-entry acceptance UI path passes:
  `input → draft → review → confirm → transaction → relaunch → inspect`.
- [x] Settings privacy copy acceptance check passes.
- [x] Upload retention/save-without copy acceptance check passes.
- [x] Full `LumenFinanceUITests` target is executed and its results are classified according to `docs/knowledge/testing/ios-runtime-validation.md`; retained known-red characterization/probe tests are evidence, not silently promoted into release blockers.
- [x] Authentic Phase 1A existing-store compatibility harness passes against the Pass F production candidate.
- [x] Existing-store report proves historical store open, historical values preserved, current mutation/relaunch, and no migration requirement introduced by Phase 1B.
- [x] Repository media inventory contains no personal diagnostic/test images or private evidence artifacts. Production app artwork is allowed.

## Physical-device release acceptance

Use one known Pass F build on a physical iPhone. Keep the same installed build, bundle identity, and app data container throughout each terminate/relaunch sequence. Do not reinstall between pre/post observations.

Record:

- device model / iOS version;
- build source SHA;
- install method;
- observation date;
- whether the app was backgrounded or force-closed at each lifecycle boundary.

### Retained-evidence path

1. Launch the app and complete onboarding if genuinely required.
2. Add an image through the normal Upload flow.
3. Reach Review and verify the selected image produced a staged evidence-backed draft.
4. Confirm using the normal retained-evidence action.
5. Open the resulting Transaction Detail.
6. Verify Attachment reports **Retained image available**.
7. Force-close the app.
8. Relaunch the same installed build without reinstalling.
9. Reopen the same Transaction.
10. Verify the Transaction still exists.
11. Verify Attachment still reports **Retained image available**.

Acceptance meaning:

```text
confirmed TransactionSource commitment marker
+
retained payload
+
startup Pass E reconciliation
→ committed source preserved
→ committed payload preserved
→ Pass D reports available after relaunch
```

A failure here blocks Phase 1B release completion and should be diagnosed before any architecture change.

### Save Without Retained Evidence path

1. Add a second image through Upload.
2. Reach Review.
3. Choose **Save without retained evidence**.
4. Open the resulting Transaction Detail.
5. Verify the transaction remains canonical and Attachment truthfully reports that the original image was not retained / no retained locator exists.
6. Force-close the app.
7. Relaunch the same installed build.
8. Reopen the same Transaction.
9. Verify the Transaction still exists.
10. Verify the attachment presentation remains truthful and does not claim a retained image is available.

Acceptance meaning:

```text
saved financial transaction
+
nil retained locator
+
no retained v1 payload
→ financial record survives relaunch
→ Pass D does not invent attachment availability
```

### Manual-entry path

1. Create a transaction using **Manual Entry** only.
2. Enter amount and merchant.
3. Review and confirm.
4. Force-close and relaunch.
5. Reopen the transaction.
6. Verify the transaction persisted and Attachment reports **No attachment**.

Manual entry must require no source, staging area, retained-evidence store, or evidence availability to remain usable.

## Optional crash/orphan characterization

Only if a controlled build/test setup can create genuine never-committed v1 material without adding release-only production APIs:

```text
recognized never-committed v1 material
→ terminate before commitment
→ relaunch
→ startup reconciliation
→ stale controlled material cleaned
→ canonical ledger unchanged
```

Do not add a maintenance UI, schema field, generalized reconciliation trigger, or other production mechanism merely to make this characterization convenient.

## Release hygiene

Before Phase 1B is declared complete:

- [x] Compare the production candidate schema/model files against canonical Pass E and confirm no unplanned schema change.
- [x] Confirm no migration code was added for Phase 1B.
- [x] Confirm no personal receipt/photo fixture, Picker Lab image, screenshot, PDF, xcresult, archive, or other private diagnostic asset entered the production repository.
- [ ] Confirm temporary validation workflows are removed after their evidence is captured.
- [ ] Record the final validation candidate SHA, workflow run IDs, artifact digests, physical-device result, and final branch head in PR/release evidence.

## Completion rule

Phase 1B Confirmed Evidence Retention v1 is release-complete only when all required automated gates, authentic existing-store compatibility, and the physical-device retained-confirm/relaunch path have acceptable evidence.

Pass F may correct release defects that validation demonstrates. It must not reopen A–E or add unrelated product scope merely to simplify validation.


---

## Pass F closure evidence — 2026-09-21

### Automated validation

Validated executable candidate: `91c571bd3e16a3a252adca5b7385b280929335f2`

GitHub Actions run: `35664571269` — **success**

- Complete `LumenFinanceTests`: 135 executed, 1 established simulator-only characterization skip, 0 failures.
- Pass F acceptance UI paths: 3 executed, 0 failures.
- Complete `LumenFinanceUITests`: 18 executed, 2 expected gated compatibility skips in the ordinary full-target invocation, 0 failures.
- Authentic existing-store compatibility job: passed through historical-store materialization/open, historical sentinel verification, current mutation, and post-mutation relaunch.
- Schema-surface, migration-introduction, and repository media/diagnostic inventory gates passed.

Artifacts:

- `Lumen-Phase1B-PassF-Release-3` — artifact ID `10669242021`; SHA-256 `f462f605c28aae4b66ddb3720aed9b010fc8edaf29cfd2323d7be5aefbf3b1e9`.
- `Lumen-Phase1B-PassF-ExistingStore-3` — artifact ID `10669283706`; SHA-256 `755891f0686419e653e5602f9545ab4357bad7b184bc22952b9db894cc625013`.

### Physical-device acceptance

Device: iPhone 13 Pro (iPhone14,2), iOS 18.5.  
Observation date: 2026-09-21.  
Build source SHA: `91c571bd3e16a3a252adca5b7385b280929335f2`.  
Install continuity: the Pass F build was installed in place over the existing Lumen installation; the existing personal ledger remained present. The distribution mechanism is not asserted by this record because it was not captured as repository evidence.

Observed on the same installed app/data container:

- existing pre-Phase-1B ledger survived the in-place update;
- a real PhotosPicker-backed draft reached Review and confirmed through the normal retained-evidence path;
- the resulting Transaction reported retained evidence available and the retained image was readable;
- after force-close and relaunch, the same Transaction survived and the retained image remained readable;
- startup reconciliation therefore did not destroy the committed source/payload in this exercised path;
- a Manual Entry transaction proceeded through Review and Save with no evidence requirement;
- after force-close and relaunch, that manual Transaction survived and continued to report **No attachment**.

### Save Without Retained Evidence classification

**Physical healthy-state Save Without was not executed and is not classified as a physical Pass F release gate.**

The checklist's earlier physical Save Without sequence assumed that the action is available during a healthy evidence-backed Review. Source tracing during device acceptance established that this is not the frozen Pass C contract: healthy staged evidence uses the normal retain-evidence path, while **Save Without Retained Evidence** becomes user-accessible from the retryable retention-failure state.

The canonical Pass F implementation plan requires physical retained-confirm/relaunch verification; it does not require deliberate induction of a retention failure on a physical device. Save-without recovery semantics remain covered by deterministic Pass C validation. No device/container corruption, storage exhaustion, protection-state manipulation, debug failure injection, or production behavior change was introduced merely to manufacture this state.

### Closure disposition

All substantive canonical Pass F acceptance criteria are supported by automated, authentic-store, and physical-device evidence. Remaining work after this record is release bookkeeping only: remove temporary validation workflow infrastructure, prove the validated-candidate → final-head delta is non-executable bookkeeping/infrastructure only, inspect the canonical Pass E → final Pass F diff, and package the evidence in the Pass F pull request.
