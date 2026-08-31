"""Screenshot the folder-based library after a real scan."""
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

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("library.png")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window.show()
    window.offer_default_folders()
    window._on_scan()

    def shot() -> None:
        rows = window.tree.topLevelItemCount()
        if rows and window.tree.currentItem() is None:
            window.tree.setCurrentItem(window.tree.topLevelItem(0))
        window.grab().save(str(OUT))
        print(f"rows   : {rows}")
        print(f"folders: {len(window.library.folders)}")
        print(f"saved  : {OUT}")
        # Close through the window so worker threads are stopped cleanly.
        window.close()
        app.quit()

    QTimer.singleShot(9000, shot)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
