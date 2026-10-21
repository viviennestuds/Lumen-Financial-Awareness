#!/usr/bin/env python3
"""Standalone Phase 1C A4 xattr-name attribution on ONE disposable Simulator.

READ-ONLY INSPECTION, except the explicit creation of one synthetic run layout
through the already reviewed artifact_capture.create_disposable_run helper.
Not a diagnostic controller, A4 acceptance test, or xattr policy override.

This utility has no functionality to launch a Simulator app, run diagnostic
scenarios, signal processes, access Lumen's production bundle, or read xattr values.
"""
from __future__ import annotations

import argparse
import ctypes
import errno
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from typing import Any

# Only available in the separate, exact-approved diagnostic checkout.
from artifact_capture import create_disposable_run, IntegrityBlocked

BUNDLE_ID = "org.lumenresearch.phase1c.stagea.probe"
APP_EXECUTABLE = "Phase1CStageAProbe"
APPROVED_SOURCE = "ab7de1532a9e75106a52c377da334dbe1843a381"
XATTR_SHOWCOMPRESSION = 0x0020
MAX_XATTR_BYTES = 65536
MAX_XATTR_ATTEMPTS = 3
MAX_OBJECTS = 4096
MAX_DEPTH = 32
MAX_SECONDS_PER_PHASE = 60.0
MAX_FAILURES = 256
MAX_REPORTED_CANDIDATES = 1024
O_DIR = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
O_FILE = os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC
EXPECTED_RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-18-5"


class RootUntrusted(RuntimeError):
    """Root identity or containment failed: never proceed to run-layout setup."""


class ObservationIssue(RuntimeError):
    def __init__(self, code: str, detail: str, err: int | None = None):
        super().__init__(detail)
        self.code = code
        self.err = err


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def invoke(*command: str) -> str:
    result = subprocess.run(command, text=True, capture_output=True, check=False, timeout=45)
    if result.returncode:
        raise RootUntrusted("Required Simulator/source verification command did not succeed")
    return result.stdout.strip()


def verify_source(source: Path) -> dict[str, Any]:
    if not source.is_absolute() or source.is_symlink() or not source.is_dir():
        raise RootUntrusted("Exact approved source checkout is not a verified directory")
    actual = invoke("git", "-C", str(source), "rev-parse", "HEAD")
    if actual != APPROVED_SOURCE:
        raise RootUntrusted("Diagnostic checkout does not match approved source SHA")
    dirty = invoke("git", "-C", str(source), "status", "--porcelain", "--untracked-files=all", "--", "diagnostics/phase1c-stagea")
    if dirty:
        raise RootUntrusted("Approved diagnostic source subtree is dirty")
    host = source / "diagnostics" / "phase1c-stagea" / "Host"
    expected = (host / "artifact_capture.py").resolve(strict=True)
    if Path(sys.modules["artifact_capture"].__file__).resolve(strict=True) != expected:
        raise RootUntrusted("Attribution helper imported a non-approved artifact-capture module")
    return {
        "commit": actual,
        "host_hashes": {n: sha256_file(host / n) for n in ("artifact_capture.py", "controller.py", "oracles.py")},
    }


def verify_app(app: Path) -> dict[str, str]:
    if not app.is_absolute() or app.is_symlink() or not app.is_dir():
        raise RootUntrusted("Built diagnostic app is not an independent absolute directory")
    info = app / "Info.plist"
    if info.is_symlink():
        raise RootUntrusted("Diagnostic Info.plist is symlinked")
    with info.open("rb") as fh:
        meta = plistlib.load(fh)
    if meta.get("CFBundleIdentifier") != BUNDLE_ID or meta.get("CFBundleExecutable") != APP_EXECUTABLE:
        raise RootUntrusted("Built app does not match exclusive diagnostic bundle and executable")
    binary = app / APP_EXECUTABLE
    if binary.is_symlink() or not binary.is_file():
        raise RootUntrusted("Diagnostic binary unavailable or symlinked")
    return {"bundle_identifier": BUNDLE_ID, "binary_sha256": sha256_file(binary)}


