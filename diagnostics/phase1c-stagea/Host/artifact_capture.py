"""Fail-closed, host-side artifact capture for synthetic Phase 1C Stage A stores.

No SwiftData/SQLite opens; no access to production or historical stores.
These byte-level inventories do NOT prove logical database consistency or authority.
"""
from __future__ import annotations

import ctypes
import hashlib
import os
import stat
import sys
from pathlib import Path
from typing import Any

O_DIR = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
O_FILE = os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC
O_NEW = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC
STORE_DIR = "source-store"
COPY_DIR = "inspection-copy"


class IntegrityBlocked(RuntimeError):
    """Observation integrity could not be warranted; never report a PASS."""


def _lstat_chain(path: Path) -> None:
    if not path.is_absolute():
        raise IntegrityBlocked("A diagnostic path must be absolute")
    cur = Path(path.anchor)
    for component in path.parts[1:]:
        cur /= component
        try:
            info = os.lstat(cur)
        except FileNotFoundError:
            raise IntegrityBlocked("Expected controlled path does not exist") from None
        if not stat.S_ISDIR(info.st_mode) or stat.S_ISLNK(info.st_mode):
            raise IntegrityBlocked("A path component is not a real directory")


def validate_run_root(data_container: Path, run_root: Path, run_id: str) -> None:
    """Exact app-container/run-dir match, not a prefix or substring check."""
    expected = data_container / "Library" / "Application Support" / "Phase1CStageA" / run_id
    if os.path.abspath(run_root) != os.path.abspath(expected):
        raise IntegrityBlocked("Run root does not match the diagnostic app's data container")
    for path in (data_container, run_root):
        _lstat_chain(path)
    if os.path.realpath(expected) != str(expected):
        raise IntegrityBlocked("Run-root path contains a symlink or unexpected alias")
    if not run_id or "/" in run_id or run_id in (".", ".."):
        raise IntegrityBlocked("Malformed run identity")


def create_disposable_run(data_container: Path, run_id: str) -> Path:
    """Create ONLY a UUID child of the verified diagnostic data container.

    Each directory is opened via a no-follow directory descriptor; no untrusted
    pathname traversal or symlink substitution can redirect the mkdir operations.
    """
    if not re_full_uuid(run_id):
        raise IntegrityBlocked("Unrecognized disposable run UUID")
    _lstat_chain(data_container)
    data_fd, device = _open_dir(data_container)
    opened = [data_fd]
    try:
        library = os.open("Library", O_DIR, dir_fd=data_fd)
        opened.append(library)
        _check_node(os.fstat(library), device, file=False)
        try:
            os.mkdir("Application Support", 0o700, dir_fd=library)
        except FileExistsError:
            pass
        support = os.open("Application Support", O_DIR, dir_fd=library)
        opened.append(support)
        _check_node(os.fstat(support), device, file=False)
        try:
            os.mkdir("Phase1CStageA", 0o700, dir_fd=support)
        except FileExistsError:
            pass
        phase = os.open("Phase1CStageA", O_DIR, dir_fd=support)
        opened.append(phase)
        _check_node(os.fstat(phase), device, file=False)
        os.mkdir(run_id, 0o700, dir_fd=phase)
        run = os.open(run_id, O_DIR, dir_fd=phase)
        opened.append(run)
        os.mkdir("events", 0o700, dir_fd=run)
    finally:
        for fd in reversed(opened):
            os.close(fd)
    root = data_container / "Library" / "Application Support" / "Phase1CStageA" / run_id
    validate_run_root(data_container, root, run_id)
    return root


def re_full_uuid(value: str) -> bool:
    import uuid
    try:
        parsed = uuid.UUID(value)
        return str(parsed) == value
    except (ValueError, AttributeError):
        return False


def assert_run_layout(root: Path) -> None:
    """An unexpected store-associated sibling cannot be silently ignored."""
    _lstat_chain(root)
    names = set(os.listdir(root))
    if not names.issubset({"source-store", "inspection-copy", "events"}):
        raise IntegrityBlocked("Uncaptured artifacts escaped the expected store subtree")
    for name in names:
        _lstat_chain(root / name)


