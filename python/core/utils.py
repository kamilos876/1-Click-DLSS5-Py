"""Filesystem, PE and hardware helpers shared by the whole application."""
from __future__ import annotations

import hashlib
import os
import re
import struct
import subprocess
import sys
from pathlib import Path
from typing import Iterator

IMAGE_FILE_MACHINE_AMD64 = 0x8664


def sha256_of(path: str | Path) -> str:
    """Uppercase hex SHA256, streamed so large payloads stay off the heap."""
    hasher = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest().upper()


def is_x64_pe(path: str | Path) -> bool:
    """True when the file is a PE image whose machine type is x86-64."""
    try:
        with open(path, "rb") as handle:
            header = handle.read(4096)
    except OSError:
        return False

    if len(header) < 64 or header[:2] != b"MZ":
        return False

    e_lfanew = struct.unpack_from("<i", header, 60)[0]
    if e_lfanew < 0 or e_lfanew + 24 > len(header):
        return False
    if header[e_lfanew:e_lfanew + 4] != b"PE\0\0":
        return False

    machine = struct.unpack_from("<H", header, e_lfanew + 4)[0]
    return machine == IMAGE_FILE_MACHINE_AMD64


_TRAILING_PATH_IN_PARENS = re.compile(r"-\s*\(([A-Za-z]:\\[^()]+)\)\s*$")
_EMBEDDED_WINDOWS_PATH = re.compile(r'([A-Za-z]:\\[^:*?"<>|\r\n]+)')


def sanitize_path(raw: str) -> str:
    """Pull a usable Windows path out of decorated text pasted by the user.

    Handles quoting and the "Name - (C:\Path)" shape produced by some launchers.
    """
    if not raw or not raw.strip():
        return ""

    text = raw.strip().strip('"').strip("'")

    # A path that already exists is taken as-is: folder names legitimately
    # contain brackets ("Painkiller RTX [GOG]"), which the cleanup below strips.
    if os.path.exists(text):
        return text

    match = _TRAILING_PATH_IN_PARENS.search(text)
    if match:
        return match.group(1).strip()

    match = _EMBEDDED_WINDOWS_PATH.search(text)
    if match:
        return re.sub(r"[)\]]+$", "", match.group(1).strip()).strip()

    return text


def iter_files(root: str | Path, pattern: str = "*", max_depth: int = 12) -> Iterator[Path]:
    """Depth-limited recursive walk that survives permission errors.

    os.scandir is used directly because pathlib.rglob offers no depth cap and
    aborts the whole walk on the first unreadable directory.
    """
    root = Path(root)
    if not root.is_dir():
        return

    stack: list[tuple[Path, int]] = [(root, 0)]
    matcher = re.compile(_glob_to_regex(pattern), re.IGNORECASE)

    while stack:
        current, depth = stack.pop()
        try:
            entries = list(os.scandir(current))
        except (OSError, PermissionError):
            continue

        for entry in entries:
            try:
                if entry.is_dir(follow_symlinks=False):
                    if depth < max_depth:
                        stack.append((Path(entry.path), depth + 1))
                elif entry.is_file(follow_symlinks=False) and matcher.fullmatch(entry.name):
                    yield Path(entry.path)
            except OSError:
                continue


def _glob_to_regex(pattern: str) -> str:
    """Translate a simple *?-style glob into a regex source string."""
    out = []
    for char in pattern:
        if char == "*":
            out.append(".*")
        elif char == "?":
            out.append(".")
        else:
            out.append(re.escape(char))
    return "".join(out)


def fixed_drives() -> list[str]:
    """Root paths of ready, fixed local drives (e.g. ``C:\``)."""
    if sys.platform != "win32":
        return ["/"]

    import ctypes

    drives: list[str] = []
    bitmask = ctypes.windll.kernel32.GetLogicalDrives()
    for index in range(26):
        if not bitmask & (1 << index):
            continue
        root = f"{chr(ord('A') + index)}:\\"
        # DRIVE_FIXED == 3
        if ctypes.windll.kernel32.GetDriveTypeW(ctypes.c_wchar_p(root)) == 3:
            drives.append(root)
    return drives


def _query_video_controllers(field: str) -> list[str]:
    """Read one Win32_VideoController column via PowerShell CIM."""
    if sys.platform != "win32":
        return []

    script = (
        "Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue"
        f" | ForEach-Object {{ $_.{field} }}"
    )
    try:
        completed = subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script],
            capture_output=True,
            text=True,
            timeout=20,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
    except (OSError, subprocess.SubprocessError):
        return []

    return [line.strip() for line in completed.stdout.splitlines() if line.strip()]


def gpu_names() -> list[str]:
    """Display names of installed video controllers."""
    return _query_video_controllers("Name")


def driver_versions() -> list[str]:
    """Driver versions of installed video controllers."""
    return _query_video_controllers("DriverVersion")


def open_in_explorer(path: str | Path) -> None:
    """Reveal a folder in Windows Explorer."""
    if sys.platform == "win32":
        subprocess.Popen(["explorer.exe", str(path)])
    else:
        subprocess.Popen(["xdg-open", str(path)])
