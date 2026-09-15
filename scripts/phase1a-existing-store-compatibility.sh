#!/bin/bash
set -uo pipefail

BASELINE_SHA="${BASELINE_SHA:-dbc28ed9649d4930b45e2dcc44a7462729dfcf11}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-app.rork.8m36zsug0ex00d13e28li}"
CURRENT_ROOT="${CURRENT_ROOT:?CURRENT_ROOT is required}"
BASELINE_ROOT="${BASELINE_ROOT:?BASELINE_ROOT is required}"
OUTPUT_DIR="${OUTPUT_DIR:?OUTPUT_DIR is required}"
RUN_TAG="${GITHUB_RUN_ID:-local}-$(date +%s)"
PROJECT_RELATIVE="ios-lumen-finance/LumenFinance.xcodeproj"
SCHEME="LumenFinance"
TEST_CLASS="LumenFinanceUITests/LumenExistingStoreCompatibilityUITests"

mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/compatibility-report.txt"
SIMULATORS_FILE="$OUTPUT_DIR/simulators.txt"
: > "$SIMULATORS_FILE"

cat > "$REPORT" <<EOF_REPORT
baseline_sha=UNESTABLISHED
candidate_sha=UNESTABLISHED
bundle_identity=UNESTABLISHED
candidate_financial_sample_reseeding_capability=UNESTABLISHED
historical_store_materialized=NOT_REACHED
historical_store_reopen_observed=NOT_REACHED
xctest_harness_continuity=NOT_REACHED
compatibility_test_execution=NOT_REACHED
install_continuity=NOT_REACHED
historical_sentinel_assertions=NOT_REACHED
historical_financial_corpus_verified=NOT_REACHED
candidate_logical_compatibility=NOT_REACHED
current_mutation=NOT_REACHED
post_mutation_relaunch=NOT_REACHED
furthest_boundary=INITIALIZED
failed_boundary=NONE
phase1a_compatibility_gate=NOT_SATISFIED
production_change_authorized=NO
EOF_REPORT

set_field() {
  local key="$1"
  local value="$2"
  python3 - "$REPORT" "$key" "$value" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
key, value = sys.argv[2], sys.argv[3]
lines = path.read_text().splitlines()
needle = key + "="
for index, line in enumerate(lines):
    if line.startswith(needle):
        lines[index] = needle + value
        break
else:
    lines.append(needle + value)
path.write_text("\n".join(lines) + "\n")
PY
}

record_boundary() {
  set_field furthest_boundary "$1"
  echo "LUMEN_COMPATIBILITY_BOUNDARY $1"
}

fail_boundary() {
  local boundary="$1"
  shift
  set_field failed_boundary "$boundary"
  echo "LUMEN_COMPATIBILITY_FAILURE boundary=$boundary message=$*" | tee -a "$OUTPUT_DIR/failure-summary.txt"
  exit 1
}

inventory_dir() {
  local root="$1"
  local output="$2"
  python3 - "$root" "$output" <<'PY'
import hashlib, pathlib, sys
root = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
if not root.is_dir():
    raise SystemExit(f"missing directory: {root}")
rows = []
for path in sorted(p for p in root.rglob("*") if p.is_file()):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    rows.append(f"{path.relative_to(root).as_posix()}\t{path.stat().st_size}\t{digest}")
out.write_text("\n".join(rows) + ("\n" if rows else ""))
PY
}

wait_for_files() {
  local root="$1"
  local attempts="${2:-30}"
  for _ in $(seq 1 "$attempts"); do
    if [ -d "$root" ] && find "$root" -type f -print -quit | grep -q .; then
      return 0
    fi
    sleep 1
  done
  return 1
}

wait_for_stable_inventory() {
  local root="$1"
  local output="$2"
  local previous="$OUTPUT_DIR/.inventory.previous"
  local current="$OUTPUT_DIR/.inventory.current"
  rm -f "$previous" "$current"
  local stable=0

  for _ in $(seq 1 30); do
    if [ -d "$root" ]; then
      inventory_dir "$root" "$current" || true
      if [ -s "$current" ] && [ -f "$previous" ] && cmp -s "$previous" "$current"; then
        stable=$((stable + 1))
        if [ "$stable" -ge 2 ]; then
          cp "$current" "$output"
          rm -f "$previous" "$current"
          return 0
        fi
      else
        stable=0
      fi
      cp "$current" "$previous" 2>/dev/null || true
    fi
    sleep 1
  done

  rm -f "$previous" "$current"
  return 1
}

