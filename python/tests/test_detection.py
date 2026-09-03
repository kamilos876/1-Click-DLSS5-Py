"""Detection tests: synthetic fixtures plus a live probe of real installs."""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core import constants as C
from core.detection import (
    DetectionError,
    detect_graphics_api,
    detect_upscaler_type,
    resolve_game_target,
)
from core.messages import render
from core.utils import is_x64_pe, pe_imported_dlls
from core.scanner import candidate_dirs, classify

# Minimal 64-bit PE: MZ header, e_lfanew at 0x40, PE signature, AMD64 machine.
_PE64 = bytearray(512)
_PE64[0:2] = b"MZ"
_PE64[60:64] = (0x80).to_bytes(4, "little")
_PE64[0x80:0x84] = b"PE\0\0"
_PE64[0x84:0x86] = (0x8664).to_bytes(2, "little")

_PE32 = bytearray(_PE64)
_PE32[0x84:0x86] = (0x014C).to_bytes(2, "little")  # IMAGE_FILE_MACHINE_I386


def _write_exe(path: Path, x64: bool = True, pad: int = 0) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(_PE64 if x64 else _PE32) + b"\0" * pad)


def test_folder_name_match_wins(tmp: Path) -> None:
    game = tmp / "Icarus"
    _write_exe(game / "Icarus.exe")
    _write_exe(game / "SomeOther.exe")
    target = resolve_game_target(str(game))
    assert target.exe_name == "Icarus.exe", target.exe_name
    assert target.install_folder == game


def test_launcher_is_ignored(tmp: Path) -> None:
    game = tmp / "MyGame"
    _write_exe(game / "MyGameLauncher.exe", pad=50 * 1024 * 1024)
    _write_exe(game / "Binaries" / "Win64" / "MyGame-Win64-Shipping.exe")
    target = resolve_game_target(str(game))
    assert "Launcher" not in target.exe_name, target.exe_name


def test_unreal_binaries_win64_preferred(tmp: Path) -> None:
    game = tmp / "UEProject"
    _write_exe(game / "Start.exe")
    _write_exe(game / "Binaries" / "Win64" / "Shipping.exe")
    target = resolve_game_target(str(game))
    assert "Win64" in str(target.install_folder), target.install_folder


def test_32bit_exe_is_accepted(tmp: Path) -> None:
    """A 32-bit game is injectable: the Feeder ships an addon32 and a host."""
    exe = tmp / "old32.exe"
    _write_exe(exe, x64=False)
    target = resolve_game_target(str(exe))
    assert target.executable == exe
    assert not is_x64_pe(exe)


def test_non_executable_is_rejected(tmp: Path) -> None:
    """Accepting 32-bit must not mean accepting anything that ends in .exe."""
    fake = tmp / "notreally.exe"
    fake.write_bytes(b"this is not a PE image at all")
    try:
        resolve_game_target(str(fake))
    except DetectionError as err:
        assert err.message.key == "NotAWindowsExe", err.message.key
    else:
        raise AssertionError("expected DetectionError for a non-PE file")


def test_64bit_outranks_32bit_when_both_ship(tmp: Path) -> None:
    """A game shipping both keeps the 32-bit copy for legacy hardware."""
    game = tmp / "DualArch"
    _write_exe(game / "bin" / "win32" / "DualArch.exe", x64=False)
    _write_exe(game / "bin" / "win64" / "DualArch.exe", x64=True)
    target = resolve_game_target(str(game))
    assert "win64" in str(target.executable).lower(), target.executable


def test_missing_path_raises(tmp: Path) -> None:
    try:
        resolve_game_target(str(tmp / "does-not-exist"))
    except DetectionError:
        pass
    else:
        raise AssertionError("expected DetectionError for a missing path")


def test_upscaler_priority(tmp: Path) -> None:
    game = tmp / "PriorityGame"
    _write_exe(game / "PriorityGame.exe")
    assert detect_upscaler_type(game, game) == C.UNIVERSAL_FEEDER

    (game / "libxess.dll").write_bytes(b"x")
    assert detect_upscaler_type(game, game) == C.XESS_BRIDGE

    (game / "ffx_fsr2_api_x64.dll").write_bytes(b"x")
    assert detect_upscaler_type(game, game) == C.FSR2_BRIDGE

    (game / "nvngx_dlss.dll").write_bytes(b"x")
    assert detect_upscaler_type(game, game) == C.NATIVE_DLSS