def _check_node(info: os.stat_result, device: int, file: bool) -> None:
    if info.st_dev != device:
        raise IntegrityBlocked("File crosses to a different mounted device")
    if file:
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
            raise IntegrityBlocked("Not an independent regular file")
    elif not stat.S_ISDIR(info.st_mode):
        raise IntegrityBlocked("Not a directory")


def _open_dir(path: Path, device: int | None = None) -> tuple[int, int]:
    fd = os.open(path, O_DIR)
    info = os.fstat(fd)
    _check_node(info, info.st_dev if device is None else device, file=False)
    return fd, info.st_dev


def _file_hash(fd: int, before: os.stat_result) -> str:
    digest = hashlib.sha256()
    os.lseek(fd, 0, os.SEEK_SET)
    while data := os.read(fd, 1 << 20):
        digest.update(data)
    after = os.fstat(fd)
    if (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns) != (
        before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns
    ):
        raise IntegrityBlocked("Source artifact changed while reading")
    return digest.hexdigest()


def _extended_attributes(fd: int) -> None:
    """Fail closed unless Darwin reports zero accessible extended attributes.

    flistxattr(fd, NULL, 0, XATTR_SHOWCOMPRESSION) queries the *size* of
    accessible attribute names, not their contents. A zero result means none
    were reported under these options and the caller's filesystem visibility;
    it is NOT proof that no extended attributes exist anywhere.

    The descriptor is opened and checked by the existing no-follow traversal.
    XATTR_NOFOLLOW is pathname-only and must NOT be passed to flistxattr.
    """
    if sys.platform != "darwin":
        raise IntegrityBlocked("Darwin descriptor-based xattr observation unavailable")
    if isinstance(fd, bool) or not isinstance(fd, int) or not (0 <= fd <= 0x7FFFFFFF):
        raise IntegrityBlocked("Invalid extended-attribute observation descriptor")

    try:
        libc = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
        native = libc.flistxattr
        native.argtypes = (ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int)
        native.restype = ctypes.c_ssize_t
    except (OSError, AttributeError, TypeError) as exc:
        raise IntegrityBlocked("Darwin flistxattr interface could not be resolved") from exc

    # 0x0020 is XATTR_SHOWCOMPRESSION from Apple's <sys/xattr.h>.
    # Do not pass XATTR_NOFOLLOW, XATTR_NOSECURITY, or XATTR_NODEFAULT.
    ctypes.set_errno(0)
    try:
        size = native(fd, None, 0, 0x0020)
    except (OSError, TypeError, ValueError, ctypes.ArgumentError) as exc:
        raise IntegrityBlocked("Darwin flistxattr invocation failed") from exc
    if size == 0:
        return
    if size > 0:
        raise IntegrityBlocked(
            "Uncharacterized accessible extended attributes reported by Darwin flistxattr"
        )
    if size == -1:
        error = ctypes.get_errno()
        description = os.strerror(error) if error else "errno not set"
        raise IntegrityBlocked(
            f"Darwin flistxattr enumeration failed (errno={error}: {description})"
        )
    raise IntegrityBlocked("Darwin flistxattr returned an unexpected negative result")


