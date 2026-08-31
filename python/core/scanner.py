"""Discovering games inside user-nominated folders."""
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from . import constants as C
from .detection import DetectionError, resolve_game_target
from .gameinfo import GameIdentity, identify_game
from .installer import is_installed
from .utils import fixed_drives

# Called with (percent, current_game_name); return False to abort the scan.
ProgressFn = Callable[[int, str], bool]


@dataclass
class DiscoveredGame:
    """One game found on disk, with its compatibility verdict."""

    name: str
    path: Path
    badge: str
    order: int
    exe_name: str = ""
    icon_source: Path | None = None
    badge_key: str = "BadgeFeeder"
    source_folder: str = ""
    # How sure we are this is a game at all, and where the name came from.
    confidence: str = "uncertain"
    identity_source: str = "folder"
    folder_name: str = ""
    # Which injection mode is already installed here, if any.
    installed_mode: str = ""

    @property
    def is_game(self) -> bool:
        return self.confidence in ("confirmed", "likely")

    @property
    def display_name(self) -> str:
        return f"{self.badge} {self.name}"


# Only the runtime libraries count as evidence. Matching any name containing
# "dlss" also matched other mods' log files (Dying Light ships a third-party
# dlss-enabler.log), which wrongly graded games as having native DLSS.
_NATIVE_DLSS_FILES = re.compile(
    r"^(nvngx_dlss(d|g|nr)?\.dll|sl\.dlss(_[a-z]+)?\.dll|sl\.interposer\.dll"
    r"|_nvngx\.dll|libxell\.dll)$"
)
_FSR_FILES = re.compile(
    r"^(ffx_fsr\d.*\.dll|amd_fidelityfx.*\.dll|fsr\d?\.dll"
    r"|ffx_backend_dx1[12]\.dll)$"
)
_XESS_FILES = re.compile(r"^(libxess\.dll|xess\.dll)$")


def default_library_folders() -> list[str]:
    """Well-known store folders that exist, offered as a starting point."""
    found: list[str] = []
    for drive_root in fixed_drives():
        for subpath in C.GAME_LIBRARY_SUBPATHS:
            candidate = Path(drive_root) / subpath
            if candidate.is_dir():
                found.append(str(candidate))
    return found


def _is_ignored_dir(name: str) -> bool:
    """True for folders that are never games: stores' own data, dev clutter."""
    lowered = name.lower()
    if lowered in C.IGNORED_GAME_DIRS:
        return True
    # Dot-folders (.git, .cache) and Windows metadata are never games.
    return lowered.startswith(".") or lowered.startswith("$")


def _looks_like_game(folder: Path) -> bool:
    """True when the folder itself resolves to a game executable."""
    try:
        resolve_game_target(str(folder))
        return True
    except DetectionError:
        return False


def _holds_game_files(folder: Path) -> bool:
    """True when this folder is a game's own directory, not a group of them.

    resolve_game_target() searches several levels deep, so it answers True for
    a grouping folder like "D:\Gry" purely because some game below it has an
    executable. A real game directory has its own binaries or data right here.
    """
    try:
        entries = list(os.scandir(folder))
    except (OSError, PermissionError):
        return False

    for entry in entries:
        try:
            if not entry.is_file(follow_symlinks=False):
                continue
        except OSError:
            continue
        name = entry.name.lower()
        if name.endswith((".exe", ".dll", ".pak", ".assets", ".bin", ".dat")):
            return True

    # Engine layouts keep the binary one level down, beside their data.
    for marker in ("Binaries", "Engine", "bin", "Content", "Data", "game"):
        if (folder / marker).is_dir():
            return True
    return False


# Subfolders that hold games rather than being one, relative to a launcher
# or store root. "D:\Gry\Steam" keeps its games three levels down.
_CONTAINER_SUBPATHS = [
    ("steamapps", "common"),
    ("games",),
    ("Launcher", "games"),
]

# Folder names that are stores or launchers: their games live inside, so the
# scanner must descend instead of listing the launcher itself as a game.
_CONTAINER_NAMES = {
    "steam", "steamlibrary", "epic games", "gog galaxy", "ubisoft game launcher",
    "ubisoft", "origin games", "ea games", "ea desktop", "battle.net",
    "rockstar games", "riot games", "amazon games", "xboxgames", "microsoft games",
    "games", "gry",
}


def _immediate_subdirs(folder: Path) -> list[Path]:
    """Directories directly inside ``folder``, minus the ignored ones."""
    found: list[Path] = []
    try:
        entries = sorted(os.scandir(folder), key=lambda e: e.name)
    except (OSError, PermissionError):
        return found

    for entry in entries:
        try:
            if not entry.is_dir(follow_symlinks=False):
                continue
        except OSError:
            continue
        if _is_ignored_dir(entry.name):
            continue
        found.append(Path(entry.path))
    return found


def _container_targets(folder: Path) -> list[Path]:
    """Where a launcher or store keeps its games, if this is such a folder.

    Steam nests them under steamapps\common and Ubisoft under games\, so a
    plain one-level listing would report the launcher itself as a game.
    """
    targets: list[Path] = []
    for parts in _CONTAINER_SUBPATHS:
        candidate = folder.joinpath(*parts)
        if candidate.is_dir():
            targets.append(candidate)
    return targets