def verify_simulator(udid: str) -> dict[str, str]:
    try:
        if str(uuid.UUID(udid)).lower() != udid.lower():
            raise ValueError("noncanonical UDID")
    except ValueError as exc:
        raise RootUntrusted("Explicit Simulator UDID invalid") from exc
    data = json.loads(invoke("xcrun", "simctl", "list", "devices", "--json"))
    found = [
        (runtime, item) for runtime, devices in data.get("devices", {}).items()
        for item in devices if item.get("udid", "").lower() == udid.lower()
    ]
    if len(found) != 1 or found[0][0] != EXPECTED_RUNTIME or found[0][1].get("state") != "Booted":
        raise RootUntrusted("Simulator not uniquely verified as booted iOS 18.5 runtime")
    return {"udid": udid, "runtime": found[0][0], "device": found[0][1].get("name", "")}


def validate_absolute_chain(path: Path) -> None:
    """Reject aliases/symlinks for each directory leading to the container."""
    if not path.is_absolute() or str(path) != os.path.abspath(path):
        raise RootUntrusted("Noncanonical/relative container path")
    current = Path(path.anchor)
    for component in path.parts[1:]:
        current = current / component
        try:
            item = os.lstat(current)
        except OSError as exc:
            raise RootUntrusted("Container ancestor cannot be verified") from exc
        if not stat.S_ISDIR(item.st_mode) or stat.S_ISLNK(item.st_mode):
            raise RootUntrusted("Container ancestor is not a real directory")


def root_record(info: os.stat_result) -> dict[str, int]:
    return {
        "device": info.st_dev, "inode": info.st_ino,
        "mode": info.st_mode, "links": info.st_nlink,
        "size": info.st_size, "mtime_ns": info.st_mtime_ns,
        "ctime_ns": info.st_ctime_ns,
    }


def identity(info: os.stat_result) -> tuple[int, int, int]:
    return info.st_dev, info.st_ino, stat.S_IFMT(info.st_mode)


def verify_root(path: Path, fd: int, baseline: os.stat_result) -> os.stat_result:
    validate_absolute_chain(path)
    try:
        by_path = os.lstat(path)
        opened = os.fstat(fd)
    except OSError as exc:
        raise RootUntrusted("Container-root descriptor/path lost identity") from exc
    if not (stat.S_ISDIR(by_path.st_mode) and
            identity(by_path) == identity(opened) == identity(baseline)):
        raise RootUntrusted("Container-root descriptor/path identity or containment changed")
    return opened


def container_root(udid: str) -> Path:
    location = invoke("xcrun", "simctl", "get_app_container", udid, BUNDLE_ID, "data")
    if not location.startswith("/") or "\n" in location:
        raise RootUntrusted("Simulator returned unusable container path")
    data = Path(location)
    validate_absolute_chain(data)
    return data


