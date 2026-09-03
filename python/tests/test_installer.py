"""Install/restore round-trip tests against a synthetic game and payload."""
import sys
import shutil
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core import constants as C
from core import installer
from core.installer import (
    InstallState,
    check_compatibility,
    install_dlss5,
    is_installed,
    uninstall_dlss5,
)

_PE64 = bytearray(512)
_PE64[0:2] = b"MZ"
_PE64[60:64] = (0x80).to_bytes(4, "little")
_PE64[0x80:0x84] = b"PE\0\0"
_PE64[0x84:0x86] = (0x8664).to_bytes(2, "little")


def _write_exe(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(_PE64))


def _make_payload_zip(tmp: Path) -> Path:
    """A ZIP containing a valid 64-bit nvngx_dlssnr.dll, as prepare_payload expects."""
    staging = tmp / "zipsrc"
    staging.mkdir(parents=True, exist_ok=True)
    _write_exe(staging / "nvngx_dlssnr.dll")
    (staging / "nvngx_dlss.dll").write_bytes(b"payload-dlss")

    zip_path = tmp / "streamline.zip"
    with zipfile.ZipFile(zip_path, "w") as archive:
        archive.write(staging / "nvngx_dlssnr.dll", "nvngx_dlssnr.dll")
        archive.write(staging / "nvngx_dlss.dll", "nvngx_dlss.dll")
    return zip_path


def _isolate_cache(tmp: Path) -> None:
    """Point the payload cache at the temp dir so tests never touch LOCALAPPDATA."""
    C.CACHE_ROOT = tmp / "cache"


def test_feeder_install_and_restore(tmp: Path) -> None:
    game = tmp / "TestGame"
    _write_exe(game / "TestGame.exe")
    original_dll = game / "nvngx_dlss.dll"
    original_dll.write_bytes(b"ORIGINAL-GAME-DLL")

    zip_path = _make_payload_zip(tmp)
    _isolate_cache(tmp)

    upscaler = install_dlss5(
        target_path=str(game),
        dlss_zip_path=str(zip_path),
        install_reshade_runtime=False,
        full_package=False,
        selected_mode=C.MODE_FEEDER,
    )
    assert upscaler == C.UNIVERSAL_FEEDER, upscaler

    state = is_installed(game)
    assert state is not None, "state file was not written"
    assert state.mode == C.MODE_FEEDER, state.mode
    assert (game / "ReShade.ini").is_file()
    assert (game / "ReShadePreset.ini").is_file()
    assert (game / C.ADDON_NAME).is_file()

    # The game's own DLL was overwritten, so it must have been backed up first.
    assert "nvngx_dlss.dll" in state.backed_up_files, state.backed_up_files
    assert game / C.BACKUP_NAME / "nvngx_dlss.dll"

    uninstall_dlss5(str(game))

    assert original_dll.read_bytes() == b"ORIGINAL-GAME-DLL", "original DLL was not restored"
    assert not (game / C.STATE_NAME).exists()
    assert not (game / C.BACKUP_NAME).exists()
    assert not (game / "ReShade.ini").exists()
    assert not (game / "ReShadePreset.ini").exists()
    assert not (game / "reshade-shaders").exists()
    assert not (game / C.ADDON_NAME).exists()


def test_direct_install_backs_up_originals(tmp: Path) -> None:
    game = tmp / "DirectGame"
    _write_exe(game / "DirectGame.exe")
    (game / "nvngx_dlss.dll").write_bytes(b"GAME-NATIVE-DLSS")

    zip_path = _make_payload_zip(tmp)
    _isolate_cache(tmp)

    upscaler = install_dlss5(
        target_path=str(game),
        dlss_zip_path=str(zip_path),
        install_reshade_runtime=False,
        full_package=False,
        selected_mode=C.MODE_DIRECT,
    )
    assert upscaler == C.NATIVE_DLSS, upscaler
    assert (game / "nvngx_dlssnr.dll").is_file()

    uninstall_dlss5(str(game))
    assert (game / "nvngx_dlss.dll").read_bytes() == b"GAME-NATIVE-DLSS"