def _is_container(folder: Path, subdirs: list[Path]) -> bool:
    """True when the folder groups several games rather than being one."""
    if folder.name.lower() in _CONTAINER_NAMES:
        return True
    # A folder that itself resolves to a game is a game, not a container.
    return False


def candidate_dirs(folder: Path, _depth: int = 0) -> list[Path]:
    """Games to examine under ``folder``.

    A store library holds one game per subfolder; a folder that is itself a
    game (the user picked the game directly) is returned on its own. Launcher
    roots such as Steam or Ubisoft Connect nest their games deeper, so those
    are followed into their real game directories.
    """
    if not folder.is_dir() or _depth > 3:
        return []

    # A launcher root: scan the folder its games actually live in.
    nested = _container_targets(folder)
    if nested:
        found: list[Path] = []
        for target in nested:
            found.extend(_immediate_subdirs(target))
        if found:
            return found

    subdirs = _immediate_subdirs(folder)
    if not subdirs:
        return [folder] if _looks_like_game(folder) else []

    # A folder holding its own binaries is the game: its Data/Binaries
    # subfolders are parts of it, never separate games. Launcher roots are
    # exempt, since they keep their client files beside the games they hold.
    if _holds_game_files(folder) and folder.name.lower() not in _CONTAINER_NAMES:
        return [folder]

    # A grouping folder (Rockstar Games, Epic Games, or the user's own "Gry")
    # holds one game per subfolder. Descend only into children that are
    # themselves launcher roots or grouping folders; a child that holds its own
    # game files is the game, and must not be opened further.
    if _is_container(folder, subdirs):
        found: list[Path] = []
        for sub in subdirs:
            # A child that is itself a launcher root gets opened; one that
            # holds its own game files is the game and stops here.
            if _container_targets(sub) or sub.name.lower() in _CONTAINER_NAMES:
                found.extend(candidate_dirs(sub, _depth + 1) or [sub])
            else:
                found.append(sub)
        return found

    return subdirs


def classify(game_path: Path) -> tuple[str, int]:
    """Return the compatibility marker key and sort order for a game folder.

    One walk collects every signal, so a large install is traversed once
    instead of once per upscaler family.
    """
    has_fsr = False
    has_xess = False

    stack: list[tuple[Path, int]] = [(game_path, 0)]
    while stack:
        current, depth = stack.pop()
        try:
            entries = list(os.scandir(current))
        except (OSError, PermissionError):
            continue

        for entry in entries:
            try:
                if entry.is_dir(follow_symlinks=False):
                    if depth < 12:
                        stack.append((Path(entry.path), depth + 1))
                    continue
                if not entry.is_file(follow_symlinks=False):
                    continue
            except OSError:
                continue

            name = entry.name.lower()
            if _NATIVE_DLSS_FILES.match(name):
                # Native DLSS is the top verdict; nothing can outrank it.
                return "Badge100", 1
            if _FSR_FILES.match(name):
                has_fsr = True
            elif _XESS_FILES.match(name):
                has_xess = True

    if has_fsr or has_xess:
        return "BadgeBridge", 2
    return "BadgeFeeder", 3


def scan_folders(
    folders: list[str],
    badges: dict[str, str] | None = None,
    progress: ProgressFn | None = None,
) -> list[DiscoveredGame]:
    """Scan every nominated folder, best-compatibility first.

    ``badges`` maps marker keys onto localized labels; ``progress`` is called
    per game and may return False to cancel.
    """
    badges = badges or {}

    planned: list[tuple[Path, str]] = []
    seen: set[str] = set()
    for raw in folders:
        folder = Path(raw)
        for game_dir in candidate_dirs(folder):
            key = str(game_dir).lower()
            if key in seen:
                continue
            seen.add(key)
            planned.append((game_dir, str(folder)))

    total = len(planned)
    if total == 0:
        return []

    results: list[DiscoveredGame] = []
    for index, (game_path, source) in enumerate(planned, start=1):
        if progress is not None:
            if progress(int(index / total * 100), game_path.name) is False:
                break

        badge_key, order = classify(game_path)
        exe_name = ""
        icon_source: Path | None = None
        executable = None
        installed_mode = ""
        try:
            resolved = resolve_game_target(str(game_path))
            exe_name = resolved.exe_name
            icon_source = resolved.executable
            executable = resolved.executable
            state = is_installed(resolved.install_folder)
            if state is not None:
                installed_mode = state.mode
        except DetectionError:
            pass

        identity = identify_game(game_path, executable)

        results.append(
            DiscoveredGame(
                name=identity.display_name or game_path.name,
                path=game_path,
                badge=badges.get(badge_key, badge_key),
                order=order,
                exe_name=exe_name,
                icon_source=icon_source,
                badge_key=badge_key,
                source_folder=source,
                confidence=identity.confidence,
                identity_source=identity.source,
                folder_name=game_path.name,
                installed_mode=installed_mode,
            )
        )

    results.sort(key=lambda game: (game.order, game.name.lower()))
    return results
