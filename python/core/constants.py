"""Static configuration: product metadata, payload file lists and game profiles."""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

PRODUCT_NAME = "1 Click DLSS 5"
VERSION = "1.5.0"

ADDON_NAME = "renodx-dlss5.addon64"
ADDON_HASH = "E1C28FDE0922B12FC10734E58C3D24A36808E575247F4FD4F36226540D7EE023"

RESHADE_URL = "https://reshade.me/downloads/ReShade_Setup_6.8.0_Addon.exe"
RESHADE_HASH = "AFE4C8F13048306307983B8B3D41D5BF00A86820440B0E57DEA10950E1176445"
RESHADE_SETUP_NAME = "ReShade_Setup_6.8.0_Addon.exe"

STATE_NAME = "_1Click_DLSS5_State.json"
BACKUP_NAME = "_1Click_DLSS5_Backup"

# Application root: the folder that holds payload/ and assets/. Since v1.5.0 the
# PowerShell edition keeps those under core/, so probe there before falling back
# to the repository root used by earlier layouts.
REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def _resolve_app_root() -> Path:
    for candidate in (REPO_ROOT / "core", REPO_ROOT):
        if (candidate / "payload").is_dir():
            return candidate
    return REPO_ROOT / "core"


APP_ROOT = _resolve_app_root()
PAYLOAD_ROOT = APP_ROOT / "payload"
ASSETS_ROOT = APP_ROOT / "assets"
ICON_PATH = ASSETS_ROOT / "logo.ico"
CACHE_ROOT = Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "1ClickDLSS5"

# Injection modes as stored in the per-game state file.
MODE_AUTO = "AUTO"
MODE_DIRECT = "DIRECT"
MODE_OPTISCALER = "OPTISCALER"
MODE_FEEDER = "FEEDER"

# Graphics APIs a game can present with; each maps onto the ReShade proxy DLL
# name the runtime must be installed as.
API_OPENGL = "OPENGL"
API_D3D9 = "D3D9"
API_D3D12 = "D3D12"
API_VULKAN = "VULKAN"
API_DXGI = "DXGI"

# Proxy DLL ReShade loads under for each API. DXGI covers DirectX 10/11/12 and
# Vulkan, which ReShade hooks through its own layer rather than a proxy.
API_PROXY_DLL = {
    API_OPENGL: "opengl32.dll",
    API_D3D9: "d3d9.dll",
    API_D3D12: "d3d12.dll",
    API_VULKAN: "dxgi.dll",
    API_DXGI: "dxgi.dll",
}

# --api flag passed to the headless ReShade installer.
API_INSTALLER_FLAG = {
    API_OPENGL: "opengl",
    API_D3D9: "d3d9",
    API_D3D12: "d3d12",
    API_VULKAN: "vulkan",
    API_DXGI: "dxgi",
}

# Executable names that identify an OpenGL renderer outright.
OPENGL_EXE_HINTS = [
    "projectzomboid", "minecraft", "javaw.exe", "wolfneworder",
    "wolfoldblood", "rage.exe", "cemu.exe", "yuzu.exe", "ryujinx.exe",
    "citra.exe",
]

# Path fragments that mark an engine needing d3d12.dll for direct injection.
D3D12_PATH_HINTS = [r"binaries\win64", "htgame", "hitman"]

# Upscaler families detected in a game folder.
NATIVE_DLSS = "NATIVE_DLSS"
FSR2_BRIDGE = "FSR2_BRIDGE"
XESS_BRIDGE = "XESS_BRIDGE"
UNIVERSAL_FEEDER = "UNIVERSAL_FEEDER"

MINIMAL_FILES = [
    "renodx-dlss5.addon64",
    "nvngx_dlssnr.dll",
]

FULL_FILES = [
    "renodx-dlss5.addon64",
    "nvngx_dlssnr.dll",
    "sl.dlss_nr.dll",
    "sl.common.dll",
    "sl.interposer.dll",
    "sl.deepdvc.dll",
    "sl.dlss.dll",
    "sl.dlss_d.dll",
    "sl.dlss_g.dll",
    "sl.nis.dll",
    "sl.pcl.dll",
    "sl.reflex.dll",
    "nvngx_dlss.dll",
    "nvngx_dlssd.dll",
    "nvngx_dlssg.dll",
]