def test_reinstall_keeps_first_backup(tmp: Path) -> None:
    """A second install must not overwrite the backup with our own injected file."""
    game = tmp / "ReinstallGame"
    _write_exe(game / "ReinstallGame.exe")
    (game / "nvngx_dlss.dll").write_bytes(b"TRUE-ORIGINAL")

    zip_path = _make_payload_zip(tmp)
    _isolate_cache(tmp)

    for _ in range(2):
        install_dlss5(
            target_path=str(game),
            dlss_zip_path=str(zip_path),
            install_reshade_runtime=False,
            full_package=False,
            selected_mode=C.MODE_FEEDER,
        )

    backup = game / C.BACKUP_NAME / "nvngx_dlss.dll"
    assert backup.is_file(), "backup missing after reinstall"
    assert backup.read_bytes() == b"TRUE-ORIGINAL", "backup was clobbered by reinstall"

    uninstall_dlss5(str(game))
    assert (game / "nvngx_dlss.dll").read_bytes() == b"TRUE-ORIGINAL"


def test_state_roundtrip(tmp: Path) -> None:
    state = InstallState(
        installed_at="2026-08-31 12:00:00",
        target_exe=r"E:\Games\X\x.exe",
        mode=C.MODE_FEEDER,
        upscaler_type=C.UNIVERSAL_FEEDER,
        backed_up_files=["a.dll"],
        injected_files=["b.dll"],
    )
    path = tmp / C.STATE_NAME
    path.write_text(state.to_json(), encoding="utf-8")
    loaded = InstallState.load(path)
    assert loaded is not None
    assert loaded.mode == C.MODE_FEEDER
    assert loaded.backed_up_files == ["a.dll"]
    assert loaded.injected_files == ["b.dll"]


def test_state_load_tolerates_powershell_scalar(tmp: Path) -> None:
    """PowerShell serializes a one-element array as a bare string."""
    path = tmp / C.STATE_NAME
    path.write_text(
        '{"Mode":"FEEDER","BackedUpFiles":"only.dll","InjectedFiles":null}',
        encoding="utf-8-sig",
    )
    loaded = InstallState.load(path)
    assert loaded is not None
    assert loaded.backed_up_files == ["only.dll"]
    assert loaded.injected_files == []


def test_payload_falls_back_to_extracted_cache(tmp: Path) -> None:
    """A user who no longer has the ZIP can still install from an earlier run.

    The ZIP is only a delivery mechanism; once extracted and verified, the
    runtime it produced is enough to install from.
    """
    from core.payload import PayloadError, prepare_payload

    _isolate_cache(tmp)
    zip_path = _make_payload_zip(tmp)

    # First run extracts and caches the payload.
    first = prepare_payload(str(zip_path))
    assert (first.folder / "nvngx_dlssnr.dll").is_file()

    # The ZIP is gone, but the extracted cache remains.
    zip_path.unlink()
    second = prepare_payload("")
    assert second.folder == first.folder, second.folder
    assert (second.folder / "nvngx_dlssnr.dll").is_file()

    # With neither a ZIP nor a cache, it must still refuse rather than proceed.
    shutil.rmtree(C.CACHE_ROOT, ignore_errors=True)
    try:
        prepare_payload("")
    except PayloadError:
        pass
    else:
        raise AssertionError("expected PayloadError with no ZIP and no cache")


