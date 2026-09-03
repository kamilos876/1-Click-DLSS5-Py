"""Rewriting ReShade.ini so DLSS 5 loads with the right addon chain."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

from . import constants as C

_SECTION_RE = re.compile(r"^\[(.*)\]$")

# Keys removed wholesale so a reinstall never inherits stale tuning values.
_STRIPPED_KEY_RE = re.compile(
    r"^(Neural|NRPreset|NRStyle|NRIntensity|NRLocalTone|NRLocalStructure"
    r"|NRSkinStructure|NRAutoMask|NRUICorrection|AutoSkinMask|LocalToneStrength"
    r"|StructureStrength|SkinStructure|NeuralIntensity|NeuralUplift|Preset="
    r"|Style=|Enabled=|LoadFromDllMain=renodx|TutorialProgress|ShowOverlayMessage"
    r"|ShowPresetTransitionMessage|ShowScreenshotMessage)"
)

# Technique lines that reference the Feeder-only shader chain.
_FEEDER_TECHNIQUE_RE = re.compile(r"^(Techniques|TechniqueSorting)\s*=.*(DLSS5_Feed|[Ll]umenite)")

_OVERLAY_SECTION = """[OVERLAY]
TutorialProgress=4
ShowOverlayMessage=0
ShowPresetTransitionMessage=0
ShowScreenshotMessage=0
ShowFPS=0
ShowClock=0"""

_GENERAL_SECTION_FEEDER = r"""[GENERAL]
EffectSearchPaths=.\reshade-shaders\Shaders,.\reshade-shaders\Shaders\include,.\
TextureSearchPaths=.\reshade-shaders\Textures,.\
Techniques=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
TechniqueSorting=Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx
PreprocessorDefinitions=DLSS5_MV_PROVIDER=3,IMAGE_SPACE=1
PerformanceMode=0
NoReloadOnInit=0
SkipLoadingDisabledEffects=0
"""

_RENODX_SECTION = """[RenoDX.DLSS5]
NeuralUplift=1
NREnableUpscaling=0
NRPreset=2
NRStyle=1
NRIntensity=0.850000
NRLocalTone=1.000000
NRLocalStructure=1.000000
NRSkinStructure=-0.500000
NRAutoMask=1
NRUICorrection=1
NRPaperWhiteScale=1.000000
NRTransferStrength=1.000000
NRColorStrength=1.000000
NRDepthMode=0
NRMVecScaleX=1.000000
NRMVecScaleY=1.000000
EnableHooks=2
NRToggleKey=117
NRScreenshotKey=116

[DLSS5]
Enabled=1
AutoSkinMask=1
NRAutoMask=1
Preset=2
NRPreset=2
Style=1
NRStyle=1
NeuralIntensity=0.850000
NRIntensity=0.850000
LocalToneStrength=1.000000
StructureStrength=1.000000
SkinStructure=-0.500000