class DarwinNames:
    """Name-only native descriptor API, never retrieves xattr values."""

    def __init__(self) -> None:
        if sys.platform != "darwin":
            raise RootUntrusted("Native attribution requires Darwin")
        try:
            libc = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
            function = libc.flistxattr
            function.argtypes = (ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int)
            function.restype = ctypes.c_ssize_t
        except (OSError, AttributeError, TypeError) as exc:
            raise RootUntrusted("Native Darwin flistxattr unavailable") from exc
        self.function = function

    def _call(self, fd: int, pointer: Any, length: int) -> int:
        ctypes.set_errno(0)
        try:
            result = self.function(fd, pointer, length, XATTR_SHOWCOMPRESSION)
        except (TypeError, ValueError, OSError, ctypes.ArgumentError) as exc:
            raise ObservationIssue("NATIVE_CALL_FAILED", type(exc).__name__) from exc
        if result == -1:
            code = ctypes.get_errno()
            raise ObservationIssue("NATIVE_ERRNO", "flistxattr failed", code)
        if result < -1:
            raise ObservationIssue("INVALID_NATIVE_RESULT", "Unexpected negative ssize_t result")
        return result

    def names(self, fd: int) -> tuple[list[str], int]:
        for attempt in range(1, MAX_XATTR_ATTEMPTS + 1):
            try:
                need = self._call(fd, None, 0)
            except ObservationIssue as exc:
                if exc.err == errno.ERANGE and attempt < MAX_XATTR_ATTEMPTS:
                    continue
                raise
            if need == 0:
                return [], attempt
            if need > MAX_XATTR_BYTES:
                raise ObservationIssue("NAME_BUFFER_LIMIT", "Native attribute list exceeds per-object cap")
            buf = ctypes.create_string_buffer(need)
            try:
                received = self._call(fd, ctypes.cast(buf, ctypes.c_void_p), need)
            except ObservationIssue as exc:
                if exc.err == errno.ERANGE and attempt < MAX_XATTR_ATTEMPTS:
                    continue
                raise
            if received > need:
                raise ObservationIssue("INVALID_NATIVE_LENGTH", "Native retrieval exceeds allocated capacity")
            if received == 0 or received < need:
                if attempt < MAX_XATTR_ATTEMPTS:
                    continue
                raise ObservationIssue("UNSTABLE_NATIVE_LENGTH", "Name-list size changed during enumeration")
            names = self._decode(buf.raw[:received])
            # A second query detects some (not all) concurrent changes.
            check = self._call(fd, None, 0)
            if check != received:
                raise ObservationIssue("UNSTABLE_NATIVE_LENGTH", "Post-read attribute list length differs")
            return names, attempt
        raise ObservationIssue("XATTR_RETRIES_EXHAUSTED", "Failed to establish stable native name enumeration")

    @staticmethod
    def _decode(raw: bytes) -> list[str]:
        if not raw or raw[-1:] != b"\x00":
            raise ObservationIssue("MALFORMED_NAMES", "Name buffer lacks final null terminator")
        chunks = raw[:-1].split(b"\x00")
        if not all(chunks):
            raise ObservationIssue("MALFORMED_NAMES", "Empty attribute name in buffer")
        try:
            names = [c.decode("utf-8", "strict") for c in chunks]
        except UnicodeDecodeError as exc:
            raise ObservationIssue("MALFORMED_NAMES", "Attribute name not valid UTF-8") from exc
        if len(set(names)) != len(names):
            raise ObservationIssue("MALFORMED_NAMES", "Duplicate attribute names")
        return sorted(names)


def role(relative: str, run_id: str) -> str:
    if relative == ".":
        return "container_root"
    prefix = "Library/Application Support/Phase1CStageA"
    run = f"{prefix}/{run_id}"
    if relative in ("Library", "Library/Application Support", prefix):
        return "shared_ancestor"
    if relative == run:
        return "run_root"
    if relative == run + "/events" or relative.startswith(run + "/events/"):
        return "events"
    if relative == run + "/source-store" or relative.startswith(run + "/source-store/"):
        return "source_store_artifact"
    if relative == run + "/inspection-copy" or relative.startswith(run + "/inspection-copy/"):
        return "inspection_copy_artifact"
    return "ambient_container_state"


def safe_names(fd: int) -> list[str]:
    try:
        names = os.listdir(fd)
    except OSError as exc:
        raise ObservationIssue("DIRECTORY_LIST_FAILED", "Cannot enumerate directory", exc.errno) from exc
    if len(names) > MAX_OBJECTS:
        raise ObservationIssue("DIRECTORY_MEMBER_LIMIT", "Directory entry count exceeds bound")
    return sorted(names)


def safe_entry_name(name: str) -> bool:
    if not isinstance(name, str) or name in ("", ".", "..") or "/" in name or "\x00" in name:
        return False
    try:
        name.encode("utf-8", "strict")
    except UnicodeEncodeError:
        return False
    return True