def test_backup_is_not_treated_as_a_plugin_folder(tmp: Path) -> None:
    """A reinstall must not nest a backup inside the previous one.

    Direct mode also updates engine plugin folders, found by looking for
    nvngx_dlss.dll under the game root. Our own backup holds a copy of that DLL,
    so it matched -- and got "updated", burying the game's real originals one
    level deeper on every reinstall, where a restore would never find them.
    """
    _isolate_cache(tmp)
    game = tmp / "PluginGame"
    _write_exe(game / "PluginGame.exe")
    (game / "nvngx_dlss.dll").write_bytes(b"ORIGINAL-GAME-DLL")
    zip_path = _make_payload_zip(tmp)

    for _ in range(3):
        install_dlss5(str(game), str(zip_path), False, True, C.MODE_DIRECT)

    nested = list(game.rglob(f"{C.BACKUP_NAME}/{C.BACKUP_NAME}"))
    assert not nested, f"backup nested inside backup: {nested}"

    uninstall_dlss5(str(game))
    restored = (game / "nvngx_dlss.dll").read_bytes()
    assert restored == b"ORIGINAL-GAME-DLL", restored


def test_restore_removes_injected_dlls_but_spares_the_game_s_own(tmp: Path) -> None:
    """Every injected DLL must go, and nothing the game shipped may go with it.

    nvngx_dlssg.dll and friends used to survive a restore because they were not
    on the purge list at all. Adding them there is only safe because a name a
    game may ship itself is deleted solely when this install recorded injecting
    it -- otherwise a full-package install over a game that shipped its own copy
    would delete a file it never backed up.
    """
    _isolate_cache(tmp)
    zip_path = _make_payload_zip(tmp)

    # A game shipping its own DLL, installed over WITHOUT that file in the
    # payload set: minimal mode never touches it, so no backup is taken.
    minimal = tmp / "MinimalGame"
    _write_exe(minimal / "MinimalGame.exe")
    (minimal / "nvngx_dlss.dll").write_bytes(b"GAME-OWN-DLL")
    install_dlss5(str(minimal), str(zip_path), False, False, C.MODE_DIRECT)
    uninstall_dlss5(str(minimal))
    assert (minimal / "nvngx_dlss.dll").read_bytes() == b"GAME-OWN-DLL"

    # A full install does inject it, so a restore must put the original back and
    # leave no injected leftovers behind.
    full = tmp / "FullGame"
    _write_exe(full / "FullGame.exe")
    (full / "nvngx_dlss.dll").write_bytes(b"GAME-OWN-DLL")
    install_dlss5(str(full), str(zip_path), False, True, C.MODE_DIRECT)
    uninstall_dlss5(str(full))
    assert (full / "nvngx_dlss.dll").read_bytes() == b"GAME-OWN-DLL"
    for leftover in ("nvngx_dlssnr.dll", "renodx-dlss5.addon64", "ReShade.ini"):
        assert not (full / leftover).exists(), f"{leftover} survived the restore"


def test_restore_spares_a_game_s_own_streamline(tmp: Path) -> None:
    """Titles that ship their own sl.*.dll must not lose it to a restore.

    The Witcher 3, Cyberpunk 2077 and STALKER 2 all ship Streamline. A minimal
    install never copies those files, so it never backs them up -- and the purge
    list names every one of them. Without GAME_OWNED_FILES covering the family,
    installing and then restoring deleted the game's own runtime for good.
    """
    _isolate_cache(tmp)
    zip_path = _make_payload_zip(tmp)
    shipped = ("sl.interposer.dll", "sl.common.dll", "sl.dlss.dll", "libxess.dll")

    game = tmp / "StreamlineGame"
    _write_exe(game / "StreamlineGame.exe")
    for name in shipped:
        (game / name).write_bytes(b"GAME-OWN")

    # Minimal: these are never touched, so they must simply survive.
    install_dlss5(str(game), str(zip_path), False, False, C.MODE_DIRECT)
    uninstall_dlss5(str(game))
    for name in shipped:
        assert (game / name).read_bytes() == b"GAME-OWN", name

    # Full: these are overwritten, so the backup must put the originals back.
    for name in shipped:
        (game / name).write_bytes(b"GAME-OWN")
    install_dlss5(str(game), str(zip_path), False, True, C.MODE_DIRECT)
    uninstall_dlss5(str(game))
    for name in shipped:
        assert (game / name).read_bytes() == b"GAME-OWN", name


