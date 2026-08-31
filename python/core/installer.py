"""Installing, verifying, restoring and launching a DLSS 5 injection."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable

from . import constants as C
from .detection import (
    DetectionError,
    GameTarget,
    detect_graphics_api,
    detect_upscaler_type,
    resolve_game_target,
)
from .messages import Message, msg
from .payload import LogFn, PayloadError, get_reshade_setup, install_reshade, prepare_payload, _noop
from .reshade_ini import write_dlss5_reshade_ini, write_feeder_preset
from .utils import driver_versions, gpu_names, is_x64_pe, iter_files


class InstallError(Exception):
    """Raised when an install or restore cannot proceed.

    Carries a Message so the UI renders it in the user's language.
    """

    def __init__(self, message: Message) -> None:
        super().__init__(message.key)
        self.message = message


@dataclass
class CompatibilityReport:
    """Outcome of the pre-install check shown in the diagnostics log."""

    can_install: bool = False
    # Message keys, rendered by the UI in the active language.
    fatal: list[Message] = field(default_factory=list)
    warnings: list[Message] = field(default_factory=list)
    info: list[Message] = field(default_factory=list)
    target: GameTarget | None = None
    payload_folder: Path | None = None


@dataclass
class InstallState:
    """The per-game state file recording what was injected and backed up."""

    installed_at: str
    target_exe: str
    mode: str
    upscaler_type: str
    backed_up_files: list[str] = field(default_factory=list)
    injected_files: list[str] = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(
            {
                "InstalledAt": self.installed_at,
                "TargetExe": self.target_exe,
                "Mode": self.mode,
                "UpscalerType": self.upscaler_type,
                "BackedUpFiles": self.backed_up_files,
                "InjectedFiles": self.injected_files,
            },
            indent=2,
        )

    @staticmethod
    def load(path: Path) -> "InstallState | None":
        """Read a state file, tolerating the PowerShell version's format."""
        try:
            data = json.loads(path.read_text(encoding="utf-8-sig"))
        except (OSError, ValueError):
            return None

        def as_list(value: object) -> list[str]:
            if isinstance(value, list):
                return [str(item) for item in value]
            if isinstance(value, str):
                return [value]
            return []

        return InstallState(
            installed_at=str(data.get("InstalledAt", "")),
            target_exe=str(data.get("TargetExe", "")),
            mode=str(data.get("Mode", C.MODE_DIRECT)),
            upscaler_type=str(data.get("UpscalerType", "")),
            backed_up_files=as_list(data.get("BackedUpFiles")),
            injected_files=as_list(data.get("InjectedFiles")),
        )


def mode_for_upscaler(upscaler_type: str) -> str:
    """Map a detected upscaler family onto the stored install mode."""
    if upscaler_type == C.NATIVE_DLSS:
        return C.MODE_DIRECT
    if upscaler_type in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
        return C.MODE_OPTISCALER
    return C.MODE_FEEDER


def resolve_selected_mode(selected: str, detected: str) -> str:
    """Turn the UI's mode choice into a concrete upscaler family."""
    return {
        C.MODE_DIRECT: C.NATIVE_DLSS,
        C.MODE_OPTISCALER: C.FSR2_BRIDGE,
        C.MODE_FEEDER: C.UNIVERSAL_FEEDER,
    }.get(selected, detected)


def check_compatibility(
    target_path: str,
    dlss_zip_path: str,
    log: LogFn = _noop,
) -> CompatibilityReport:
    """Resolve the game, describe the hardware and validate the payload."""
    report = CompatibilityReport()

    try:
        target = resolve_game_target(target_path)
    except DetectionError as err:
        report.fatal.append(err.message)
        return report

    report.target = target
    report.info.append(msg("GameRoot", target.root))
    report.info.append(msg("TargetExe", target.exe_name))
    report.info.append(msg("InjectFolder", target.install_folder))

    if target.existing_dlss_dll:
        report.info.append(msg("NativeDlssFound", target.existing_dlss_dll))
    else:
        report.warnings.append(msg("NoNativeDlss"))

    gpus = gpu_names()
    if gpus:
        gpu_text = ", ".join(gpus)
        import re

        if re.search(r"RTX\s*(20|30|40|50)", gpu_text):
            report.info.append(msg("GpuFullySupported", gpu_text))
        else:
            report.info.append(msg("GpuDetected", gpu_text))

    drivers = driver_versions()
    if drivers:
        report.info.append(msg("DriverVersion", ", ".join(drivers)))

    try:
        payload = prepare_payload(dlss_zip_path, log)
        report.payload_folder = payload.folder
        report.info.append(msg("PayloadValidated"))
    except PayloadError as err:
        report.fatal.append(err.message)

    report.can_install = not report.fatal
    return report