class Phase:
    def __init__(self, label: str, data: Path, root_fd: int,
                 root_info: os.stat_result, run_id: str, native: DarwinNames) -> None:
        self.label, self.data, self.fd, self.root_info = label, data, root_fd, root_info
        self.run_id, self.native = run_id, native
        self.deadline = time.monotonic() + MAX_SECONDS_PER_PHASE
        self.count = 0
        self.entries_encountered = 0
        self.nodes: list[dict[str, Any]] = []
        self.candidates: list[dict[str, Any]] = []
        self.issues: list[dict[str, Any]] = []
        self.unstable = False
        self.incomplete = False
        self.root_blocked = False
        self.limit_exhausted = False

    def failure(self, code: str, path: str, *, error: int | None = None,
                unstable: bool = False) -> None:
        self.incomplete = True
        if unstable:
            self.unstable = True
        if len(self.issues) < MAX_FAILURES:
            self.issues.append({"type": code, "relative_path": path, "errno": error})
        else:
            self.limit_exhausted = True

    def bounds(self, depth: int) -> bool:
        if self.count >= MAX_OBJECTS or depth > MAX_DEPTH or time.monotonic() > self.deadline:
            self.failure("TRAVERSAL_LIMIT", ".")
            self.limit_exhausted = True
            return False
        return True

    def inspect(self) -> dict[str, Any]:
        try:
            verify_root(self.data, self.fd, self.root_info)
            self.walk(self.fd, ".", self.root_info, depth=0)
            verify_root(self.data, self.fd, self.root_info)
        except RootUntrusted as exc:
            self.failure("ROOT_IDENTITY_UNTRUSTWORTHY", ".")
            self.root_blocked = True
        coverage = (
            "ROOT_BLOCKED" if self.root_blocked else
            "UNSTABLE" if self.unstable else
            "INCOMPLETE" if self.incomplete else "COMPLETE"
        )
        return {
            "phase": self.label, "coverage": coverage,
            "root_trusted": not self.root_blocked,
            "examined_objects": self.count,
            "directory_entries_encountered": self.entries_encountered,
            "xattr_bearing_objects": self.candidates,
            "xattr_bearing_count": len(self.candidates),
            "issues": self.issues,
            "issue_count_at_least": len(self.issues),
            "limits_reached": self.limit_exhausted,
            "nodes": self.nodes,
            "xattr_enumeration_options": "XATTR_SHOWCOMPRESSION (0x0020)",
            "visibility_limit": "Accessible attributes reported for this descriptor/process/options only",
        }

    def walk(self, fd: int, relative: str, first: os.stat_result, depth: int) -> None:
        if not self.bounds(depth) or self.root_blocked:
            return
        verify_root(self.data, self.fd, self.root_info)
        self.count += 1
        before = os.fstat(fd)
        if identity(before) != identity(first):
            self.failure("IDENTITY_CHANGED", relative, unstable=True)
            return
        if not (stat.S_ISDIR(before.st_mode) or stat.S_ISREG(before.st_mode)):
            self.failure("UNSUPPORTED_OBJECT", relative)
            return
        node: dict[str, Any] = {
            "relative_path": relative,
            "role": role(relative, self.run_id),
            "type": "directory" if stat.S_ISDIR(before.st_mode) else "regular_file",
            "stat_before": root_record(before),
        }
        self.nodes.append(node)
        try:
            names, attempts = self.native.names(fd)
            node["accessible_xattr_names"] = names
            node["native_attempts"] = attempts
            if names:
                candidate = {"relative_path": relative, "role": node["role"],
                             "type": node["type"], "stat": node["stat_before"],
                             "accessible_xattr_names": names}
                if len(self.candidates) < MAX_REPORTED_CANDIDATES:
                    self.candidates.append(candidate)
                else:
                    self.failure("CANDIDATE_REPORT_LIMIT", relative)
        except ObservationIssue as exc:
            node["xattr_status"] = exc.code
            self.failure(exc.code, relative, error=exc.err,
                         unstable=exc.code.startswith("UNSTABLE"))
        try:
            if stat.S_ISDIR(before.st_mode) and not self.limit_exhausted:
                self.children(fd, relative, depth)
        finally:
            try:
                after = os.fstat(fd)
                node["stat_after"] = root_record(after)
                if root_record(before) != root_record(after):
                    self.failure("OBJECT_METADATA_CHANGED", relative, unstable=True)
            except OSError as exc:
                self.failure("POST_STAT_FAILED", relative, error=exc.errno, unstable=True)

    def children(self, fd: int, relative: str, depth: int) -> None:
        try:
            initial = safe_names(fd)
        except ObservationIssue as exc:
            self.failure(exc.code, relative, error=exc.err)
            if exc.code == "DIRECTORY_MEMBER_LIMIT":
                self.limit_exhausted = True
            return
        for name in initial:
            if self.limit_exhausted or self.root_blocked:
                break
            child = name if relative == "." else relative + "/" + name
            self.entries_encountered += 1
            if (self.entries_encountered > MAX_OBJECTS or
                    time.monotonic() > self.deadline):
                self.failure("TRAVERSAL_LIMIT", child)
                self.limit_exhausted = True
                break
            verify_root(self.data, self.fd, self.root_info)
            if not safe_entry_name(name):
                self.failure("INVALID_DIRECTORY_ENTRY", relative)
                continue
            try:
                observed = os.stat(name, dir_fd=fd, follow_symlinks=False)
                if stat.S_ISLNK(observed.st_mode):
                    self.failure("SYMLINK_NOT_FOLLOWED", child)
                    continue
                if observed.st_dev != self.root_info.st_dev:
                    self.failure("CROSS_DEVICE_NODE", child)
                    continue
                if stat.S_ISREG(observed.st_mode):
                    if observed.st_nlink != 1:
                        self.failure("SUSPICIOUS_HARDLINK", child)
                        continue
                    flags = O_FILE
                elif stat.S_ISDIR(observed.st_mode):
                    flags = O_DIR
                else:
                    self.failure("UNSUPPORTED_OBJECT", child)
                    continue
                childfd = os.open(name, flags, dir_fd=fd)
            except OSError as exc:
                self.failure("CHILD_STAT_OR_OPEN_FAILED", child, error=exc.errno)
                continue
            try:
                checked = os.fstat(childfd)
                if identity(observed) != identity(checked):
                    self.failure("CHILD_REPLACED_BEFORE_INSPECTION", child, unstable=True)
                    continue
                self.walk(childfd, child, checked, depth+1)
            except OSError as exc:
                self.failure("CHILD_INSPECTION_FAILED", child, error=exc.errno)
            finally:
                os.close(childfd)
        try:
            latest = safe_names(fd)
            if latest != initial:
                self.failure("DIRECTORY_MEMBERSHIP_CHANGED", relative, unstable=True)
                if len(self.issues) < MAX_FAILURES:
                    self.issues.append({"type": "MEMBERSHIP_DELTA", "relative_path": relative,
                                        "added": sorted(set(latest)-set(initial)),
                                        "removed": sorted(set(initial)-set(latest))})
        except ObservationIssue as exc:
            self.failure("DIRECTORY_RELIST_FAILED", relative, error=exc.err, unstable=True)