create_simulator() {
  local name="$1"
  local udid
  udid=$(xcrun simctl create "$name" "$DEVICE_TYPE_ID" "$RUNTIME_ID") || return 1
  echo "$udid" >> "$SIMULATORS_FILE"
  echo "$udid"
}

boot_simulator() {
  local udid="$1"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
}

get_data_container() {
  local udid="$1"
  xcrun simctl get_app_container "$udid" "$EXPECTED_BUNDLE_ID" data
}

configure_xctestrun_environment() {
  local plist="$1"
  python3 - "$plist" <<'PY'
import plistlib, pathlib, sys
path = pathlib.Path(sys.argv[1])
with path.open("rb") as fh:
    data = plistlib.load(fh)
count = 0

def apply(node, parent_key=""):
    global count
    if isinstance(node, dict):
        signature = " ".join(str(node.get(k, "")) for k in (
            "BlueprintName", "TestBundlePath", "TestHostBundleIdentifier", "TestTargetName"
        ))
        if "LumenFinanceUITests" in parent_key or "LumenFinanceUITests" in signature:
            env = node.setdefault("EnvironmentVariables", {})
            env["LUMEN_EXISTING_STORE_COMPATIBILITY"] = "1"
            count += 1
        for key, value in node.items():
            apply(value, str(key))
    elif isinstance(node, list):
        for value in node:
            apply(value, parent_key)

apply(data)
if count == 0:
    raise SystemExit("Could not find LumenFinanceUITests entry in generated xctestrun")
with path.open("wb") as fh:
    plistlib.dump(data, fh, fmt=plistlib.FMT_XML, sort_keys=False)
print(f"configured_ui_test_entries={count}")
PY
}

ACTUAL_BASELINE_SHA=$(git -C "$BASELINE_ROOT" rev-parse HEAD) || fail_boundary BASELINE_SOURCE_RESOLUTION "Unable to resolve baseline checkout"
ACTUAL_CANDIDATE_SHA=$(git -C "$CURRENT_ROOT" rev-parse HEAD) || fail_boundary CANDIDATE_SOURCE_RESOLUTION "Unable to resolve candidate checkout"
set_field baseline_sha "$ACTUAL_BASELINE_SHA"
set_field candidate_sha "$ACTUAL_CANDIDATE_SHA"

if [ "$ACTUAL_BASELINE_SHA" != "$BASELINE_SHA" ]; then
  fail_boundary BASELINE_SOURCE_RESOLUTION "Expected $BASELINE_SHA but checkout resolved to $ACTUAL_BASELINE_SHA"
fi
record_boundary SOURCE_PROVENANCE

python3 - "$BASELINE_ROOT/ios-lumen-finance/LumenFinance/Data/Seed.swift" "$CURRENT_ROOT/ios-lumen-finance/LumenFinance/Data/Seed.swift" <<'PY'
import pathlib, sys
baseline = pathlib.Path(sys.argv[1]).read_text()
candidate = pathlib.Path(sys.argv[2]).read_text()

def bootstrap_prefix(text):
    marker = "// MARK: - Categories"
    return text.split(marker, 1)[0]

if "seedTransactions(" not in bootstrap_prefix(baseline):
    raise SystemExit("Historical bootstrap no longer demonstrates production financial sample seeding")
if "seedTransactions(" in bootstrap_prefix(candidate):
    raise SystemExit("Candidate bootstrap can seed financial sample transactions; false-positive risk is not controlled")
PY
if [ $? -ne 0 ]; then
  fail_boundary SAMPLE_RESEEDING_GUARD "Historical/candidate seeding assumptions were not satisfied"
fi
set_field candidate_financial_sample_reseeding_capability ABSENT_VERIFIED_FROM_SOURCE
record_boundary RESEEDING_GUARD