def install_dlss5(
    target_path: str,
    dlss_zip_path: str,
    install_reshade_runtime: bool,
    full_package: bool,
    selected_mode: str = C.MODE_AUTO,
    log: LogFn = _noop,
) -> str:
    """Inject DLSS 5 into a game and return the upscaler family that was used.

    Compatibility is re-checked first; the caller is expected to have already
    confirmed the action with the user.
    """
    report = check_compatibility(target_path, dlss_zip_path, log)
    for line in report.info:
        log(line, "INFO")
    for line in report.warnings:
        log(line, "WARN")
    for line in report.fatal:
        log(line, "ERROR")

    if not report.can_install or report.target is None or report.payload_folder is None:
        raise InstallError(msg("VerifyFailed"))

    target = report.target
    payload_folder = report.payload_folder
    folder = target.install_folder

    detected = detect_upscaler_type(folder, target.root)
    upscaler_type = resolve_selected_mode(selected_mode, detected)
    log(msg("ModeSelected", upscaler_type, detected), "INFO")

    backup_folder = folder / C.BACKUP_NAME
    backup_folder.mkdir(parents=True, exist_ok=True)
    state_file = folder / C.STATE_NAME

    prior = InstallState.load(state_file)
    state = InstallState(
        installed_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        target_exe=str(target.executable),
        mode=mode_for_upscaler(upscaler_type),
        upscaler_type=upscaler_type,
        backed_up_files=list(prior.backed_up_files) if prior else [],
    )

    graphics_api = detect_graphics_api(target.executable, folder)
    log(msg("GraphicsApiDetected", graphics_api), "INFO")

    injected_dll = ""
    if install_reshade_runtime:
        setup = get_reshade_setup(log)
        # Only the proxy DLL actually written is tracked, so a restore does not
        # delete a name this install never created.
        injected_dll = install_reshade(target.executable, setup, log, graphics_api)
        if injected_dll not in state.injected_files:
            state.injected_files.append(injected_dll)

    for legacy in C.LEGACY_ADDONS:
        legacy_path = folder / legacy
        if legacy_path.is_file():
            legacy_path.unlink(missing_ok=True)
            log(msg("LegacyAddonRemoved", legacy), "INFO")

    target_ini = folder / "ReShade.ini"

    if upscaler_type == C.NATIVE_DLSS:
        _install_direct(target, folder, backup_folder, payload_folder, full_package, state, target_ini, log)
    elif upscaler_type in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
        _install_optiscaler(upscaler_type, folder, backup_folder, payload_folder, state, target_ini, log)
    else:
        _install_feeder(
            target, folder, payload_folder, state, target_ini, log,
            keep_proxy={injected_dll} if injected_dll else None,
        )

    state_file.write_text(state.to_json(), encoding="utf-8")

    log(msg("Separator"), "OK")
    log(msg("InstallSucceeded"), "OK")
    if upscaler_type == C.NATIVE_DLSS:
        log(msg("HintDirect"), "OK")
    elif upscaler_type in (C.FSR2_BRIDGE, C.XESS_BRIDGE):
        bridge = "FSR2" if upscaler_type == C.FSR2_BRIDGE else "XeSS"
        log(msg("HintBridge", bridge), "OK")
    else:
        log(msg("HintFeeder"), "OK")
    log(msg("Separator"), "OK")

    return upscaler_type


