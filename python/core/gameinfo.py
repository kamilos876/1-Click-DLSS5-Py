"""Deciding whether a folder holds a real game, and what the game is called.

Everything here reads local files only: store metadata dropped by GOG, Steam,
Epic and Xbox installers, the engine files a game ships, and the version
resource compiled into the executable itself. No network, no API keys, and no
list of the user's games leaving the machine.
"""
from __future__ import annotations

import ctypes
import json
import os
import re
import sys
from ctypes import wintypes
from dataclasses import dataclass, field
from pathlib import Path

from .utils import iter_files

# --- Confidence -------------------------------------------------------------

CONFIRMED = "confirmed"    # store metadata or engine files prove it is a game
LIKELY = "likely"          # strong hints: game-shaped layout or exe metadata
UNCERTAIN = "uncertain"    # nothing says game; probably an application
NOT_A_GAME = "not_a_game"  # positively identified as something else

_ORDER = {CONFIRMED: 0, LIKELY: 1, UNCERTAIN: 2, NOT_A_GAME: 3}


@dataclass
class GameIdentity:
    """What we could establish about a folder."""

    display_name: str
    confidence: str = UNCERTAIN
    source: str = "folder"          # where display_name came from
    publisher: str = ""
    store: str = ""                 # gog / steam / epic / xbox
    engine: str = ""                # unreal / unity / source / ...
    reasons: list[str] = field(default_factory=list)

    @property
    def is_game(self) -> bool:
        return self.confidence in (CONFIRMED, LIKELY)


# --- Engine and store fingerprints -----------------------------------------

# Files that only ship with a game engine or a game's store integration.
_ENGINE_MARKERS: list[tuple[str, str]] = [
    ("UnityPlayer.dll", "Unity"),
    ("UnityCrashHandler64.exe", "Unity"),
    ("GameAssembly.dll", "Unity"),
    ("hl2.exe", "Source"),
    ("engine2.dll", "Source 2"),
    ("bink2w64.dll", "Bink video"),
    ("binkw32.dll", "Bink video"),
    ("PhysX3_x64.dll", "PhysX"),
    ("PhysXDevice64.dll", "PhysX"),
    ("d3dcompiler_47.dll", ""),  # weak on its own; scored lower below
    ("fmod.dll", "FMOD"),
    ("fmodstudio.dll", "FMOD"),
    ("fmod64.dll", "FMOD"),
    ("wwise.dll", "Wwise"),
    ("galaxy64.dll", "GOG Galaxy SDK"),
    ("galaxy.dll", "GOG Galaxy SDK"),
    ("steam_api.dll", "Steamworks"),
    ("steam_api64.dll", "Steamworks"),
    ("eossdk-win64-shipping.dll", "Epic Online Services"),
    ("xinput1_3.dll", ""),
    ("openvr_api.dll", "OpenVR"),
]

# Weak markers: common in games but also in ordinary software.
_WEAK_MARKERS = {"d3dcompiler_47.dll", "xinput1_3.dll"}

# Directory names that mean "this is a game" in engine layouts.
_ENGINE_DIRS: list[tuple[str, str]] = [
    ("binaries/win64", "Unreal Engine"),
    ("binaries/wingdk", "Unreal Engine"),
    ("engine/binaries", "Unreal Engine"),
    ("_data/managed", "Unity"),
    ("content/paks", "Unreal Engine"),
]

# A folder full of these is an installer or an archive, not an install.
_INSTALLER_HINTS = re.compile(
    r"^(setup[_\-].*\.(exe|bin)|.*\.(bin|iso|mds|mdf|nrg|r\d\d|part\d+\.rar|rar|7z|zip)"
    r"|autorun\.inf)$",
    re.IGNORECASE,
)

# Publishers whose software is never a game, matched against CompanyName.
_NON_GAME_PUBLISHERS = re.compile(
    r"(microsoft corporation|adobe|autodesk|oracle|realtek|intel corporation"
    r"|nvidia corporation|advanced micro devices|asustek|gigabyte|msi|corsair"
    r"|logitech|razer|python software|jetbrains|git for windows|mozilla"
    r"|google llc|dropbox|valve corporation$)",
    re.IGNORECASE,
)