RUNTIME_ID=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
items = [r for r in json.load(sys.stdin)["runtimes"] if r.get("isAvailable") and "iOS" in r.get("name", "")]
if not items: raise SystemExit(1)
def version(r):
    parts = r.get("version", "0").split(".")
    return tuple(int(p) if p.isdigit() else 0 for p in parts)
print(max(items, key=version)["identifier"])
') || fail_boundary SIMULATOR_SETUP "No available iOS simulator runtime"

DEVICE_TYPE_ID=$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
items = [d for d in json.load(sys.stdin)["devicetypes"] if d.get("name", "").startswith("iPhone")]
if not items: raise SystemExit(1)
preferred = ["iPhone 16 Pro", "iPhone 16", "iPhone 15 Pro", "iPhone 15"]
for name in preferred:
    match = next((d for d in items if d.get("name") == name), None)
    if match:
        print(match["identifier"]); break
else:
    print(items[-1]["identifier"])
') || fail_boundary SIMULATOR_SETUP "No iPhone simulator device type"

echo "runtime_id=$RUNTIME_ID" > "$OUTPUT_DIR/simulator-environment.txt"
echo "device_type_id=$DEVICE_TYPE_ID" >> "$OUTPUT_DIR/simulator-environment.txt"

PREFLIGHT_UDID=$(create_simulator "Lumen-Harness-$RUN_TAG") || fail_boundary SIMULATOR_SETUP "Could not create harness simulator"
COMPAT_UDID=$(create_simulator "Lumen-Compatibility-$RUN_TAG") || fail_boundary SIMULATOR_SETUP "Could not create compatibility simulator"
echo "preflight_udid=$PREFLIGHT_UDID" >> "$OUTPUT_DIR/simulator-environment.txt"
echo "compatibility_udid=$COMPAT_UDID" >> "$OUTPUT_DIR/simulator-environment.txt"
boot_simulator "$PREFLIGHT_UDID" || fail_boundary SIMULATOR_SETUP "Could not boot harness simulator"
record_boundary SIMULATOR_SETUP

BASELINE_DERIVED="$RUNNER_TEMP/LumenBaselineDerivedData"
CANDIDATE_DERIVED="$RUNNER_TEMP/LumenCandidateDerivedData"
rm -rf "$BASELINE_DERIVED" "$CANDIDATE_DERIVED"

BASELINE_PROJECT="$BASELINE_ROOT/$PROJECT_RELATIVE"
CANDIDATE_PROJECT="$CURRENT_ROOT/$PROJECT_RELATIVE"
DESTINATION="platform=iOS Simulator,id=$PREFLIGHT_UDID"

set +e
xcodebuild build \
  -project "$BASELINE_PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$BASELINE_DERIVED" \
  2>&1 | tee "$OUTPUT_DIR/baseline-build.log"
BASELINE_BUILD_STATUS=${PIPESTATUS[0]}
set -e
if [ "$BASELINE_BUILD_STATUS" -ne 0 ]; then
  fail_boundary BASELINE_BUILD_TOOLCHAIN "Historical source did not build unchanged"
fi
record_boundary BASELINE_BUILD

set +e
xcodebuild build-for-testing \
  -project "$CANDIDATE_PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$CANDIDATE_DERIVED" \
  2>&1 | tee "$OUTPUT_DIR/candidate-build-for-testing.log"
CANDIDATE_BUILD_STATUS=${PIPESTATUS[0]}
set -e
if [ "$CANDIDATE_BUILD_STATUS" -ne 0 ]; then
  fail_boundary CANDIDATE_BUILD "Candidate build-for-testing failed"
fi
record_boundary CANDIDATE_BUILD

BASELINE_APP="$BASELINE_DERIVED/Build/Products/Debug-iphonesimulator/LumenFinance.app"
CANDIDATE_APP="$CANDIDATE_DERIVED/Build/Products/Debug-iphonesimulator/LumenFinance.app"
if [ ! -d "$BASELINE_APP" ] || [ ! -d "$CANDIDATE_APP" ]; then
  fail_boundary BUILD_OUTPUT "Expected simulator app bundle missing"