def _remove_conflicts(folder: Path, names: list[str], keep: set[str] | None = None) -> None:
    """Delete rival hook DLLs so only one injection path stays active.

    ``keep`` protects the proxy DLL this run just installed: a d3d12 game gets
    ReShade as d3d12.dll, which the Feeder conflict list would otherwise delete.
    """
    protected = {name.lower() for name in (keep or set())}
    for name in names:
        if name.lower() in protected:
            continue
        path = folder / name
        if path.is_file():
            path.unlink(missing_ok=True)
    host64 = folder / "host64"
    if host64.is_dir():
        shutil.rmtree(host64, ignore_errors=True)


def _copy_with_backup(
    src: Path,
    dst: Path,
    backup_folder: Path,
    state: InstallState | None,
    track_name: str | None = None,
) -> None:
    """Copy a payload file, preserving the game's original on first overwrite."""
    if not src.is_file():
        return

    if dst.is_file():
        backup_dst = backup_folder / dst.name
        if not backup_dst.is_file():
            backup_folder.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, backup_dst)
            if state is not None and dst.name not in state.backed_up_files:
                state.backed_up_files.append(dst.name)

    shutil.copy2(src, dst)
    if state is not None and track_name and track_name not in state.injected_files:
        state.injected_files.append(track_name)


def _install_direct(
    target: GameTarget,
    folder: Path,
    backup_folder: Path,
    payload_folder: Path,
    full_package: bool,
    state: InstallState,
    target_ini: Path,
    log: LogFn,
) -> None:
    """Direct mode: Streamline runtime beside a game that already has DLSS."""
    log(msg("ModeDirectStart"), "INFO")
    _remove_conflicts(folder, C.CONFLICTS_FOR_DIRECT)

    write_dlss5_reshade_ini(target_ini, feeder_mode=False)
    if "ReShade.ini" not in state.injected_files:
        state.injected_files.append("ReShade.ini")

    files = C.FULL_FILES if full_package else C.MINIMAL_FILES
    for name in files:
        _copy_with_backup(payload_folder / name, folder / name, backup_folder, state, name)

    # Engine plugin folders (Unreal ships its own DLSS DLLs) need the same update.
    # Our own backup folders hold a copied nvngx_dlss.dll too, so they look like
    # plugin dirs and would be "updated" -- nesting a backup inside a backup and
    # burying the game's real originals one level deeper on every reinstall.
    plugin_dirs = {
        dll.parent
        for dll in iter_files(target.root, "nvngx_dlss.dll", max_depth=12)
        if dll.parent != folder and C.BACKUP_NAME not in dll.parts
    }
    for plugin_dir in sorted(plugin_dirs):
        log(msg("PluginUpdated", plugin_dir), "INFO")
        plugin_backup = plugin_dir / C.BACKUP_NAME
        plugin_backup.mkdir(parents=True, exist_ok=True)
        for name in files:
            _copy_with_backup(payload_folder / name, plugin_dir / name, plugin_backup, None)


def _install_optiscaler(
    upscaler_type: str,
    folder: Path,
    backup_folder: Path,
    payload_folder: Path,
    state: InstallState,
    target_ini: Path,
    log: LogFn,
) -> None:
    """Bridge mode: OptiScaler reroutes the game's FSR2/XeSS calls into DLSS."""
    bridge = "FSR2/FSR3" if upscaler_type == C.FSR2_BRIDGE else "XeSS"
    log(msg("ModeBridgeStart", bridge), "INFO")
    _remove_conflicts(folder, C.CONFLICTS_FOR_OPTISCALER)

    write_dlss5_reshade_ini(target_ini, feeder_mode=False)
    if "ReShade.ini" not in state.injected_files:
        state.injected_files.append("ReShade.ini")

    opti_root = C.PAYLOAD_ROOT / "optiscaler"
    opti_src = opti_root / "OptiScaler.dll"
    if not opti_src.is_file():
        raise InstallError(msg("OptiScalerMissing"))
    # OptiScaler loads as a version.dll proxy next to the executable.
    _copy_with_backup(opti_src, folder / "version.dll", backup_folder, state, "version.dll")
    log(msg("OptiScalerInstalled"), "OK")

    _copy_with_backup(
        opti_root / "OptiScaler.ini",
        folder / "OptiScaler.ini",
        backup_folder,
        state,
        "OptiScaler.ini",
    )

    _copy_with_backup(opti_root / "libxess.dll", folder / "libxess.dll", backup_folder, state, "libxess.dll")

    _copy_with_backup(
        payload_folder / "nvngx_dlssnr.dll",
        folder / "nvngx_dlssnr.dll",
        backup_folder,
        state,
        "nvngx_dlssnr.dll",
    )
    _copy_with_backup(
        C.PAYLOAD_ROOT / C.ADDON_NAME,
        folder / C.ADDON_NAME,
        backup_folder,
        state,
        C.ADDON_NAME,
    )


