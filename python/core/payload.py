"""Preparing the DLSS payload and installing the ReShade runtime."""
from __future__ import annotations

import shutil
import subprocess
import sys
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from . import constants as C
from .messages import Message, msg
from .utils import is_x64_pe, iter_files, sanitize_path, sha256_of

# Called with (message, level) where level is INFO / OK / WARN / ERROR.
# The message is a Message key, so the UI can render it in any language.
LogFn = Callable[["Message | str", str], None]


def _noop(message: "Message | str", level: str = "INFO") -> None:
    """Default sink so core functions work headless and in tests."""


class PayloadError(Exception):
    """Raised when the DLSS payload is missing, invalid or unreadable.

    Carries a Message so the UI renders it in the user's language.
    """

    def __init__(self, message: Message) -> None:
        super().__init__(message.key)
        self.message = message


@dataclass
class Payload:
    """An extracted payload: the folder holding the runtime DLLs."""

    folder: Path
    zip_path: Path
    zip_hash: str


def find_embedded_streamline_zip() -> Path | None:
    """Locate the bundled streamline.zip across the layouts shipped so far.

    v1.5.0 moved payload/ under core/, and the app may run from either the
    repository root or that subfolder, so every plausible location is probed
    before the user is asked to pick the ZIP by hand.
    """
    roots = [C.APP_ROOT, C.REPO_ROOT, Path.cwd()]
    seen: set[Path] = set()
    for root in roots:
        for candidate in (root / "payload" / "streamline.zip",
                          root / "core" / "payload" / "streamline.zip"):
            if candidate in seen:
                continue
            seen.add(candidate)
            if candidate.is_file():
                return candidate.resolve()
    return None


def prepare_payload(zip_path: str = "", log: LogFn = _noop) -> Payload:
    """Extract the Streamline ZIP into a hash-keyed cache and stage the addon.

    The cache is keyed by the ZIP's own hash, so an unchanged package is
    extracted once and reused on every later run.
    """
    clean = sanitize_path(zip_path)
    if not clean:
        # The ZIP argument is optional: fall back to the bundled payload so a
        # default install needs no file picker at all.
        found = find_embedded_streamline_zip()
        if found is None:
            raise PayloadError(msg("PayloadSelectZip"))
        clean = str(found)

    zip_file = Path(clean)
    if not zip_file.is_file():
        raise PayloadError(msg("PayloadZipMissing", clean))

    addon = C.PAYLOAD_ROOT / C.ADDON_NAME
    if not addon.is_file():
        raise PayloadError(msg("PayloadAddonMissing", C.ADDON_NAME))

    zip_hash = sha256_of(zip_file)
    C.CACHE_ROOT.mkdir(parents=True, exist_ok=True)
    cache = C.CACHE_ROOT / f"user-payload-{zip_hash[:12]}"

    runtime = _find_runtime(cache)
    if runtime is None:
        if cache.exists():
            shutil.rmtree(cache, ignore_errors=True)
        cache.mkdir(parents=True, exist_ok=True)
        log(msg("PayloadExtracting"), "INFO")
        try:
            with zipfile.ZipFile(zip_file) as archive:
                archive.extractall(cache)
        except (zipfile.BadZipFile, OSError) as err:
            raise PayloadError(msg("PayloadExtractFailed", err)) from err

        runtime = _find_runtime(cache)
        if runtime is None:
            raise PayloadError(msg("PayloadNoRuntime"))

    folder = runtime.parent
    shutil.copy2(addon, folder / C.ADDON_NAME)
    return Payload(folder=folder, zip_path=zip_file, zip_hash=zip_hash)


def _find_runtime(cache: Path) -> Path | None:
    """Find a valid 64-bit nvngx_dlssnr.dll inside an extracted payload."""
    if not cache.is_dir():
        return None
    for candidate in iter_files(cache, "nvngx_dlssnr.dll", max_depth=12):
        if is_x64_pe(candidate):
            return candidate
    return None


def get_reshade_setup(log: LogFn = _noop) -> Path:
    """Return a path to the ReShade installer, preferring the bundled copy."""
    C.CACHE_ROOT.mkdir(parents=True, exist_ok=True)
    setup = C.CACHE_ROOT / C.RESHADE_SETUP_NAME

    bundled = C.PAYLOAD_ROOT / C.RESHADE_SETUP_NAME
    if bundled.is_file():
        shutil.copy2(bundled, setup)
        return setup

    if setup.is_file() and sha256_of(setup) == C.RESHADE_HASH:
        return setup

    log(msg("ReShadeDownloading"), "INFO")
    try:
        with urllib.request.urlopen(C.RESHADE_URL, timeout=120) as response:
            setup.write_bytes(response.read())
    except OSError as err:
        raise PayloadError(msg("ReShadeDownloadFailed", err)) from err
    return setup


def install_reshade(
    target_exe: Path,
    setup: Path,
    log: LogFn = _noop,
    target_api: str = C.API_DXGI,
) -> str:
    """Run the ReShade installer headlessly and return the proxy DLL it loads as.

    ReShade only hooks a game when its DLL carries the name that game's renderer
    imports, so the installer is told which API to target and the result is
    renamed if it still landed on dxgi.dll. An existing large proxy DLL is
    reused, renamed when it sits under the wrong name for this API.
    """
    folder = target_exe.parent
    dxgi = folder / "dxgi.dll"
    expected_name = C.API_PROXY_DLL.get(target_api, "dxgi.dll")
    expected = folder / expected_name

    existing = _find_existing_reshade(folder)
    if existing is not None:
        if existing != expected and not expected.is_file():
            shutil.move(str(existing), str(expected))
            log(msg("ReShadeRenamed", expected_name, target_api), "OK")
        log(msg("ReShadePresent", expected_name), "OK")
        return expected_name

    api_flag = C.API_INSTALLER_FLAG.get(target_api, "dxgi")

    try:
        completed = subprocess.run(
            [str(setup), "--headless", "--api", api_flag, str(target_exe)],
            capture_output=True,
            timeout=300,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0) if sys.platform == "win32" else 0,
        )
        exit_code = completed.returncode
    except (OSError, subprocess.SubprocessError) as err:
        raise PayloadError(msg("ReShadeRunFailed", err)) from err

    # Older ReShade builds ignore --api for some targets and write dxgi.dll.
    if expected != dxgi and dxgi.is_file() and not expected.is_file():
        shutil.move(str(dxgi), str(expected))
        log(msg("ReShadeRenamed", expected_name, target_api), "OK")

    if not (expected.is_file() or dxgi.is_file()) and exit_code != 0:
        raise PayloadError(msg("ReShadeExitCode", exit_code))

    return expected_name


def _find_existing_reshade(folder: Path) -> Path | None:
    """Return an already-installed ReShade proxy DLL, whatever name it uses.

    A proxy larger than 2 MB is a real ReShade build rather than a game stub.
    """
    for name in ("opengl32.dll", "d3d12.dll", "dxgi.dll", "d3d9.dll"):
        candidate = folder / name
        if not candidate.is_file():
            continue
        try:
            if candidate.stat().st_size > 2 * 1024 * 1024:
                return candidate
        except OSError:
            continue
    return None
