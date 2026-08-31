"""Verify the generated ReShade.ini matches what the PowerShell version writes."""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.reshade_ini import write_dlss5_reshade_ini


def _sections(text: str) -> list[str]:
    return [
        line.strip()[1:-1]
        for line in text.splitlines()
        if line.strip().startswith("[") and line.strip().endswith("]")
    ]


def test_direct_mode_sections(tmp: Path) -> None:
    """Direct mode appends our sections and never chains the Feeder addon.

    [GENERAL] may be inherited from the bundled default INI: it carries
    ReShade's own shader search paths, which Direct mode does not own.
    """
    ini = tmp / "ReShade.ini"
    write_dlss5_reshade_ini(ini, feeder_mode=False)
    text = ini.read_text(encoding="utf-8")
    names = _sections(text)
    assert names[-5:] == ["OVERLAY", "ADDON", "RenoDX.DLSS5", "DLSS5", "RenoDX"], names
    assert "LoadFromDllMain=renodx-dlss5.addon64\n" in text.replace("\r\n", "\n")
    assert "dlss5-feed.addon64" not in text
    assert "DLSS5_Feed@DLSS5_Feed.fx" not in text


def test_feeder_mode_sections(tmp: Path) -> None:
    ini = tmp / "ReShade.ini"
    write_dlss5_reshade_ini(ini, feeder_mode=True)
    text = ini.read_text(encoding="utf-8")
    names = _sections(text)
    assert names == ["GENERAL", "OVERLAY", "ADDON", "RenoDX.DLSS5", "DLSS5", "RenoDX"], names
    assert "LoadFromDllMain=renodx-dlss5.addon64,dlss5-feed.addon64" in text
    assert "Lumenite_Kernel@lumenite_Kernel.fx" in text


def test_user_settings_preserved(tmp: Path) -> None:
    """Sections we do not own must survive a rewrite verbatim."""
    ini = tmp / "ReShade.ini"
    ini.write_text(
        "[INPUT]\nKeyMenu=36,0,0,0\n\n[SCREENSHOT]\nSavePath=C:\\shots\n",
        encoding="utf-8",
    )
    write_dlss5_reshade_ini(ini, feeder_mode=False)
    text = ini.read_text(encoding="utf-8")
    assert "KeyMenu=36,0,0,0" in text
    assert "SavePath=C:\\shots" in text
    assert "[INPUT]" in text and "[SCREENSHOT]" in text


def test_reinstall_is_idempotent(tmp: Path) -> None:
    """Running twice must not duplicate our sections."""
    ini = tmp / "ReShade.ini"
    write_dlss5_reshade_ini(ini, feeder_mode=True)
    first = ini.read_text(encoding="utf-8")
    write_dlss5_reshade_ini(ini, feeder_mode=True)
    second = ini.read_text(encoding="utf-8")
    assert first == second, "second write differs from the first"
    assert second.count("[ADDON]") == 1
    assert second.count("[RenoDX.DLSS5]") == 1


def test_mode_switch_drops_feeder_chain(tmp: Path) -> None:
    """Switching Feeder -> Direct must unhook the Feeder addon and its shaders."""
    ini = tmp / "ReShade.ini"
    write_dlss5_reshade_ini(ini, feeder_mode=True)
    assert "dlss5-feed.addon64" in ini.read_text(encoding="utf-8")

    write_dlss5_reshade_ini(ini, feeder_mode=False)
    text = ini.read_text(encoding="utf-8")
    assert "dlss5-feed.addon64" not in text, "stale Feeder addon survived the switch"
    assert "DLSS5_Feed@DLSS5_Feed.fx" not in text, "stale Feeder techniques survived"
    assert text.count("[ADDON]") == 1


def test_no_bom(tmp: Path) -> None:
    """ReShade cannot parse an INI that starts with a UTF-8 BOM."""
    ini = tmp / "ReShade.ini"
    write_dlss5_reshade_ini(ini, feeder_mode=False)
    assert not ini.read_bytes().startswith(b"\xef\xbb\xbf")


if __name__ == "__main__":
    tests = [
        test_direct_mode_sections,
        test_feeder_mode_sections,
        test_user_settings_preserved,
        test_reinstall_is_idempotent,
        test_mode_switch_drops_feeder_chain,
        test_no_bom,
    ]
    for func in tests:
        with tempfile.TemporaryDirectory() as raw:
            func(Path(raw))
        print(f"  PASS  {func.__name__}")
    print("reshade_ini OK")