def test_own_injected_files_are_not_counted(tmp: Path) -> None:
    """A previous Feeder install must not be misread as native DLSS."""
    game = tmp / "FeederInstalled"
    _write_exe(game / "FeederInstalled.exe")
    shaders = game / "reshade-shaders" / "Shaders"
    shaders.mkdir(parents=True)
    (shaders / "nvngx_dlss.dll").write_bytes(b"x")
    host = game / "host64"
    host.mkdir()
    (host / "sl.interposer.dll").write_bytes(b"x")
    assert detect_upscaler_type(game, game) == C.UNIVERSAL_FEEDER


# --- launcher and store folder layouts --------------------------------------

def test_steam_library_is_opened(tmp: Path) -> None:
    """Steam keeps its games three levels down, under steamapps/common."""
    common = tmp / "Steam" / "steamapps" / "common"
    for name in ("Fallout 4", "Stray"):
        _write_exe(common / name / f"{name}.exe")
    (tmp / "Steam" / "steam.exe").write_bytes(bytes(_PE64))

    found = {d.name for d in candidate_dirs(tmp / "Steam")}
    assert found == {"Fallout 4", "Stray"}, found


def test_ubisoft_games_subfolder_is_opened(tmp: Path) -> None:
    """Ubisoft Connect nests its games under games/."""
    root = tmp / "Ubisoft Game Launcher"
    for name in ("Assassin's Creed II", "The Division"):
        _write_exe(root / "games" / name / "game.exe")
    _write_exe(root / "upc.exe")

    found = {d.name for d in candidate_dirs(root)}
    assert found == {"Assassin's Creed II", "The Division"}, found


def test_publisher_folder_lists_each_game(tmp: Path) -> None:
    """Rockstar Games holds several games beside its own launcher binaries."""
    root = tmp / "Rockstar Games"
    for name in ("Red Dead Redemption", "Red Dead Redemption 2"):
        _write_exe(root / name / "game.exe")
    # The launcher's own files sit right next to them.
    _write_exe(root / "Launcher.exe")
    (root / "Launcher.rpf").write_bytes(b"x")

    found = {d.name for d in candidate_dirs(root)}
    assert "Red Dead Redemption" in found, found
    assert "Red Dead Redemption 2" in found, found


def test_nested_launchers_under_one_root(tmp: Path) -> None:
    """A user's own games folder holding several launchers must be unpacked."""
    root = tmp / "Gry"
    _write_exe(root / "Steam" / "steamapps" / "common" / "Stray" / "Stray.exe")
    _write_exe(root / "Rockstar Games" / "Red Dead Redemption" / "RDR.exe")
    _write_exe(root / "Control" / "Control.exe")

    found = {d.name for d in candidate_dirs(root)}
    assert "Stray" in found, found
    assert "Red Dead Redemption" in found, found
    assert "Control" in found, found
    # The launcher roots themselves must not be listed as games.
    assert "Steam" not in found and "Rockstar Games" not in found, found


def test_game_folder_is_not_split_into_its_subfolders(tmp: Path) -> None:
    """A game's own Data/Binaries folders must never be listed as games."""
    game = tmp / "SomeGame"
    _write_exe(game / "SomeGame.exe")
    (game / "Data").mkdir()
    (game / "Binaries").mkdir()

    found = {d.name for d in candidate_dirs(game)}
    assert "Data" not in found and "Binaries" not in found, found


def test_classify_ignores_third_party_dlss_logs(tmp: Path) -> None:
    """A mod's dlss-enabler.log must not grade a game as having native DLSS.

    Dying Light ships one and was wrongly marked "100% COMPATIBLE".
    """
    game = tmp / "NoDlssGame"
    _write_exe(game / "NoDlssGame.exe")
    (game / "dlss-enabler.log").write_text("log", encoding="utf-8")
    (game / "dlss-enabler.ini").write_text("cfg", encoding="utf-8")
    (game / "readme-dlss.txt").write_text("notes", encoding="utf-8")

    badge, order = classify(game)
    assert badge == "BadgeFeeder", f"{badge}: a log file is not a DLSS runtime"
    assert order == 3