fi

BASELINE_BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$BASELINE_APP/Info.plist")
CANDIDATE_BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$CANDIDATE_APP/Info.plist")
printf 'baseline_bundle_id=%s\ncandidate_bundle_id=%s\nexpected_bundle_id=%s\n' \
  "$BASELINE_BUNDLE" "$CANDIDATE_BUNDLE" "$EXPECTED_BUNDLE_ID" > "$OUTPUT_DIR/bundle-identity.txt"
if [ "$BASELINE_BUNDLE" != "$EXPECTED_BUNDLE_ID" ] || [ "$CANDIDATE_BUNDLE" != "$EXPECTED_BUNDLE_ID" ] || [ "$BASELINE_BUNDLE" != "$CANDIDATE_BUNDLE" ]; then
  set_field bundle_identity FAIL
  fail_boundary BUNDLE_IDENTITY_MISMATCH "Baseline/candidate bundle identity differs"
fi
set_field bundle_identity PASS
record_boundary BUNDLE_IDENTITY

XCTESTRUN=$(find "$CANDIDATE_DERIVED/Build/Products" -name '*.xctestrun' -type f -print -quit)
if [ -z "$XCTESTRUN" ] || [ ! -f "$XCTESTRUN" ]; then
  fail_boundary XCTESTRUN_DISCOVERY "Generated xctestrun not found"
fi
cp "$XCTESTRUN" "$OUTPUT_DIR/candidate-original.xctestrun"
configure_xctestrun_environment "$XCTESTRUN" | tee "$OUTPUT_DIR/xctestrun-environment-configuration.txt" || \
  fail_boundary XCTESTRUN_CONFIGURATION "Could not inject test-process compatibility marker"
cp "$XCTESTRUN" "$OUTPUT_DIR/candidate-compatibility.xctestrun"
record_boundary XCTESTRUN_CONFIGURATION

xcrun simctl install "$PREFLIGHT_UDID" "$CANDIDATE_APP" || fail_boundary XCTEST_PREFLIGHT_INSTALL "Could not install candidate on harness simulator"
xcrun simctl launch "$PREFLIGHT_UDID" "$EXPECTED_BUNDLE_ID" > "$OUTPUT_DIR/preflight-initial-launch.txt" || \
  fail_boundary XCTEST_PREFLIGHT_LAUNCH "Could not launch candidate on harness simulator"
sleep 3
xcrun simctl terminate "$PREFLIGHT_UDID" "$EXPECTED_BUNDLE_ID" >/dev/null 2>&1 || true
PREFLIGHT_CONTAINER_BEFORE=$(get_data_container "$PREFLIGHT_UDID") || fail_boundary XCTEST_PREFLIGHT_CONTAINER "Could not resolve preflight data container"
mkdir -p "$PREFLIGHT_CONTAINER_BEFORE/Library/Application Support/LumenCompatibilityHarness"
PREFLIGHT_SENTINEL="$PREFLIGHT_CONTAINER_BEFORE/Library/Application Support/LumenCompatibilityHarness/continuity.txt"
printf 'run=%s\ncandidate=%s\nnonce=%s\n' "$RUN_TAG" "$ACTUAL_CANDIDATE_SHA" "$(uuidgen)" > "$PREFLIGHT_SENTINEL"
PREFLIGHT_SENTINEL_HASH=$(shasum -a 256 "$PREFLIGHT_SENTINEL" | awk '{print $1}')
printf 'container_before=%s\nsentinel_hash_before=%s\n' "$PREFLIGHT_CONTAINER_BEFORE" "$PREFLIGHT_SENTINEL_HASH" > "$OUTPUT_DIR/xctest-harness-continuity.txt"

set +e
LUMEN_EXISTING_STORE_COMPATIBILITY=1 xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN" \
  -destination "platform=iOS Simulator,id=$PREFLIGHT_UDID" \
  -only-testing:"$TEST_CLASS/testHarnessDataContinuityPreflight" \
  -resultBundlePath "$OUTPUT_DIR/preflight.xcresult" \
  2>&1 | tee "$OUTPUT_DIR/xctest-harness-preflight.log"
