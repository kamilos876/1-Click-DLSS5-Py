"""Administrator rights check and self-elevation.

Games under Program Files cannot receive injected DLLs without elevation. The
PowerShell version never checked, so installs there failed with an opaque
access error; here we detect it up front and offer to relaunch.
"""
from __future__ import annotations

import sys
from pathlib import Path

# Locations that always require elevation to write into.
_PROTECTED_PREFIXES = (
    "c:\\program files",
    "c:\\program files (x86)",
    "c:\\windows",
)


def is_admin() -> bool:
    """True when the process already holds administrator rights."""
    if sys.platform != "win32":
        import os

        return os.geteuid() == 0  # type: ignore[attr-defined]

    import ctypes

    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def needs_elevation(target: str | Path) -> bool:
    """True when writing to ``target`` would require rights we do not have."""
    if is_admin():
        return False
    lowered = str(target).lower()
    return any(lowered.startswith(prefix) for prefix in _PROTECTED_PREFIXES)


def relaunch_as_admin() -> bool:
    """Restart this program elevated. Returns False if the user declines UAC."""
    if sys.platform != "win32" or is_admin():
        return False

    import ctypes

    script = str(Path(sys.argv[0]).resolve())
    params = " ".join(f'"{arg}"' for arg in sys.argv[1:])

    if getattr(sys, "frozen", False):
        # A PyInstaller build is its own executable.
        target, arguments = sys.executable, params
    else:
        target, arguments = sys.executable, f'"{script}" {params}'.strip()

    try:
        # ShellExecuteW with "runas" raises the UAC prompt.
        result = ctypes.windll.shell32.ShellExecuteW(
            None, "runas", target, arguments, None, 1
        )
    except Exception:
        return False

    # Anything above 32 means the new process started.
    return int(result) > 32
