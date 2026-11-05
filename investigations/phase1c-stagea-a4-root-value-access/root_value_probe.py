"""Isolated Lumen Stage A container-root value-access capability characterization.

Only the verified disposable diagnostic data-container root is inspected. Values
remain in short-lived native buffers; reports contain no values or fingerprints.
This is not an A4 scenario runner and never relaxes the approved copier.
"""
from __future__ import annotations

import argparse
import ctypes
import errno
import hmac
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import time
import uuid
from datetime import datetime, timezone
from typing import Any

import attribute_names as prior
from artifact_capture import IntegrityBlocked, create_disposable_run

APPROVED_SOURCE = "ab7de1532a9e75106a52c377da334dbe1843a381"
ATTRIBUTION_BASE = "5143cc37d109853254ce689fdd6a9ba0508cc6d6"
MAX_NAME_BYTES = 65536
MAX_VALUE_BYTES = 65536
MAX_NAMES = 32
MAX_ATTEMPTS = 3
MAX_PHASE_SECONDS = 60.0
XATTR_SHOWCOMPRESSION = 0x0020
O_ROOT = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
HISTORICAL = "BLOCKED / OBSERVATION INTEGRITY UNPROVEN"


class CapabilityIssue(RuntimeError):
    def __init__(self, code: str, err: int | None = None, *, unstable: bool = False):
        super().__init__(code)
        self.code = code
        self.err = err
        self.unstable = unstable


class Secret:
    def __init__(self, length: int):
        self.length = length
        self.storage = ctypes.create_string_buffer(max(length, 1))

    def equals(self, other: "Secret") -> bool:
        return (self.length == other.length and
                hmac.compare_digest(memoryview(self.storage).cast("B")[:self.length],
                                    memoryview(other.storage).cast("B")[:other.length]))

    def erase(self) -> None:
        ctypes.memset(ctypes.addressof(self.storage), 0, ctypes.sizeof(self.storage))


class NativeValues:
    """Six-argument Darwin descriptor access; the native buffer never becomes JSON."""

    def __init__(self) -> None:
        if sys.platform != "darwin":
            raise CapabilityIssue("DARWIN_API_UNAVAILABLE")
        try:
            lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
            native = lib.fgetxattr
            native.argtypes = (ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p,
                               ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int)
            native.restype = ctypes.c_ssize_t
        except (OSError, TypeError, AttributeError) as exc:
            raise CapabilityIssue("FGETXATTR_INTERFACE_UNAVAILABLE") from exc
        self.native = native

    def call(self, fd: int, name: bytes, target: Secret | None,
             length: int) -> int:
        address = None if target is None else ctypes.cast(target.storage, ctypes.c_void_p)
        ctypes.set_errno(0)
        try:
            n = self.native(fd, name, address, length, 0, 0)
        except (OSError, TypeError, ValueError, ctypes.ArgumentError) as exc:
            raise CapabilityIssue("FGETXATTR_INVOCATION_FAILED") from exc
        if n == -1:
            e = ctypes.get_errno()
            if e in (getattr(errno, "ENOATTR", -1000), getattr(errno, "ENODATA", -1000)):
                raise CapabilityIssue("ATTRIBUTE_MISSING", e, unstable=True)
            if e == errno.ERANGE:
                raise CapabilityIssue("BUFFER_RACE", e, unstable=True)
            if e in (errno.EACCES, errno.EPERM):
                raise CapabilityIssue("ATTRIBUTE_UNREADABLE", e)
            if e in (getattr(errno, "ENOTSUP", -1001), errno.EINVAL,
                     getattr(errno, "EOPNOTSUPP", -1002)):
                raise CapabilityIssue("ATTRIBUTE_UNSUPPORTED", e)
            raise CapabilityIssue("NATIVE_VALUE_ERROR", e)
        if n < -1 or n > length and target is not None:
            raise CapabilityIssue("INVALID_NATIVE_LENGTH", unstable=True)
        return n

    def complete(self, fd: int, name: str, deadline: float) -> Secret:
        raw = name.encode("utf-8")
        for attempt in range(MAX_ATTEMPTS):
            if time.monotonic() > deadline:
                raise CapabilityIssue("PHASE_TIME_LIMIT")
            try:
                need = self.call(fd, raw, None, 0)
            except CapabilityIssue as exc:
                if exc.code == "BUFFER_RACE" and attempt + 1 < MAX_ATTEMPTS:
                    continue
                raise
            if need > MAX_VALUE_BYTES:
                raise CapabilityIssue("VALUE_SIZE_LIMIT")
            value = Secret(need)
            established = False
            try:
                if need > 0:
                    obtained = self.call(fd, raw, value, need)
                    if obtained != need:
                        raise CapabilityIssue("VALUE_LENGTH_CHANGED", unstable=True)
                after = self.call(fd, raw, None, 0)
                if after != need:
                    raise CapabilityIssue("VALUE_LENGTH_CHANGED", unstable=True)
                established = True
                return value
            except CapabilityIssue:
                raise
            finally:
                if not established:
                    value.erase()
        raise CapabilityIssue("VALUE_RETRY_EXHAUSTED", unstable=True)