PREFLIGHT_TEST_STATUS=${PIPESTATUS[0]}
set -e

PREFLIGHT_CONTAINER_AFTER=$(get_data_container "$PREFLIGHT_UDID" 2>/dev/null || true)
printf 'container_after=%s\n' "$PREFLIGHT_CONTAINER_AFTER" >> "$OUTPUT_DIR/xctest-harness-continuity.txt"
PREFLIGHT_SENTINEL_AFTER="$PREFLIGHT_CONTAINER_AFTER/Library/Application Support/LumenCompatibilityHarness/continuity.txt"
PREFLIGHT_ACTIVE=0
PREFLIGHT_PASS_MARKER=0
grep -q 'LUMEN_COMPATIBILITY_PREFLIGHT_ACTIVE' "$OUTPUT_DIR/xctest-harness-preflight.log" && PREFLIGHT_ACTIVE=1
grep -q 'LUMEN_COMPATIBILITY_PREFLIGHT_PASS' "$OUTPUT_DIR/xctest-harness-preflight.log" && PREFLIGHT_PASS_MARKER=1

if [ "$PREFLIGHT_ACTIVE" -ne 1 ] || [ "$PREFLIGHT_PASS_MARKER" -ne 1 ] || [ "$PREFLIGHT_TEST_STATUS" -ne 0 ]; then
  set_field xctest_harness_continuity UNESTABLISHED
  fail_boundary XCTEST_HARNESS_ACTIVATION "Exact compatibility UI-test path did not execute successfully"
fi
if [ ! -f "$PREFLIGHT_SENTINEL_AFTER" ]; then
  set_field xctest_harness_continuity FAIL
  fail_boundary XCTEST_HARNESS_DATA_CONTINUITY "Harness test path removed/replaced app data"
fi
PREFLIGHT_SENTINEL_HASH_AFTER=$(shasum -a 256 "$PREFLIGHT_SENTINEL_AFTER" | awk '{print $1}')
echo "sentinel_hash_after=$PREFLIGHT_SENTINEL_HASH_AFTER" >> "$OUTPUT_DIR/xctest-harness-continuity.txt"
if [ "$PREFLIGHT_SENTINEL_HASH" != "$PREFLIGHT_SENTINEL_HASH_AFTER" ]; then
  set_field xctest_harness_continuity FAIL
  fail_boundary XCTEST_HARNESS_DATA_CONTINUITY "Harness test path changed sentinel contents"
fi
set_field xctest_harness_continuity PASS
record_boundary XCTEST_HARNESS_CONTINUITY

boot_simulator "$COMPAT_UDID" || fail_boundary SIMULATOR_SETUP "Could not boot compatibility simulator"
xcrun simctl install "$COMPAT_UDID" "$BASELINE_APP" || fail_boundary BASELINE_INSTALL "Could not install historical app"
xcrun simctl launch "$COMPAT_UDID" "$EXPECTED_BUNDLE_ID" > "$OUTPUT_DIR/baseline-first-launch.txt" || \
  fail_boundary BASELINE_LAUNCH "Could not launch historical app"
sleep 2
BASELINE_CONTAINER=$(get_data_container "$COMPAT_UDID") || fail_boundary BASELINE_CONTAINER "Could not resolve historical data container"
BASELINE_SUPPORT="$BASELINE_CONTAINER/Library/Application Support"
echo "$BASELINE_CONTAINER" > "$OUTPUT_DIR/baseline-data-container.txt"
if ! wait_for_files "$BASELINE_SUPPORT" 30; then
  set_field historical_store_materialized FAIL
  fail_boundary BASELINE_STORE_READINESS "Historical app did not materialize persistent Application Support files"
fi
xcrun simctl terminate "$COMPAT_UDID" "$EXPECTED_BUNDLE_ID" >/dev/null 2>&1 || true
if ! wait_for_stable_inventory "$BASELINE_SUPPORT" "$OUTPUT_DIR/baseline-first-termination-inventory.txt"; then
  set_field historical_store_materialized UNESTABLISHED
  fail_boundary BASELINE_STORE_STABILITY "Historical store did not stabilize after first termination"