def _walk(fd: int, prefix: str, device: int, result: dict[str, Any]) -> None:
    for name in sorted(os.listdir(fd)):
        if name in (".", "..") or "/" in name or "\x00" in name:
            raise IntegrityBlocked("Unsafe directory entry")
        entry = f"{prefix}/{name}" if prefix else name
        info = os.stat(name, dir_fd=fd, follow_symlinks=False)
        if stat.S_ISDIR(info.st_mode):
            _check_node(info, device, file=False)
            child = os.open(name, O_DIR, dir_fd=fd)
            try:
                observed = os.fstat(child)
                if (info.st_dev, info.st_ino) != (observed.st_dev, observed.st_ino):
                    raise IntegrityBlocked("Directory replaced during inventory")
                _extended_attributes(child)
                result[entry] = {
                    "kind": "dir", "mode": stat.S_IMODE(info.st_mode),
                    "mtime_ns": observed.st_mtime_ns,
                }
                _walk(child, entry, device, result)
            finally:
                os.close(child)
        elif stat.S_ISREG(info.st_mode):
            _check_node(info, device, file=True)
            child = os.open(name, O_FILE, dir_fd=fd)
            try:
                before = os.fstat(child)
                if (info.st_dev, info.st_ino) != (before.st_dev, before.st_ino):
                    raise IntegrityBlocked("File replaced during inventory")
                _extended_attributes(child)
                result[entry] = {
                    "kind": "file", "mode": stat.S_IMODE(before.st_mode),
                    "size": before.st_size, "sha256": _file_hash(child, before),
                    "mtime_ns": before.st_mtime_ns,
                }
            finally:
                os.close(child)
        else:
            raise IntegrityBlocked("Unexpected symlink/special store-associated artifact")


def inventory(directory: Path) -> dict[str, Any]:
    if not directory.exists() and not directory.is_symlink():
        return {"exists": False, "entries": {}}
    _lstat_chain(directory)
    fd, device = _open_dir(directory)
    try:
        info = os.fstat(fd)
        _extended_attributes(fd)  # directories can carry protection-relevant metadata
        result: dict[str, Any] = {}
        _walk(fd, "", device, result)
        return {
            "exists": True,
            "root": {
                "mode": stat.S_IMODE(info.st_mode),
                "mtime_ns": info.st_mtime_ns,
            },
            "entries": result,
        }
    finally:
        os.close(fd)


def comparable_entries(manifest: dict[str, Any]) -> dict[str, tuple[Any, ...]]:
    """Ignore inode and legitimate copy metadata; compare bytes + tree structure."""
    return {
        name: (record["kind"], record.get("mode"), record.get("size"), record.get("sha256"))
        for name, record in manifest["entries"].items()
    }


def assert_matching_bytes(source: dict[str, Any], copy: dict[str, Any]) -> None:
    if source["exists"] is not True or copy["exists"] is not True:
        raise IntegrityBlocked("Cannot match a missing artifact tree")
    if source["root"]["mode"] != copy["root"]["mode"]:
        raise IntegrityBlocked("Source and copy root permission modes differ")
    if comparable_entries(source) != comparable_entries(copy):
        raise IntegrityBlocked("Source/copy artifact modes, bytes or tree differ")


def _copy_tree(source_fd: int, copy_fd: int, device: int) -> None:
    for name in sorted(os.listdir(source_fd)):
        info = os.stat(name, dir_fd=source_fd, follow_symlinks=False)
        if stat.S_ISDIR(info.st_mode):
            _check_node(info, device, file=False)
            source_child = os.open(name, O_DIR, dir_fd=source_fd)
            try:
                check = os.fstat(source_child)
                if (check.st_dev, check.st_ino) != (info.st_dev, info.st_ino):
                    raise IntegrityBlocked("Source directory identity changed during copying")
                _extended_attributes(source_child)
                os.mkdir(name, mode=0o700, dir_fd=copy_fd)
                dest_child = os.open(name, O_DIR, dir_fd=copy_fd)
                try:
                    _copy_tree(source_child, dest_child, device)
                    os.fchmod(dest_child, stat.S_IMODE(check.st_mode))
                    os.fsync(dest_child)
                finally:
                    os.close(dest_child)
            finally:
                os.close(source_child)
        elif stat.S_ISREG(info.st_mode):
            _check_node(info, device, file=True)
            source_file = os.open(name, O_FILE, dir_fd=source_fd)
            try:
                before = os.fstat(source_file)
                if (before.st_dev, before.st_ino) != (info.st_dev, info.st_ino):
                    raise IntegrityBlocked("Source identity changed during copying")
                _extended_attributes(source_file)
                dest_file = os.open(name, O_NEW, 0o600, dir_fd=copy_fd)
                try:
                    while chunk := os.read(source_file, 1 << 20):
                        view = memoryview(chunk)
                        while view:
                            count = os.write(dest_file, view)
                            if count <= 0:
                                raise IntegrityBlocked("Incomplete copied bytes")
                            view = view[count:]
                    os.fchmod(dest_file, stat.S_IMODE(before.st_mode))
                    os.fsync(dest_file)
                    _file_hash(source_file, before)  # detects changes while copying
                finally:
                    os.close(dest_file)
            finally:
                os.close(source_file)
        else:
            raise IntegrityBlocked("Unexpected store-associated node during copying")


