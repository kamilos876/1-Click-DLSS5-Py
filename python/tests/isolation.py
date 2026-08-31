"""Redirect the app's cache so tests never touch the user's real library.

Import this BEFORE anything from `ui`: MainWindow reads library.json in its
constructor and writes it back on close, so a test that sets the cache later
would already have loaded — and would then overwrite — the real file.
"""
from __future__ import annotations

import atexit
import shutil
import tempfile
from pathlib import Path

from core import constants as C

_TEMP_CACHE = Path(tempfile.mkdtemp(prefix="dlss5-test-cache-"))
C.CACHE_ROOT = _TEMP_CACHE


@atexit.register
def _cleanup() -> None:
    shutil.rmtree(_TEMP_CACHE, ignore_errors=True)


def cache_root() -> Path:
    """The throwaway cache this test process is using."""
    return _TEMP_CACHE