# Names that identify a launcher or store client rather than a game.
# Anchored at both ends: "Steam" is a launcher, "SteamGame" is a game folder.
_LAUNCHER_NAMES = re.compile(
    r"^(gog galaxy|steam|steamlibrary|epic games launcher|epic games"
    r"|ea app|origin|ubisoft connect|uplay|battle\.net"
    r"|rockstar games launcher|xbox|xbox app|riot client|nvidia app"
    r"|geforce experience|discord|playnite|itch)\s*$",
    re.IGNORECASE,
)

# Overlays, benchmarks and tuning utilities: they ship game-like DLLs but are
# not games themselves.
_TOOL_NAMES = re.compile(
    r"(rivatuner|afterburner|statistics server|desktop overlay|fraps|obs studio"
    r"|bandicam|shadowplay|reshade setup|special ?k|msi center|armoury crate"
    r"|3dmark|furmark|unigine|heaven benchmark|superposition|cinebench"
    r"|crystaldisk|hwinfo|gpu-z|cpu-z|display driver uninstaller"
    # Launcher plumbing that ships beside real games and looks game-like.
    r"|overlay runtime|error handler|crash ?(handler|reporter)|updater"
    r"|redistributab|prerequisit|helper|bootstrapper|web ?installer"
    r"|dependenc|third ?party|directx|vc\+\+|visual c\+\+)",
    re.IGNORECASE,
)

_STORE_METADATA = {
    "goggame-*.info": "gog",
    "*.mancpn": "epic",
    "MicrosoftGame.config": "xbox",
    "steam_appid.txt": "steam",
}


# --- Executable version resource -------------------------------------------


def read_version_info(exe_path: str | Path) -> dict[str, str]:
    """Read ProductName / FileDescription / CompanyName from a PE file.

    This is the single most reliable local source of a game's real title.
    Returns an empty dict when the file has no version resource.
    """
    if sys.platform != "win32":
        return {}

    path = str(exe_path)
    try:
        version = ctypes.windll.version
        size = version.GetFileVersionInfoSizeW(path, None)
        if not size:
            return {}

        buffer = ctypes.create_string_buffer(size)
        if not version.GetFileVersionInfoW(path, 0, size, buffer):
            return {}

        lang_ptr = ctypes.c_void_p()
        length = wintypes.UINT()
        if not version.VerQueryValueW(
            buffer, "\\VarFileInfo\\Translation",
            ctypes.byref(lang_ptr), ctypes.byref(length),
        ):
            return {}

        codes = ctypes.cast(lang_ptr, ctypes.POINTER(wintypes.WORD))
        lang_id, codepage = codes[0], codes[1]

        found: dict[str, str] = {}
        for key in ("ProductName", "FileDescription", "CompanyName"):
            sub_block = f"\\StringFileInfo\\{lang_id:04x}{codepage:04x}\\{key}"
            value = ctypes.c_wchar_p()
            count = wintypes.UINT()
            if version.VerQueryValueW(
                buffer, sub_block, ctypes.byref(value), ctypes.byref(count)
            ) and value.value:
                found[key] = value.value.strip()
        return found
    except Exception:
        # A malformed resource must never break a scan.
        return {}


# --- Folder-name cleanup ----------------------------------------------------

# Release-group and repack noise stripped from a folder name.
_NAME_NOISE = re.compile(
    r"\b(repack|proper|readnfo|multi\d*|incl[\s._-]*dlc|all[\s._-]*dlc"
    r"|goty|game[\s._-]*of[\s._-]*the[\s._-]*year|deluxe|ultimate|complete"
    r"|edition|remastered|definitive|enhanced|directors[\s._-]*cut"
    r"|v?\d+\.\d+[\d.]*|build[\s._-]*\d+|update[\s._-]*\d+|u\d+"
    r"|x64|x86|win64|win32|pc|dodi|fitgirl|codex|plaza|skidrow|rune|empress"
    r"|elamigos|gog|steam|epic|razor1911|tenoke|flt|hoodlum)\b",
    re.IGNORECASE,
)

