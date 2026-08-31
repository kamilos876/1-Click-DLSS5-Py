"""Screenshot the window in English with a real game preselected."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from ui import theme
from ui.main_window import MainWindow

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("win_en.png")
GAME = sys.argv[2] if len(sys.argv) > 2 else r"E:\Games\Halo Campaign Evolved Premium Edition"


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window._set_language("EN")
    window.show()
    window.preselect_folder(GAME)

    def shot() -> None:
        window.grab().save(str(OUT))
        print(f"exe   : {window.txt_exe.text()}")
        print(f"lang  : {window.lang}")
        print(f"lib   : {window.lbl_library.text()}")
        print(f"mode  : {window.combo_mode.currentText()}")
        print(f"saved : {OUT}")
        app.quit()

    QTimer.singleShot(500, shot)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
