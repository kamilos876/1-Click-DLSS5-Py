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
IMAGE_FILE_MACHINE_I386 = 0x014C
IMAGE_FILE_MACHINE_ARM64 = 0xAA64

# Architectures pe_architecture() can report.
ARCH_X64 = "X64"
ARCH_X86 = "X86"
ARCH_ARM64 = "ARM64"
ARCH_PE = "VALID_PE"     # a real PE image of some other machine type
ARCH_UNKNOWN = "UNKNOWN"  # unreadable, or not a PE image at all


def sha256_of(path: str | Path) -> str:
    """Uppercase hex SHA256, streamed so large payloads stay off the heap."""
    hasher = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest().upper()


def pe_architecture(path: str | Path) -> str:
    """Report a PE image's machine type, or UNKNOWN when it is not one.

    A game that ships a 32-bit binary is still injectable -- the Feeder has an
    addon32 and an out-of-process host for exactly that -- so callers that only
    need "is this a real executable" should use is_valid_pe rather than
    demanding x86-64.
    """
    try:
        with open(path, "rb") as handle:
            header = handle.read(4096)
    except OSError:
        return ARCH_UNKNOWN

    if len(header) < 64 or header[:2] != b"MZ":
        return ARCH_UNKNOWN

    e_lfanew = struct.unpack_from("<i", header, 60)[0]
    if e_lfanew < 0 or e_lfanew + 24 > len(header):
        return ARCH_UNKNOWN
    if header[e_lfanew:e_lfanew + 4] != b"PE\0\0":
        return ARCH_UNKNOWN

    machine = struct.unpack_from("<H", header, e_lfanew + 4)[0]
    if machine == IMAGE_FILE_MACHINE_AMD64:
        return ARCH_X64
    if machine == IMAGE_FILE_MACHINE_I386:
        return ARCH_X86
    if machine == IMAGE_FILE_MACHINE_ARM64:
        return ARCH_ARM64
    return ARCH_PE


def pe_imported_dlls(path: str | Path) -> set[str]:
    """Names of the DLLs an executable imports, lowercased.

    Read from the PE import directory rather than by scanning the file for
    strings: a game that merely mentions "libxess.dll" in a log format or a
    config parser does not depend on it, and treating that as a dependency
    would restore files a game never wanted.

    Returns an empty set for anything that is not a readable PE image.
    """
    try:
        with open(path, "rb") as handle:
            data = handle.read()
    except OSError:
        return set()

    try:
        return _parse_imports(data)
    except (struct.error, IndexError, ValueError):
        # A malformed or packed header is not worth a traceback; it just means
        # we cannot tell what the file needs.
        return set()


def _parse_imports(data: bytes) -> set[str]:
    """Walk a PE image's import directory. Raises on a malformed header."""
    if len(data) < 64 or data[:2] != b"MZ":
        return set()

    pe_offset = struct.unpack_from("<i", data, 60)[0]
    if pe_offset < 0 or pe_offset + 24 > len(data):
        return set()
    if data[pe_offset:pe_offset + 4] != b"PE\0\0":
        return set()

    number_of_sections = struct.unpack_from("<H", data, pe_offset + 6)[0]
    optional_size = struct.unpack_from("<H", data, pe_offset + 20)[0]
    optional_offset = pe_offset + 24
    if optional_offset + optional_size > len(data):
        return set()

    magic = struct.unpack_from("<H", data, optional_offset)[0]
    if magic == 0x20B:      # PE32+
        directories_offset = optional_offset + 112
    elif magic == 0x10B:    # PE32
        directories_offset = optional_offset + 96
    else:
        return set()

    # Data directory 1 is the import table.
    import_rva = struct.unpack_from("<I", data, directories_offset + 8)[0]
    if not import_rva:
        return set()

    sections = _pe_sections(data, optional_offset + optional_size, number_of_sections)
    table_offset = _rva_to_offset(import_rva, sections)
    if table_offset is None:
        return set()

    names: set[str] = set()
    # Descriptors are 20 bytes each, terminated by an all-zero one.
    while table_offset + 20 <= len(data):
        name_rva = struct.unpack_from("<I", data, table_offset + 12)[0]
        if name_rva == 0:
            break
        name_offset = _rva_to_offset(name_rva, sections)
        if name_offset is not None and name_offset < len(data):
            end = data.find(b"\0", name_offset)
            if end != -1:
                names.add(data[name_offset:end].decode("ascii", "ignore").lower())
        table_offset += 20

    return names


def _pe_sections(data: bytes, offset: int, count: int) -> list[tuple[int, int, int]]:
    """Section headers as (virtual_address, virtual_size, raw_offset) triples."""
    sections: list[tuple[int, int, int]] = []
    for index in range(count):
        header = offset + index * 40
        if header + 40 > len(data):
            break
        virtual_size, virtual_address, _raw_size, raw_offset = struct.unpack_from(
            "<IIII", data, header + 8
        )
        sections.append((virtual_address, virtual_size, raw_offset))
    return sections


def _rva_to_offset(rva: int, sections: list[tuple[int, int, int]]) -> int | None:
    """Map a relative virtual address onto a file offset."""
    for virtual_address, virtual_size, raw_offset in sections:
        if virtual_address <= rva < virtual_address + max(virtual_size, 1):
            return raw_offset + (rva - virtual_address)
    return None


def is_valid_pe(path: str | Path) -> bool:
    """True for any Windows executable image, whatever its architecture."""
    return pe_architecture(path) in (ARCH_X64, ARCH_X86, ARCH_PE)


def is_x64_pe(path: str | Path) -> bool:
    """True when the file is a PE image whose machine type is x86-64."""
    return pe_architecture(path) == ARCH_X64


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