_TRAILING_ID = re.compile(r"[\s._-]*[\(\[]\s*\d{3,}\s*[\)\]]\s*$")
_LEADING_TAG = re.compile(r"^\s*(game|setup|install)[\s._-]+", re.IGNORECASE)
_BRACKETS = re.compile(r"[\(\[]\s*[\)\]]")
# A dotted initialism such as S.T.A.L.K.E.R. must keep its own casing.
_DOTTED_ACRONYM = re.compile(r"^(?:[A-Za-z]\.){2,}$")


def clean_folder_name(name: str) -> str:
    """Turn a scene-style folder name into something readable.

    "game-the.sinking.city.remastered-(88711)" -> "The Sinking City"
    """
    text = _TRAILING_ID.sub("", name)
    text = _LEADING_TAG.sub("", text)

    # Strip dotted version strings (v2.1, 1.0.3) before dots become spaces,
    # otherwise "v2.1" survives as the words "V2 1".
    text = re.sub(r"[\s._-]v?\d+(?:\.\d+)+[a-z]?(?=[\s._-]|$)", " ", text, flags=re.IGNORECASE)

    # Dots and underscores are word separators in release names, but keep
    # them inside initialisms like S.T.A.L.K.E.R.
    if not re.search(r"(?:[A-Za-z]\.){2,}", text):
        text = text.replace(".", " ").replace("_", " ")
    text = text.replace("-", " ")

    text = _NAME_NOISE.sub(" ", text)
    text = _BRACKETS.sub(" ", text)
    text = re.sub(r"\s{2,}", " ", text).strip(" -.,")

    if not text:
        return name

    # Title-case lowercase words; keep short all-caps words as acronyms
    # (RTX, HD, VR, GOTY) and leave MiXeD casing alone.
    minor = {"of", "the", "and", "in", "on", "a", "an", "to", "for", "vs"}
    words = []
    for index, word in enumerate(text.split()):
        if _DOTTED_ACRONYM.match(word):
            words.append(word.upper())  # S.T.A.L.K.E.R.
        elif word.isupper() and len(word) <= 4:
            words.append(word)          # acronym: RTX, HD, VR
        elif index > 0 and word.lower() in minor:
            words.append(word.lower())
        elif word.islower() or word.isupper():
            words.append(word.capitalize())
        else:
            words.append(word)
    return " ".join(words)


# --- Store metadata ---------------------------------------------------------


def _read_gog_info(folder: Path) -> tuple[str, str]:
    """Return (name, exe) from a goggame-<id>.info file, if present."""
    for info in folder.glob("goggame-*.info"):
        try:
            data = json.loads(info.read_text(encoding="utf-8-sig"))
        except (OSError, ValueError):
            continue
        name = str(data.get("name", "")).strip()
        exe = ""
        tasks = data.get("playTasks") or []
        for task in tasks:
            if isinstance(task, dict) and task.get("path"):
                exe = str(task["path"])
                break
        if name:
            return name, exe
    return "", ""


def _read_xbox_config(folder: Path) -> str:
    """Return the display name from MicrosoftGame.config."""
    for config in list(folder.glob("MicrosoftGame.config")) + list(
        folder.glob("*/MicrosoftGame.config")
    ):
        try:
            text = config.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            continue
        for pattern in (
            r'OverrideDisplayName\s*=\s*"([^"]+)"',
            r'<ShellVisuals[^>]*\bDefaultDisplayName="([^"]+)"',
            r"<Name>([^<]+)</Name>",
        ):
            match = re.search(pattern, text)
            if match:
                name = match.group(1).strip()
                # Xbox configs often point at a localized resource we cannot
                # resolve; fall through to the next source instead.
                if name and not name.lower().startswith("ms-resource:"):
                    return name
    return ""