def metadata_tuple(info: os.stat_result) -> tuple[int, int, int, int, int, int]:
    return (info.st_dev, info.st_ino, stat.S_IFMT(info.st_mode), info.st_mode,
            info.st_mtime_ns, info.st_ctime_ns)


def name_list(names: prior.DarwinNames, fd: int) -> list[str]:
    value, _attempts = names.names(fd)
    if len(value) > MAX_NAMES:
        raise CapabilityIssue("NAME_COUNT_LIMIT")
    if sum(len(x.encode("utf-8")) + 1 for x in value) > MAX_NAME_BYTES:
        raise CapabilityIssue("NAME_BYTES_LIMIT")
    return sorted(value)


class Observation:
    def __init__(self, phase: str):
        self.phase = phase
        self.secrets: dict[str, Secret] = {}
        self.record: dict[str, Any] = {"phase": phase, "acquisition": "NOT_REACHED",
                                      "root_identity": "NOT_REACHED", "names": [],
                                      "attributes": [], "failure": None}

    def clear(self) -> None:
        for secret in self.secrets.values():
            secret.erase()
        self.secrets.clear()


def observe_root(phase: str, data: Path, fd: int, baseline: os.stat_result,
                 names: prior.DarwinNames, values: NativeValues) -> Observation:
    observed = Observation(phase)
    report = observed.record
    deadline = time.monotonic() + MAX_PHASE_SECONDS
    try:
        before = prior.verify_root(data, fd, baseline)
        report["root_identity"] = "TRUSTED"
        first = name_list(names, fd)
        report["names"] = first
        for name in first:
            if time.monotonic() > deadline:
                raise CapabilityIssue("PHASE_TIME_LIMIT")
            prior.verify_root(data, fd, baseline)
            first_value = values.complete(fd, name, deadline)
            try:
                second_value = values.complete(fd, name, deadline)
                try:
                    if not first_value.equals(second_value):
                        raise CapabilityIssue("WITHIN_PHASE_BYTES_CHANGED", unstable=True)
                finally:
                    second_value.erase()
                observed.secrets[name] = first_value
                report["attributes"].append({"name": name, "value_state": "OBSERVED",
                                             "zero_length": first_value.length == 0,
                                             "repeat_equal": True})
            except BaseException:
                if name not in observed.secrets:
                    first_value.erase()
                raise
        last = name_list(names, fd)
        if first != last:
            raise CapabilityIssue("WITHIN_PHASE_NAMES_CHANGED", unstable=True)
        after = prior.verify_root(data, fd, baseline)
        if metadata_tuple(before) != metadata_tuple(after):
            raise CapabilityIssue("WITHIN_PHASE_ROOT_METADATA_CHANGED", unstable=True)
        report["acquisition"] = "COMPLETE"
    except prior.RootUntrusted:
        report["root_identity"] = "ROOT_BLOCKED"
        report["acquisition"] = "INCOMPLETE"
        report["failure"] = {"code": "ROOT_IDENTITY_UNTRUSTWORTHY"}
        observed.clear()
    except (CapabilityIssue, prior.ObservationIssue, OSError) as exc:
        code = exc.code if hasattr(exc, "code") else type(exc).__name__
        native_errno = exc.err if hasattr(exc, "err") else getattr(exc, "errno", None)
        report["acquisition"] = "UNSTABLE" if getattr(exc, "unstable", False) else "INCOMPLETE"
        report["failure"] = {"code": code, "errno": native_errno}
        observed.clear()
        try:
            prior.verify_root(data, fd, baseline)
        except (prior.RootUntrusted, OSError):
            report["root_identity"] = "ROOT_BLOCKED"
    return observed


