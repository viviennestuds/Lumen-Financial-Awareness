#!/usr/bin/env python3
"""Mac-host controller for *disposable* A0/A1/A4 Simulator diagnostics.

IMPLEMENTATION REVIEW ONLY. Do not run without the separate owner execution gate.
No bare PID-based os.kill is permitted: macOS host PID verification followed by
os.kill leaves an unclosed PID-reuse/TOCTOU window. The A0 SIGKILL scenario is
fail-closed until a process-bound backend is independently reviewed and admitted.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import stat
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from artifact_capture import (
    IntegrityBlocked, assert_run_layout, create_disposable_run, inventory,
    preserve, source_unchanged,
)
from oracles import (
    BLOCKED_INTEGRITY, BLOCKED_TERMINATION, INCONCLUSIVE, NOT_REACHED,
    Verdict, a0_external_kill, a0_negative, a1_store,
    a4_known, a4_missing, finalize,
)

BUNDLE_ID = "org.lumenresearch.phase1c.stagea.probe"
RUNS_DIR = Path(__file__).resolve().parents[1] / ".runs"
SCENARIOS = (
    "a0-injected-error", "a0-ordinary-exit", "a0-external-sigkill",
    "a1-store", "a4-known-store", "a4-missing-store",
)
MARKER_RE = re.compile(r"^[a-z0-9_-]+$")
PID_RE = re.compile(r"(?m)^\s*" + re.escape(BUNDLE_ID) + r":\s*(\d+)\s*$")


class DiagnosticBlocked(RuntimeError):
    def __init__(self, category: str, reason: str):
        super().__init__(reason)
        self.category = category


def checked(cmd: list[str], *, timeout: int = 60) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, check=False)
    if result.returncode:
        raise DiagnosticBlocked(INCONCLUSIVE, "Host command failed; platform capability not proven")
    return result.stdout.strip()


def sha256_file(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Expected independent regular file")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def verify_app(app: Path) -> dict[str, str]:
    if not app.is_absolute() or app.is_symlink() or not app.is_dir():
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Diagnostic app path not a real absolute directory")
    info_path = app / "Info.plist"
    if info_path.is_symlink():
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Diagnostic bundle information is symlinked")
    with info_path.open("rb") as handle:
        info = plistlib.load(handle)
    if info.get("CFBundleIdentifier") != BUNDLE_ID:
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Bundle identifier does not match exclusive diagnostic ID")
    executable = info.get("CFBundleExecutable")
    if not isinstance(executable, str) or "/" in executable:
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Unexpected executable name")
    binary = app / executable
    return {"bundle_id": BUNDLE_ID, "binary_sha256": sha256_file(binary)}


def verify_simulator(udid: str) -> None:
    if not re.fullmatch(r"[0-9A-Fa-f-]{36}", udid):
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Simulator UDID must be explicit")
    data = json.loads(checked(["xcrun", "simctl", "list", "devices", "--json"]))
    devices = [d for array in data.get("devices", {}).values() for d in array]
    matches = [d for d in devices if d.get("udid") == udid and d.get("state") == "Booted"]
    if len(matches) != 1:
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Explicit simulator not uniquely identified as booted")


def process_snapshot(pid: int) -> str | None:
    # Used ONLY for exit observation. It is NOT a process-bound kill primitive.
    output = subprocess.run(
        ["ps", "-p", str(pid), "-o", "pid=,lstart=,command="],
        capture_output=True, text=True, timeout=5, check=False,
    )
    return output.stdout.strip() if output.returncode == 0 else None


def run_marker(run_root: Path, name: str) -> str | None:
    if not MARKER_RE.fullmatch(name):
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Invalid marker name")
    file = run_root / "events" / (name + ".txt")
    try:
        fd = os.open(file, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    except FileNotFoundError:
        return None
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_size > 4096:
            raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Unsafe marker object")
        return os.read(fd, 4097).decode("utf-8", errors="strict")
    finally:
        os.close(fd)


def wait_marker(root: Path, name: str, seconds: float = 35) -> bool:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if run_marker(root, name) is not None:
            return True
        time.sleep(0.2)
    return False


def wait_process_exit(pid: int, first: str | None, *, seconds: float = 35) -> bool:
    if first is None:
        return False  # No initial identity; cannot prove this worker was tracked.
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        current = process_snapshot(pid)
        if current is None:
            return True
        if current != first:
            # Reuse/identity change is not proof of the original exit mechanism.
            return False
        time.sleep(0.25)
    return False


def acknowledge_identity(root: Path) -> None:
    """Release the worker only after the controller has observed a matching process."""
    location = root / "events" / "host_ack.txt"
    fd = os.open(location, os.O_WRONLY | os.O_CREAT | os.O_EXCL |
                 os.O_NOFOLLOW | os.O_CLOEXEC, 0o600)
    try:
        os.write(fd, b"host observed worker identity before exit\n")
        os.fsync(fd)
    finally:
        os.close(fd)


def launch(simulator: str, role: str, run_id: str, root: Path) -> tuple[int, str | None, str]:
    raw = checked([
        "xcrun", "simctl", "launch", simulator, BUNDLE_ID,
        "--role", role, "--run-id", run_id, "--root", str(root),
    ])
    match = PID_RE.search(raw)
    if match is None:
        raise DiagnosticBlocked(INCONCLUSIVE, "Simulator launch did not return a parsable worker PID")
    pid = int(match.group(1))
    if pid < 2:
        raise DiagnosticBlocked(INCONCLUSIVE, "Unsafe process identifier")
    initial = process_snapshot(pid)
    if initial is None or "Phase1CStageAProbe" not in initial:
        raise DiagnosticBlocked(INCONCLUSIVE, "App PID cannot be independently associated with the diagnostic executable")
    acknowledge_identity(root)
    return pid, initial, raw


def exit_quiescent(root: Path, pid: int, start: str | None, marker: str) -> bool:
    # The marker alone is not enough; require an independently recorded exit.
    return wait_marker(root, marker) and wait_process_exit(pid, start)


def install(simulator: str, app: Path) -> None:
    # Called only by an explicitly executed controller, after bundle identity preflight.
    checked(["xcrun", "simctl", "install", simulator, str(app)], timeout=120)


def container_root(simulator: str) -> Path:
    result = checked(["xcrun", "simctl", "get_app_container", simulator, BUNDLE_ID, "data"])
    if not result.startswith("/"):
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Simulator returned a nonabsolute app data root")
    return Path(result)


def inspect_one(
    simulator: str, root: Path, run_id: str,
    *, missing: bool, evidence: dict[str, Any],
) -> None:
    source = root / "source-store"
    copied = root / "inspection-copy"
    # Quiescence was already proven from the worker exit or the source is empty.
    assert_run_layout(root)
    snapshot = preserve(source, copied, missing_source_control=missing)
    evidence["preservation"] = snapshot
    evidence["source_copy_bytes_verified"] = True
    pid, snap, raw = launch(
        simulator, "a4-missing-observer" if missing else "a1-observer", run_id, root
    )
    evidence["observer_launch"] = {"pid": pid, "reported": raw, "identity": snap}
    evidence["fresh_observer_identity"] = bool(snap) and pid != evidence.get("worker_pid")
    ended = exit_quiescent(root, pid, snap, "observer_fetch")
    evidence["observer_exited"] = ended
    before = snapshot["source_preopen"]
    assert_run_layout(root)
    evidence["source_postopen"] = inventory(source)
    evidence["copy_postopen"] = inventory(copied)
    source_unchanged(before, evidence["source_postopen"])
    evidence["original_unchanged"] = True
    evidence["inspection_delta_recorded"] = True
    fetched = run_marker(root, "observer_fetch")
    match = re.search(r"synthetic record count=(\d+)", fetched or "")
    evidence["observer_records"] = int(match.group(1)) if match else None
    evidence["sentinel_matched"] = not missing and evidence["observer_records"] == 1
    evidence["a4_integrity_verified"] = bool(
        ended and evidence["fresh_observer_identity"] and
        evidence["source_copy_bytes_verified"] and evidence["original_unchanged"] and
        evidence["inspection_delta_recorded"]
    )
    if not evidence["a4_integrity_verified"]:
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "A4 fresh inspection/original isolation unproven")


def perform(
    simulator: str, app: Path, scenario: str, run_id: str,
    evidence: dict[str, Any],
) -> tuple[Verdict, dict[str, Any]]:
    evidence.update({
        "scenario": scenario, "run_id": run_id,
        "UTC_started": datetime.now(timezone.utc).isoformat(),
        "external_signal": None,
        "process_bound_signal_backend_verified": False,
        "markers": [],
        "excluded": ["A2", "A3", "Stage B", "production authority"],
    })

    # Deliberately no os.kill(pid, SIGKILL): a process snapshot and a PID cannot
    # bind a signal to the original Simulator process through a PID-reuse race.
    # No process is launched before this BLOCKED disposition.
    if scenario == "a0-external-sigkill":
        return a0_external_kill(evidence), evidence

    verify_simulator(simulator)
    evidence["app"] = verify_app(app)
    install(simulator, app)
    data = container_root(simulator)
    root = create_disposable_run(data, run_id)
    assert_run_layout(root)
    evidence["simulator"] = simulator

    if scenario == "a4-missing-store":
        evidence["source_initially_absent"] = not (root / "source-store").exists()
        inspect_one(simulator, root, run_id, missing=True, evidence=evidence)
        evidence["source_still_absent"] = not (root / "source-store").exists()
        return a4_missing(evidence), evidence

    # Exactly one disposable worker, with no production bundle or schema imports.
    if scenario in ("a0-injected-error", "a0-ordinary-exit"):
        role = scenario
    else:
        role = "a1-create"
    evidence["source_initially_absent"] = not (root / "source-store").exists()
    pid, snap, raw = launch(simulator, role, run_id, root)
    evidence["worker_pid"] = pid
    evidence["worker_launch"] = {"pid": pid, "reported": raw, "identity": snap}

    if scenario in ("a0-injected-error", "a0-ordinary-exit"):
        marker = "negative_injected" if scenario == "a0-injected-error" else "negative_ordinary"
        evidence["worker_exited"] = exit_quiescent(root, pid, snap, marker)
        if run_marker(root, marker) is not None:
            evidence["markers"].append(marker)
        return a0_negative(scenario, evidence), evidence

    evidence["worker_exited"] = exit_quiescent(root, pid, snap, "store_save_returned")
    if run_marker(root, "store_save_returned") is not None:
        evidence["markers"].append("store_save_returned")
    if not evidence["worker_exited"]:
        raise DiagnosticBlocked(BLOCKED_INTEGRITY, "Worker not demonstrably quiescent")
    inspect_one(simulator, root, run_id, missing=False, evidence=evidence)
    a4_result = a4_known(evidence)
    if a4_result.category != "OBSERVED (NARROW PLATFORM RESULT)":
        return a4_result, evidence
    if scenario == "a1-store":
        return a1_store(evidence), evidence
    return a4_result, evidence


def record_manifest(run_id: str, payload: dict[str, Any]) -> Path:
    RUNS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    target = RUNS_DIR / (run_id + ".json")
    with target.open("x", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description="Synthetic, isolated Stage A evidence controller")
    parser.add_argument("--simulator-udid", required=True)
    parser.add_argument("--app", required=True, type=Path, help="Existing built diagnostic .app")
    parser.add_argument("--scenario", required=True, choices=SCENARIOS)
    args = parser.parse_args()
    run_id = str(uuid.uuid4())
    evidence: dict[str, Any] = {"scenario": args.scenario, "run_id": run_id}
    try:
        verdict, evidence = perform(args.simulator_udid, args.app, args.scenario, run_id, evidence)
    except DiagnosticBlocked as exc:
        verdict = Verdict(exc.category, str(exc))
    except IntegrityBlocked as exc:
        verdict = Verdict(BLOCKED_INTEGRITY, str(exc))
    except Exception:
        # Avoid embedding private paths/host details in a shareable manifest.
        verdict = Verdict(INCONCLUSIVE, "Unhandled diagnostic-controller condition; source needs review")
    payload = finalize(verdict, evidence)
    payload["timestamp_utc"] = datetime.now(timezone.utc).isoformat()
    payload["controller_source_revision"] = "IMPLEMENTATION-ONLY / UNBUILT / UNEXECUTED"
    record_manifest(run_id, payload)
    print(f"{run_id}: {verdict.category} — {verdict.reason}")
    return 0 if verdict.category == "OBSERVED (NARROW PLATFORM RESULT)" else 2


if __name__ == "__main__":
    sys.exit(main())
