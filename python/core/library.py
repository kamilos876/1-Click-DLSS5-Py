"""The persistent game library: scan folders and the games found in them.

Replaces the drive-picker model. The user nominates folders to scan; the games
discovered there are saved to disk and reloaded on the next start, so the list
is there immediately instead of being rebuilt by a full disk sweep every time.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from . import constants as C

LIBRARY_VERSION = 1


def library_file() -> Path:
    """Where the library is stored. Read live so tests can redirect the cache."""
    return C.CACHE_ROOT / "library.json"


@dataclass
class LibraryEntry:
    """One saved game: where it is, what it supports, and whether it still exists."""

    name: str
    path: str
    badge_key: str = "BadgeFeeder"
    order: int = 3
    exe_name: str = ""
    exe_path: str = ""
    source_folder: str = ""
    added_at: str = ""
    # Whether this folder is really a game, and where its name came from.
    confidence: str = "uncertain"
    identity_source: str = "folder"
    folder_name: str = ""
    # Recomputed on scan and refresh; `missing` is transient, while the
    # install mode is saved so the list shows it before the first refresh.
    missing: bool = False
    installed_mode: str = ""

    def exists(self) -> bool:
        return Path(self.path).is_dir()

    @property
    def is_game(self) -> bool:
        """False for launchers, utilities and installer folders."""
        return self.confidence in ("confirmed", "likely")

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "path": self.path,
            "badge_key": self.badge_key,
            "order": self.order,
            "exe_name": self.exe_name,
            "exe_path": self.exe_path,
            "source_folder": self.source_folder,
            "added_at": self.added_at,
            "confidence": self.confidence,
            "identity_source": self.identity_source,
            "folder_name": self.folder_name,
            "installed_mode": self.installed_mode,
        }

    @staticmethod
    def from_dict(data: dict) -> "LibraryEntry":
        return LibraryEntry(
            name=str(data.get("name", "")),
            path=str(data.get("path", "")),
            badge_key=str(data.get("badge_key", "BadgeFeeder")),
            order=int(data.get("order", 3) or 3),
            exe_name=str(data.get("exe_name", "")),
            exe_path=str(data.get("exe_path", "")),
            source_folder=str(data.get("source_folder", "")),
            added_at=str(data.get("added_at", "")),
            confidence=str(data.get("confidence", "uncertain")),
            identity_source=str(data.get("identity_source", "folder")),
            folder_name=str(data.get("folder_name", "")),
            installed_mode=str(data.get("installed_mode", "")),
        )


@dataclass
class Library:
    """Saved scan folders plus every game discovered under them."""

    folders: list[str] = field(default_factory=list)
    entries: list[LibraryEntry] = field(default_factory=list)

    # ------------------------------------------------------------- persistence

    @staticmethod
    def load(path: Path | None = None) -> "Library":
        """Read the saved library, returning an empty one when absent or broken."""
        target = path or library_file()
        try:
            data = json.loads(target.read_text(encoding="utf-8-sig"))
        except (OSError, ValueError):
            return Library()

        if not isinstance(data, dict):
            return Library()

        folders = [str(item) for item in data.get("folders", []) if str(item).strip()]
        raw_entries = data.get("games", [])
        entries = [
            LibraryEntry.from_dict(item)
            for item in raw_entries
            if isinstance(item, dict) and item.get("path")
        ]
        return Library(folders=folders, entries=entries)

    def save(self, path: Path | None = None) -> None:
        """Write the library, creating the cache directory when needed."""
        target = path or library_file()
        payload = {
            "version": LIBRARY_VERSION,
            "saved_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "folders": self.folders,
            "games": [entry.to_dict() for entry in self.entries],
        }
        try:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError:
            # A read-only cache must not break the running app.
            pass

    # ----------------------------------------------------------------- folders

    def add_folder(self, folder: str) -> bool:
        """Register a folder to scan. False when it was already present."""
        clean = str(Path(folder))
        if any(existing.lower() == clean.lower() for existing in self.folders):
            return False
        self.folders.append(clean)
        return True

    def remove_folder(self, folder: str, drop_games: bool = True) -> None:
        """Unregister a folder and, by default, the games found under it."""
        clean = folder.lower()
        self.folders = [f for f in self.folders if f.lower() != clean]
        if drop_games:
            self.entries = [
                entry
                for entry in self.entries
                if entry.source_folder.lower() != clean
            ]

    # ------------------------------------------------------------------ games

    def upsert(self, entry: LibraryEntry) -> None:
        """Insert a game, or refresh the one already saved at that path."""
        key = entry.path.lower()
        for index, existing in enumerate(self.entries):
            if existing.path.lower() == key:
                # Keep the original added_at so the list order stays stable.
                entry.added_at = existing.added_at or entry.added_at
                self.entries[index] = entry
                return
        if not entry.added_at:
            entry.added_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.entries.append(entry)

    def remove(self, path: str) -> None:
        key = path.lower()
        self.entries = [e for e in self.entries if e.path.lower() != key]

    def prune_missing(self) -> list[LibraryEntry]:
        """Drop games whose folders are gone, returning what was removed."""
        gone = [entry for entry in self.entries if not entry.exists()]
        if gone:
            keep = {id(entry) for entry in gone}
            self.entries = [e for e in self.entries if id(e) not in keep]
        return gone

    def sorted_entries(self, include_uncertain: bool = False) -> list[LibraryEntry]:
        """Best compatibility first, then alphabetical.

        Entries that are not recognised as games are held back unless
        ``include_uncertain`` asks for them.
        """
        entries = self.entries if include_uncertain else [
            e for e in self.entries if e.is_game
        ]
        return sorted(entries, key=lambda e: (e.order, e.name.lower()))

    def uncertain_count(self) -> int:
        """How many saved entries are hidden as 'not recognised as a game'."""
        return sum(1 for e in self.entries if not e.is_game)