def _install_feeder(
    target: GameTarget,
    folder: Path,
    payload_folder: Path,
    state: InstallState,
    target_ini: Path,
    log: LogFn,
    keep_proxy: set[str] | None = None,
) -> None:
    """Feeder mode: synthesize a DLAA contract for games with no upscaler."""
    log(msg("ModeFeederStart"), "INFO")
    _remove_conflicts(folder, C.CONFLICTS_FOR_FEEDER, keep=keep_proxy)

    feeder_payload = C.PAYLOAD_ROOT / "feeder"
    is_x64 = is_x64_pe(target.executable)

    if is_x64:
        feed_src = feeder_payload / "dlss5-feed.addon64"
        if feed_src.is_file():
            shutil.copy2(feed_src, folder / "dlss5-feed.addon64")
            if "dlss5-feed.addon64" not in state.injected_files:
                state.injected_files.append("dlss5-feed.addon64")
            log(msg("FeederX64Installed"), "OK")
    else:
        # A 32-bit game cannot host the 64-bit DLSS runtime: it runs out of process.
        feed_src32 = feeder_payload / "dlss5-feed.addon32"
        if feed_src32.is_file():
            shutil.copy2(feed_src32, folder / "dlss5-feed.addon32")
            if "dlss5-feed.addon32" not in state.injected_files:
                state.injected_files.append("dlss5-feed.addon32")
            log(msg("FeederX86Installed"), "OK")

        host_src = feeder_payload / "host64"
        if host_src.is_dir():
            host_dst = folder / "host64"
            shutil.copytree(host_src, host_dst, dirs_exist_ok=True)

            addon_src = C.PAYLOAD_ROOT / C.ADDON_NAME
            if addon_src.is_file():
                shutil.copy2(addon_src, host_dst / C.ADDON_NAME)
            nr_src = payload_folder / "nvngx_dlssnr.dll"
            if nr_src.is_file():
                shutil.copy2(nr_src, host_dst / "nvngx_dlssnr.dll")
            dlss_src = payload_folder / "nvngx_dlss.dll"
            if dlss_src.is_file():
                shutil.copy2(dlss_src, host_dst / "nvngx_dlss.dll")

            if "host64" not in state.injected_files:
                state.injected_files.append("host64")

    _copy_with_backup(
        C.PAYLOAD_ROOT / C.ADDON_NAME,
        folder / C.ADDON_NAME,
        folder / C.BACKUP_NAME,
        state,
        C.ADDON_NAME,
    )

    # These overwrite DLLs a game may legitimately ship, so back up the
    # originals: a restore has to put the game's own runtime back.
    backup_folder = folder / C.BACKUP_NAME
    for name in ("nvngx_dlssnr.dll", "nvngx_dlss.dll"):
        _copy_with_backup(payload_folder / name, folder / name, backup_folder, state, name)

    shader_dir = folder / "reshade-shaders" / "Shaders"
    texture_dir = folder / "reshade-shaders" / "Textures"
    shader_dir.mkdir(parents=True, exist_ok=True)
    texture_dir.mkdir(parents=True, exist_ok=True)

    src_shaders = feeder_payload / "shaders"
    if src_shaders.is_dir():
        shutil.copytree(src_shaders, shader_dir, dirs_exist_ok=True)
        log(msg("ShadersInstalled"), "OK")

    src_textures = feeder_payload / "textures"
    if src_textures.is_dir():
        shutil.copytree(src_textures, texture_dir, dirs_exist_ok=True)
        log(msg("TexturesInstalled"), "OK")

    if "reshade-shaders" not in state.injected_files:
        state.injected_files.append("reshade-shaders")

    cfg_src = feeder_payload / "dlss5-feed.cfg"
    if cfg_src.is_file():
        shutil.copy2(cfg_src, folder / "dlss5-feed.cfg")
        if "dlss5-feed.cfg" not in state.injected_files:
            state.injected_files.append("dlss5-feed.cfg")

    write_dlss5_reshade_ini(target_ini, feeder_mode=True)
    if "ReShade.ini" not in state.injected_files:
        state.injected_files.append("ReShade.ini")

    write_feeder_preset(folder / "ReShadePreset.ini")
    if "ReShadePreset.ini" not in state.injected_files:
        state.injected_files.append("ReShadePreset.ini")

    log(msg("FeederConfigured"), "OK")


