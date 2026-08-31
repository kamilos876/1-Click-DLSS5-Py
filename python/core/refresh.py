"""Re-checking a saved library against what is actually on disk."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from .detection import DetectionError, resolve_game_target
from .gameinfo import identify_game
from .installer import is_installed
from .library import Library, LibraryEntry
from .scanner import classify

# Called with (percent, entry_name); return False to abort.
ProgressFn = Callable[[int, str], bool]


@dataclass
class RefreshResult:
    """What changed when the saved library was re-checked."""

    present: list[LibraryEntry] = field(default_factory=list)
    missing: list[LibraryEntry] = field(default_factory=list)
    updated: list[LibraryEntry] = field(default_factory=list)

    @property
    def total(self) -> int:
        return len(self.present) + len(self.missing)


def refresh_library(
    library: Library,
    progress: ProgressFn | None = None,
) -> RefreshResult:
    """Verify each saved game still exists and refresh its status in place.

    Nothing is removed here: entries are flagged so the UI can show what is
    gone and let the user decide whether to prune it.
    """
    result = RefreshResult()
    # Refresh every saved entry, including ones hidden from the list.
    entries = library.sorted_entries(include_uncertain=True)
    total = len(entries)

    for index, entry in enumerate(entries, start=1):
        if progress is not None:
            percent = int(index / total * 100) if total else 100
            if progress(percent, entry.name) is False:
                break

        path = Path(entry.path)
        if not path.is_dir():
            entry.missing = True
            entry.installed_mode = ""
            result.missing.append(entry)
            continue

        entry.missing = False
        changed = False

        # The executable may have moved between game patches.
        try:
            resolved = resolve_game_target(entry.path)
            if resolved.exe_name != entry.exe_name:
                entry.exe_name = resolved.exe_name
                changed = True
            if str(resolved.executable) != entry.exe_path:
                entry.exe_path = str(resolved.executable)
                changed = True
            install_folder = resolved.install_folder
        except DetectionError:
            install_folder = path

        # Re-identify: an installer folder becomes a real game once it is
        # installed, and a name can improve as metadata appears.
        identity = identify_game(path, entry.exe_path or None)
        if identity.confidence != entry.confidence:
            entry.confidence = identity.confidence
            changed = True
        if identity.display_name and identity.display_name != entry.name:
            entry.name = identity.display_name
            entry.identity_source = identity.source
            changed = True

        # A game patch can add or remove native DLSS, changing the verdict.
        badge_key, order = classify(path)
        if badge_key != entry.badge_key:
            entry.badge_key = badge_key
            entry.order = order
            changed = True

        state = is_installed(install_folder)
        mode = state.mode if state is not None else ""
        if mode != entry.installed_mode:
            entry.installed_mode = mode
            changed = True

        result.present.append(entry)
        if changed:
            result.updated.append(entry)

    return result