def preserve(source: Path, copy: Path, *, missing_source_control: bool = False) -> dict[str, Any]:
    if source.name != STORE_DIR or copy.name != COPY_DIR or source.parent != copy.parent:
        raise IntegrityBlocked("Source and copy must be prescribed sibling subtrees")
    _lstat_chain(source.parent)
    if copy.exists() or copy.is_symlink():
        raise IntegrityBlocked("Inspection destination is not fresh")
    before = inventory(source)
    if not before["exists"] and not missing_source_control:
        raise IntegrityBlocked("Source store artifact subtree is missing")
    os.mkdir(copy, 0o700)
    if before["exists"]:
        src_fd, device = _open_dir(source)
        dest_fd, _ = _open_dir(copy)
        try:
            source_root_info = os.fstat(src_fd)
            _extended_attributes(src_fd)
            _copy_tree(src_fd, dest_fd, device)
            os.fchmod(dest_fd, stat.S_IMODE(source_root_info.st_mode))
            os.fsync(dest_fd)
        finally:
            os.close(dest_fd)
            os.close(src_fd)
    after_copy = inventory(copy)
    source_after_preservation = inventory(source)
    if source_after_preservation != before:
        raise IntegrityBlocked("Source changed during preservation")
    if before["exists"]:
        assert_matching_bytes(before, after_copy)
    elif after_copy["entries"]:
        raise IntegrityBlocked("Missing-store negative control copy is not empty")
    return {
        "source_preopen": before,
        "source_after_preservation": source_after_preservation,
        "copy_preopen": after_copy,
        "byte_and_mode_copy_verified": True,
        # An independent scenario-local consistency admission is still required.
        "snapshot_consistency_admitted": False,
        "snapshot_consistency_basis": "UNPROVEN",
    }


def require_changes_within(
    before: dict[str, Any], after: dict[str, Any], allowed_rel_subtrees: tuple[str, ...],
) -> list[str]:
    """Fail closed on unexpected app-container artifacts outside recorded subtrees.

    The inventory comparison gives *scenario-local evidence* about configured
    store artifact scope, not a promise about all possible SwiftData versions.
    """
    if before.get("exists") is not True or after.get("exists") is not True:
        raise IntegrityBlocked("Cannot establish full app-container artifact changes")
    start, end = before["entries"], after["entries"]
    changed: list[str] = []
    for path in sorted(set(start) | set(end)):
        if start.get(path) == end.get(path):
            continue
        inside = any(path == a or path.startswith(a + "/") for a in allowed_rel_subtrees)
        ancestor = any(a.startswith(path + "/") for a in allowed_rel_subtrees)
        if not inside and not ancestor:
            raise IntegrityBlocked("Uncharacterized app-container change outside disposable root")
        if ancestor and not inside:
            first, second = start.get(path), end.get(path)
            if (first and first.get("kind") != "dir") or (
                second and second.get("kind") != "dir"
            ):
                raise IntegrityBlocked("Non-directory ancestor changed during scoped capture")
            if first and second and first.get("mode") != second.get("mode"):
                raise IntegrityBlocked("Unexpected ancestor directory permission change")
        changed.append(path)
    return changed


def source_unchanged(baseline: dict[str, Any], final: dict[str, Any]) -> None:
    """Compare all *recorded* source attributes, including root metadata.

    Equality is a bounded physical observation, not a proof that no unrecorded
    filesystem change occurred or that an inspected database was logically valid.
    """
    if baseline != final:
        raise IntegrityBlocked(
            "Original source's recorded root metadata, entries or existence changed"
        )