def compare(a: Observation, b: Observation) -> str:
    if a.record["acquisition"] != "COMPLETE" or b.record["acquisition"] != "COMPLETE":
        return "NOT_ESTABLISHED"
    if set(a.secrets) != set(b.secrets):
        return "NAMES_CHANGED"
    if any(not a.secrets[name].equals(b.secrets[name]) for name in a.secrets):
        return "VALUES_CHANGED"
    return "EQUAL"


def sanitized_presence(data: Path, fd: int, baseline: os.stat_result,
                       run_id: str, label: str) -> dict[str, str]:
    records = prior.presence(data, fd, baseline, run_id, label)
    return {key: item["status"] for key, item in records.items()}


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def emit_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        raise CapabilityIssue("OUTPUT_PATH_SYMLINK")
    with path.open("x", encoding="utf-8") as out:
        json.dump(doc, out, sort_keys=True, indent=2, ensure_ascii=True)
        out.write("\n")


def real_fixture() -> None:
    """Characterize actual Darwin descriptor operations on a disposable host file."""
    lib = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
    put = lib.fsetxattr
    put.argtypes = (ctypes.c_int, ctypes.c_char_p, ctypes.c_void_p,
                    ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int)
    put.restype = ctypes.c_int
    remove = lib.fremovexattr
    remove.argtypes = (ctypes.c_int, ctypes.c_char_p, ctypes.c_int)
    remove.restype = ctypes.c_int
    getter = NativeValues()
    names = prior.DarwinNames()
    key = b"org.lumenresearch.stagea.fixture"
    with tempfile.TemporaryDirectory(prefix="lumen-root-value-fixture-") as directory:
        target = Path(directory) / "host-only-file"
        fd = os.open(target, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600)
        try:
            try:
                getter.complete(fd, key.decode(), time.monotonic() + 10)
            except CapabilityIssue as exc:
                assert exc.code == "ATTRIBUTE_MISSING"
            else:
                raise AssertionError("Missing attribute misclassified")

            def put_value(payload: bytes) -> None:
                buffer = ctypes.create_string_buffer(payload, max(1, len(payload)))
                try:
                    ctypes.set_errno(0)
                    assert put(fd, key, ctypes.cast(buffer, ctypes.c_void_p), len(payload), 0, 0) == 0, "Disposable host attribute write unavailable"
                finally:
                    ctypes.memset(ctypes.addressof(buffer), 0, ctypes.sizeof(buffer))

            put_value(b"")
            zero = getter.complete(fd, key.decode(), time.monotonic() + 10)
            try:
                assert zero.length == 0
            finally:
                zero.erase()
            put_value(b"fixture-sample-one")
            v1 = getter.complete(fd, key.decode(), time.monotonic() + 10)
            v1_again = getter.complete(fd, key.decode(), time.monotonic() + 10)
            try:
                assert v1.equals(v1_again)
                assert key.decode() in name_list(names, fd)
                put_value(b"fixture-sample-two")
                v2 = getter.complete(fd, key.decode(), time.monotonic() + 10)
                try:
                    assert v2.length == v1.length and not v1.equals(v2)
                finally:
                    v2.erase()
                tiny = Secret(1)
                try:
                    try:
                        getter.call(fd, key, tiny, 1)
                    except CapabilityIssue as exc:
                        assert exc.code == "BUFFER_RACE"
                    else:
                        raise AssertionError("ERANGE fixture did not fail")
                finally:
                    tiny.erase()
                ctypes.set_errno(0)
                assert remove(fd, key, 0) == 0
                assert key.decode() not in name_list(names, fd)
            finally:
                v1.erase()
                v1_again.erase()
        finally:
            os.close(fd)


class FakeValues:
    def __init__(self, series: list[bytes]):
        self.series = series
        self.index = 0

    def complete(self, fd: int, name: str, deadline: float) -> Secret:
        value = self.series[min(self.index, len(self.series) - 1)]
        self.index += 1
        result = Secret(len(value))
        if value:
            ctypes.memmove(result.storage, value, len(value))
        return result