OPTISCALER_FILES = [
    "version.dll",
    "OptiScaler.ini",
    "libxess.dll",
]

FEEDER_FILES = [
    "dlss5-feed.addon64",
    "dlss5-feed.addon32",
    "dlss5-feed.cfg",
    "nvngx_dlss.dll",
    "nvngx_dlssnr.dll",
    "renodx-dlss5.addon64",
]

# Addon names shipped by older releases; removed before a fresh install.
LEGACY_ADDONS = [
    "renodx-dlss5++.addon64",
    "renodx-dlss5-v3.addon64",
]

# Everything a factory restore may delete when it is not a backed-up original.
PURGE_LIST = [
    "opengl32.dll", "d3d9.dll", "d3d12.dll", "dxgi.dll",
    "renodx-dlss5.addon64", "renodx-dlss5++.addon64", "renodx-dlss5-v3.addon64",
    "dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg",
    "dlss5-feed.log", "dlss5-feed.ini",
    "nvngx_dlssnr.dll", "sl.dlss_nr.dll",
    "nvngx_dlss.dll", "nvngx_dlssd.dll", "nvngx_dlssg.dll", "libxess.dll",
    "version.dll", "OptiScaler.ini", "OptiScaler.log",
    "ReShade.ini", "ReShadePreset.ini", "ReShade.log",
    "sl.common.dll", "sl.interposer.dll", "sl.deepdvc.dll",
    "sl.dlss.dll", "sl.dlss_d.dll", "sl.dlss_g.dll",
    "sl.nis.dll", "sl.pcl.dll", "sl.reflex.dll",
    "sl.config.json", "sl.param.global.log",
    STATE_NAME,
    "_DLSS5_Easy_Installer_State.json", "dlss5_backup_manifest.json",
]

# Names a game may legitimately ship itself. A restore only deletes one of these
# when this install is recorded as having injected it -- otherwise a game that
# shipped its own copy, and was installed over without a backup being taken,
# would lose the file for good.
GAME_OWNED_FILES = {
    "nvngx_dlss.dll",
    "nvngx_dlssd.dll",
    "nvngx_dlssg.dll",
    "libxess.dll",
}

# Files removed before a Direct-mode install so Feeder/OptiScaler hooks cannot clash.
CONFLICTS_FOR_DIRECT = [
    "dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg",
    "dlss5-feed.log", "dlss5-feed.ini",
    "version.dll", "OptiScaler.ini", "OptiScaler.log",
]

# Files removed before an OptiScaler-mode install.
CONFLICTS_FOR_OPTISCALER = [
    "dlss5-feed.addon64", "dlss5-feed.addon32", "dlss5-feed.cfg",
    "dlss5-feed.log", "dlss5-feed.ini",
    "sl.interposer.dll", "sl.common.dll", "sl.dlss_nr.dll", "sl.dlss.dll",
    "sl.dlss_g.dll", "sl.nis.dll", "sl.pcl.dll", "sl.reflex.dll",
    "sl.config.json",
]

# Files removed before a Feeder-mode install.
CONFLICTS_FOR_FEEDER = [
    "sl.interposer.dll", "sl.common.dll", "sl.dlss.dll", "sl.dlss_g.dll",
    "sl.dlss_nr.dll", "sl.pcl.dll", "sl.reflex.dll", "sl.nis.dll",
    "sl.config.json", "version.dll", "OptiScaler.ini", "OptiScaler.log",
    "d3d12.dll",
]

# Executable name fragments that never identify the main game binary.
IGNORED_EXE_KEYWORDS = [
    "unins", "crash", "setup", "helper", "launcher", "redist", "patcher",
    "_eac", "eac_", "easyanticheat", "battleye", "vanguard", "unitycrash",
    "crashreport", "directx", "vcredist", "dotnet", "report", "config",
    "benchmark", "tool", "dxgi", "d3d", "server", "dedicated", "startserver",
    # Xbox/GDK ships this stub beside the real binary.
    "gamelaunchhelper",
]