def uninstall_dlss5(target_path: str, log: LogFn = _noop) -> None:
    """Restore a game to its factory state, reinstating every backed-up file."""
    target = resolve_game_target(target_path)
    folder = target.install_folder
    state_file = folder / C.STATE_NAME
    backup_folder = folder / C.BACKUP_NAME

    log(msg("RestoreStart", folder), "INFO")

    if backup_folder.is_dir():
        for backed in sorted(backup_folder.iterdir()):
            if backed.is_file():
                shutil.copy2(backed, folder / backed.name)
                log(msg("FileRestored", backed.name), "OK")
        shutil.rmtree(backup_folder, ignore_errors=True)

    # Engine plugin folders got their own backup during a Direct install.
    for plugin_backup in _find_plugin_backups(target.root):
        parent = plugin_backup.parent
        for backed in sorted(plugin_backup.iterdir()):
            if backed.is_file():
                shutil.copy2(backed, parent / backed.name)
                log(msg("PluginFileRestored", backed.name), "OK")
        shutil.rmtree(plugin_backup, ignore_errors=True)

    state = InstallState.load(state_file)
    backed_up_names = set(state.backed_up_files) if state else set()

    injected_names = set(state.injected_files) if state else set()

    for name in C.PURGE_LIST:
        # A restored original must never be deleted by the purge pass.
        if name in backed_up_names:
            continue
        # Nor may a file the game shipped itself: only delete one of those when
        # this install is on record as having put it there.
        if name in C.GAME_OWNED_FILES and name not in injected_names:
            continue
        path = folder / name
        if path.is_file():
            path.unlink(missing_ok=True)

    state_file.unlink(missing_ok=True)

    for directory in ("host64", "reshade-shaders"):
        path = folder / directory
        if path.is_dir():
            shutil.rmtree(path, ignore_errors=True)

    log(msg("RestoreDone"), "OK")


def _find_plugin_backups(root: Path, max_depth: int = 12) -> list[Path]:
    """Locate every backup folder this tool created under a game root."""
    import os

    found: list[Path] = []
    stack: list[tuple[Path, int]] = [(root, 0)]
    while stack:
        current, depth = stack.pop()
        try:
            entries = list(os.scandir(current))
        except (OSError, PermissionError):
            continue
        for entry in entries:
            try:
                if not entry.is_dir(follow_symlinks=False):
                    continue
            except OSError:
                continue
            if entry.name == C.BACKUP_NAME:
                found.append(Path(entry.path))
            elif depth < max_depth:
                stack.append((Path(entry.path), depth + 1))
    return found


def is_installed(folder: Path) -> InstallState | None:
    """Return the recorded install state for a game folder, if any."""
    return InstallState.load(folder / C.STATE_NAME)


def launch_game(target_path: str, log: LogFn = _noop) -> None:
    """Start the resolved game executable in its own working directory."""
    target = resolve_game_target(target_path)
    log(msg("Launching", target.exe_name), "INFO")
    if sys.platform == "win32":
        subprocess.Popen([str(target.executable)], cwd=str(target.install_folder))
    else:
        subprocess.Popen([str(target.executable)], cwd=str(target.install_folder))
