"""Verify the generated ReShade.ini matches what the PowerShell version writes."""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core import constants as C
from core.reshade_ini import (
    _ACTIVE_TECHNIQUES,
    _OPTIONAL_FILTERS,
    write_dlss5_reshade_ini,
    write_feeder_preset,
)


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


def test_optional_filters_are_offered_but_not_enabled(tmp: Path) -> None:
    """The v2.x payload ships CAS, SMAA, FXAA and friends.

    They belong in TechniqueSorting so the ReShade overlay lists them in a
    sensible order, but never in Techniques: switching one on is the user's
    choice, and enabling them by default would change the image nobody asked
    to change.
    """
    preset = tmp / "ReShadePreset.ini"
    write_feeder_preset(preset)
    text = preset.read_text(encoding="utf-8")

    active = next(l for l in text.splitlines() if l.startswith("Techniques="))
    sorting = next(l for l in text.splitlines() if l.startswith("TechniqueSorting="))

    # The Feeder chain must be the only thing running.
    assert active == "Techniques=" + _ACTIVE_TECHNIQUES, active

    shaders = C.PAYLOAD_ROOT / "feeder" / "shaders"
    for entry, filename in _OPTIONAL_FILTERS:
        if not (shaders / filename).is_file():
            continue
        assert entry in sorting, f"{entry} missing from the sort order"
        assert entry not in active, f"{entry} must not be enabled by default"


if __name__ == "__main__":
    tests = [
        test_direct_mode_sections,
        test_feeder_mode_sections,
        test_user_settings_preserved,
        test_reinstall_is_idempotent,
        test_mode_switch_drops_feeder_chain,
        test_no_bom,
        test_optional_filters_are_offered_but_not_enabled,
    ]
    for func in tests:
        with tempfile.TemporaryDirectory() as raw:
            func(Path(raw))
        print(f"  PASS  {func.__name__}")
    print("reshade_ini OK")