# Library subfolders that are never games.
IGNORED_GAME_DIRS = [
    "steamworks shared", "_commonredist", "directx", "vcredist", "dotnet",
    "crashreport", "tools", "easyanticheat", "battleye",
    # Store-managed folders that sit beside real installs.
    "gamesave", "gamesaves", "savegames", "minecraft launcher",
    ".egstore", "epic online services", "directxredist", "_redist",
    # Development and system clutter, in case a source folder is scanned.
    "__pycache__", ".git", ".svn", ".idea", ".vscode", "node_modules",
    "venv", ".venv", "site-packages", "$recycle.bin",
    "system volume information", "windows", "temp", "tmp",
]

# Store layouts probed on every fixed drive during a library scan.
GAME_LIBRARY_SUBPATHS = [
    "Games",
    "Jogos",
    r"Steam\steamapps\common",
    r"SteamLibrary\steamapps\common",
    r"Program Files (x86)\Steam\steamapps\common",
    r"Program Files\Steam\steamapps\common",
    r"Program Files\Epic Games",
    "Epic Games",
    "XboxGames",
]


@dataclass(frozen=True)
class GameProfile:
    """Hand-tuned executable resolution for games the heuristic gets wrong."""

    id: str
    display_name: str
    folder_hints: list[str] = field(default_factory=list)
    executable_names: list[str] = field(default_factory=list)
    preferred_relative_paths: list[str] = field(default_factory=list)


GAME_PROFILES = [
    GameProfile(
        id="hitmanwoa",
        display_name="HITMAN World of Assassination",
        folder_hints=["HITMAN World of Assassination", "HITMAN 3", "Hitman3"],
        executable_names=["HITMAN3.exe", "HITMAN.exe"],
        preferred_relative_paths=[r"Retail\HITMAN3.exe", r"Retail\HITMAN.exe"],
    ),
    GameProfile(
        id="forzahorizon",
        display_name="Forza Horizon",
        folder_hints=["Forza Horizon 6", "Forza Horizon 5", "ForzaHorizon5", "ForzaHorizon6"],
        executable_names=["forzahorizon6.exe", "ForzaHorizon6.exe", "ForzaHorizon5.exe"],
        preferred_relative_paths=["forzahorizon6.exe", "ForzaHorizon6.exe", "ForzaHorizon5.exe"],
    ),
    GameProfile(
        id="7daystodie",
        display_name="7 Days To Die",
        folder_hints=["7 Days To Die", "7DaysToDie"],
        executable_names=["7DaysToDie.exe"],
        preferred_relative_paths=["7DaysToDie.exe"],
    ),
    GameProfile(
        id="cyberpunk",
        display_name="Cyberpunk 2077",
        folder_hints=["Cyberpunk 2077", "Cyberpunk2077"],
        executable_names=["Cyberpunk2077.exe"],
        preferred_relative_paths=[r"bin\x64\Cyberpunk2077.exe"],
    ),
    GameProfile(
        id="starfield",
        display_name="Starfield",
        folder_hints=["Starfield"],
        executable_names=["Starfield.exe"],
        preferred_relative_paths=["Starfield.exe"],
    ),
    GameProfile(
        id="control",
        display_name="Control (DX12)",
        folder_hints=["Control"],
        executable_names=["Control_DX12.exe", "Control.exe"],
        preferred_relative_paths=["Control_DX12.exe", "Control.exe"],
    ),
    GameProfile(
        id="msfs2024",
        display_name="Microsoft Flight Simulator 2024",
        folder_hints=["Microsoft Flight Simulator 2024", "Limitless", "MSFS2024"],
        executable_names=["FlightSimulator2024.exe", "FlightSimulator.exe"],
        preferred_relative_paths=[
            "FlightSimulator2024.exe",
            r"Content\FlightSimulator2024.exe",
        ],
    ),
]