class FakeNames:
    def __init__(self, series: list[list[str]]):
        self.series = series
        self.index = 0

    def names(self, fd: int) -> tuple[list[str], int]:
        value = self.series[min(self.index, len(self.series)-1)]
        self.index += 1
        return value, 1


def simulated_checks() -> int:
    with tempfile.TemporaryDirectory(prefix="lumen-root-value-test-") as directory:
        path = Path(directory)
        fd = os.open(path, O_ROOT)
        try:
            baseline = os.fstat(fd)
            same = observe_root("fixture", path, fd, baseline, FakeNames([["fixture"], ["fixture"]]), FakeValues([b"abc", b"abc"]))
            assert same.record["acquisition"] == "COMPLETE"
            same.clear()
            changed = observe_root("fixture", path, fd, baseline, FakeNames([["fixture"], ["fixture"]]), FakeValues([b"abc", b"xyz"]))
            assert changed.record["acquisition"] == "UNSTABLE" and changed.record["failure"]["code"] == "WITHIN_PHASE_BYTES_CHANGED"
            changed.clear()
            names_changed = observe_root("fixture", path, fd, baseline, FakeNames([["fixture"], ["added"]]), FakeValues([b"abc", b"abc"]))
            assert names_changed.record["acquisition"] == "UNSTABLE"
            names_changed.clear()
            a = Observation("a")
            b = Observation("b")
            a.record["acquisition"] = b.record["acquisition"] = "COMPLETE"
            a.secrets["sample"] = Secret(3)
            b.secrets["sample"] = Secret(3)
            ctypes.memmove(a.secrets["sample"].storage, b"abc", 3)
            ctypes.memmove(b.secrets["sample"].storage, b"xyz", 3)
            assert compare(a,b) == "VALUES_CHANGED"
            ctypes.memmove(b.secrets["sample"].storage, b"abc", 3)
            assert compare(a,b) == "EQUAL"
            b.secrets["new"] = Secret(0)
            assert compare(a,b) == "NAMES_CHANGED"
            a.clear()
            b.clear()
        finally:
            os.close(fd)
    return 6


def self_test() -> int:
    count = simulated_checks()
    if sys.platform == "darwin":
        real_fixture()
        print("HOST_VALUE_FIXTURES=PASS; REAL_DARWIN=PASS; SIMULATED_CASES=" + str(count))
    else:
        print("HOST_VALUE_FIXTURES=PASS; REAL_DARWIN=NOT_AVAILABLE; SIMULATED_CASES=" + str(count))
    return 0