fi
set_field historical_store_materialized PASS
record_boundary HISTORICAL_STORE_MATERIALIZED

xcrun simctl launch "$COMPAT_UDID" "$EXPECTED_BUNDLE_ID" > "$OUTPUT_DIR/baseline-relaunch.txt" || \
  fail_boundary BASELINE_RELAUNCH "Historical app could not reopen"
sleep 3
xcrun simctl terminate "$COMPAT_UDID" "$EXPECTED_BUNDLE_ID" >/dev/null 2>&1 || true
BASELINE_CONTAINER_AFTER_REOPEN=$(get_data_container "$COMPAT_UDID") || fail_boundary BASELINE_REOPEN_CONTAINER "Historical data container unavailable after reopen"
BASELINE_SUPPORT_AFTER_REOPEN="$BASELINE_CONTAINER_AFTER_REOPEN/Library/Application Support"
if ! wait_for_stable_inventory "$BASELINE_SUPPORT_AFTER_REOPEN" "$OUTPUT_DIR/baseline-store-inventory.txt"; then
  set_field historical_store_reopen_observed UNESTABLISHED
  fail_boundary BASELINE_REOPEN_STABILITY "Historical store did not stabilize after reopen"
fi
set_field historical_store_reopen_observed PASS
record_boundary HISTORICAL_STORE_REOPEN

tar -C "$BASELINE_SUPPORT_AFTER_REOPEN" -czf "$OUTPUT_DIR/baseline-store-snapshot.tar.gz" . || \
  fail_boundary BASELINE_STORE_SNAPSHOT "Could not preserve historical store snapshot"
shasum -a 256 "$OUTPUT_DIR/baseline-store-snapshot.tar.gz" > "$OUTPUT_DIR/baseline-store-snapshot.tar.gz.sha256"
record_boundary HISTORICAL_STORE_SNAPSHOT

xcrun simctl install "$COMPAT_UDID" "$CANDIDATE_APP" || fail_boundary CANDIDATE_INSTALL "Could not install candidate over historical app"
CANDIDATE_CONTAINER_PRELAUNCH=$(get_data_container "$COMPAT_UDID") || fail_boundary CANDIDATE_PRELAUNCH_CONTAINER "Candidate data container unavailable before launch"
CANDIDATE_SUPPORT_PRELAUNCH="$CANDIDATE_CONTAINER_PRELAUNCH/Library/Application Support"
echo "$CANDIDATE_CONTAINER_PRELAUNCH" > "$OUTPUT_DIR/candidate-prelaunch-data-container.txt"
inventory_dir "$CANDIDATE_SUPPORT_PRELAUNCH" "$OUTPUT_DIR/candidate-prelaunch-store-inventory.txt" || \
  fail_boundary PRELAUNCH_STORE_CONTINUITY "Could not inventory candidate prelaunch store"
if ! cmp -s "$OUTPUT_DIR/baseline-store-inventory.txt" "$OUTPUT_DIR/candidate-prelaunch-store-inventory.txt"; then
  set_field install_continuity FAIL
  diff -u "$OUTPUT_DIR/baseline-store-inventory.txt" "$OUTPUT_DIR/candidate-prelaunch-store-inventory.txt" \
    > "$OUTPUT_DIR/prelaunch-store-inventory.diff" || true
  fail_boundary PRELAUNCH_STORE_CONTINUITY "Historical Application Support store bytes changed across candidate installation"
fi
set_field install_continuity PASS
record_boundary PRELAUNCH_STORE_CONTINUITY

set +e
LUMEN_EXISTING_STORE_COMPATIBILITY=1 xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN" \
  -destination "platform=iOS Simulator,id=$COMPAT_UDID" \
  -only-testing:"$TEST_CLASS/testHistoricalStoreCompatibility" \
  -resultBundlePath "$OUTPUT_DIR/compatibility.xcresult" \
  2>&1 | tee "$OUTPUT_DIR/compatibility-ui-test.log"
COMPAT_TEST_STATUS=${PIPESTATUS[0]}
set -e

