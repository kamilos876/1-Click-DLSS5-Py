"""Telling games apart from launchers, tools and installer folders."""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.gameinfo import (
    CONFIRMED,
    NOT_A_GAME,
    _is_better_title,
    _looks_like_filename,
    clean_folder_name,
    identify_game,
    looks_like_installer,
)

_PE64 = bytearray(512)
_PE64[0:2] = b"MZ"
_PE64[60:64] = (0x80).to_bytes(4, "little")
_PE64[0x80:0x84] = b"PE\0\0"
_PE64[0x84:0x86] = (0x8664).to_bytes(2, "little")


def _write_exe(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(_PE64))


# --- folder-name cleanup ----------------------------------------------------

def test_clean_scene_names() -> None:
    cases = [
        ("game-the.sinking.city.remastered-(88711)", "The Sinking City"),
        ("Metal.Gear.Solid.Master.Collection.Vol.1", "Metal Gear Solid Master Collection Vol 1"),
        ("Cyberpunk.2077.v2.1.REPACK-FitGirl", "Cyberpunk 2077"),
        ("Painkiller RTX [GOG]", "Painkiller RTX"),
    ]
    for raw, expected in cases:
        got = clean_folder_name(raw)
        assert got == expected, f"{raw!r} -> {got!r}, expected {expected!r}"


def test_clean_keeps_initialisms() -> None:
    """S.T.A.L.K.E.R. must not be flattened into spaced letters."""
    got = clean_folder_name("S.T.A.L.K.E.R. Shadow of Chernobyl")
    assert "S.T.A.L.K.E.R." in got, got


def test_clean_never_returns_empty() -> None:
    assert clean_folder_name("REPACK") == "REPACK"


# --- installer detection ----------------------------------------------------

def test_installer_folder_detected(tmp: Path) -> None:
    folder = tmp / "game-something-(12345)"
    folder.mkdir()
    for i in range(1, 6):
        (folder / f"setup_something_(12345)-{i}.bin").write_bytes(b"x")
    (folder / "setup_something.exe").write_bytes(b"x")
    assert looks_like_installer(folder) is True

    identity = identify_game(folder)
    assert identity.confidence == NOT_A_GAME, identity.confidence


def test_real_install_is_not_an_installer(tmp: Path) -> None:
    folder = tmp / "RealGame"
    _write_exe(folder / "RealGame.exe")
    (folder / "UnityPlayer.dll").write_bytes(b"x")
    assert looks_like_installer(folder) is False


# --- game confirmation ------------------------------------------------------

def test_engine_files_confirm_a_game(tmp: Path) -> None:
    folder = tmp / "SomeGame"
    _write_exe(folder / "SomeGame.exe")
    (folder / "UnityPlayer.dll").write_bytes(b"x")
    identity = identify_game(folder, folder / "SomeGame.exe")
    assert identity.confidence == CONFIRMED, identity.reasons
    assert identity.is_game


def test_steam_api_confirms_a_game(tmp: Path) -> None:
    folder = tmp / "SteamGame"
    _write_exe(folder / "SteamGame.exe")
    (folder / "steam_api64.dll").write_bytes(b"x")
    assert identify_game(folder, folder / "SteamGame.exe").is_game


def test_gog_metadata_gives_the_real_name(tmp: Path) -> None:
    import json

    folder = tmp / "ugly_folder_name-(999)"
    folder.mkdir()
    _write_exe(folder / "game.exe")
    (folder / "goggame-1234567890.info").write_text(
        json.dumps({"name": "The Witcher 3: Wild Hunt",
                    "playTasks": [{"path": "bin/x64/witcher3.exe"}]}),
        encoding="utf-8",
    )
    identity = identify_game(folder, folder / "game.exe")
    assert identity.display_name == "The Witcher 3: Wild Hunt", identity.display_name
    assert identity.store == "gog"
    assert identity.confidence == CONFIRMED


def test_launcher_folder_rejected(tmp: Path) -> None:
    folder = tmp / "GOG Galaxy"
    _write_exe(folder / "GalaxyClient.exe")
    identity = identify_game(folder, folder / "GalaxyClient.exe")
    assert identity.confidence == NOT_A_GAME, identity.reasons
    assert not identity.is_game


