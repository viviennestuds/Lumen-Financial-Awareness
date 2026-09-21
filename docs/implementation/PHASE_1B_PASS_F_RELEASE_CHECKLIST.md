# Phase 1B Pass F — Release Correctness Checklist

Canonical Phase 1B baseline: `5e8397c4bd37e888185314a9fa11848d5c5ba30d`

Pass F validates the integrated Confirmed Evidence Retention v1 capability. Passes A–E are fixed dependencies. Validation inconvenience does not authorize architecture expansion; a failing acceptance check must be diagnosed before any production correction is admitted.

## Automated release gates

- [ ] Complete `LumenFinanceTests` target passes, allowing only previously documented simulator-only characterization skips.
- [ ] Manual-entry acceptance UI path passes:
  `input → draft → review → confirm → transaction → relaunch → inspect`.
- [ ] Settings privacy copy acceptance check passes.
- [ ] Upload retention/save-without copy acceptance check passes.
- [ ] Full `LumenFinanceUITests` target is executed and its results are classified according to `docs/knowledge/testing/ios-runtime-validation.md`; retained known-red characterization/probe tests are evidence, not silently promoted into release blockers.
- [ ] Authentic Phase 1A existing-store compatibility harness passes against the Pass F production candidate.
- [ ] Existing-store report proves historical store open, historical values preserved, current mutation/relaunch, and no migration requirement introduced by Phase 1B.
- [ ] Repository media inventory contains no personal diagnostic/test images or private evidence artifacts. Production app artwork is allowed.

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

- [ ] Compare the production candidate schema/model files against canonical Pass E and confirm no unplanned schema change.
- [ ] Confirm no migration code was added for Phase 1B.
- [ ] Confirm no personal receipt/photo fixture, Picker Lab image, screenshot, PDF, xcresult, archive, or other private diagnostic asset entered the production repository.
- [ ] Confirm temporary validation workflows are removed after their evidence is captured.
- [ ] Record the final validation candidate SHA, workflow run IDs, artifact digests, physical-device result, and final branch head in PR/release evidence.

## Completion rule

Phase 1B Confirmed Evidence Retention v1 is release-complete only when all required automated gates, authentic existing-store compatibility, and the physical-device retained-confirm/relaunch path have acceptable evidence.

Pass F may correct release defects that validation demonstrates. It must not reopen A–E or add unrelated product scope merely to simplify validation.