def run(args: argparse.Namespace) -> int:
    run_id = str(uuid.uuid4())
    doc: dict[str, Any] = {
        "version": "phase1c-a4-root-value-capability-v1",
        "status": "NOT_REACHED", "run_uuid": run_id, "started_utc": utc(),
        "historical_a4_disposition": HISTORICAL,
        "source_attribution_checkpoint": ATTRIBUTION_BASE,
        "scope": "verified disposable diagnostic data-container root only",
        "access": "names and private in-process values; no value serialization",
        "limitations": ["two phases are not atomic snapshots", "native accessible metadata only",
                        "no store created", "A4 integrity not established", "value semantics unknown"],
        "pre_run_layout": {"acquisition": "NOT_REACHED"},
        "post_run_layout": {"acquisition": "NOT_REACHED"},
        "comparison": "NOT_ESTABLISHED",
        "a4_root_unchanged": "NOT_ESTABLISHED",
    }
    first: Observation | None = None
    second: Observation | None = None
    rootfd: int | None = None
    exit_code = 2
    try:
        if not re.fullmatch(r"[a-f0-9]{40}", args.workflow_sha):
            raise prior.RootUntrusted("Required exact triggering workflow SHA invalid")
        if not re.fullmatch(r"[a-f0-9]{64}", args.helper_sha):
            raise prior.RootUntrusted("Required helper SHA-256 invalid")
        if prior.sha256_file(Path(__file__).resolve()) != args.helper_sha:
            raise prior.RootUntrusted("Running helper does not match recorded SHA-256")
        doc["workflow_sha"] = args.workflow_sha
        doc["helper_sha256"] = args.helper_sha
        doc["source"] = prior.verify_source(args.source_root)
        doc["diagnostic_app"] = prior.verify_app(args.app)
        doc["simulator"] = prior.verify_simulator(args.simulator_udid)
        data = prior.container_root(args.simulator_udid)
        rootfd = os.open(data, O_ROOT)
        baseline = os.fstat(rootfd)
        prior.verify_root(data, rootfd, baseline)
        doc["root_identity"] = prior.root_record(baseline)
        names, values = prior.DarwinNames(), NativeValues()
        first = observe_root("pre_run_layout", data, rootfd, baseline, names, values)
        doc["pre_run_layout"] = first.record
        if first.record["acquisition"] != "COMPLETE" or first.record["root_identity"] != "TRUSTED":
            raise CapabilityIssue("PHASE_A_NOT_COMPLETE")
        if not first.record["names"]:
            raise CapabilityIssue("NO_ROOT_ATTRIBUTES_TO_CHARACTERIZE")
        doc["pre_run_expected_paths"] = sanitized_presence(data, rootfd, baseline, run_id, "pre_run_layout")
        if any(x != "EXPECTED_ABSENT" for x in doc["pre_run_expected_paths"].values()):
            raise prior.RootUntrusted("Required before-setup absence not verified")
        prior.verify_root(data, rootfd, baseline)
        created = create_disposable_run(data, run_id)
        expected = data / "Library" / "Application Support" / "Phase1CStageA" / run_id
        if str(created) != str(expected):
            raise prior.RootUntrusted("Run layout created at unexpected path")
        doc["post_run_expected_paths"] = sanitized_presence(data, rootfd, baseline, run_id, "post_run_layout")
        expected_status = {"run_root": "PRESENT_OBSERVED", "events": "PRESENT_OBSERVED",
                           "source_store": "EXPECTED_ABSENT", "inspection_copy": "EXPECTED_ABSENT"}
        if doc["post_run_expected_paths"] != expected_status:
            raise prior.RootUntrusted("Required after-setup disposition failed")
        prior.verify_root(data, rootfd, baseline)
        second = observe_root("post_run_layout", data, rootfd, baseline, names, values)
        doc["post_run_layout"] = second.record
        if second.record["acquisition"] != "COMPLETE" or second.record["root_identity"] != "TRUSTED":
            raise CapabilityIssue("PHASE_B_NOT_COMPLETE")
        doc["comparison"] = compare(first, second)
        doc["status"] = "SCOPED_COMPARISON_OBSERVED"
        doc["a4_root_unchanged"] = "NOT_ESTABLISHED"
        exit_code = 0
    except (prior.RootUntrusted, IntegrityBlocked, CapabilityIssue, prior.ObservationIssue,
            OSError, ValueError, AssertionError) as exc:
        doc["status"] = "BLOCKED_OR_UNESTABLISHED"
        doc["failure"] = {"type": type(exc).__name__,
                          "code": exc.code if isinstance(exc, CapabilityIssue) else "REQUIRED_OPERATION_FAILED"}
    finally:
        if first is not None:
            first.clear()
        if second is not None:
            second.clear()
        if rootfd is not None:
            os.close(rootfd)
        doc["finished_utc"] = utc()
        emit_json(args.output, doc)
        print("ROOT_VALUE_RESULT=" + json.dumps({"status": doc["status"],
            "phase_a": doc["pre_run_layout"].get("acquisition", "NOT_REACHED"),
            "phase_b": doc["post_run_layout"].get("acquisition", "NOT_REACHED"),
            "comparison": doc["comparison"], "run_uuid": run_id}, sort_keys=True))
    return exit_code


def main() -> int:
    parser = argparse.ArgumentParser(description="Isolated Stage A container-root native value capability")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--simulator-udid")
    parser.add_argument("--source-root", type=Path)
    parser.add_argument("--app", type=Path)
    parser.add_argument("--workflow-sha")
    parser.add_argument("--helper-sha")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    required = (args.simulator_udid, args.source_root, args.app,
                args.workflow_sha, args.helper_sha, args.output)
    if any(x is None for x in required):
        parser.error("All explicit diagnostic execution arguments required")
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
