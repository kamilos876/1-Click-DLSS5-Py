"""Drive the real window through select -> install -> restore, headlessly.

Uses a synthetic game and payload under a temp dir, so no real install is
touched. Confirmation dialogs are auto-answered.
"""
import sys
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtWidgets import QApplication, QMessageBox

from core import constants as C
from core.messages import msg
from core.scanner import DiscoveredGame
from ui import theme
from ui.main_window import MainWindow

_PE64 = bytearray(512)
_PE64[0:2] = b"MZ"
_PE64[60:64] = (0x80).to_bytes(4, "little")
_PE64[0x80:0x84] = b"PE\0\0"
_PE64[0x84:0x86] = (0x8664).to_bytes(2, "little")


def _write_exe(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(_PE64))


def _make_zip(tmp: Path) -> Path:
    src = tmp / "zipsrc"
    src.mkdir(parents=True, exist_ok=True)
    _write_exe(src / "nvngx_dlssnr.dll")
    (src / "nvngx_dlss.dll").write_bytes(b"payload-dlss")
    zip_path = tmp / "streamline.zip"
    with zipfile.ZipFile(zip_path, "w") as archive:
        archive.write(src / "nvngx_dlssnr.dll", "nvngx_dlssnr.dll")
        archive.write(src / "nvngx_dlss.dll", "nvngx_dlss.dll")
    return zip_path


def _auto_answer_dialogs(monkey_yes: bool = True) -> None:
    """Silence modal dialogs so the flow runs unattended."""
    QMessageBox.question = staticmethod(
        lambda *a, **k: QMessageBox.StandardButton.Yes
        if monkey_yes
        else QMessageBox.StandardButton.No
    )
    QMessageBox.warning = staticmethod(lambda *a, **k: QMessageBox.StandardButton.Yes)
    QMessageBox.information = staticmethod(lambda *a, **k: QMessageBox.StandardButton.Ok)
    QMessageBox.critical = staticmethod(lambda *a, **k: QMessageBox.StandardButton.Ok)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication(sys.argv)
    app.setStyleSheet(theme.STYLESHEET)
    _auto_answer_dialogs()

    tmp = Path(tempfile.mkdtemp(prefix="dlss5-gui-"))
    C.CACHE_ROOT = tmp / "cache"

    game_dir = tmp / "SyntheticGame"
    _write_exe(game_dir / "SyntheticGame.exe")
    (game_dir / "nvngx_dlss.dll").write_bytes(b"ORIGINAL")

    window = MainWindow()
    window.show()

    game = DiscoveredGame(
        name=game_dir.name,
        path=game_dir,
        badge="TEST",
        order=3,
        exe_name="SyntheticGame.exe",
        icon_source=game_dir / "SyntheticGame.exe",
    )
    window._select_game(game)
    window.txt_zip.setText(str(_make_zip(tmp)))
    window.chk_reshade.setChecked(False)

    print(f"  inspector root  : {window.txt_root.text()}")
    print(f"  inspector exe   : {window.txt_exe.text()}")
    print(f"  detected        : {window.detected_upscaler}")
    print(f"  mode combo      : {window.combo_mode.currentText()[:44]}")
    assert window.txt_exe.text() == "SyntheticGame.exe"
    assert window.detected_upscaler == C.NATIVE_DLSS

    # Force Feeder mode to exercise the widest install path.
    window.combo_mode.setCurrentIndex(3)
    assert window._selected_mode() == C.MODE_FEEDER

    # Verify pass.
    window._on_verify()
    log_text = window.log.toPlainText()
    # The log follows the interface language, which now defaults to English.
    assert "validated successfully" in log_text, log_text[-400:]
    print("  verify          : OK")

    # Install synchronously: call the core path the worker would run.
    from core.installer import install_dlss5, is_installed, uninstall_dlss5

    upscaler = install_dlss5(
        target_path=str(game_dir),
        dlss_zip_path=window.txt_zip.text(),
        install_reshade_runtime=False,
        full_package=window.chk_full.isChecked(),
        selected_mode=window._selected_mode(),
        log=window.write_status,
    )
    print(f"  install         : {upscaler}")
    assert (game_dir / "ReShade.ini").is_file()

    # The inspector must now report the install.
    window._select_game(game)
    badge = window.lbl_game_badge.text()
    print(f"  badge after     : {badge[:52]}")
    # Default language is EN now, so accept either wording.
    assert "INSTALADO" in badge.upper() or "INSTALLED" in badge.upper(), badge

    uninstall_dlss5(str(game_dir), window.write_status)
    assert (game_dir / "nvngx_dlss.dll").read_bytes() == b"ORIGINAL"
    assert is_installed(game_dir) is None
    print("  restore         : OK (original DLL back)")

    window._select_game(game)
    print(f"  badge restored  : {window.lbl_game_badge.text()[:52]}")

    # Language switch must not crash and must retranslate.
    window._set_language("PT")
    assert "BIBLIOTECA" in window.lbl_library.text(), window.lbl_library.text()
    window._set_language("EN")
    assert "GAME LIBRARY" in window.lbl_library.text()
    print("  language switch : OK")

    # A worker reports failure as a Message key, not a sentence. Qt only accepts
    # str, so a handler that forwards the Message raw raises TypeError at the
    # worst possible moment -- while reporting another error.
    seen: list[object] = []
    QMessageBox.critical = staticmethod(
        lambda parent, title, text, *a, **k: seen.append(text)
        or QMessageBox.StandardButton.Ok
    )
    window._on_install_failed(msg("PayloadSelectZip"))
    assert seen, "install failure should surface a dialog"
    assert isinstance(seen[0], str), f"dialog got {type(seen[0]).__name__}, not str"
    assert seen[0] != "PayloadSelectZip", "the key leaked instead of its translation"
    print("  install failure : OK (Message rendered, not passed raw)")

    window.close()
    print("\ngui flow OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