def _detect_store(folder: Path) -> str:
    """Which store's metadata is present in this folder."""
    for pattern, store in _STORE_METADATA.items():
        if any(folder.glob(pattern)):
            return store
    if (folder / ".egstore").is_dir():
        return "epic"
    return ""


# --- Identification ---------------------------------------------------------


def looks_like_installer(folder: Path) -> bool:
    """True when the folder holds an installer or archive set, not an install.

    A GOG offline installer is a pile of setup_*.bin files; injecting into one
    is impossible, so those folders should not be listed as games.
    """
    try:
        entries = [e for e in os.scandir(folder) if e.is_file()]
    except (OSError, PermissionError):
        return False

    if not entries:
        return False

    matches = sum(1 for e in entries if _INSTALLER_HINTS.match(e.name))
    # Mostly archive parts, and no real executable tree beside them.
    return matches >= 2 and matches >= len(entries) * 0.5


def _scan_markers(folder: Path, max_depth: int = 6) -> tuple[list[str], str]:
    """Find engine/store marker files. Returns (reasons, engine name)."""
    wanted = {name.lower(): engine for name, engine in _ENGINE_MARKERS}
    reasons: list[str] = []
    engine = ""

    for file in iter_files(folder, "*", max_depth=max_depth):
        lowered = file.name.lower()
        if lowered in wanted:
            if lowered in _WEAK_MARKERS:
                continue
            label = wanted[lowered] or file.name
            if label not in reasons:
                reasons.append(label)
                if not engine and wanted[lowered]:
                    engine = wanted[lowered]
            if len(reasons) >= 3:
                break

    lowered_paths = str(folder).lower()
    for fragment, engine_name in _ENGINE_DIRS:
        probe = folder / Path(fragment)
        if probe.exists() or fragment.replace("/", os.sep) in lowered_paths:
            if engine_name not in reasons:
                reasons.append(engine_name)
            engine = engine or engine_name
            break

    return reasons, engine


def identify_game(
    folder: str | Path,
    executable: str | Path | None = None,
) -> GameIdentity:
    """Work out whether ``folder`` is a game and what it is called.

    Sources are tried strongest first: store metadata, then engine files, then
    the executable's own version resource, then a cleaned-up folder name.
    """
    folder = Path(folder)
    fallback = clean_folder_name(folder.name)

    if looks_like_installer(folder):
        return GameIdentity(
            display_name=fallback,
            confidence=NOT_A_GAME,
            source="folder",
            reasons=["installer/archive, not an installed game"],
        )

    identity = GameIdentity(display_name=fallback, source="folder")

    if _TOOL_NAMES.search(folder.name) or _LAUNCHER_NAMES.match(folder.name):
        return GameIdentity(
            display_name=fallback,
            confidence=NOT_A_GAME,
            source="folder",
            reasons=["launcher or utility, not a game"],
        )

    # 1. Store metadata is authoritative for both name and game-ness.
    store = _detect_store(folder)
    if store:
        identity.store = store
        identity.confidence = CONFIRMED
        identity.reasons.append(f"{store} metadata")

    gog_name, _gog_exe = _read_gog_info(folder)
    if gog_name:
        identity.display_name = gog_name
        identity.source = "gog"
        identity.store = "gog"
        identity.confidence = CONFIRMED

    xbox_name = _read_xbox_config(folder)
    if xbox_name:
        identity.display_name = xbox_name
        identity.source = "xbox"
        identity.store = "xbox"
        identity.confidence = CONFIRMED

    # 2. Engine and SDK files prove a game even with no store metadata.
    markers, engine = _scan_markers(folder)
    if markers:
        identity.engine = engine
        identity.reasons.extend(markers)
        if identity.confidence != CONFIRMED:
            identity.confidence = CONFIRMED

    # 3. The executable's version resource: best source of a real title.
    if executable:
        info = read_version_info(executable)
        company = info.get("CompanyName", "")
        product = info.get("ProductName", "")
        if not product:
            description = info.get("FileDescription", "")
            # Remedy's Control writes "Game_rmdwin10_f.exe" here; a filename is
            # never the title we want to show.
            if description and not _looks_like_filename(description):
                product = description

        if company and _NON_GAME_PUBLISHERS.search(company) and not markers:
            identity.confidence = NOT_A_GAME
            identity.reasons.append(f"publisher: {company}")

        if product and _LAUNCHER_NAMES.match(product):
            identity.confidence = NOT_A_GAME
            identity.reasons.append(f"launcher/client: {product}")
        elif product and _TOOL_NAMES.search(product):
            identity.confidence = NOT_A_GAME
            identity.reasons.append(f"utility: {product}")
        elif product and not _looks_like_placeholder(product):
            if identity.confidence == UNCERTAIN:
                # A real product name is a decent hint, short of proof.
                identity.confidence = LIKELY
                identity.reasons.append("executable product name")
            identity.publisher = company

            # Only take the name when it beats the folder name. Some games
            # ship an internal codename ("Pal" for Palworld) or literally the
            # filename in FileDescription, both worse than the folder.
            if _is_better_title(product, fallback):
                identity.display_name = _normalize_case(product)
                identity.source = "exe"


    return identity


