"""Locating a game's real executable and identifying its upscaler family."""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from . import constants as C
from .messages import Message, msg
from .utils import is_x64_pe, iter_files, sanitize_path


class DetectionError(Exception):
    """Raised when a path cannot be resolved to an injectable game.

    Carries a Message rather than a sentence so the UI can render it in
    whatever language the user picked.
    """

    def __init__(self, message: Message) -> None:
        super().__init__(message.key)
        self.message = message


@dataclass
class GameTarget:
    """A resolved game: where it lives and which binary receives the injection."""

    root: Path
    executable: Path
    install_folder: Path
    existing_dlss_dll: Path | None = None

    @property
    def exe_name(self) -> str:
        return self.executable.name


# DLL names that prove each upscaler family is present, in priority order.
_NATIVE_DLSS_RE = re.compile(
    r"^(nvngx_dlss\.dll|nvngx_dlssd\.dll|nvngx_dlssg\.dll"
    r"|sl\.dlss\.dll|sl\.interposer\.dll|_nvngx\.dll)$",
    re.IGNORECASE,
)
_FSR_RE = re.compile(
    r"^(ffx_fsr2_api.*\.dll|ffx_fsr3_api.*\.dll|amd_fidelityfx.*\.dll"
    r"|FSR2\.dll|ffx_backend_dx12\.dll)$",
    re.IGNORECASE,
)
_XESS_RE = re.compile(r"^(libxess\.dll|xess\.dll|libxell\.dll)$", re.IGNORECASE)

# Our own injected files must never count as the game's native upscaler.
_OWN_FILES_RE = re.compile(
    r"(_1Click_DLSS5|_DLSS5_|reshade-shaders|[\\/]host64[\\/])",
    re.IGNORECASE,
)


def resolve_game_target(target_path: str) -> GameTarget:
    """Resolve a file or folder into the executable DLSS 5 should be injected beside.

    A path to an .exe is used directly; a folder is matched against the curated
    profiles first, then scored heuristically.
    """
    clean = sanitize_path(target_path)
    if not clean:
        raise DetectionError(msg("SelectGameFirst"))

    item = Path(clean)
    if not item.exists():
        raise DetectionError(msg("PathNotFound", clean))

    if item.is_file():
        if item.suffix.lower() != ".exe":
            raise DetectionError(msg("NotAnExe"))
        if not is_x64_pe(item):
            raise DetectionError(msg("Not64Bit"))
        target_root = item.parent
        target_exe: Path | None = item
    else:
        target_root = item
        target_exe = _match_profile(target_root) or _best_scored_exe(target_root)

    if target_exe is None:
        raise DetectionError(msg("NoMainExe"))

    install_folder = target_exe.parent
    return GameTarget(
        root=target_root,
        executable=target_exe,
        install_folder=install_folder,
        existing_dlss_dll=_find_existing_dlss(target_root, install_folder),
    )


def _match_profile(target_root: Path) -> Path | None:
    """Use a curated profile when the folder name identifies a known game."""
    root_lower = str(target_root).lower()
    for profile in C.GAME_PROFILES:
        if not any(hint.lower() in root_lower for hint in profile.folder_hints):
            continue
        for relative in profile.preferred_relative_paths:
            candidate = target_root / relative
            if candidate.is_file():
                return candidate
    return None


def _best_scored_exe(target_root: Path) -> Path | None:
    """Score every plausible 64-bit .exe and return the strongest candidate.

    Points favour a name matching the folder, engine-standard binary
    directories, and large files — launchers and crash handlers are excluded.
    """
    folder_key = target_root.name.lower().replace(" ", "")
    best: tuple[int, Path] | None = None

    # Depth 5 covers Xbox/GDK layouts, which bury the binary under
    # Content\<Project>\Binaries\WinGDK\. Note that Game Pass titles are
    # encrypted on disk: their PE headers do not parse, so they resolve to
    # nothing here — those games cannot be injected at all.
    for exe in iter_files(target_root, "*.exe", max_depth=5):
        name_lower = exe.name.lower()
        if any(keyword in name_lower for keyword in C.IGNORED_EXE_KEYWORDS):
            continue
        if not is_x64_pe(exe):
            continue

        path_lower = str(exe).lower()
        score = 10

        stem = name_lower.replace(".exe", "").replace(" ", "")
        if stem == folder_key:
            score += 100
        elif folder_key and folder_key in name_lower:
            score += 60

        if "binaries\\win64" in path_lower:
            score += 80
        elif "binaries\\wingdk" in path_lower:
            score += 80
        elif "bin\\x64" in path_lower:
            score += 70
        elif "retail" in path_lower:
            score += 60
        elif "content" in path_lower:
            score += 40

        try:
            size = exe.stat().st_size
        except OSError:
            size = 0
        if size > 20 * 1024 * 1024:
            score += 30
        elif size > 5 * 1024 * 1024:
            score += 15

        if best is None or score > best[0]:
            best = (score, exe)

    return best[1] if best else None