def test_preflight_flags_a_running_game_and_an_unwritable_folder(tmp: Path) -> None:
    """Both conditions fail an install midway, so the check must catch them.

    A running game holds its DLLs open, and a folder needing elevation refuses
    the copy -- either way the injection stops with the folder half written.
    """
    import core.installer as installer_mod

    _isolate_cache(tmp)
    zip_path = _make_payload_zip(tmp)
    game = tmp / "PreflightGame"
    _write_exe(game / "PreflightGame.exe")

    # Healthy baseline: a real temp folder, nothing running.
    report = check_compatibility(str(game), str(zip_path))
    assert report.can_install, [m.key for m in report.fatal]

    original_writable = installer_mod.is_writable
    original_running = installer_mod.is_process_running
    try:
        installer_mod.is_writable = lambda folder: False
        report = check_compatibility(str(game), str(zip_path))
        assert not report.can_install
        assert any(m.key == "FolderNotWritable" for m in report.fatal), report.fatal

        installer_mod.is_writable = original_writable
        installer_mod.is_process_running = lambda name: True
        report = check_compatibility(str(game), str(zip_path))
        assert not report.can_install
        assert any(m.key == "GameIsRunning" for m in report.fatal), report.fatal
    finally:
        installer_mod.is_writable = original_writable
        installer_mod.is_process_running = original_running


def test_every_mode_ships_the_filters_but_only_feeder_runs_a_chain(tmp: Path) -> None:
    """CAS, SMAA, FXAA and friends belong with every install.

    They cost nothing switched off, they save the user hunting for shaders, and
    a populated effect path spares ReShade's "no effect files found" warning.
    What must NOT follow is a filter running by itself: only Feeder mode needs a
    technique active, because only it renders through a shader.
    """
    _isolate_cache(tmp)
    zip_path = _make_payload_zip(tmp)
    filters = {"CAS.fx", "SMAA.fx", "FXAA.fx", "Vibrance.fx", "Tonemap.fx"}

    for mode in (C.MODE_DIRECT, C.MODE_OPTISCALER, C.MODE_FEEDER):
        game = tmp / f"Game_{mode}"
        _write_exe(game / "Game.exe")
        install_dlss5(str(game), str(zip_path), False, False, mode)

        shaders = game / "reshade-shaders" / "Shaders"
        present = {path.name for path in shaders.glob("*.fx")}
        assert filters <= present, f"{mode}: missing {sorted(filters - present)}"

        preset = game / "ReShadePreset.ini"
        assert preset.is_file(), f"{mode}: no preset written"
        active = next(
            line
            for line in preset.read_text(encoding="utf-8").splitlines()
            if line.startswith("Techniques=")
        )
        if mode == C.MODE_FEEDER:
            assert "DLSS5_Feed" in active, active
        else:
            assert active == "Techniques=", f"{mode}: {active!r} should be empty"
        # Nothing optional may be switched on by itself in any mode.
        for name in ("CAS", "SMAA", "FXAA", "Vibrance", "Tonemap"):
            assert name not in active, f"{mode}: {name} enabled by default"


if __name__ == "__main__":
    tests = [
        test_feeder_install_and_restore,
        test_direct_install_backs_up_originals,
        test_reinstall_keeps_first_backup,
        test_state_roundtrip,
        test_state_load_tolerates_powershell_scalar,
        test_payload_falls_back_to_extracted_cache,
        test_backup_is_not_treated_as_a_plugin_folder,
        test_restore_removes_injected_dlls_but_spares_the_game_s_own,
        test_restore_spares_a_game_s_own_streamline,
        test_preflight_flags_a_running_game_and_an_unwritable_folder,
        test_every_mode_ships_the_filters_but_only_feeder_runs_a_chain,
    ]
    original_cache = C.CACHE_ROOT
    for func in tests:
        with tempfile.TemporaryDirectory() as raw:
            try:
                func(Path(raw))
            finally:
                C.CACHE_ROOT = original_cache
        print(f"  PASS  {func.__name__}")
    print("installer OK")