CANDIDATE_CONTAINER_FINAL=$(get_data_container "$COMPAT_UDID" 2>/dev/null || true)
if [ -n "$CANDIDATE_CONTAINER_FINAL" ] && [ -d "$CANDIDATE_CONTAINER_FINAL/Library/Application Support" ]; then
  echo "$CANDIDATE_CONTAINER_FINAL" > "$OUTPUT_DIR/candidate-final-data-container.txt"
  inventory_dir "$CANDIDATE_CONTAINER_FINAL/Library/Application Support" "$OUTPUT_DIR/candidate-final-store-inventory.txt" || true
fi

ACTIVE_MARKER=0
LEDGER_OPEN_MARKER=0
PHASE_A_MARKER=0
MUTATION_MARKER=0
RELAUNCH_MARKER=0
grep -q 'LUMEN_COMPATIBILITY_TEST_ACTIVE' "$OUTPUT_DIR/compatibility-ui-test.log" && ACTIVE_MARKER=1
grep -q 'LUMEN_COMPATIBILITY_LEDGER_OPEN_PASS' "$OUTPUT_DIR/compatibility-ui-test.log" && LEDGER_OPEN_MARKER=1
grep -q 'LUMEN_COMPATIBILITY_PHASE_A_PASS' "$OUTPUT_DIR/compatibility-ui-test.log" && PHASE_A_MARKER=1
grep -q 'LUMEN_COMPATIBILITY_MUTATION_PASS' "$OUTPUT_DIR/compatibility-ui-test.log" && MUTATION_MARKER=1
grep -q 'LUMEN_COMPATIBILITY_RELAUNCH_PASS' "$OUTPUT_DIR/compatibility-ui-test.log" && RELAUNCH_MARKER=1

if [ "$ACTIVE_MARKER" -ne 1 ]; then
  set_field compatibility_test_execution FAIL
  fail_boundary COMPATIBILITY_TEST_HARNESS_ACTIVATION "Dedicated compatibility selector did not enter active harness path"
fi
set_field compatibility_test_execution PASS
record_boundary COMPATIBILITY_TEST_ACTIVE

if [ "$LEDGER_OPEN_MARKER" -ne 1 ]; then
  set_field historical_sentinel_assertions NOT_REACHED
  set_field historical_financial_corpus_verified UNESTABLISHED
  set_field candidate_logical_compatibility FAIL
  fail_boundary CANDIDATE_LEDGER_OPEN "Candidate did not establish inherited ledger-open success"
fi
record_boundary CANDIDATE_LEDGER_OPEN

if [ "$PHASE_A_MARKER" -ne 1 ]; then
  set_field historical_sentinel_assertions FAIL
  set_field historical_financial_corpus_verified UNESTABLISHED
  set_field candidate_logical_compatibility UNESTABLISHED
  fail_boundary HISTORICAL_SENTINELS "Required historical read-only assertions did not all pass"
fi
set_field historical_sentinel_assertions PASS
set_field historical_financial_corpus_verified PASS
set_field candidate_logical_compatibility PASS
record_boundary HISTORICAL_SENTINELS

if [ "$MUTATION_MARKER" -ne 1 ]; then
  set_field current_mutation FAIL
  fail_boundary CURRENT_MUTATION "Inherited Pending to Posted mutation did not complete"
fi
set_field current_mutation PASS
record_boundary CURRENT_MUTATION

if [ "$RELAUNCH_MARKER" -ne 1 ]; then
  set_field post_mutation_relaunch FAIL
  fail_boundary POST_MUTATION_RELAUNCH "Current mutation or historical sentinels did not survive candidate relaunch"
fi
set_field post_mutation_relaunch PASS
record_boundary POST_MUTATION_RELAUNCH

if [ "$COMPAT_TEST_STATUS" -ne 0 ]; then
  fail_boundary COMPATIBILITY_TEST_EXIT "Compatibility markers passed but XCTest returned nonzero"
fi

set_field phase1a_compatibility_gate SATISFIED
set_field failed_boundary NONE
record_boundary POST_MUTATION_RELAUNCH

echo "Phase 1A existing-store compatibility validation PASSED."
cat "$REPORT"