def _find_existing_dlss(target_root: Path, install_folder: Path) -> Path | None:
    """Locate a pre-existing nvngx_dlss DLL shipped by the game."""
    direct = install_folder / "nvngx_dlss.dll"
    if direct.is_file():
        return direct
    for found in iter_files(target_root, "nvngx_dlss*.dll", max_depth=12):
        return found
    return None


def detect_upscaler_type(game_folder: str | Path, game_root: str | Path = "") -> str:
    """Classify which upscaler a game ships, deciding the default injection mode.

    Native DLSS wins over FSR, which wins over XeSS; anything else falls back to
    the Universal Feeder, which works on any renderer.
    """
    search_dirs: list[Path] = []

    if game_root:
        root_path = Path(game_root)
        if root_path.is_dir():
            search_dirs.append(root_path)

    folder = Path(game_folder)
    if folder.is_dir():
        if folder not in search_dirs:
            search_dirs.append(folder)
        if not game_root:
            search_dirs.extend(_walk_up_from(folder))

    names: list[str] = []
    for directory in search_dirs:
        for dll in iter_files(directory, "*.dll", max_depth=12):
            if _OWN_FILES_RE.search(str(dll)):
                continue
            names.append(dll.name)

    if any(_NATIVE_DLSS_RE.match(name) for name in names):
        return C.NATIVE_DLSS
    if any(_FSR_RE.match(name) for name in names):
        return C.FSR2_BRIDGE
    if any(_XESS_RE.match(name) for name in names):
        return C.XESS_BRIDGE
    return C.UNIVERSAL_FEEDER


def detect_graphics_api(target_exe: str | Path, game_folder: str | Path = "") -> str:
    """Classify the renderer a game presents with, deciding the ReShade proxy DLL.

    ReShade only hooks a game when it loads under the DLL name that game's API
    actually imports, so an OpenGL title needs opengl32.dll and a DirectX 9 one
    d3d9.dll. Modern DirectX 10/11/12 titles are served by dxgi.dll, which is
    also the fallback when nothing more specific is proven.
    """
    exe = Path(target_exe)
    folder = Path(game_folder) if game_folder else exe.parent

    exe_lower = str(exe).lower()

    if any(hint in exe_lower for hint in C.OPENGL_EXE_HINTS):
        return C.API_OPENGL
    if _has_any(folder, ("*lwjgl*", "*glfw3*", "*opengl*.txt")):
        return C.API_OPENGL

    # Unreal and Glacier bury the binary under a path that identifies the engine;
    # both need the d3d12 proxy rather than dxgi to load at all.
    if any(hint in exe_lower for hint in C.D3D12_PATH_HINTS):
        return C.API_D3D12

    has_modern_dx = _has_any(folder, ("d3d11*.dll", "d3d12*.dll", "dxgi*.dll"))

    # A legacy DLL only proves the API when no modern DirectX runtime sits
    # beside it: many games ship d3d9 helpers they no longer render with.
    if not has_modern_dx:
        if _has_any(folder, ("d3d9*.dll", "d3dx9*.dll")):
            return C.API_D3D9
        if _has_any(folder, ("vulkan-1.dll",)):
            return C.API_VULKAN

    return C.API_DXGI


def _has_any(folder: Path, patterns: tuple[str, ...], max_depth: int = 2) -> bool:
    """True when any file matching one of ``patterns`` exists under ``folder``."""
    if not folder.is_dir():
        return False
    for pattern in patterns:
        for _ in iter_files(folder, pattern, max_depth=max_depth):
            return True
    return False


def _walk_up_from(folder: Path, levels: int = 4) -> list[Path]:
    """Walk up to ``levels`` parents, stopping at a drive or a Steam library root."""
    found: list[Path] = []
    current = folder
    for _ in range(levels):
        parent = current.parent
        if parent == current or not parent.is_dir():
            break
        parent_lower = str(parent).lower()
        if re.fullmatch(r"[a-z]:\\", parent_lower):
            break
        if parent_lower.endswith("\\common") or parent_lower.endswith("\\steamapps"):
            break
        found.append(parent)
        current = parent
    return found
