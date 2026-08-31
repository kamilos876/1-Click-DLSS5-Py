"""Background workers so disk scans and installs never freeze the window.

The PowerShell version ran both on the UI thread and kept the window alive with
DoEvents; here each job runs on a QThread and reports back through signals.

Callers must keep a reference to the worker for as long as the thread runs: a
worker held only in a local variable is garbage collected when the starting
method returns, and the thread then spins on an empty event loop forever.
"""
from __future__ import annotations

from PySide6.QtCore import QObject, Signal

from core.detection import DetectionError
from core.installer import InstallError, install_dlss5
from core.library import Library
from core.messages import msg
from core.payload import PayloadError
from core.refresh import RefreshResult, refresh_library
from core.scanner import scan_folders


class ScanWorker(QObject):
    """Scans the user's nominated folders for games."""

    progress = Signal(int, str)
    finished = Signal(list)
    failed = Signal(object)

    def __init__(self, folders: list[str], badges: dict[str, str]) -> None:
        super().__init__()
        self._folders = folders
        self._badges = badges
        self._cancelled = False

    def cancel(self) -> None:
        self._cancelled = True

    def run(self) -> None:
        try:
            games = scan_folders(
                self._folders,
                badges=self._badges,
                progress=self._on_progress,
            )
            self.finished.emit(games)
        except Exception as err:  # a scan must never take the app down
            self.failed.emit(msg("ScanFailed", err))

    def _on_progress(self, percent: int, name: str) -> bool:
        self.progress.emit(percent, name)
        return not self._cancelled


class RefreshWorker(QObject):
    """Re-checks the saved library against what is on disk now."""

    progress = Signal(int, str)
    finished = Signal(object)
    failed = Signal(object)

    def __init__(self, library: Library) -> None:
        super().__init__()
        self._library = library
        self._cancelled = False

    def cancel(self) -> None:
        self._cancelled = True

    def run(self) -> None:
        try:
            result = refresh_library(self._library, progress=self._on_progress)
            self.finished.emit(result)
        except Exception as err:
            self.failed.emit(msg("RefreshFailed", err))

    def _on_progress(self, percent: int, name: str) -> bool:
        self.progress.emit(percent, name)
        return not self._cancelled


class InstallWorker(QObject):
    """Runs one DLSS 5 injection."""

    log = Signal(object, str)
    finished = Signal(str)
    failed = Signal(object)

    def __init__(
        self,
        target_path: str,
        zip_path: str,
        install_reshade: bool,
        full_package: bool,
        selected_mode: str,
    ) -> None:
        super().__init__()
        self._target_path = target_path
        self._zip_path = zip_path
        self._install_reshade = install_reshade
        self._full_package = full_package
        self._selected_mode = selected_mode

    def run(self) -> None:
        try:
            upscaler = install_dlss5(
                target_path=self._target_path,
                dlss_zip_path=self._zip_path,
                install_reshade_runtime=self._install_reshade,
                full_package=self._full_package,
                selected_mode=self._selected_mode,
                log=lambda message, level="INFO": self.log.emit(message, level),
            )
            self.finished.emit(upscaler)
        except (InstallError, DetectionError, PayloadError) as err:
            self.failed.emit(err.message)
        except OSError as err:
            # Most often a locked DLL because the game is still running.
            self.failed.emit(msg("FileAccessDenied", err))
        except Exception as err:
            self.failed.emit(msg("InstallUnexpected", err))
