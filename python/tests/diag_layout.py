"""Report the inspector's geometry to find where widgets get squeezed."""
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


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    app = QApplication([])
    app.setStyle("Fusion")
    app.setStyleSheet(theme.STYLESHEET)

    window = MainWindow()
    window.resize(1200, 900)
    window.show()

    def report() -> None:
        widgets = [
            ("lbl_inspector", window.lbl_inspector),
            ("lbl_root", window.lbl_root),
            ("txt_root", window.txt_root),
            ("lbl_inject", window.lbl_inject),
            ("txt_inject", window.txt_inject),
            ("lbl_exe", window.lbl_exe),
            ("txt_exe", window.txt_exe),
            ("lbl_mode", window.lbl_mode),
            ("combo_mode", window.combo_mode),
            ("lbl_payload", window.lbl_payload),
            ("txt_zip", window.txt_zip),
        ]
        print(f"{'widget':16} {'y':>5} {'h':>4} {'hint':>5} {'min':>5}  bottom")
        print("-" * 58)
        rows = []
        for name, w in widgets:
            geo = w.geometry()
            top_left = w.mapTo(window, geo.topLeft() - geo.topLeft())
            y = top_left.y()
            rows.append((name, y, geo.height(), w.sizeHint().height(),
                         w.minimumSizeHint().height()))
            print(f"{name:16} {y:5} {geo.height():4} "
                  f"{w.sizeHint().height():5} {w.minimumSizeHint().height():5}"
                  f"  {y + geo.height()}")

        print()
        # Widgets side by side in the same grid row share a y; only compare
        # ones that actually overlap horizontally.
        def rect_of(name):
            widget = dict(widgets)[name]
            geo = widget.geometry()
            x = widget.mapTo(window, geo.topLeft() - geo.topLeft()).x()
            return x, x + geo.width()

        clipped = [n for n, _y, h, hint, _m in rows if h < hint]
        for i, (n1, y1, h1, _, _) in enumerate(rows):
            for (n2, y2, h2, _, _) in rows[i + 1:]:
                if y2 >= y1 + h1 or y1 >= y2 + h2:
                    continue
                l1, r1 = rect_of(n1)
                l2, r2 = rect_of(n2)
                if r1 <= l2 or r2 <= l1:
                    continue  # side by side, not stacked
                print(f"OVERLAP: {n1} and {n2} share space vertically")

        if clipped:
            print(f"CLIPPED (height below hint): {', '.join(clipped)}")
        else:
            print("No clipped widgets: every control has its full height.")

        # Is the panel shorter than the sum of what it holds?
        panel = window.lbl_inspector.parentWidget()
        print(f"\ninspector panel height : {panel.height()}")
        print(f"inspector size hint    : {panel.sizeHint().height()}")
        print(f"inspector minimum hint : {panel.minimumSizeHint().height()}")
        if panel.height() < panel.minimumSizeHint().height():
            print("PANEL IS SQUEEZED BELOW ITS MINIMUM")

        window.close()
        app.quit()

    QTimer.singleShot(500, report)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
