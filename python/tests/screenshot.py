"""Render the main window offscreen and save a PNG for visual review."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Must precede any `ui` import: it redirects the cache away from the
# user's real library.
import isolation  # noqa: E402,F401

from PySide6.QtCore import QTimer
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication

from core import constants as C
from ui import theme
from ui.main_window import MainWindow


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("window.png")
    populate = "--scan" in sys.argv

    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)
    if C.ICON_PATH.is_file():
        app.setWindowIcon(QIcon(str(C.ICON_PATH)))

    window = MainWindow()
    window.resize(1200, 900)
    window.show()

    if populate:
        # Fill the library synchronously so the shot shows real rows.
        from core.i18n import get_dict
        from core.scanner import default_library_folders, scan_folders

        window.games = scan_folders(
            default_library_folders(), badges=get_dict(window.lang)
        )
        window._apply_filter()
        if window.tree.topLevelItemCount() > 0:
            window.tree.setCurrentItem(window.tree.topLevelItem(0))

    def capture() -> None:
        window.grab().save(str(out))
        print(f"saved {out} ({out.stat().st_size} bytes)")
        app.quit()

    QTimer.singleShot(600, capture)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