def _looks_like_filename(value: str) -> bool:
    """True when a version-resource string is really a file name."""
    return bool(re.search(r"\.(exe|dll|bin)$", value.strip(), re.IGNORECASE))


def _is_better_title(product: str, folder_title: str) -> bool:
    """Decide whether the executable's title beats the cleaned folder name.

    A codename like "Pal" that the folder already spells out as "Palworld"
    is worse, so keep the folder in that case.
    """
    candidate = product.strip()
    if not candidate or _looks_like_filename(candidate):
        return False

    folder = folder_title.strip()
    if not folder:
        return True

    squashed_candidate = re.sub(r"[^a-z0-9]", "", candidate.lower())
    squashed_folder = re.sub(r"[^a-z0-9]", "", folder.lower())
    if not squashed_candidate:
        return False

    # Reject only genuine codenames: a short prefix of the folder name, such
    # as "Pal" for "Palworld". A fuller title that happens to start the same
    # way ("Halo Campaign Evolved" vs the folder's "... Premium Edition") is
    # still the better name.
    if squashed_folder.startswith(squashed_candidate):
        missing = len(squashed_folder) - len(squashed_candidate)
        if len(squashed_candidate) < 8 and missing >= 3:
            return False

    return True


def _normalize_case(name: str) -> str:
    """Title-case a SHOUTED product name, leaving deliberate casing alone.

    "METAL GEAR SOLID 4 GUNS OF THE PATRIOTS" reads better title-cased, but
    "S.T.A.L.K.E.R." and "DOOM" must survive untouched.
    """
    letters = [c for c in name if c.isalpha()]
    if not letters or not all(c.isupper() for c in letters):
        return name
    # Short all-caps titles are usually stylised on purpose (DOOM, RAGE).
    if len(name.split()) <= 2:
        return name
    if re.search(r"(?:[A-Za-z]\.){2,}", name):
        return name

    minor = {"of", "the", "and", "in", "on", "a", "an", "to", "for", "vs"}
    words = name.split()
    out = []
    for index, word in enumerate(words):
        lowered = word.lower()
        if index > 0 and lowered in minor:
            out.append(lowered)
        elif word.isdigit() or len(word) <= 1:
            out.append(word)
        else:
            out.append(word.capitalize())
    return " ".join(out)


def _looks_like_placeholder(product: str) -> bool:
    """True for generic engine defaults that are not the game's title."""
    generic = {
        "unrealgame", "ue4game", "ue5game", "unreal engine", "unity",
        "shipping", "game", "myproject", "windowsnoeditor", "defaultcompany",
    }
    return product.strip().lower() in generic