def presence(data: Path, root_fd: int, root_info: os.stat_result, run_id: str,
             phase: str) -> dict[str, dict[str, Any]]:
    """Verify absence only by an explicit ENOENT under a checked directory."""
    base = "Library/Application Support/Phase1CStageA/" + run_id
    expected = {
        "run_root": base, "events": base + "/events",
        "source_store": base + "/source-store",
        "inspection_copy": base + "/inspection-copy",
    }
    expected_present = {"run_root", "events"} if phase == "post_run_layout" else set()
    report: dict[str, dict[str, Any]] = {}
    for title, rel in expected.items():
        verify_root(data, root_fd, root_info)
        parts = rel.split("/")
        fd = os.dup(root_fd)
        status, basis = "UNRESOLVED", "unverified"
        try:
            for i, name in enumerate(parts):
                try:
                    meta = os.stat(name, dir_fd=fd, follow_symlinks=False)
                except FileNotFoundError:
                    status, basis = "EXPECTED_ABSENT", "ENOENT from verified parent: " + "/".join(parts[:i])
                    break
                except OSError as exc:
                    status, basis = "UNREADABLE", "stat error errno=" + str(exc.errno)
                    break
                if not stat.S_ISDIR(meta.st_mode) or meta.st_dev != root_info.st_dev:
                    status, basis = "UNRESOLVED", "non-directory or device transition ancestor"
                    break
                try:
                    nextfd = os.open(name, O_DIR, dir_fd=fd)
                except FileNotFoundError:
                    status, basis = "UNSTABLE", "positive stat followed by missing open target"
                    break
                except OSError as exc:
                    status, basis = "UNREADABLE", "open error errno=" + str(exc.errno)
                    break
                opened = os.fstat(nextfd)
                if identity(meta) != identity(opened):
                    os.close(nextfd)
                    status, basis = "UNSTABLE", "directory identity changed"
                    break
                os.close(fd)
                fd = nextfd
            else:
                status, basis = "PRESENT_OBSERVED", "verified descriptor traversal"
        finally:
            os.close(fd)
        if title in expected_present and status == "EXPECTED_ABSENT":
            status = "UNRESOLVED"
            basis = "required object missing: " + basis
        if title not in expected_present and status == "PRESENT_OBSERVED":
            status = "UNEXPECTED_PRESENT"
        report[title] = {"status": status, "basis": basis, "relative_path": rel}
    return report