def test_classify_finds_real_dlss_runtime(tmp: Path) -> None:
    game = tmp / "DlssGame"
    _write_exe(game / "DlssGame.exe")
    (game / "nvngx_dlss.dll").write_bytes(b"x")
    assert classify(game) == ("Badge100", 1)


def test_classify_finds_fsr_and_xess(tmp: Path) -> None:
    fsr = tmp / "FsrGame"
    _write_exe(fsr / "FsrGame.exe")
    (fsr / "ffx_fsr2_api_x64.dll").write_bytes(b"x")
    assert classify(fsr) == ("BadgeBridge", 2)

    xess = tmp / "XessGame"
    _write_exe(xess / "XessGame.exe")
    (xess / "libxess.dll").write_bytes(b"x")
    assert classify(xess) == ("BadgeBridge", 2)


def test_api_opengl_from_exe_name(tmp: Path) -> None:
    game = tmp / "PZ"
    _write_exe(game / "ProjectZomboid64.exe")
    assert detect_graphics_api(game / "ProjectZomboid64.exe") == C.API_OPENGL


def test_api_opengl_from_lwjgl_library(tmp: Path) -> None:
    game = tmp / "JavaGame"
    _write_exe(game / "JavaGame.exe")
    (game / "lwjgl64.dll").write_bytes(b"x")
    assert detect_graphics_api(game / "JavaGame.exe") == C.API_OPENGL


def test_api_d3d12_for_unreal_layout(tmp: Path) -> None:
    exe = tmp / "Shipping" / "Binaries" / "Win64" / "Game.exe"
    _write_exe(exe)
    assert detect_graphics_api(exe) == C.API_D3D12


def test_api_d3d9_only_without_modern_runtime(tmp: Path) -> None:
    game = tmp / "OldGame"
    _write_exe(game / "OldGame.exe")
    (game / "d3dx9_43.dll").write_bytes(b"x")
    assert detect_graphics_api(game / "OldGame.exe") == C.API_D3D9

    # A modern DirectX runtime beside it means d3d9 is only a leftover helper.
    (game / "d3d12.dll").write_bytes(b"x")
    assert detect_graphics_api(game / "OldGame.exe") == C.API_DXGI


def test_api_vulkan_detected(tmp: Path) -> None:
    game = tmp / "VkGame"
    _write_exe(game / "VkGame.exe")
    (game / "vulkan-1.dll").write_bytes(b"x")
    assert detect_graphics_api(game / "VkGame.exe") == C.API_VULKAN


def test_api_defaults_to_dxgi(tmp: Path) -> None:
    game = tmp / "ModernGame"
    _write_exe(game / "ModernGame.exe")
    assert detect_graphics_api(game / "ModernGame.exe") == C.API_DXGI


def test_game_named_after_an_ignored_keyword_survives(tmp: Path) -> None:
    """The keyword list is substring-matched, so a title may collide with it.

    "Tools Up!" ships Tools Up.exe, which contains "tool" -- one of the keywords
    meant to skip utilities. A binary named after its own folder is the game.
    """
    game = tmp / "Tools Up!"
    _write_exe(game / "Tools Up.exe")
    _write_exe(game / "UnityCrashHandler64.exe", pad=40 * 1024 * 1024)
    target = resolve_game_target(str(game))
    assert target.exe_name == "Tools Up.exe", target.exe_name


