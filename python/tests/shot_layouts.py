"""Screenshot both layout orientations, in a chosen language."""
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

OUT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
LANG = sys.argv[2] if len(sys.argv) > 2 else "EN"


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    if LANG != window.lang:
        window._set_language(LANG)
    window.show()

    if not window.library.entries:
        window.offer_default_folders()
        window._on_scan()

    def shoot() -> None:
        if window.tree.topLevelItemCount() and window.tree.currentItem() is None:
            window.tree.setCurrentItem(window.tree.topLevelItem(0))

        for label in ("horizontal", "vertical"):
            app.processEvents()
            out = OUT_DIR / f"layout_{label}_{LANG}.png"
            window.grab().save(str(out))
            print(f"  {label:11} {window.width()}x{window.height()}  -> {out.name}")
            if label == "horizontal":
                window._toggle_layout()

        print(f"rows: {window.tree.topLevelItemCount()}  lang: {window.lang}")
        window.close()
        app.quit()

    QTimer.singleShot(9000, shoot)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