def write_json(output: Path, payload: dict[str, Any]) -> None:
    if not output.is_absolute() or output.suffix != ".json":
        raise ValueError("Result location must be absolute JSON path")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, sort_keys=True, ensure_ascii=True)
        fh.write("\n")


def run() -> int:
    p = argparse.ArgumentParser(description="Read-only A4 xattr names in one disposable diagnostic container")
    p.add_argument("--simulator-udid", required=True)
    p.add_argument("--source-root", required=True, type=Path)
    p.add_argument("--app", required=True, type=Path)
    p.add_argument("--attribution-sha", required=True)
    p.add_argument("--workflow-sha", required=True)
    p.add_argument("--output", required=True, type=Path)
    args = p.parse_args()
    run_id = str(uuid.uuid4())
    evidence: dict[str, Any] = {
        "version": "phase1c-a4-xattr-attribution-v1",
        "run_uuid": run_id,
        "started_utc": utc_now(),
        "status": "NOT_REACHED",
        "historical_a4_run": "39535161853",
        "historical_a4_disposition": "BLOCKED / OBSERVATION INTEGRITY UNPROVEN",
        "excluded_claims": [
            "same object caused historical A4 failure", "origin or harmlessness of xattrs",
            "universal xattr visibility", "complete SwiftData artifacts", "SwiftData behavior",
            "A4 success", "A1 success", "pre-open database consistency", "production authority",
        ],
        "setup_policy": "Fresh diagnostic Simulator install plus one explicit disposable run-root creation",
        "inspection_policy": "Two read-only descriptor-based container attribution phases; names only",
    }
    result = 2
    rootfd: int | None = None
    try:
        if not re.fullmatch("[0-9a-f]{40}", args.workflow_sha) or not re.fullmatch("[0-9a-f]{64}", args.attribution_sha):
            raise RootUntrusted("Exact workflow commit and utility SHA-256 required")
        if sha256_file(Path(__file__).resolve()) != args.attribution_sha:
            raise RootUntrusted("Attribution helper content differs from its recorded SHA-256")
        evidence["workflow_sha"] = args.workflow_sha
        evidence["attribution_sha256"] = args.attribution_sha
        evidence["diagnostic_source"] = verify_source(args.source_root)
        evidence["app"] = verify_app(args.app)
        evidence["simulator"] = verify_simulator(args.simulator_udid)
        data = container_root(args.simulator_udid)
        rootfd = os.open(data, O_DIR)
        baseline = os.fstat(rootfd)
        verify_root(data, rootfd, baseline)
        evidence["container_root_identity"] = root_record(baseline)
        native = DarwinNames()

        first = Phase("pre_run_layout", data, rootfd, baseline, run_id, native).inspect()
        evidence["pre_run_layout"] = first
        if first["coverage"] == "ROOT_BLOCKED":
            raise RootUntrusted("Phase A lost trusted root; no setup permitted")
        evidence["pre_run_expected_paths"] = presence(data, rootfd, baseline, run_id, "pre_run_layout")
        if any(x["status"] != "EXPECTED_ABSENT" for x in evidence["pre_run_expected_paths"].values()):
            raise RootUntrusted("Run-layout expected absence was not demonstrable before setup")
        # A root identity or containment loss MUST prevent this mutation.
        verify_root(data, rootfd, baseline)
        created = create_disposable_run(data, run_id)
        wanted = data / "Library" / "Application Support" / "Phase1CStageA" / run_id
        if str(created) != str(wanted):
            raise RootUntrusted("Run-layout helper returned unexpected location")
        evidence["post_run_expected_paths"] = presence(data, rootfd, baseline, run_id, "post_run_layout")
        expected = {"run_root": "PRESENT_OBSERVED", "events": "PRESENT_OBSERVED",
                    "source_store": "EXPECTED_ABSENT", "inspection_copy": "EXPECTED_ABSENT"}
        if any(evidence["post_run_expected_paths"][k]["status"] != v for k,v in expected.items()):
            raise RootUntrusted("Post-setup expected presence/absence state not established")
        verify_root(data, rootfd, baseline)
        second = Phase("post_run_layout", data, rootfd, baseline, run_id, native).inspect()
        evidence["post_run_layout"] = second
        if second["coverage"] == "ROOT_BLOCKED":
            raise RootUntrusted("Phase B lost trusted root; attribution terminated")
        earlier = {item["relative_path"]: item for item in first["nodes"]}
        later = {item["relative_path"]: item for item in second["nodes"]}
        changes = []
        for rel in sorted(set(earlier) | set(later)):
            if rel not in earlier:
                changes.append({"relative_path": rel, "type": "POST_ONLY_REPORTED"})
            elif rel not in later:
                changes.append({"relative_path": rel, "type": "PRE_ONLY_REPORTED"})
            elif earlier[rel].get("accessible_xattr_names") != later[rel].get("accessible_xattr_names"):
                changes.append({"relative_path": rel, "type": "REPORTED_XATTR_NAMES_CHANGED_OR_UNAVAILABLE"})
            elif earlier[rel].get("stat_after") != later[rel].get("stat_after"):
                changes.append({"relative_path": rel, "type": "RECORDED_METADATA_CHANGED"})
        evidence["cross_phase_comparison"] = {
            "reported_changes": changes,
            "meaning": "Time-separated reported objects only; no causal-origin inference",
        }
        evidence["cross_phase_candidates"] = {
            "pre": [x["relative_path"] for x in first["xattr_bearing_objects"]],
            "post": [x["relative_path"] for x in second["xattr_bearing_objects"]],
            "meaning": "Time-separated reported locations only; no causal-origin inference",
        }
        evidence["status"] = "ATTRIBUTION_OBSERVED_SCOPED" if (
            first["coverage"] == "COMPLETE" and second["coverage"] == "COMPLETE"
        ) else "PARTIAL_INCOMPLETE_OR_UNSTABLE"
        result = 0 if evidence["status"] == "ATTRIBUTION_OBSERVED_SCOPED" else 3
    except (RootUntrusted, IntegrityBlocked, ObservationIssue, OSError, ValueError) as exc:
        evidence["status"] = "ROOT_BLOCKED_OR_EXECUTION_INCOMPLETE"
        evidence["failure_type"] = type(exc).__name__
        # Errors are generic; neither absolute host paths nor xattr values are emitted.
        evidence["failure_summary"] = "Required source/root/containment/platform operation failed"
        if isinstance(exc, ObservationIssue):
            evidence["failure_code"] = exc.code
            evidence["failure_errno"] = exc.err
    finally:
        if rootfd is not None:
            os.close(rootfd)
        evidence["finished_utc"] = utc_now()
        write_json(args.output, evidence)
        print("ATTRIBUTION_RESULT=" + json.dumps({
            "status": evidence["status"], "run_uuid": run_id,
            "phase_a": evidence.get("pre_run_layout", {}).get("coverage", "NOT_REACHED"),
            "phase_b": evidence.get("post_run_layout", {}).get("coverage", "NOT_REACHED"),
            "candidate_count_a": len(evidence.get("pre_run_layout", {}).get("xattr_bearing_objects", [])),
            "candidate_count_b": len(evidence.get("post_run_layout", {}).get("xattr_bearing_objects", [])),
        }, sort_keys=True))
    return result


if __name__ == "__main__":
    sys.exit(run())