def _write_importing_exe(path: Path, dll_names: list[str]) -> None:
    """Write a real PE image whose import directory names ``dll_names``."""
    import struct

    section_rva, section_raw = 0x1000, 0x400
    blob = bytearray()
    offsets: dict[str, int] = {}
    for name in dll_names:
        offsets[name] = len(blob)
        blob += name.encode() + b"\0"
    descriptors = len(blob) + (-len(blob)) % 4
    blob += b"\0" * (descriptors - len(blob))
    for name in dll_names:
        blob += struct.pack("<IIIII", 0, 0, 0, section_rva + offsets[name], 0)
    blob += b"\0" * 20   # terminating descriptor

    data = bytearray(section_raw + len(blob) + 16)
    data[0:2] = b"MZ"
    struct.pack_into("<i", data, 60, 0x80)
    pe = 0x80
    data[pe:pe + 4] = b"PE\0\0"
    struct.pack_into("<H", data, pe + 4, 0x8664)
    struct.pack_into("<H", data, pe + 6, 1)
    struct.pack_into("<H", data, pe + 20, 240)
    optional = pe + 24
    struct.pack_into("<H", data, optional, 0x20B)
    struct.pack_into("<I", data, optional + 112 + 8, section_rva + descriptors)
    section = optional + 240
    data[section:section + 8] = b".text\0\0\0"
    struct.pack_into("<IIII", data, section + 8, len(blob), section_rva, len(blob), section_raw)
    data[section_raw:section_raw + len(blob)] = blob

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(data))


def test_pe_imports_are_read_from_the_import_table(tmp: Path) -> None:
    """Dependencies come from the import directory, not from a string search."""
    exe = tmp / "forza.exe"
    _write_importing_exe(exe, ["libxess.dll", "kernel32.dll"])
    assert pe_imported_dlls(exe) == {"libxess.dll", "kernel32.dll"}


def test_a_mention_is_not_an_import(tmp: Path) -> None:
    """A binary that merely contains the text must not count as importing it."""
    exe = tmp / "mentions.exe"
    _write_importing_exe(exe, ["kernel32.dll"])
    exe.write_bytes(exe.read_bytes() + b"log: libxess.dll not found\0")
    assert "libxess.dll" not in pe_imported_dlls(exe)


def test_imports_of_a_non_pe_file_are_empty(tmp: Path) -> None:
    junk = tmp / "junk.exe"
    junk.write_bytes(b"not a PE at all")
    assert pe_imported_dlls(junk) == set()


def _run_synthetic() -> None:
    import tempfile

    tests = [
        test_folder_name_match_wins,
        test_launcher_is_ignored,
        test_unreal_binaries_win64_preferred,
        test_32bit_exe_is_accepted,
        test_non_executable_is_rejected,
        test_64bit_outranks_32bit_when_both_ship,
        test_game_named_after_an_ignored_keyword_survives,
        test_pe_imports_are_read_from_the_import_table,
        test_a_mention_is_not_an_import,
        test_imports_of_a_non_pe_file_are_empty,
        test_missing_path_raises,
        test_upscaler_priority,
        test_own_injected_files_are_not_counted,
        test_steam_library_is_opened,
        test_ubisoft_games_subfolder_is_opened,
        test_publisher_folder_lists_each_game,
        test_nested_launchers_under_one_root,
        test_game_folder_is_not_split_into_its_subfolders,
        test_classify_ignores_third_party_dlss_logs,
        test_classify_finds_real_dlss_runtime,
        test_classify_finds_fsr_and_xess,
        test_api_opengl_from_exe_name,
        test_api_opengl_from_lwjgl_library,
        test_api_d3d12_for_unreal_layout,
        test_api_d3d9_only_without_modern_runtime,
        test_api_vulkan_detected,
        test_api_defaults_to_dxgi,
    ]
    for func in tests:
        with tempfile.TemporaryDirectory() as raw:
            func(Path(raw))
        print(f"  PASS  {func.__name__}")


def _run_live(paths: list[str]) -> None:
    for raw in paths:
        path = Path(raw)
        if not path.exists():
            print(f"  SKIP  {raw} (not installed)")
            continue
        started = time.time()
        try:
            target = resolve_game_target(str(path))
            upscaler = detect_upscaler_type(target.install_folder, target.root)
            elapsed = time.time() - started
            print(f"  LIVE  {path.name}: {target.exe_name} | {upscaler} | {elapsed:.1f}s")
        except DetectionError as err:
            print(f"  LIVE  {path.name}: FAILED - {err}")


if __name__ == "__main__":
    print("Synthetic fixtures:")
    _run_synthetic()
    print("\nReal installs:")
    _run_live(sys.argv[1:])
    print("\ndetection OK")