[RenoDX]
NeuralUplift=1
AutoSkinMask=1
NRAutoMask=1
NeuralIntensity=0.850000
NRIntensity=0.850000
Preset=2
NRPreset=2
Style=1
NRStyle=1"""

# The chain that must run, in this order, for the Feeder to work at all.
_ACTIVE_TECHNIQUES = "Lumenite_Kernel@lumenite_Kernel.fx,DLSS5_Feed@DLSS5_Feed.fx"

# Optional filters shipped in the payload since the v2.x releases. They are
# listed in the sort order but never in Techniques, so they sit ready in the
# ReShade overlay for the user to switch on, without altering the image by
# default. Each is offered only when its .fx is actually present.
_OPTIONAL_FILTERS = [
    ("SMAA@SMAA.fx", "SMAA.fx"),
    ("FXAA@FXAA.fx", "FXAA.fx"),
    ("Lumenite_TRAA@lumenite_TRAA.fx", "lumenite_TRAA.fx"),
    ("Vibrance@Vibrance.fx", "Vibrance.fx"),
    ("Tonemap@Tonemap.fx", "Tonemap.fx"),
    ("ContrastAdaptiveSharpen@CAS.fx", "CAS.fx"),
    ("Splitscreen@Splitscreen.fx", "Splitscreen.fx"),
]


def _technique_sorting() -> str:
    """The Feeder chain, followed by whichever optional filters are installed."""
    shaders = C.PAYLOAD_ROOT / "feeder" / "shaders"
    available = [
        entry for entry, filename in _OPTIONAL_FILTERS if (shaders / filename).is_file()
    ]
    return ",".join([_ACTIVE_TECHNIQUES] + available)


_PRESET_BODY = "\r\n".join([
    "",
    "",
    "[DLSS5_Feed.fx]",
    "VALIDATE_LUMA=1",
    "LUMA_TOLERANCE=0.150000",
    "VALIDATE_STATIC=1",
    "STATIC_BIAS=0.350000",
    "STATIC_MIN_CONTRAST=0.005000",
    "MASK_STRENGTH=1.000000",
    "VALIDATE_DEPTH=1",
    "VALIDATE_MV=1",
    "MV_CONSISTENCY=1.000000",
    "GEOM_ENABLE=0",
])


def feeder_preset_content() -> str:
    """ReShadePreset.ini for Feeder mode: the chain, its order, and its tuning."""
    header = "\r\n".join([
        f"Techniques={_ACTIVE_TECHNIQUES}",
        f"TechniqueSorting={_technique_sorting()}",
    ])
    return header + _PRESET_BODY


def write_dlss5_reshade_ini(ini_path: Path, feeder_mode: bool = False) -> None:
    """Strip our previous sections from ReShade.ini and append a fresh config.

    The user's own ReShade settings are preserved; only sections this tool owns
    are replaced. Any failure falls back to copying the bundled default INI.
    """
    default_ini = C.PAYLOAD_ROOT / "ReShade.ini"

    if not ini_path.is_file() and default_ini.is_file():
        shutil.copy2(default_ini, ini_path)

    try:
        base_text = _strip_managed_sections(ini_path, feeder_mode)
        sections = _build_sections(feeder_mode)
        final = sections.strip() if not base_text else base_text + "\r\n" + sections
        # UTF-8 without BOM: ReShade will not parse a BOM-prefixed INI.
        ini_path.write_text(final, encoding="utf-8", newline="")
    except OSError:
        if default_ini.is_file():
            shutil.copy2(default_ini, ini_path)


def _strip_managed_sections(ini_path: Path, feeder_mode: bool) -> str:
    """Return the INI text with this tool's own sections and keys removed."""
    if not ini_path.is_file():
        return ""

    try:
        text = ini_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""

    ignored = {"RenoDX.DLSS5", "ADDON", "DLSS5", "RenoDX", "OVERLAY"}
    if feeder_mode:
        # Feeder mode owns [GENERAL] too: it pins the shader technique order.
        ignored.add("GENERAL")

    kept: list[str] = []
    current_section = ""
    for line in text.splitlines():
        stripped = line.strip()
        match = _SECTION_RE.match(stripped)
        if match:
            current_section = match.group(1)
        if current_section in ignored:
            continue
        if _STRIPPED_KEY_RE.match(stripped):
            continue
        # Technique lists naming Feeder shaders must go even when [GENERAL] is
        # kept: switching to Direct deletes those .fx files, and ReShade fails
        # to load an effect chain that points at them.
        if current_section == "GENERAL" and _FEEDER_TECHNIQUE_RE.match(stripped):
            continue
        kept.append(line)

    return "\r\n".join(kept).strip()


def _build_sections(feeder_mode: bool) -> str:
    """Compose the INI sections this tool appends."""
    addon_line = (
        "LoadFromDllMain=renodx-dlss5.addon64,dlss5-feed.addon64"
        if feeder_mode
        else "LoadFromDllMain=renodx-dlss5.addon64"
    )
    general = _GENERAL_SECTION_FEEDER if feeder_mode else ""
    return f"{general}\n{_OVERLAY_SECTION}\n\n[ADDON]\n{addon_line}\n\n{_RENODX_SECTION}\n"


def write_feeder_preset(preset_path: Path) -> None:
    """Write ReShadePreset.ini pinning the LumeniteFX -> DLSS5_Feed chain."""
    preset_path.write_text(feeder_preset_content(), encoding="utf-8", newline="")