def test_tool_folder_rejected(tmp: Path) -> None:
    folder = tmp / "RivaTuner Statistics Server"
    _write_exe(folder / "RTSS.exe")
    identity = identify_game(folder, folder / "RTSS.exe")
    assert identity.confidence == NOT_A_GAME, identity.reasons


def test_plain_folder_stays_uncertain(tmp: Path) -> None:
    """No evidence either way: hidden by default, not deleted."""
    folder = tmp / "Some Application"
    _write_exe(folder / "app.exe")
    identity = identify_game(folder, folder / "app.exe")
    assert not identity.is_game, identity.confidence


def test_xbox_resource_token_is_not_used_as_name(tmp: Path) -> None:
    """MicrosoftGame.config often points at an unresolvable resource id."""
    folder = tmp / "XboxTitle"
    folder.mkdir()
    _write_exe(folder / "game.exe")
    (folder / "MicrosoftGame.config").write_text(
        '<Game><ShellVisuals DefaultDisplayName="ms-resource:AppDisplayName" /></Game>',
        encoding="utf-8",
    )
    identity = identify_game(folder, folder / "game.exe")
    assert not identity.display_name.startswith("ms-resource:"), identity.display_name


# --- picking a title over the folder name -----------------------------------

def test_filename_in_version_resource_rejected() -> None:
    """Control writes "Game_rmdwin10_f.exe" into FileDescription."""
    assert _looks_like_filename("Game_rmdwin10_f.exe") is True
    assert _looks_like_filename("Control") is False
    assert _is_better_title("Game_rmdwin10_f.exe", "Control") is False


def test_short_codename_loses_to_folder() -> None:
    """Palworld's executable calls itself "Pal"; the folder knows better."""
    assert _is_better_title("Pal", "Palworld") is False


def test_fuller_title_beats_folder() -> None:
    """A real title wins even when it starts like the folder name."""
    assert _is_better_title(
        "Halo: Campaign Evolved", "Halo Campaign Evolved Premium Edition"
    ) is True
    assert _is_better_title("Aliens: Fireteam Elite", "Aliens. Fireteam Elite") is True


def test_store_metadata_alone_does_not_confirm_an_empty_folder(tmp: Path) -> None:
    """Steam leaves steam_appid.txt behind when a game is uninstalled.

    That marker used to be enough for a CONFIRMED verdict, so an empty leftover
    folder listed as a fully recognised game that could never be installed to.
    """
    gone = tmp / "Uninstalled Game"
    gone.mkdir(parents=True)
    (gone / "steam_appid.txt").write_text("123456", encoding="utf-8")
    identity = identify_game(gone, None)
    assert not identity.is_game, identity.confidence

    # The same folder with a real binary stays a game.
    still_here = tmp / "Installed Game"
    still_here.mkdir(parents=True)
    (still_here / "steam_appid.txt").write_text("123456", encoding="utf-8")
    (still_here / "Installed Game.exe").write_bytes(b"MZ" + b"\0" * 200)
    assert identify_game(still_here, None).is_game


if __name__ == "__main__":
    tests = [
        test_clean_scene_names,
        test_clean_keeps_initialisms,
        test_clean_never_returns_empty,
        test_installer_folder_detected,
        test_real_install_is_not_an_installer,
        test_engine_files_confirm_a_game,
        test_steam_api_confirms_a_game,
        test_gog_metadata_gives_the_real_name,
        test_launcher_folder_rejected,
        test_tool_folder_rejected,
        test_plain_folder_stays_uncertain,
        test_store_metadata_alone_does_not_confirm_an_empty_folder,
        test_xbox_resource_token_is_not_used_as_name,
        test_filename_in_version_resource_rejected,
        test_short_codename_loses_to_folder,
        test_fuller_title_beats_folder,
    ]
    for func in tests:
        if func.__code__.co_argcount:
            with tempfile.TemporaryDirectory() as raw:
                func(Path(raw))
        else:
            func()
        print(f"  PASS  {func.__name__}")
    print("gameinfo OK")
